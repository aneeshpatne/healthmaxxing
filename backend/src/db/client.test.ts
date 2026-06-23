import { afterAll, describe, expect, test } from "bun:test";

process.env.DATABASE_URL ??= "postgres://healthmaxxing:healthmaxxing@127.0.0.1:5432/healthmaxxing";

const { closeDatabase, postgresQuery } = await import("./client");

describe("postgresQuery", () => {
  test("converts positional parameters and preserves camel-case aliases", () => {
    expect(postgresQuery("SELECT created_at AS createdAt WHERE id = ? AND name = ?")).toBe(
      'SELECT created_at AS "createdAt" WHERE id = $1 AND name = $2',
    );
  });

  test("converts SQLite date windows", () => {
    expect(postgresQuery("created_at >= datetime('now', '-30 days')")).toBe(
      "created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'",
    );
    expect(postgresQuery("created_at >= datetime('now', ?)")).toBe(
      "created_at >= CURRENT_TIMESTAMP + $1::interval",
    );
  });

  test("converts scalar max and two-argument round", () => {
    expect(postgresQuery("ROUND(MAX(fat_free_mass_kg - muscle_mass_kg, 0), 2)")).toBe(
      "ROUND((GREATEST(fat_free_mass_kg - muscle_mass_kg, 0))::numeric,  2)::double precision",
    );
  });

  test("converts SQLite boolean comparisons", () => {
    expect(postgresQuery("WHERE is_trendable = 1")).toBe("WHERE is_trendable = true");
  });
});

afterAll(async () => {
  await closeDatabase();
});
