import { v7 as uuidv7 } from "uuid";
import { db } from "./db";

export type JobId = string;
export type ProfileId = string;

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

export function registerUser(name: string): ProfileId {
  const profileId: ProfileId = uuidv7();

  db.prepare(
    `
  INSERT INTO profiles (
    id,
    name,
    created_at
  )
  VALUES (?, ?, CURRENT_TIMESTAMP)
`,
  ).run(profileId, name);

  return profileId;
}
