import { db } from "./db";

export type JobId = string;

export function initJob(jobId: JobId): void {
  db.prepare(
    `
  INSERT INTO jobs (
    id,
    status,
    created_at,
    updated_at
  )
  VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
`,
  ).run(jobId, "created");
}
