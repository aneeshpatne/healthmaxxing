import { v7 as uuidv7 } from "uuid";
import { db } from "./db";

export type JobId = string;
export type ProfileId = string;

export type UserWeight = {
  id: string;
  weight: number | null;
  createdAt: string;
};

export type UserWaist = {
  id: string;
  waist: number;
  createdAt: string;
};

export type BodyMeasurement = {
  id: string;
  waistCm: number | null;
  neckCm: number | null;
  createdAt: string;
};

export type Users = {
  id: string;
  name: string | null;
  heightCm: number | null;
  dateOfBirth: string | null;
  createdAt: string;
};

export type RegisterUserInput = {
  name: string;
  heightCm?: number | null;
  dateOfBirth?: string | null;
};

export type BodyMeasurementInput = {
  waistCm?: number | null;
  neckCm?: number | null;
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
  heightCm = null,
  dateOfBirth = null,
}: RegisterUserInput): ProfileId {
  const profileId: ProfileId = uuidv7();

  db.prepare(
    `
  INSERT INTO profiles (
    id,
    name,
    height_cm,
    date_of_birth,
    created_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(profileId, name, heightCm, dateOfBirth);

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

export function addWaistMeasurement(profileId: ProfileId, waist: number): string {
  return addBodyMeasurement(profileId, { waistCm: waist });
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

export function listUserWaist(profileId: ProfileId): UserWaist[] {
  return db
    .prepare(
      `
  SELECT
    id,
    waist_cm AS waist,
    created_at AS createdAt
  FROM body_measurements
  WHERE profile_id = ?
    AND waist_cm IS NOT NULL
  ORDER BY created_at DESC
`,
    )
    .all(profileId) as UserWaist[];
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
    created_at AS createdAt
  FROM profiles
  ORDER BY created_at DESC
`,
    )
    .all() as Users[];
}
