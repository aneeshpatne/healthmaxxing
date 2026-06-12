import { Database } from "bun:sqlite";

export const db = new Database("mydb.sqlite");

export const BODY_COMPOSITION_METRICS_NEW_FACTORS = [
  "bmi",
  "body_fat_pct",
  "body_score",
  "body_age_years",
  "water_pct",
  "muscle_mass_kg",
  "bmr_kcal",
  "visceral_fat",
  "protein_pct",
  "subcutaneous_fat_pct",
] as const;

db.run(`
  CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    mail_address TEXT UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profiles (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    name TEXT,
    is_primary INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(account_id) REFERENCES accounts(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profile_metadata (
    profile_id TEXT PRIMARY KEY,
    height_cm REAL,
    date_of_birth TEXT,
    people_type TEXT,
    gender TEXT,
    profile_image TEXT,
    preferred_body_fat_pct REAL NOT NULL DEFAULT 18,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

const profileMetadataColumns = db
  .prepare("PRAGMA table_info(profile_metadata)")
  .all() as Array<{ name: string }>;
const profileMetadataColumnNames = new Set(
  profileMetadataColumns.map((column) => column.name),
);

if (!profileMetadataColumnNames.has("preferred_body_fat_pct")) {
  db.run(
    "ALTER TABLE profile_metadata ADD COLUMN preferred_body_fat_pct REAL NOT NULL DEFAULT 18",
  );
}

db.run(`
  CREATE TABLE IF NOT EXISTS jobs (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TEXT,
    result TEXT,
    error TEXT,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS measurements (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    weight REAL,
    heart_rate INTEGER,
    impedance REAL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS body_measurements (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    neck_cm REAL,
    shoulder_cm REAL,
    chest_cm REAL,
    stomach_cm REAL,
    waist_cm REAL,
    calf_cm REAL,
    thigh_cm REAL,
    bicep_cm REAL,
    forearm_cm REAL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id),
    CHECK (
      neck_cm IS NOT NULL OR
      shoulder_cm IS NOT NULL OR
      chest_cm IS NOT NULL OR
      stomach_cm IS NOT NULL OR
      waist_cm IS NOT NULL OR
      calf_cm IS NOT NULL OR
      thigh_cm IS NOT NULL OR
      bicep_cm IS NOT NULL OR
      forearm_cm IS NOT NULL
    )
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS body_composition_metrics (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    body_fat_pct REAL NOT NULL,
    muscle_mass_kg REAL NOT NULL,
    water_pct REAL NOT NULL,
    protein_pct REAL NOT NULL,
    fat_free_mass_kg REAL NOT NULL,
    fat_mass_kg REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS body_composition_metrics_new (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    bmi REAL NOT NULL,
    body_fat_pct REAL NOT NULL,
    fat_mass_kg REAL NOT NULL,
    fat_free_mass_kg REAL NOT NULL,
    desired_weight_kg REAL NOT NULL,
    body_score INTEGER NOT NULL,
    body_age_years INTEGER NOT NULL,
    water_pct REAL NOT NULL,
    muscle_mass_kg REAL NOT NULL,
    muscle_rate_pct REAL NOT NULL,
    bmr_kcal INTEGER NOT NULL,
    visceral_fat INTEGER NOT NULL,
    ideal_weight_kg REAL NOT NULL,
    protein_mass_kg REAL NOT NULL,
    protein_pct REAL NOT NULL,
    skeletal_muscle_kg REAL NOT NULL,
    subcutaneous_fat_pct REAL NOT NULL,
    subcutaneous_fat_mass_kg REAL NOT NULL,
    predicted_lean_mass_kg REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS derived_body_composition_metrics (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    fmi REAL NOT NULL,
    ffmi REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

const bodyCompositionMetricsNewColumns = db
  .prepare("PRAGMA table_info(body_composition_metrics_new)")
  .all() as Array<{ name: string }>;
const bodyCompositionMetricsNewColumnNames = new Set(
  bodyCompositionMetricsNewColumns.map((column) => column.name),
);

if (!bodyCompositionMetricsNewColumnNames.has("desired_weight_kg")) {
  db.run("ALTER TABLE body_composition_metrics_new ADD COLUMN desired_weight_kg REAL");
  db.run(`
    UPDATE body_composition_metrics_new
    SET desired_weight_kg = ROUND(predicted_lean_mass_kg / 0.82, 2)
    WHERE desired_weight_kg IS NULL
  `);
}

db.run(`
  CREATE TABLE IF NOT EXISTS progress_measurements (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT NOT NULL DEFAULT 'cm',
    notes TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profile_ai_overviews (
    profile_id TEXT PRIMARY KEY,
    overview_title TEXT NOT NULL,
    overview_remarks TEXT NOT NULL,
    foundation TEXT NOT NULL,
    momentum TEXT NOT NULL,
    biggest_lever TEXT NOT NULL,
    physique_archetype TEXT NOT NULL,
    model_name TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profile_effort_scores (
    profile_id TEXT PRIMARY KEY,
    score INTEGER NOT NULL CHECK(score >= 0 AND score <= 100),
    remark TEXT NOT NULL,
    model_name TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS derived_metrics_comments (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL UNIQUE,
    ffmi TEXT NOT NULL,
    ffmi_vs_fmi TEXT NOT NULL,
    composition_flow TEXT NOT NULL,
    composition_trend TEXT NOT NULL,
    recomp_vector TEXT NOT NULL,
    excess_fat_gauge TEXT NOT NULL,
    body_ratios TEXT NOT NULL,
    model_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS reports (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    lab_name TEXT,
    report_date TEXT,
    collection_date TEXT,
    extraction_status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
  )
`);

const reportColumns = db
  .prepare("PRAGMA table_info(reports)")
  .all() as Array<{ name: string }>;
const reportColumnNames = new Set(reportColumns.map((column) => column.name));
const hasLegacyReportColumns =
  reportColumnNames.has("raw_text") || reportColumnNames.has("source_file_url");

if (hasLegacyReportColumns) {
  db.run("DROP INDEX IF EXISTS idx_reports_profile_report_date");
  db.run("DROP INDEX IF EXISTS idx_reports_extraction_status");
  db.run("ALTER TABLE reports RENAME TO reports_legacy");
  db.run(`
    CREATE TABLE reports (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL,
      lab_name TEXT,
      report_date TEXT,
      collection_date TEXT,
      extraction_status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
    )
  `);
  db.run(`
    INSERT INTO reports (
      id,
      profile_id,
      lab_name,
      report_date,
      collection_date,
      extraction_status,
      created_at
    )
    SELECT
      id,
      profile_id,
      lab_name,
      report_date,
      collection_date,
      extraction_status,
      created_at
    FROM reports_legacy
  `);
  db.run("DROP TABLE reports_legacy");
}

db.run(`
  CREATE INDEX IF NOT EXISTS idx_reports_profile_report_date
  ON reports(profile_id, report_date DESC, created_at DESC)
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_reports_extraction_status
  ON reports(extraction_status)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS report_sections (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    section_name_raw TEXT NOT NULL,
    section_name_normalized TEXT,
    FOREIGN KEY(report_id) REFERENCES reports(id) ON DELETE CASCADE
  )
`);

const reportSectionColumns = db
  .prepare("PRAGMA table_info(report_sections)")
  .all() as Array<{ name: string }>;
const reportSectionColumnNames = new Set(
  reportSectionColumns.map((column) => column.name),
);

if (reportSectionColumnNames.has("sort_order")) {
  db.run("DROP INDEX IF EXISTS idx_report_sections_report_sort");
  db.run("ALTER TABLE report_sections RENAME TO report_sections_legacy");
  db.run(`
    CREATE TABLE report_sections (
      id TEXT PRIMARY KEY,
      report_id TEXT NOT NULL,
      section_name_raw TEXT NOT NULL,
      section_name_normalized TEXT,
      FOREIGN KEY(report_id) REFERENCES reports(id) ON DELETE CASCADE
    )
  `);
  db.run(`
    INSERT INTO report_sections (
      id,
      report_id,
      section_name_raw,
      section_name_normalized
    )
    SELECT
      id,
      report_id,
      section_name_raw,
      section_name_normalized
    FROM report_sections_legacy
  `);
  db.run("DROP TABLE report_sections_legacy");
}

db.run(`
  CREATE INDEX IF NOT EXISTS idx_report_sections_report_id
  ON report_sections(report_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS observation_fields (
    id TEXT PRIMARY KEY,
    field_name TEXT NOT NULL,
    field_name_normalized TEXT NOT NULL UNIQUE,
    explanation TEXT NOT NULL DEFAULT '',
    default_unit TEXT,
    is_trendable INTEGER NOT NULL DEFAULT 0 CHECK(is_trendable IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
`);

const observationFieldColumns = db
  .prepare("PRAGMA table_info(observation_fields)")
  .all() as Array<{ name: string }>;
const observationFieldColumnNames = new Set(
  observationFieldColumns.map((column) => column.name),
);

if (!observationFieldColumnNames.has("is_trendable")) {
  db.run(
    "ALTER TABLE observation_fields ADD COLUMN is_trendable INTEGER NOT NULL DEFAULT 0 CHECK(is_trendable IN (0, 1))",
  );
}

if (
  observationFieldColumnNames.has("updated_at") ||
  observationFieldColumnNames.has("loinc_code")
) {
  db.run("DROP INDEX IF EXISTS idx_observation_fields_name");
  db.run("ALTER TABLE observation_fields RENAME TO observation_fields_legacy");
  db.run(`
    CREATE TABLE observation_fields (
      id TEXT PRIMARY KEY,
      field_name TEXT NOT NULL,
      field_name_normalized TEXT NOT NULL UNIQUE,
      explanation TEXT NOT NULL DEFAULT '',
      default_unit TEXT,
      is_trendable INTEGER NOT NULL DEFAULT 0 CHECK(is_trendable IN (0, 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  db.run(`
    INSERT INTO observation_fields (
      id,
      field_name,
      field_name_normalized,
      explanation,
      default_unit,
      is_trendable,
      created_at
    )
    SELECT
      id,
      field_name,
      field_name_normalized,
      explanation,
      default_unit,
      is_trendable,
      created_at
    FROM observation_fields_legacy
  `);
  db.run("DROP TABLE observation_fields_legacy");
}

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observation_fields_name
  ON observation_fields(field_name_normalized)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS observation_field_remarks (
    id TEXT PRIMARY KEY,
    observation_field_id TEXT NOT NULL UNIQUE,
    remark TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(observation_field_id) REFERENCES observation_fields(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observation_field_remarks_field
  ON observation_field_remarks(observation_field_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS observations (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    section_id TEXT,
    observation_field_id TEXT,
    test_name_raw TEXT NOT NULL,
    test_name_normalized TEXT,
    value_raw TEXT NOT NULL,
    value_numeric REAL,
    value_text TEXT,
    unit_raw TEXT,
    unit_normalized TEXT,
    reference_range_raw TEXT,
    ref_low REAL,
    ref_high REAL,
    inference TEXT NOT NULL DEFAULT '',
    confidence_score REAL CHECK(confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(report_id) REFERENCES reports(id) ON DELETE CASCADE,
    FOREIGN KEY(section_id) REFERENCES report_sections(id) ON DELETE SET NULL,
    FOREIGN KEY(observation_field_id) REFERENCES observation_fields(id) ON DELETE SET NULL
  )
`);

const observationColumns = db
  .prepare("PRAGMA table_info(observations)")
  .all() as Array<{ name: string; notnull: number }>;
const observationColumnNames = new Set(
  observationColumns.map((column) => column.name),
);
const observationInferenceColumn = observationColumns.find(
  (column) => column.name === "inference",
);

if (!observationColumnNames.has("observation_field_id")) {
  db.run("ALTER TABLE observations ADD COLUMN observation_field_id TEXT");
}

if (!observationColumnNames.has("inference")) {
  db.run("ALTER TABLE observations ADD COLUMN inference TEXT NOT NULL DEFAULT ''");
}

const observationForeignKeys = db
  .prepare("PRAGMA foreign_key_list(observations)")
  .all() as Array<{ table: string }>;
const hasObservationFieldForeignKey = observationForeignKeys.some(
  (foreignKey) => foreignKey.table === "observation_fields",
);
const hasLegacyObservationColumns =
  observationColumnNames.has("loinc_code") ||
  observationColumnNames.has("flag") ||
  observationColumnNames.has("extraction_notes") ||
  observationColumnNames.has("raw_json");
const hasNullableObservationInference =
  observationInferenceColumn !== undefined &&
  observationInferenceColumn.notnull === 0;

if (
  !hasObservationFieldForeignKey ||
  hasLegacyObservationColumns ||
  hasNullableObservationInference
) {
  db.run("DROP INDEX IF EXISTS idx_observations_report");
  db.run("DROP INDEX IF EXISTS idx_observations_section");
  db.run("DROP INDEX IF EXISTS idx_observations_test_name");
  db.run("DROP INDEX IF EXISTS idx_observations_observation_field");
  db.run("ALTER TABLE observations RENAME TO observations_legacy");
  db.run(`
    CREATE TABLE observations (
      id TEXT PRIMARY KEY,
      report_id TEXT NOT NULL,
      section_id TEXT,
      observation_field_id TEXT,
      test_name_raw TEXT NOT NULL,
      test_name_normalized TEXT,
      value_raw TEXT NOT NULL,
      value_numeric REAL,
      value_text TEXT,
      unit_raw TEXT,
      unit_normalized TEXT,
      reference_range_raw TEXT,
      ref_low REAL,
      ref_high REAL,
      inference TEXT NOT NULL DEFAULT '',
      confidence_score REAL CHECK(confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(report_id) REFERENCES reports(id) ON DELETE CASCADE,
      FOREIGN KEY(section_id) REFERENCES report_sections(id) ON DELETE SET NULL,
      FOREIGN KEY(observation_field_id) REFERENCES observation_fields(id) ON DELETE SET NULL
    )
  `);
  db.run(`
    INSERT INTO observations (
      id,
      report_id,
      section_id,
      observation_field_id,
      test_name_raw,
      test_name_normalized,
      value_raw,
      value_numeric,
      value_text,
      unit_raw,
      unit_normalized,
      reference_range_raw,
      ref_low,
      ref_high,
      inference,
      confidence_score,
      created_at
    )
    SELECT
      id,
      report_id,
      section_id,
      observation_field_id,
      test_name_raw,
      test_name_normalized,
      value_raw,
      value_numeric,
      value_text,
      unit_raw,
      unit_normalized,
      reference_range_raw,
      ref_low,
      ref_high,
      CASE
        WHEN (SELECT COUNT(*) FROM pragma_table_info('observations_legacy') WHERE name = 'inference') > 0
        THEN COALESCE(inference, '')
        ELSE ''
      END,
      confidence_score,
      created_at
    FROM observations_legacy
  `);
  db.run("DROP TABLE observations_legacy");
}

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observations_report
  ON observations(report_id)
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observations_section
  ON observations(section_id)
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observations_test_name
  ON observations(test_name_normalized)
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_observations_observation_field
  ON observations(observation_field_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS performance_reports (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    body_composition_metrics_id TEXT NOT NULL,
    fmi REAL,
    ffmi REAL,
    model_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY(body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_performance_reports_profile_created
  ON performance_reports(profile_id, created_at DESC)
`);

db.run(`
  CREATE UNIQUE INDEX IF NOT EXISTS idx_performance_reports_snapshot
  ON performance_reports(body_composition_metrics_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS performance_report_comments (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    factor TEXT NOT NULL,
    remark TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(report_id) REFERENCES performance_reports(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_performance_report_comments_report
  ON performance_report_comments(report_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profile_insight_reports (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    body_composition_metrics_id TEXT NOT NULL,
    overview_title TEXT,
    overview_remarks TEXT,
    foundation TEXT,
    momentum TEXT,
    biggest_lever TEXT,
    physique_archetype TEXT,
    effort_score INTEGER CHECK(effort_score IS NULL OR (effort_score >= 0 AND effort_score <= 100)),
    effort_remark TEXT,
    model_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY(body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_profile_insight_reports_profile_created
  ON profile_insight_reports(profile_id, created_at DESC)
`);

db.run(`
  CREATE UNIQUE INDEX IF NOT EXISTS idx_profile_insight_reports_snapshot
  ON profile_insight_reports(body_composition_metrics_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS profile_insight_report_comments (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    factor TEXT NOT NULL,
    remark TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(report_id) REFERENCES profile_insight_reports(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_profile_insight_report_comments_report
  ON profile_insight_report_comments(report_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS fat_reports (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    body_composition_metrics_id TEXT NOT NULL,
    fat_percent REAL NOT NULL,
    visceral_fat_delta_30d_kg REAL NOT NULL,
    subcutaneous_fat_delta_30d_kg REAL NOT NULL,
    fat_mass_kg REAL NOT NULL,
    visceral_fat_mass_kg REAL NOT NULL,
    visceral_fat_percent REAL NOT NULL,
    subcutaneous_fat_mass_kg REAL NOT NULL,
    subcutaneous_fat_ratio REAL NOT NULL,
    model_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY(body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_fat_reports_profile_created
  ON fat_reports(profile_id, created_at DESC)
`);

db.run(`
  CREATE UNIQUE INDEX IF NOT EXISTS idx_fat_reports_snapshot
  ON fat_reports(body_composition_metrics_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS fat_report_comments (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    factor TEXT NOT NULL,
    remark TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(report_id) REFERENCES fat_reports(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_fat_report_comments_report
  ON fat_report_comments(report_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS muscle_reports (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    body_composition_metrics_id TEXT NOT NULL,
    total_muscle_kg REAL NOT NULL,
    bone_mass_kg REAL NOT NULL,
    muscle_ratio REAL NOT NULL,
    skeletal_muscle_mass_kg REAL NOT NULL,
    skeletal_muscle_ratio REAL NOT NULL,
    model_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY(body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_muscle_reports_profile_created
  ON muscle_reports(profile_id, created_at DESC)
`);

db.run(`
  CREATE UNIQUE INDEX IF NOT EXISTS idx_muscle_reports_snapshot
  ON muscle_reports(body_composition_metrics_id)
`);

db.run(`
  CREATE TABLE IF NOT EXISTS muscle_report_comments (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL,
    factor TEXT NOT NULL,
    remark TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(report_id) REFERENCES muscle_reports(id) ON DELETE CASCADE
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_muscle_report_comments_report
  ON muscle_report_comments(report_id)
`);

db.run(`
  INSERT INTO performance_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    fmi,
    ffmi,
    created_at,
    updated_at
  )
  SELECT
    lower(hex(randomblob(16))),
    metrics.profile_id,
    metrics.id,
    CASE
      WHEN profile_metadata.height_cm IS NULL OR profile_metadata.height_cm <= 0 THEN NULL
      ELSE ROUND(metrics.fat_mass_kg / ((profile_metadata.height_cm / 100.0) * (profile_metadata.height_cm / 100.0)), 2)
    END,
    CASE
      WHEN profile_metadata.height_cm IS NULL OR profile_metadata.height_cm <= 0 THEN NULL
      ELSE ROUND(metrics.fat_free_mass_kg / ((profile_metadata.height_cm / 100.0) * (profile_metadata.height_cm / 100.0)), 2)
    END,
    metrics.created_at,
    metrics.created_at
  FROM body_composition_metrics_new AS metrics
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = metrics.profile_id
  WHERE NOT EXISTS (
    SELECT 1
    FROM performance_reports
    WHERE performance_reports.body_composition_metrics_id = metrics.id
  )
`);

db.run(`
  INSERT INTO profile_insight_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    created_at,
    updated_at
  )
  SELECT
    lower(hex(randomblob(16))),
    metrics.profile_id,
    metrics.id,
    metrics.created_at,
    metrics.created_at
  FROM body_composition_metrics_new AS metrics
  WHERE NOT EXISTS (
    SELECT 1
    FROM profile_insight_reports
    WHERE profile_insight_reports.body_composition_metrics_id = metrics.id
  )
`);

db.run(`
  INSERT INTO fat_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    fat_percent,
    visceral_fat_delta_30d_kg,
    subcutaneous_fat_delta_30d_kg,
    fat_mass_kg,
    visceral_fat_mass_kg,
    visceral_fat_percent,
    subcutaneous_fat_mass_kg,
    subcutaneous_fat_ratio,
    created_at,
    updated_at
  )
  SELECT
    lower(hex(randomblob(16))),
    latest.profile_id,
    latest.id,
    latest.body_fat_pct,
    ROUND(
      (latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg) -
      (baseline.fat_mass_kg - baseline.subcutaneous_fat_mass_kg),
      2
    ),
    ROUND(latest.subcutaneous_fat_mass_kg - baseline.subcutaneous_fat_mass_kg, 2),
    latest.fat_mass_kg,
    ROUND(latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg, 2),
    ROUND(latest.body_fat_pct - latest.subcutaneous_fat_pct, 2),
    latest.subcutaneous_fat_mass_kg,
    CASE
      WHEN latest.fat_mass_kg <= 0 THEN 0
      ELSE ROUND(latest.subcutaneous_fat_mass_kg / latest.fat_mass_kg, 2)
    END,
    latest.created_at,
    latest.created_at
  FROM body_composition_metrics_new AS latest
  INNER JOIN body_composition_metrics_new AS baseline
    ON baseline.id = (
      SELECT oldest.id
      FROM body_composition_metrics_new AS oldest
      WHERE oldest.profile_id = latest.profile_id
        AND oldest.created_at >= datetime(latest.created_at, '-30 days')
        AND oldest.created_at <= latest.created_at
      ORDER BY oldest.created_at ASC
      LIMIT 1
    )
  WHERE NOT EXISTS (
    SELECT 1
    FROM fat_reports
    WHERE fat_reports.body_composition_metrics_id = latest.id
  )
`);

db.run(`
  INSERT INTO muscle_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    total_muscle_kg,
    bone_mass_kg,
    muscle_ratio,
    skeletal_muscle_mass_kg,
    skeletal_muscle_ratio,
    created_at,
    updated_at
  )
  SELECT
    lower(hex(randomblob(16))),
    metrics.profile_id,
    metrics.id,
    metrics.muscle_mass_kg,
    ROUND(MAX(metrics.fat_free_mass_kg - metrics.muscle_mass_kg, 0), 2),
    metrics.muscle_rate_pct,
    metrics.skeletal_muscle_kg,
    CASE
      WHEN metrics.fat_mass_kg + metrics.fat_free_mass_kg <= 0 THEN 0
      ELSE ROUND(metrics.skeletal_muscle_kg / (metrics.fat_mass_kg + metrics.fat_free_mass_kg) * 100, 2)
    END,
    metrics.created_at,
    metrics.created_at
  FROM body_composition_metrics_new AS metrics
  WHERE NOT EXISTS (
    SELECT 1
    FROM muscle_reports
    WHERE muscle_reports.body_composition_metrics_id = metrics.id
  )
`);

db.run(`
  UPDATE profile_insight_reports
  SET
    overview_title = (
      SELECT overview.overview_title
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    overview_remarks = (
      SELECT overview.overview_remarks
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    foundation = (
      SELECT overview.foundation
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    momentum = (
      SELECT overview.momentum
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    biggest_lever = (
      SELECT overview.biggest_lever
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    physique_archetype = (
      SELECT overview.physique_archetype
      FROM profile_ai_overviews AS overview
      WHERE overview.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    effort_score = (
      SELECT effort.score
      FROM profile_effort_scores AS effort
      WHERE effort.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    effort_remark = (
      SELECT effort.remark
      FROM profile_effort_scores AS effort
      WHERE effort.profile_id = profile_insight_reports.profile_id
      LIMIT 1
    ),
    model_name = COALESCE(
      (
        SELECT overview.model_name
        FROM profile_ai_overviews AS overview
        WHERE overview.profile_id = profile_insight_reports.profile_id
        LIMIT 1
      ),
      (
        SELECT effort.model_name
        FROM profile_effort_scores AS effort
        WHERE effort.profile_id = profile_insight_reports.profile_id
        LIMIT 1
      )
    ),
    updated_at = CURRENT_TIMESTAMP
  WHERE profile_insight_reports.body_composition_metrics_id = (
    SELECT latest.id
    FROM body_composition_metrics_new AS latest
    WHERE latest.profile_id = profile_insight_reports.profile_id
    ORDER BY latest.created_at DESC
    LIMIT 1
  )
    AND profile_insight_reports.overview_title IS NULL
    AND (
      EXISTS (
        SELECT 1
        FROM profile_ai_overviews AS overview
        WHERE overview.profile_id = profile_insight_reports.profile_id
      )
      OR EXISTS (
        SELECT 1
        FROM profile_effort_scores AS effort
        WHERE effort.profile_id = profile_insight_reports.profile_id
      )
    )
`);

db.run(`
  INSERT INTO performance_report_comments (
    id,
    report_id,
    factor,
    remark,
    comment,
    created_at
  )
  SELECT lower(hex(randomblob(16))), reports.id, comments.factor, comments.remark, comments.comment, CURRENT_TIMESTAMP
  FROM performance_reports AS reports
  INNER JOIN derived_metrics_comments AS legacy
    ON legacy.profile_id = reports.profile_id
  INNER JOIN (
    SELECT 'ffmi' AS factor, '' AS remark, json_extract(ffmi, '$.comment') AS comment, profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'ffmi_vs_fmi', '', json_extract(ffmi_vs_fmi, '$.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'composition_flow', '', json_extract(composition_flow, '$.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'composition_trend', '', json_extract(composition_trend, '$.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'recomp_vector', '', json_extract(recomp_vector, '$.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'excess_fat_gauge', '', json_extract(excess_fat_gauge, '$.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_waist_height', json_extract(body_ratios, '$.waistHeight.remark'), json_extract(body_ratios, '$.waistHeight.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_shoulder_waist', json_extract(body_ratios, '$.shoulderWaist.remark'), json_extract(body_ratios, '$.shoulderWaist.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_chest_waist', json_extract(body_ratios, '$.chestWaist.remark'), json_extract(body_ratios, '$.chestWaist.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_bicep_forearm', json_extract(body_ratios, '$.bicepForearm.remark'), json_extract(body_ratios, '$.bicepForearm.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_thigh_calf', json_extract(body_ratios, '$.thighCalf.remark'), json_extract(body_ratios, '$.thighCalf.comment'), profile_id FROM derived_metrics_comments
    UNION ALL
    SELECT 'body_ratio_neck_calf', json_extract(body_ratios, '$.neckCalf.remark'), json_extract(body_ratios, '$.neckCalf.comment'), profile_id FROM derived_metrics_comments
  ) AS comments
    ON comments.profile_id = reports.profile_id
  WHERE reports.body_composition_metrics_id = (
    SELECT latest.id
    FROM body_composition_metrics_new AS latest
    WHERE latest.profile_id = reports.profile_id
    ORDER BY latest.created_at DESC
    LIMIT 1
  )
    AND comments.comment IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM performance_report_comments AS existing
      WHERE existing.report_id = reports.id
        AND existing.factor = comments.factor
    )
`);

export function getLatestBodyCompositionMeasurement(profileId: string) {
  return db
    .prepare(
      "SELECT * FROM body_composition_metrics_new WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export function getLatestBodyMeasurement(profileId: string) {
  return db
    .prepare(
      "SELECT * FROM body_measurements WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export function getProfileMetadata(profileId: string) {
  return db
    .prepare(
      `
    SELECT
      height_cm AS heightCm,
      date_of_birth AS dateOfBirth,
      people_type AS peopleType,
      gender,
      preferred_body_fat_pct AS preferredBodyFatPct
    FROM profile_metadata
    WHERE profile_id = ?
    LIMIT 1
    `,
    )
    .get(profileId);
}

export function getLatestWeightMeasurement(profileId: string) {
  return db
    .prepare(
      `
    SELECT
      weight,
      created_at AS createdAt
    FROM measurements
    WHERE profile_id = ?
      AND weight IS NOT NULL
    ORDER BY created_at DESC
    LIMIT 1
    `,
    )
    .get(profileId);
}

export function getFirstHealthDataEntry(profileId: string) {
  return db
    .prepare(
      `
    SELECT source, created_at AS createdAt
    FROM (
      SELECT 'measurements' AS source, created_at
      FROM measurements
      WHERE profile_id = ?

      UNION ALL

      SELECT 'body_measurements' AS source, created_at
      FROM body_measurements
      WHERE profile_id = ?

      UNION ALL

      SELECT 'body_composition_metrics_new' AS source, created_at
      FROM body_composition_metrics_new
      WHERE profile_id = ?
    )
    ORDER BY created_at ASC
    LIMIT 1
    `,
    )
    .get(profileId, profileId, profileId);
}

export function getBodyCompositionMeasurementDelta(profileId: string) {
  return db
    .prepare(
      `
    WITH latest_measurement AS (
      SELECT *
      FROM body_composition_metrics_new
      WHERE profile_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ),
    forever_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
    ),
    last_year_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    ),
    last_30_days_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-30 days')
    ),
    last_7_days_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-7 days')
    )
    SELECT
      latest_measurement.bmi - forever_avg.bmi AS bmi_forever_delta,
      latest_measurement.bmi - last_year_avg.bmi AS bmi_last_year_delta,
      latest_measurement.bmi - last_30_days_avg.bmi AS bmi_last_30_days_delta,
      latest_measurement.bmi - last_7_days_avg.bmi AS bmi_last_7_days_delta,
      latest_measurement.body_fat_pct - forever_avg.body_fat_pct AS body_fat_pct_forever_delta,
      latest_measurement.body_fat_pct - last_year_avg.body_fat_pct AS body_fat_pct_last_year_delta,
      latest_measurement.body_fat_pct - last_30_days_avg.body_fat_pct AS body_fat_pct_last_30_days_delta,
      latest_measurement.body_fat_pct - last_7_days_avg.body_fat_pct AS body_fat_pct_last_7_days_delta,
      latest_measurement.fat_mass_kg - forever_avg.fat_mass_kg AS fat_mass_kg_forever_delta,
      latest_measurement.fat_mass_kg - last_year_avg.fat_mass_kg AS fat_mass_kg_last_year_delta,
      latest_measurement.fat_mass_kg - last_30_days_avg.fat_mass_kg AS fat_mass_kg_last_30_days_delta,
      latest_measurement.fat_mass_kg - last_7_days_avg.fat_mass_kg AS fat_mass_kg_last_7_days_delta,
      latest_measurement.fat_free_mass_kg - forever_avg.fat_free_mass_kg AS fat_free_mass_kg_forever_delta,
      latest_measurement.fat_free_mass_kg - last_year_avg.fat_free_mass_kg AS fat_free_mass_kg_last_year_delta,
      latest_measurement.fat_free_mass_kg - last_30_days_avg.fat_free_mass_kg AS fat_free_mass_kg_last_30_days_delta,
      latest_measurement.fat_free_mass_kg - last_7_days_avg.fat_free_mass_kg AS fat_free_mass_kg_last_7_days_delta,
      latest_measurement.desired_weight_kg - forever_avg.desired_weight_kg AS desired_weight_kg_forever_delta,
      latest_measurement.desired_weight_kg - last_year_avg.desired_weight_kg AS desired_weight_kg_last_year_delta,
      latest_measurement.desired_weight_kg - last_30_days_avg.desired_weight_kg AS desired_weight_kg_last_30_days_delta,
      latest_measurement.desired_weight_kg - last_7_days_avg.desired_weight_kg AS desired_weight_kg_last_7_days_delta,
      latest_measurement.body_score - forever_avg.body_score AS body_score_forever_delta,
      latest_measurement.body_score - last_year_avg.body_score AS body_score_last_year_delta,
      latest_measurement.body_score - last_30_days_avg.body_score AS body_score_last_30_days_delta,
      latest_measurement.body_score - last_7_days_avg.body_score AS body_score_last_7_days_delta,
      latest_measurement.body_age_years - forever_avg.body_age_years AS body_age_years_forever_delta,
      latest_measurement.body_age_years - last_year_avg.body_age_years AS body_age_years_last_year_delta,
      latest_measurement.body_age_years - last_30_days_avg.body_age_years AS body_age_years_last_30_days_delta,
      latest_measurement.body_age_years - last_7_days_avg.body_age_years AS body_age_years_last_7_days_delta,
      latest_measurement.water_pct - forever_avg.water_pct AS water_pct_forever_delta,
      latest_measurement.water_pct - last_year_avg.water_pct AS water_pct_last_year_delta,
      latest_measurement.water_pct - last_30_days_avg.water_pct AS water_pct_last_30_days_delta,
      latest_measurement.water_pct - last_7_days_avg.water_pct AS water_pct_last_7_days_delta,
      latest_measurement.muscle_mass_kg - forever_avg.muscle_mass_kg AS muscle_mass_kg_forever_delta,
      latest_measurement.muscle_mass_kg - last_year_avg.muscle_mass_kg AS muscle_mass_kg_last_year_delta,
      latest_measurement.muscle_mass_kg - last_30_days_avg.muscle_mass_kg AS muscle_mass_kg_last_30_days_delta,
      latest_measurement.muscle_mass_kg - last_7_days_avg.muscle_mass_kg AS muscle_mass_kg_last_7_days_delta,
      latest_measurement.muscle_rate_pct - forever_avg.muscle_rate_pct AS muscle_rate_pct_forever_delta,
      latest_measurement.muscle_rate_pct - last_year_avg.muscle_rate_pct AS muscle_rate_pct_last_year_delta,
      latest_measurement.muscle_rate_pct - last_30_days_avg.muscle_rate_pct AS muscle_rate_pct_last_30_days_delta,
      latest_measurement.muscle_rate_pct - last_7_days_avg.muscle_rate_pct AS muscle_rate_pct_last_7_days_delta,
      latest_measurement.bmr_kcal - forever_avg.bmr_kcal AS bmr_kcal_forever_delta,
      latest_measurement.bmr_kcal - last_year_avg.bmr_kcal AS bmr_kcal_last_year_delta,
      latest_measurement.bmr_kcal - last_30_days_avg.bmr_kcal AS bmr_kcal_last_30_days_delta,
      latest_measurement.bmr_kcal - last_7_days_avg.bmr_kcal AS bmr_kcal_last_7_days_delta,
      latest_measurement.visceral_fat - forever_avg.visceral_fat AS visceral_fat_forever_delta,
      latest_measurement.visceral_fat - last_year_avg.visceral_fat AS visceral_fat_last_year_delta,
      latest_measurement.visceral_fat - last_30_days_avg.visceral_fat AS visceral_fat_last_30_days_delta,
      latest_measurement.visceral_fat - last_7_days_avg.visceral_fat AS visceral_fat_last_7_days_delta,
      latest_measurement.ideal_weight_kg - forever_avg.ideal_weight_kg AS ideal_weight_kg_forever_delta,
      latest_measurement.ideal_weight_kg - last_year_avg.ideal_weight_kg AS ideal_weight_kg_last_year_delta,
      latest_measurement.ideal_weight_kg - last_30_days_avg.ideal_weight_kg AS ideal_weight_kg_last_30_days_delta,
      latest_measurement.ideal_weight_kg - last_7_days_avg.ideal_weight_kg AS ideal_weight_kg_last_7_days_delta,
      latest_measurement.protein_mass_kg - forever_avg.protein_mass_kg AS protein_mass_kg_forever_delta,
      latest_measurement.protein_mass_kg - last_year_avg.protein_mass_kg AS protein_mass_kg_last_year_delta,
      latest_measurement.protein_mass_kg - last_30_days_avg.protein_mass_kg AS protein_mass_kg_last_30_days_delta,
      latest_measurement.protein_mass_kg - last_7_days_avg.protein_mass_kg AS protein_mass_kg_last_7_days_delta,
      latest_measurement.protein_pct - forever_avg.protein_pct AS protein_pct_forever_delta,
      latest_measurement.protein_pct - last_year_avg.protein_pct AS protein_pct_last_year_delta,
      latest_measurement.protein_pct - last_30_days_avg.protein_pct AS protein_pct_last_30_days_delta,
      latest_measurement.protein_pct - last_7_days_avg.protein_pct AS protein_pct_last_7_days_delta,
      latest_measurement.skeletal_muscle_kg - forever_avg.skeletal_muscle_kg AS skeletal_muscle_kg_forever_delta,
      latest_measurement.skeletal_muscle_kg - last_year_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_year_delta,
      latest_measurement.skeletal_muscle_kg - last_30_days_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_30_days_delta,
      latest_measurement.skeletal_muscle_kg - last_7_days_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_7_days_delta,
      latest_measurement.subcutaneous_fat_pct - forever_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_forever_delta,
      latest_measurement.subcutaneous_fat_pct - last_year_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_year_delta,
      latest_measurement.subcutaneous_fat_pct - last_30_days_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_30_days_delta,
      latest_measurement.subcutaneous_fat_pct - last_7_days_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_7_days_delta,
      latest_measurement.subcutaneous_fat_mass_kg - forever_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_forever_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_year_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_year_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_30_days_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_30_days_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_7_days_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_7_days_delta,
      latest_measurement.predicted_lean_mass_kg - forever_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_forever_delta,
      latest_measurement.predicted_lean_mass_kg - last_year_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_year_delta,
      latest_measurement.predicted_lean_mass_kg - last_30_days_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_30_days_delta,
      latest_measurement.predicted_lean_mass_kg - last_7_days_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_7_days_delta
    FROM latest_measurement
    CROSS JOIN forever_avg
    CROSS JOIN last_year_avg
    CROSS JOIN last_30_days_avg
    CROSS JOIN last_7_days_avg
    `,
    )
    .get(profileId, profileId, profileId, profileId, profileId);
}

export function getBodyMeasurementDelta(profileId: string) {
  return db
    .prepare(
      `
    WITH latest_measurement AS (
      SELECT *
      FROM body_measurements
      WHERE profile_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ),
    forever_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
    ),
    last_year_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    ),
    last_30_days_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-30 days')
    ),
    last_7_days_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-7 days')
    )
    SELECT
      latest_measurement.neck_cm - forever_avg.neck_cm AS neck_cm_forever_delta,
      latest_measurement.neck_cm - last_year_avg.neck_cm AS neck_cm_last_year_delta,
      latest_measurement.neck_cm - last_30_days_avg.neck_cm AS neck_cm_last_30_days_delta,
      latest_measurement.neck_cm - last_7_days_avg.neck_cm AS neck_cm_last_7_days_delta,
      latest_measurement.shoulder_cm - forever_avg.shoulder_cm AS shoulder_cm_forever_delta,
      latest_measurement.shoulder_cm - last_year_avg.shoulder_cm AS shoulder_cm_last_year_delta,
      latest_measurement.shoulder_cm - last_30_days_avg.shoulder_cm AS shoulder_cm_last_30_days_delta,
      latest_measurement.shoulder_cm - last_7_days_avg.shoulder_cm AS shoulder_cm_last_7_days_delta,
      latest_measurement.chest_cm - forever_avg.chest_cm AS chest_cm_forever_delta,
      latest_measurement.chest_cm - last_year_avg.chest_cm AS chest_cm_last_year_delta,
      latest_measurement.chest_cm - last_30_days_avg.chest_cm AS chest_cm_last_30_days_delta,
      latest_measurement.chest_cm - last_7_days_avg.chest_cm AS chest_cm_last_7_days_delta,
      latest_measurement.stomach_cm - forever_avg.stomach_cm AS stomach_cm_forever_delta,
      latest_measurement.stomach_cm - last_year_avg.stomach_cm AS stomach_cm_last_year_delta,
      latest_measurement.stomach_cm - last_30_days_avg.stomach_cm AS stomach_cm_last_30_days_delta,
      latest_measurement.stomach_cm - last_7_days_avg.stomach_cm AS stomach_cm_last_7_days_delta,
      latest_measurement.waist_cm - forever_avg.waist_cm AS waist_cm_forever_delta,
      latest_measurement.waist_cm - last_year_avg.waist_cm AS waist_cm_last_year_delta,
      latest_measurement.waist_cm - last_30_days_avg.waist_cm AS waist_cm_last_30_days_delta,
      latest_measurement.waist_cm - last_7_days_avg.waist_cm AS waist_cm_last_7_days_delta,
      latest_measurement.calf_cm - forever_avg.calf_cm AS calf_cm_forever_delta,
      latest_measurement.calf_cm - last_year_avg.calf_cm AS calf_cm_last_year_delta,
      latest_measurement.calf_cm - last_30_days_avg.calf_cm AS calf_cm_last_30_days_delta,
      latest_measurement.calf_cm - last_7_days_avg.calf_cm AS calf_cm_last_7_days_delta,
      latest_measurement.thigh_cm - forever_avg.thigh_cm AS thigh_cm_forever_delta,
      latest_measurement.thigh_cm - last_year_avg.thigh_cm AS thigh_cm_last_year_delta,
      latest_measurement.thigh_cm - last_30_days_avg.thigh_cm AS thigh_cm_last_30_days_delta,
      latest_measurement.thigh_cm - last_7_days_avg.thigh_cm AS thigh_cm_last_7_days_delta,
      latest_measurement.bicep_cm - forever_avg.bicep_cm AS bicep_cm_forever_delta,
      latest_measurement.bicep_cm - last_year_avg.bicep_cm AS bicep_cm_last_year_delta,
      latest_measurement.bicep_cm - last_30_days_avg.bicep_cm AS bicep_cm_last_30_days_delta,
      latest_measurement.bicep_cm - last_7_days_avg.bicep_cm AS bicep_cm_last_7_days_delta,
      latest_measurement.forearm_cm - forever_avg.forearm_cm AS forearm_cm_forever_delta,
      latest_measurement.forearm_cm - last_year_avg.forearm_cm AS forearm_cm_last_year_delta,
      latest_measurement.forearm_cm - last_30_days_avg.forearm_cm AS forearm_cm_last_30_days_delta,
      latest_measurement.forearm_cm - last_7_days_avg.forearm_cm AS forearm_cm_last_7_days_delta
    FROM latest_measurement
    CROSS JOIN forever_avg
    CROSS JOIN last_year_avg
    CROSS JOIN last_30_days_avg
    CROSS JOIN last_7_days_avg
    `,
    )
    .get(profileId, profileId, profileId, profileId, profileId);
}
