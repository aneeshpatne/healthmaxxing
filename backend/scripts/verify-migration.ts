import { Database } from "bun:sqlite";
import { sql } from "../src/db/client";
import { TABLES } from "./sqlite-data";

const source = new Database(process.argv[2] ?? "mydb.sqlite", { readonly: true });
let failed = false;

for (const table of TABLES) {
  const sqliteCount = (source.query(`SELECT count(*) AS count FROM ${table}`).get() as { count: number }).count;
  const [row] = await sql.unsafe(`SELECT count(*)::int AS count FROM ${table}`);
  const postgresCount = Number(row.count);
  const ok = sqliteCount === postgresCount;
  console.log(`${ok ? "✓" : "✗"} ${table}: sqlite=${sqliteCount} postgres=${postgresCount}`);
  failed ||= !ok;
}

const foreignKeys = await sql`
  SELECT conrelid::regclass::text AS table_name, conname
  FROM pg_constraint
  WHERE contype = 'f' AND NOT convalidated
`;
if (foreignKeys.length) {
  console.error("Unvalidated foreign keys", foreignKeys);
  failed = true;
}

source.close();
await sql.close();
if (failed) process.exit(1);
