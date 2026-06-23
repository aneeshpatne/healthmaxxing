import { Database } from "bun:sqlite";
import { sql } from "../src/db/client";
import { BOOLEAN_COLUMNS, JSON_COLUMNS, TABLES } from "./sqlite-data";

const sqlitePath = process.argv[2] ?? "mydb.sqlite";
const source = new Database(sqlitePath, { readonly: true });

const [{ count }] = await sql`SELECT count(*)::int AS count FROM accounts`;
if (count !== 0 && !process.argv.includes("--force")) {
  throw new Error("PostgreSQL is not empty; reset it or pass --force intentionally");
}

await sql.begin(async (tx) => {
  await tx.unsafe("SET CONSTRAINTS ALL DEFERRED");
  for (const table of TABLES) {
    const rows = source.query(`SELECT * FROM ${table}`).all() as Record<string, unknown>[];
    for (const row of rows) {
      const normalized = Object.fromEntries(Object.entries(row).map(([column, value]) => {
        if (value !== null && BOOLEAN_COLUMNS[table]?.has(column)) return [column, Boolean(value)];
        if (typeof value === "string" && JSON_COLUMNS[table]?.has(column)) return [column, JSON.parse(value)];
        return [column, value];
      }));
      await tx`INSERT INTO ${tx(table)} ${tx(normalized)} ON CONFLICT DO NOTHING`;
    }
    console.log(`Imported ${table}: ${rows.length}`);
  }
});

source.close();
await sql.close();
