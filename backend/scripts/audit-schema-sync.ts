/**
 * Compare live DB columns vs code INSERT/UPDATE targets and migration-defined schema.
 */
import { readdir } from "node:fs/promises";
import { join } from "node:path";

const pass = new URL(process.env.DATABASE_URL!).password;
const user = new URL(process.env.DATABASE_URL!).username;
const dbname = new URL(process.env.DATABASE_URL!).pathname.slice(1);

async function psql(query: string): Promise<string> {
  const proc = Bun.spawn(
    [
      "docker",
      "exec",
      "-e",
      `PGPASSWORD=${pass}`,
      "healthmaxxing-postgres-1",
      "psql",
      "-U",
      user,
      "-d",
      dbname,
      "-t",
      "-A",
      "-F",
      "|",
      "-c",
      query,
    ],
    { stdout: "pipe", stderr: "pipe" },
  );
  const out = await new Response(proc.stdout).text();
  const err = await new Response(proc.stderr).text();
  if ((await proc.exited) !== 0) {
    throw new Error(err || out || "psql failed");
  }
  return out;
}

async function walk(dir: string): Promise<string[]> {
  const out: string[] = [];
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...(await walk(p)));
    else if (e.name.endsWith(".ts") && !e.name.endsWith(".test.ts")) out.push(p);
  }
  return out;
}

const raw = await psql(
  `SELECT table_name || '|' || column_name FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, column_name`,
);
const dbCols = new Map<string, Set<string>>();
for (const line of raw.split("\n")) {
  if (!line.includes("|")) continue;
  const [t, c] = line.split("|");
  if (!dbCols.has(t)) dbCols.set(t, new Set());
  dbCols.get(t)!.add(c);
}

// Ideal columns from migrations (CREATE TABLE + ADD COLUMN)
const migDir = join(import.meta.dir, "..", "migrations");
const migFiles = (await readdir(migDir)).filter((f) => f.endsWith(".sql")).sort();
let migSql = "";
for (const f of migFiles) migSql += "\n" + (await Bun.file(join(migDir, f)).text());

const ideal = new Map<string, Set<string>>();
for (const m of migSql.matchAll(/CREATE TABLE (\w+)\s*\(([\s\S]*?)\);/gi)) {
  const table = m[1].toLowerCase();
  if (!ideal.has(table)) ideal.set(table, new Set());
  for (const part of m[2].split(",")) {
    const col = part.trim().split(/\s+/)[0].replace(/[()]/g, "");
    if (
      col &&
      /^[a-z_][a-z0-9_]*$/i.test(col) &&
      !/^(PRIMARY|FOREIGN|UNIQUE|CHECK|CONSTRAINT|REFERENCES)$/i.test(col)
    ) {
      ideal.get(table)!.add(col.toLowerCase());
    }
  }
}
for (const m of migSql.matchAll(/ALTER TABLE (\w+)\s+ADD COLUMN (\w+)/gi)) {
  const table = m[1].toLowerCase();
  if (!ideal.has(table)) ideal.set(table, new Set());
  ideal.get(table)!.add(m[2].toLowerCase());
}

// Code INSERT / UPDATE targets
const codeWrites = new Map<string, Set<string>>();
const codeTables = new Set<string>();
for (const f of await walk(join(import.meta.dir, "..", "src"))) {
  const t = await Bun.file(f).text();
  for (const m of t.matchAll(/INSERT\s+(?:INTO|into)\s+(\w+)\s*\(([^)]+)\)/gi)) {
    const table = m[1].toLowerCase();
    codeTables.add(table);
    if (!codeWrites.has(table)) codeWrites.set(table, new Set());
    for (const c of m[2].split(",")) {
      const col = c.trim().replace(/[`'"]/g, "").split(/\s+/)[0].toLowerCase();
      if (col && /^[a-z_][a-z0-9_]*$/.test(col)) codeWrites.get(table)!.add(col);
    }
  }
  for (const m of t.matchAll(/UPDATE\s+(\w+)\s+SET\s+([\s\S]*?)(?:WHERE|RETURNING|;|`)/gi)) {
    const table = m[1].toLowerCase();
    codeTables.add(table);
    if (!codeWrites.has(table)) codeWrites.set(table, new Set());
    for (const part of m[2].split(",")) {
      const col = part.trim().split(/\s*=/)[0].trim().toLowerCase().replace(/[`'"]/g, "");
      if (col && /^[a-z_][a-z0-9_]*$/.test(col)) codeWrites.get(table)!.add(col);
    }
  }
  for (const m of t.matchAll(/(?:FROM|JOIN)\s+(\w+)/gi)) {
    codeTables.add(m[1].toLowerCase());
  }
}

let issues = 0;

console.log("=== CODE WRITES missing from LIVE DB ===");
for (const [table, cols] of [...codeWrites.entries()].sort()) {
  const live = dbCols.get(table);
  if (!live) {
    console.log(`MISSING TABLE: ${table}`);
    issues++;
    continue;
  }
  for (const c of [...cols].sort()) {
    if (!live.has(c)) {
      console.log(`  ${table}.${c}`);
      issues++;
    }
  }
}

console.log("\n=== MIGRATION-DEFINED columns missing from LIVE DB ===");
for (const [table, cols] of [...ideal.entries()].sort()) {
  const live = dbCols.get(table);
  if (!live) {
    console.log(`MISSING TABLE: ${table}`);
    issues++;
    continue;
  }
  for (const c of [...cols].sort()) {
    if (!live.has(c)) {
      console.log(`  ${table}.${c}`);
      issues++;
    }
  }
}

console.log("\n=== KEY TABLE SNAPSHOTS (live) ===");
for (const t of ["accounts", "measurements", "jobs", "profiles", "profile_metadata", "profile_insight_reports"]) {
  console.log(`${t}: ${[...(dbCols.get(t) ?? [])].sort().join(", ")}`);
}

console.log(`\nTotal issues: ${issues}`);
process.exit(issues > 0 ? 1 : 0);
