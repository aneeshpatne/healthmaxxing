import { v7 as uuidv7 } from "uuid";
import { db } from "./db";

export type JobId = string;
export type ProfileId = string;

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
