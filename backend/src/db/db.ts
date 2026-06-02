import { Database } from "bun:sqlite";

export const db = new Database("mydb.sqlite");

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
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id)
  )
`);

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
      gender
    FROM profile_metadata
    WHERE profile_id = ?
    LIMIT 1
    `,
    )
    .get(profileId);
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
    last_year_avg AS (
      SELECT
        AVG(bmi) AS bmi_avg,
        AVG(body_fat_pct) AS body_fat_pct_avg,
        AVG(fat_mass_kg) AS fat_mass_kg_avg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg_avg,
        AVG(body_score) AS body_score_avg,
        AVG(body_age_years) AS body_age_years_avg,
        AVG(water_pct) AS water_pct_avg,
        AVG(muscle_mass_kg) AS muscle_mass_kg_avg,
        AVG(muscle_rate_pct) AS muscle_rate_pct_avg,
        AVG(bmr_kcal) AS bmr_kcal_avg,
        AVG(visceral_fat) AS visceral_fat_avg,
        AVG(ideal_weight_kg) AS ideal_weight_kg_avg,
        AVG(protein_mass_kg) AS protein_mass_kg_avg,
        AVG(protein_pct) AS protein_pct_avg,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg_avg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct_avg,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg_avg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg_avg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    )
    SELECT
      latest_measurement.bmi - last_year_avg.bmi_avg AS bmi_delta,
      latest_measurement.body_fat_pct - last_year_avg.body_fat_pct_avg AS body_fat_pct_delta,
      latest_measurement.fat_mass_kg - last_year_avg.fat_mass_kg_avg AS fat_mass_kg_delta,
      latest_measurement.fat_free_mass_kg - last_year_avg.fat_free_mass_kg_avg AS fat_free_mass_kg_delta,
      latest_measurement.body_score - last_year_avg.body_score_avg AS body_score_delta,
      latest_measurement.body_age_years - last_year_avg.body_age_years_avg AS body_age_years_delta,
      latest_measurement.water_pct - last_year_avg.water_pct_avg AS water_pct_delta,
      latest_measurement.muscle_mass_kg - last_year_avg.muscle_mass_kg_avg AS muscle_mass_kg_delta,
      latest_measurement.muscle_rate_pct - last_year_avg.muscle_rate_pct_avg AS muscle_rate_pct_delta,
      latest_measurement.bmr_kcal - last_year_avg.bmr_kcal_avg AS bmr_kcal_delta,
      latest_measurement.visceral_fat - last_year_avg.visceral_fat_avg AS visceral_fat_delta,
      latest_measurement.ideal_weight_kg - last_year_avg.ideal_weight_kg_avg AS ideal_weight_kg_delta,
      latest_measurement.protein_mass_kg - last_year_avg.protein_mass_kg_avg AS protein_mass_kg_delta,
      latest_measurement.protein_pct - last_year_avg.protein_pct_avg AS protein_pct_delta,
      latest_measurement.skeletal_muscle_kg - last_year_avg.skeletal_muscle_kg_avg AS skeletal_muscle_kg_delta,
      latest_measurement.subcutaneous_fat_pct - last_year_avg.subcutaneous_fat_pct_avg AS subcutaneous_fat_pct_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_year_avg.subcutaneous_fat_mass_kg_avg AS subcutaneous_fat_mass_kg_delta,
      latest_measurement.predicted_lean_mass_kg - last_year_avg.predicted_lean_mass_kg_avg AS predicted_lean_mass_kg_delta
    FROM latest_measurement
    CROSS JOIN last_year_avg
    `,
    )
    .get(profileId, profileId);
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
    last_year_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm_avg,
        AVG(shoulder_cm) AS shoulder_cm_avg,
        AVG(chest_cm) AS chest_cm_avg,
        AVG(stomach_cm) AS stomach_cm_avg,
        AVG(waist_cm) AS waist_cm_avg,
        AVG(calf_cm) AS calf_cm_avg,
        AVG(thigh_cm) AS thigh_cm_avg,
        AVG(bicep_cm) AS bicep_cm_avg,
        AVG(forearm_cm) AS forearm_cm_avg
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    )
    SELECT
      latest_measurement.neck_cm - last_year_avg.neck_cm_avg AS neck_cm_delta,
      latest_measurement.shoulder_cm - last_year_avg.shoulder_cm_avg AS shoulder_cm_delta,
      latest_measurement.chest_cm - last_year_avg.chest_cm_avg AS chest_cm_delta,
      latest_measurement.stomach_cm - last_year_avg.stomach_cm_avg AS stomach_cm_delta,
      latest_measurement.waist_cm - last_year_avg.waist_cm_avg AS waist_cm_delta,
      latest_measurement.calf_cm - last_year_avg.calf_cm_avg AS calf_cm_delta,
      latest_measurement.thigh_cm - last_year_avg.thigh_cm_avg AS thigh_cm_delta,
      latest_measurement.bicep_cm - last_year_avg.bicep_cm_avg AS bicep_cm_delta,
      latest_measurement.forearm_cm - last_year_avg.forearm_cm_avg AS forearm_cm_delta
    FROM latest_measurement
    CROSS JOIN last_year_avg
    `,
    )
    .get(profileId, profileId);
}
