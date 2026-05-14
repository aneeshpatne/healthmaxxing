import { v7 as uuidv7 } from "uuid";
import { db } from "./db";

export type JobId = string;
export type ProfileId = string;

export type UserWeight = {
  id: string;
  weight: number | null;
  createdAt: string;
};

export type BodyMeasurement = {
  id: string;
  waistCm: number | null;
  neckCm: number | null;
  createdAt: string;
};

export type BodyCompositionMetrics = {
  id?: string;
  profileId: ProfileId;
  bodyFatPct: number;
  muscleMassKg: number;
  waterPct: number;
  proteinPct: number;
  fatFreeMassKg: number;
  fatMassKg: number;
};

export type Users = {
  id: string;
  name: string | null;
  heightCm: number | null;
  dateOfBirth: string | null;
  gender: "male" | "female" | null;
  createdAt: string;
};

export type RegisterUserInput = {
  name: string;
  heightCm: number;
  dateOfBirth: string;
  gender: "male" | "female";
};

export type BodyMeasurementInput = {
  waistCm?: number | null;
  neckCm?: number | null;
};

export type ProgressMeasurement = {
  id?: string;
  profile_id: string;
  name: "bicep" | "chest" | "thigh" | "forearm" | "calf" | "shoulder";
  value: number;
  unit: string;
  notes: "postWorkOut" | "preWorkOut";
};

export type profile = {
  id: string;
  name: string;
  heightCm: number;
  dateOfBirth: string;
  gender: "male" | "female";
};

export function jobExists(jobId: JobId): boolean {
  const job = db
    .prepare(
      `
  SELECT 1
  FROM jobs
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(jobId);

  return job !== null;
}

export function profileExists(profileId: ProfileId): boolean {
  const profile = db
    .prepare(
      `
  SELECT 1
  FROM profiles
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(profileId);

  return profile !== null;
}

export function getProfileIdByJobId(jobId: JobId): ProfileId | null {
  const job = db
    .prepare(
      `
  SELECT profile_id
  FROM jobs
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(jobId) as { profile_id: ProfileId } | null;

  return job?.profile_id ?? null;
}

export function initJob(jobId: JobId, profileId: ProfileId): void {
  db.prepare(
    `
  INSERT INTO jobs (
    id,
    profile_id,
    status,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
`,
  ).run(jobId, profileId, "created");
}
export function addMeasurement(
  profileId: ProfileId,
  weight: number,
  heartbeat: number,
  impedance: number,
): string {
  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO measurements (
    id,
    profile_id,
    weight,
    heart_rate,
    impedance,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(id, profileId, weight, heartbeat, impedance);

  return id;
}
export function registerUser({
  name,
  heightCm,
  dateOfBirth,
  gender,
}: RegisterUserInput): ProfileId {
  const profileId: ProfileId = uuidv7();

  db.prepare(
    `
  INSERT INTO profiles (
    id,
    name,
    height_cm,
    date_of_birth,
    gender,
    created_at
  )
  VALUES (?, ?, ?, ?, ?,  CURRENT_TIMESTAMP)
`,
  ).run(profileId, name, heightCm, dateOfBirth, gender);

  return profileId;
}

export function listUserWeight(profileId: ProfileId): UserWeight[] {
  return db
    .prepare(
      `
  SELECT
    id,
    weight,
    created_at AS createdAt
  FROM measurements
  WHERE profile_id = ?
  ORDER BY created_at DESC
`,
    )
    .all(profileId) as UserWeight[];
}

export function addBodyMeasurement(
  profileId: ProfileId,
  { waistCm = null, neckCm = null }: BodyMeasurementInput,
): string {
  if (waistCm === null && neckCm === null) {
    throw new Error("At least one body measurement is required");
  }

  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO body_measurements (
    id,
    profile_id,
    waist_cm,
    neck_cm,
    created_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(id, profileId, waistCm, neckCm);

  return id;
}

export function listUserBodyMeasurements(
  profileId: ProfileId,
): BodyMeasurement[] {
  return db
    .prepare(
      `
  SELECT
    id,
    waist_cm AS waistCm,
    neck_cm AS neckCm,
    created_at AS createdAt
  FROM body_measurements
  WHERE profile_id = ?
  ORDER BY created_at DESC
`,
    )
    .all(profileId) as BodyMeasurement[];
}

export function addBodyCompositionMetrics(
  metrics: BodyCompositionMetrics,
): string {
  const id = metrics.id ?? uuidv7();

  db.prepare(
    `
  INSERT INTO body_composition_metrics (
    id,
    profile_id,
    body_fat_pct,
    muscle_mass_kg,
    water_pct,
    protein_pct,
    fat_free_mass_kg,
    fat_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    metrics.profileId,
    metrics.bodyFatPct,
    metrics.muscleMassKg,
    metrics.waterPct,
    metrics.proteinPct,
    metrics.fatFreeMassKg,
    metrics.fatMassKg,
  );

  return id;
}

export function addProgressMeasurement(
  measurement: ProgressMeasurement,
): string {
  const id = measurement.id ?? uuidv7();

  db.prepare(
    `
  INSERT INTO progress_measurements (
    id,
    profile_id,
    name,
    value,
    unit,
    notes,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    measurement.profile_id,
    measurement.name,
    measurement.value,
    measurement.unit,
    measurement.notes,
  );

  return id;
}

export function listUsers(): Users[] {
  return db
    .prepare(
      `
  SELECT
    id,
    name,
    height_cm AS heightCm,
    date_of_birth AS dateOfBirth,
    gender,
    created_at AS createdAt
  FROM profiles
  ORDER BY created_at DESC
`,
    )
    .all() as Users[];
}

export function getProfileById(id: ProfileId) {
  return db
    .prepare(
      `
  SELECT
    id,
    name,
    height_cm AS heightCm,
    date_of_birth AS dateOfBirth,
    gender
  FROM profiles
  WHERE id = ? `,
    )
    .get(id) as profile;
}
