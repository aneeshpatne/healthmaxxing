import { Database } from "bun:sqlite";

export const db = new Database("mydb.sqlite");

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
  CREATE TABLE IF NOT EXISTS profiles (
    id TEXT PRIMARY KEY,
    name TEXT,
    height_cm REAL,
    date_of_birth TEXT,
    peopleType TEXT,
    gender TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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
    waist_cm REAL,
    neck_cm REAL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(profile_id) REFERENCES profiles(id),
    CHECK (waist_cm IS NOT NULL OR neck_cm IS NOT NULL)
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
