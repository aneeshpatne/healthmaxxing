import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { sql } from "./client";

export async function migrateDatabase(): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `;

  const directory = join(import.meta.dir, "..", "..", "migrations");
  const files = (await readdir(directory)).filter((name) => name.endsWith(".sql")).sort();

  for (const name of files) {
    const [applied] = await sql`SELECT 1 FROM schema_migrations WHERE name = ${name}`;
    if (applied) continue;
    const source = await Bun.file(join(directory, name)).text();
    await sql.begin(async (tx) => {
      await tx.unsafe(source);
      await tx`INSERT INTO schema_migrations (name) VALUES (${name})`;
    });
  }
}
