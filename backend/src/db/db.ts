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
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
`);

const profileColumns = db.prepare(`PRAGMA table_info(profiles)`).all() as {
  name: string;
}[];
const profileColumnNames = new Set(profileColumns.map((column) => column.name));

if (!profileColumnNames.has("height_cm")) {
  db.run(`ALTER TABLE profiles ADD COLUMN height_cm REAL`);
}

if (!profileColumnNames.has("date_of_birth")) {
  db.run(`ALTER TABLE profiles ADD COLUMN date_of_birth TEXT`);
}

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

const waistMeasurementsTable = db
  .prepare(
    `
  SELECT 1
  FROM sqlite_master
  WHERE type = 'table'
    AND name = 'waist_measurements'
  LIMIT 1
`,
  )
  .get();

if (waistMeasurementsTable !== null) {
  db.run(`
    INSERT OR IGNORE INTO body_measurements (
      id,
      profile_id,
      waist_cm,
      created_at
    )
    SELECT
      id,
      profile_id,
      waist,
      created_at
    FROM waist_measurements
  `);
}
