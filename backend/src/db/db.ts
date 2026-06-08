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
