import { expect, test } from "bun:test";
import { buildEndpointDeltaTable, formatProfileMetadataCompact } from "./db";

test("endpoint trends use the earliest reading rather than a period average", () => {
  const result = buildEndpointDeltaTable(
    [
      { createdAt: "2026-06-01T00:00:00.000Z", fat_mass_kg: 20 },
      { createdAt: "2026-06-15T00:00:00.000Z", fat_mass_kg: 30 },
      { createdAt: "2026-07-01T00:00:00.000Z", fat_mass_kg: 18 },
    ],
    ["fat_mass_kg"],
    "2026-07-01T00:00:00.000Z",
  );

  expect(result.readingCount).toBe(3);
  expect(result.table?.rows[0]).toEqual([
    "fat_mass_kg",
    -2,
    -2,
    -2,
    null,
  ]);
});

test("one reading does not produce a trend", () => {
  const result = buildEndpointDeltaTable(
    [{ createdAt: "2026-07-01T00:00:00.000Z", muscle_mass_kg: 42 }],
    ["muscle_mass_kg"],
    "2026-07-01T00:00:00.000Z",
  );
  expect(result.table?.rows[0]).toEqual([
    "muscle_mass_kg",
    null,
    null,
    null,
    null,
  ]);
});

test("profile context sends age instead of date of birth", () => {
  const compact = formatProfileMetadataCompact({
    heightCm: 175,
    ageYears: 31,
    dateOfBirth: "1995-01-01",
    peopleType: "athlete",
    gender: "male",
    preferredBodyFatPct: 15,
  });
  expect(compact).toBe(
    "h_cm=175 age_y=31 type=athlete sex=male targetBF_pct=15",
  );
  expect(compact.includes("1995")).toBe(false);
});
