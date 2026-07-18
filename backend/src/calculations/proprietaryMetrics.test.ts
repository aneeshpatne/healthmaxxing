import { expect, test } from "bun:test";
import { coerceMetrics } from "./proprietaryMetrics";

const validMetrics = {
  bmi: 24,
  body_fat_pct: 20,
  fat_mass_kg: 14,
  fat_free_mass_kg: 56,
  body_score: 76,
  body_age_years: 30,
  water_pct: 58,
  muscle_mass_kg: 42,
  muscle_rate_pct: 60,
  bmr_kcal: 1600,
  visceral_fat: 8,
  ideal_weight_kg: 66,
  protein_mass_kg: 12,
  protein_pct: 17,
  skeletal_muscle_kg: 31,
  subcutaneous_fat_pct: 15,
  subcutaneous_fat_mass_kg: 10.5,
  predicted_lean_mass_kg: 56,
};

test("coerceMetrics accepts a mass-conserving response", () => {
  expect(coerceMetrics(validMetrics, 70).body_score).toBe(76);
});

test("coerceMetrics rejects inconsistent mass totals", () => {
  expect(() =>
    coerceMetrics({ ...validMetrics, fat_free_mass_kg: 45 }, 70),
  ).toThrow("fat and fat-free mass do not match weight");
});

test("coerceMetrics rejects impossible compartment values", () => {
  expect(() =>
    coerceMetrics({ ...validMetrics, subcutaneous_fat_mass_kg: 16 }, 70),
  ).toThrow("subcutaneous fat exceeds total fat mass");
});
