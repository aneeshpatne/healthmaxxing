import { v7 as uuidv7 } from "uuid";
import { db } from "./db";
import type { ProprietaryBodyCompositionMetrics } from "../calculations/proprietaryMetrics";

export type JobId = string;
export type AccountId = string;
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

export type CalculatedBodyCompositionMetrics = {
  body_fat_pct: number;
  muscle_mass_kg: number;
  water_pct: number;
  protein_pct: number;
  fat_free_mass_kg: number;
  fat_mass_kg: number;
};

export type Users = {
  id: string;
  accountId: string;
  name: string | null;
  mailAddress: string | null;
  isPrimary: boolean;
  heightCm: number | null;
  dateOfBirth: string | null;
  peopleType: "standard" | "athlete" | null;
  gender: "male" | "female" | null;
  profileImage: string | null;
  createdAt: string;
};

type UserRow = Omit<Users, "isPrimary"> & {
  isPrimary: number;
};

export type RegisterUserInput = {
  mailAddress: string;
};

export type RegisterProfileInput = {
  accountId: AccountId;
  name: string;
  isPrimary?: boolean;
};

export type RegisterProfileMetadataInput = {
  profileId: ProfileId;
  dateOfBirth: string;
  gender: "male" | "female";
  heightCm: number;
  peopleType: "standard" | "athlete";
  profileImage?: string | null;
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
  accountId: string;
  name: string;
  mailAddress: string;
  isPrimary: boolean;
  heightCm: number;
  dateOfBirth: string;
  peopleType: "standard" | "athlete";
  gender: "male" | "female";
  profileImage: string | null;
};

type ProfileRow = Omit<profile, "isPrimary"> & {
  isPrimary: number;
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

export function accountExists(accountId: AccountId): boolean {
  const account = db
    .prepare(
      `
  SELECT 1
  FROM accounts
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(accountId);

  return account !== null;
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
  mailAddress,
}: RegisterUserInput): AccountId {
  const accountId: AccountId = uuidv7();

  db.prepare(
    `
  INSERT INTO accounts (
    id,
    mail_address,
    created_at
  )
  VALUES (?, ?, CURRENT_TIMESTAMP)
`,
  ).run(accountId, mailAddress);

  return accountId;
}

export function registerProfile({
  accountId,
  name,
  isPrimary = false,
}: RegisterProfileInput): ProfileId {
  const profileId: ProfileId = uuidv7();

  db.prepare(
    `
  INSERT INTO profiles (
    id,
    account_id,
    name,
    is_primary,
    created_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(profileId, accountId, name, isPrimary ? 1 : 0);

  return profileId;
}

export function registerProfileMetadata({
  profileId,
  dateOfBirth,
  gender,
  heightCm,
  peopleType,
  profileImage = null,
}: RegisterProfileMetadataInput): void {
  db.prepare(
    `
  INSERT INTO profile_metadata (
    profile_id,
    height_cm,
    date_of_birth,
    people_type,
    gender,
    profile_image,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  ON CONFLICT(profile_id) DO UPDATE SET
    height_cm = excluded.height_cm,
    date_of_birth = excluded.date_of_birth,
    people_type = excluded.people_type,
    gender = excluded.gender,
    profile_image = excluded.profile_image,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(profileId, heightCm, dateOfBirth, peopleType, gender, profileImage);
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

export function saveBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: CalculatedBodyCompositionMetrics,
): string {
  return addBodyCompositionMetrics({
    profileId,
    bodyFatPct: metrics.body_fat_pct,
    muscleMassKg: metrics.muscle_mass_kg,
    waterPct: metrics.water_pct,
    proteinPct: metrics.protein_pct,
    fatFreeMassKg: metrics.fat_free_mass_kg,
    fatMassKg: metrics.fat_mass_kg,
  });
}

export function addProprietaryBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: ProprietaryBodyCompositionMetrics,
): string {
  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO body_composition_metrics_new (
    id,
    profile_id,
    bmi,
    body_fat_pct,
    fat_mass_kg,
    fat_free_mass_kg,
    body_score,
    body_age_years,
    water_pct,
    muscle_mass_kg,
    muscle_rate_pct,
    bmr_kcal,
    visceral_fat,
    ideal_weight_kg,
    protein_mass_kg,
    protein_pct,
    skeletal_muscle_kg,
    subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    profileId,
    metrics.bmi,
    metrics.body_fat_pct,
    metrics.fat_mass_kg,
    metrics.fat_free_mass_kg,
    metrics.body_score,
    metrics.body_age_years,
    metrics.water_pct,
    metrics.muscle_mass_kg,
    metrics.muscle_rate_pct,
    metrics.bmr_kcal,
    metrics.visceral_fat,
    metrics.ideal_weight_kg,
    metrics.protein_mass_kg,
    metrics.protein_pct,
    metrics.skeletal_muscle_kg,
    metrics.subcutaneous_fat_pct,
    metrics.subcutaneous_fat_mass_kg,
    metrics.predicted_lean_mass_kg,
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
  const rows = db
    .prepare(
      `
  SELECT
    profiles.id,
    profiles.account_id AS accountId,
    profiles.name,
    accounts.mail_address AS mailAddress,
    profiles.is_primary AS isPrimary,
    profile_metadata.height_cm AS heightCm,
    profile_metadata.date_of_birth AS dateOfBirth,
    profile_metadata.people_type AS peopleType,
    profile_metadata.gender,
    profile_metadata.profile_image AS profileImage,
    profiles.created_at AS createdAt
  FROM profiles
  INNER JOIN accounts
    ON accounts.id = profiles.account_id
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = profiles.id
  ORDER BY profiles.created_at DESC
`,
    )
    .all() as UserRow[];

  return rows.map((row) => ({
    ...row,
    isPrimary: row.isPrimary === 1,
  }));
}

export function getProfileById(id: ProfileId) {
  const row = db
    .prepare(
      `
  SELECT
    profiles.id,
    profiles.account_id AS accountId,
    profiles.name,
    accounts.mail_address AS mailAddress,
    profiles.is_primary AS isPrimary,
    profile_metadata.height_cm AS heightCm,
    profile_metadata.date_of_birth AS dateOfBirth,
    profile_metadata.people_type AS peopleType,
    profile_metadata.gender,
    profile_metadata.profile_image AS profileImage
  FROM profiles
  INNER JOIN accounts
    ON accounts.id = profiles.account_id
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = profiles.id
  WHERE profiles.id = ? `,
    )
    .get(id) as ProfileRow;

  return {
    ...row,
    isPrimary: row.isPrimary === 1,
  };
}
