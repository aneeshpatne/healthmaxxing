export { db } from "./client";
import { db } from "./client";

export const BODY_COMPOSITION_METRICS_NEW_FACTORS = [
  "bmi",
  "body_fat_pct",
  "body_score",
  "body_age_years",
  "water_pct",
  "muscle_mass_kg",
  "bmr_kcal",
  "visceral_fat",
  "protein_pct",
  "subcutaneous_fat_pct",
] as const;


export async function getLatestBodyCompositionMeasurement(profileId: string) {
  return await db
    .prepare(
      "SELECT * FROM body_composition_metrics_new WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export async function getLatestBodyMeasurement(profileId: string) {
  return await db
    .prepare(
      "SELECT * FROM body_measurements WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export async function getProfileMetadata(profileId: string) {
  return await db
    .prepare(
      `
    SELECT
      height_cm AS heightCm,
      date_of_birth AS dateOfBirth,
      people_type AS peopleType,
      gender,
      preferred_body_fat_pct AS preferredBodyFatPct
    FROM profile_metadata
    WHERE profile_id = ?
    LIMIT 1
    `,
    )
    .get(profileId);
}

export async function getLatestWeightMeasurement(profileId: string) {
  return await db
    .prepare(
      `
    SELECT
      weight,
      created_at AS createdAt
    FROM measurements
    WHERE profile_id = ?
      AND weight IS NOT NULL
    ORDER BY created_at DESC
    LIMIT 1
    `,
    )
    .get(profileId);
}

export async function getFirstHealthDataEntry(profileId: string) {
  return await db
    .prepare(
      `
    SELECT source, created_at AS createdAt
    FROM (
      SELECT 'measurements' AS source, created_at
      FROM measurements
      WHERE profile_id = ?

      UNION ALL

      SELECT 'body_measurements' AS source, created_at
      FROM body_measurements
      WHERE profile_id = ?

      UNION ALL

      SELECT 'body_composition_metrics_new' AS source, created_at
      FROM body_composition_metrics_new
      WHERE profile_id = ?
    )
    ORDER BY created_at ASC
    LIMIT 1
    `,
    )
    .get(profileId, profileId, profileId);
}

export async function getBodyCompositionMeasurementDelta(profileId: string) {
  return await db
    .prepare(
      `
    WITH latest_measurement AS (
      SELECT *
      FROM body_composition_metrics_new
      WHERE profile_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ),
    forever_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
    ),
    last_year_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    ),
    last_30_days_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-30 days')
    ),
    last_7_days_avg AS (
      SELECT
        AVG(bmi) AS bmi,
        AVG(body_fat_pct) AS body_fat_pct,
        AVG(fat_mass_kg) AS fat_mass_kg,
        AVG(fat_free_mass_kg) AS fat_free_mass_kg,
        AVG(desired_weight_kg) AS desired_weight_kg,
        AVG(body_score) AS body_score,
        AVG(body_age_years) AS body_age_years,
        AVG(water_pct) AS water_pct,
        AVG(muscle_mass_kg) AS muscle_mass_kg,
        AVG(muscle_rate_pct) AS muscle_rate_pct,
        AVG(bmr_kcal) AS bmr_kcal,
        AVG(visceral_fat) AS visceral_fat,
        AVG(ideal_weight_kg) AS ideal_weight_kg,
        AVG(protein_mass_kg) AS protein_mass_kg,
        AVG(protein_pct) AS protein_pct,
        AVG(skeletal_muscle_kg) AS skeletal_muscle_kg,
        AVG(subcutaneous_fat_pct) AS subcutaneous_fat_pct,
        AVG(subcutaneous_fat_mass_kg) AS subcutaneous_fat_mass_kg,
        AVG(predicted_lean_mass_kg) AS predicted_lean_mass_kg
      FROM body_composition_metrics_new
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-7 days')
    )
    SELECT
      latest_measurement.bmi - forever_avg.bmi AS bmi_forever_delta,
      latest_measurement.bmi - last_year_avg.bmi AS bmi_last_year_delta,
      latest_measurement.bmi - last_30_days_avg.bmi AS bmi_last_30_days_delta,
      latest_measurement.bmi - last_7_days_avg.bmi AS bmi_last_7_days_delta,
      latest_measurement.body_fat_pct - forever_avg.body_fat_pct AS body_fat_pct_forever_delta,
      latest_measurement.body_fat_pct - last_year_avg.body_fat_pct AS body_fat_pct_last_year_delta,
      latest_measurement.body_fat_pct - last_30_days_avg.body_fat_pct AS body_fat_pct_last_30_days_delta,
      latest_measurement.body_fat_pct - last_7_days_avg.body_fat_pct AS body_fat_pct_last_7_days_delta,
      latest_measurement.fat_mass_kg - forever_avg.fat_mass_kg AS fat_mass_kg_forever_delta,
      latest_measurement.fat_mass_kg - last_year_avg.fat_mass_kg AS fat_mass_kg_last_year_delta,
      latest_measurement.fat_mass_kg - last_30_days_avg.fat_mass_kg AS fat_mass_kg_last_30_days_delta,
      latest_measurement.fat_mass_kg - last_7_days_avg.fat_mass_kg AS fat_mass_kg_last_7_days_delta,
      latest_measurement.fat_free_mass_kg - forever_avg.fat_free_mass_kg AS fat_free_mass_kg_forever_delta,
      latest_measurement.fat_free_mass_kg - last_year_avg.fat_free_mass_kg AS fat_free_mass_kg_last_year_delta,
      latest_measurement.fat_free_mass_kg - last_30_days_avg.fat_free_mass_kg AS fat_free_mass_kg_last_30_days_delta,
      latest_measurement.fat_free_mass_kg - last_7_days_avg.fat_free_mass_kg AS fat_free_mass_kg_last_7_days_delta,
      latest_measurement.desired_weight_kg - forever_avg.desired_weight_kg AS desired_weight_kg_forever_delta,
      latest_measurement.desired_weight_kg - last_year_avg.desired_weight_kg AS desired_weight_kg_last_year_delta,
      latest_measurement.desired_weight_kg - last_30_days_avg.desired_weight_kg AS desired_weight_kg_last_30_days_delta,
      latest_measurement.desired_weight_kg - last_7_days_avg.desired_weight_kg AS desired_weight_kg_last_7_days_delta,
      latest_measurement.body_score - forever_avg.body_score AS body_score_forever_delta,
      latest_measurement.body_score - last_year_avg.body_score AS body_score_last_year_delta,
      latest_measurement.body_score - last_30_days_avg.body_score AS body_score_last_30_days_delta,
      latest_measurement.body_score - last_7_days_avg.body_score AS body_score_last_7_days_delta,
      latest_measurement.body_age_years - forever_avg.body_age_years AS body_age_years_forever_delta,
      latest_measurement.body_age_years - last_year_avg.body_age_years AS body_age_years_last_year_delta,
      latest_measurement.body_age_years - last_30_days_avg.body_age_years AS body_age_years_last_30_days_delta,
      latest_measurement.body_age_years - last_7_days_avg.body_age_years AS body_age_years_last_7_days_delta,
      latest_measurement.water_pct - forever_avg.water_pct AS water_pct_forever_delta,
      latest_measurement.water_pct - last_year_avg.water_pct AS water_pct_last_year_delta,
      latest_measurement.water_pct - last_30_days_avg.water_pct AS water_pct_last_30_days_delta,
      latest_measurement.water_pct - last_7_days_avg.water_pct AS water_pct_last_7_days_delta,
      latest_measurement.muscle_mass_kg - forever_avg.muscle_mass_kg AS muscle_mass_kg_forever_delta,
      latest_measurement.muscle_mass_kg - last_year_avg.muscle_mass_kg AS muscle_mass_kg_last_year_delta,
      latest_measurement.muscle_mass_kg - last_30_days_avg.muscle_mass_kg AS muscle_mass_kg_last_30_days_delta,
      latest_measurement.muscle_mass_kg - last_7_days_avg.muscle_mass_kg AS muscle_mass_kg_last_7_days_delta,
      latest_measurement.muscle_rate_pct - forever_avg.muscle_rate_pct AS muscle_rate_pct_forever_delta,
      latest_measurement.muscle_rate_pct - last_year_avg.muscle_rate_pct AS muscle_rate_pct_last_year_delta,
      latest_measurement.muscle_rate_pct - last_30_days_avg.muscle_rate_pct AS muscle_rate_pct_last_30_days_delta,
      latest_measurement.muscle_rate_pct - last_7_days_avg.muscle_rate_pct AS muscle_rate_pct_last_7_days_delta,
      latest_measurement.bmr_kcal - forever_avg.bmr_kcal AS bmr_kcal_forever_delta,
      latest_measurement.bmr_kcal - last_year_avg.bmr_kcal AS bmr_kcal_last_year_delta,
      latest_measurement.bmr_kcal - last_30_days_avg.bmr_kcal AS bmr_kcal_last_30_days_delta,
      latest_measurement.bmr_kcal - last_7_days_avg.bmr_kcal AS bmr_kcal_last_7_days_delta,
      latest_measurement.visceral_fat - forever_avg.visceral_fat AS visceral_fat_forever_delta,
      latest_measurement.visceral_fat - last_year_avg.visceral_fat AS visceral_fat_last_year_delta,
      latest_measurement.visceral_fat - last_30_days_avg.visceral_fat AS visceral_fat_last_30_days_delta,
      latest_measurement.visceral_fat - last_7_days_avg.visceral_fat AS visceral_fat_last_7_days_delta,
      latest_measurement.ideal_weight_kg - forever_avg.ideal_weight_kg AS ideal_weight_kg_forever_delta,
      latest_measurement.ideal_weight_kg - last_year_avg.ideal_weight_kg AS ideal_weight_kg_last_year_delta,
      latest_measurement.ideal_weight_kg - last_30_days_avg.ideal_weight_kg AS ideal_weight_kg_last_30_days_delta,
      latest_measurement.ideal_weight_kg - last_7_days_avg.ideal_weight_kg AS ideal_weight_kg_last_7_days_delta,
      latest_measurement.protein_mass_kg - forever_avg.protein_mass_kg AS protein_mass_kg_forever_delta,
      latest_measurement.protein_mass_kg - last_year_avg.protein_mass_kg AS protein_mass_kg_last_year_delta,
      latest_measurement.protein_mass_kg - last_30_days_avg.protein_mass_kg AS protein_mass_kg_last_30_days_delta,
      latest_measurement.protein_mass_kg - last_7_days_avg.protein_mass_kg AS protein_mass_kg_last_7_days_delta,
      latest_measurement.protein_pct - forever_avg.protein_pct AS protein_pct_forever_delta,
      latest_measurement.protein_pct - last_year_avg.protein_pct AS protein_pct_last_year_delta,
      latest_measurement.protein_pct - last_30_days_avg.protein_pct AS protein_pct_last_30_days_delta,
      latest_measurement.protein_pct - last_7_days_avg.protein_pct AS protein_pct_last_7_days_delta,
      latest_measurement.skeletal_muscle_kg - forever_avg.skeletal_muscle_kg AS skeletal_muscle_kg_forever_delta,
      latest_measurement.skeletal_muscle_kg - last_year_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_year_delta,
      latest_measurement.skeletal_muscle_kg - last_30_days_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_30_days_delta,
      latest_measurement.skeletal_muscle_kg - last_7_days_avg.skeletal_muscle_kg AS skeletal_muscle_kg_last_7_days_delta,
      latest_measurement.subcutaneous_fat_pct - forever_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_forever_delta,
      latest_measurement.subcutaneous_fat_pct - last_year_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_year_delta,
      latest_measurement.subcutaneous_fat_pct - last_30_days_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_30_days_delta,
      latest_measurement.subcutaneous_fat_pct - last_7_days_avg.subcutaneous_fat_pct AS subcutaneous_fat_pct_last_7_days_delta,
      latest_measurement.subcutaneous_fat_mass_kg - forever_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_forever_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_year_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_year_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_30_days_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_30_days_delta,
      latest_measurement.subcutaneous_fat_mass_kg - last_7_days_avg.subcutaneous_fat_mass_kg AS subcutaneous_fat_mass_kg_last_7_days_delta,
      latest_measurement.predicted_lean_mass_kg - forever_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_forever_delta,
      latest_measurement.predicted_lean_mass_kg - last_year_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_year_delta,
      latest_measurement.predicted_lean_mass_kg - last_30_days_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_30_days_delta,
      latest_measurement.predicted_lean_mass_kg - last_7_days_avg.predicted_lean_mass_kg AS predicted_lean_mass_kg_last_7_days_delta
    FROM latest_measurement
    CROSS JOIN forever_avg
    CROSS JOIN last_year_avg
    CROSS JOIN last_30_days_avg
    CROSS JOIN last_7_days_avg
    `,
    )
    .get(profileId, profileId, profileId, profileId, profileId);
}

const BODY_COMPOSITION_DELTA_METRICS = [
  "bmi",
  "body_fat_pct",
  "fat_mass_kg",
  "fat_free_mass_kg",
  "desired_weight_kg",
  "body_score",
  "body_age_years",
  "water_pct",
  "muscle_mass_kg",
  "muscle_rate_pct",
  "bmr_kcal",
  "visceral_fat",
  "ideal_weight_kg",
  "protein_mass_kg",
  "protein_pct",
  "skeletal_muscle_kg",
  "subcutaneous_fat_pct",
  "subcutaneous_fat_mass_kg",
  "predicted_lean_mass_kg",
] as const;

const BODY_COMPOSITION_DELTA_PERIODS = [
  "forever",
  "last_year",
  "last_30_days",
  "last_7_days",
] as const;

type DeltaPeriod = (typeof BODY_COMPOSITION_DELTA_PERIODS)[number];
type CompactDeltaRow = [string, ...(number | null)[]];

export type CompactDeltaTable = {
  columns: ["metric", ...DeltaPeriod[]];
  rows: CompactDeltaRow[];
};

function compactDelta(value: unknown): number | null {
  // PostgreSQL returns expressions involving AVG(integer) as NUMERIC, which
  // Bun may decode as a string. BIGINT values can similarly arrive as bigint.
  if (
    typeof value !== "number" &&
    typeof value !== "bigint" &&
    typeof value !== "string"
  ) {
    return null;
  }

  if (typeof value === "string" && value.trim() === "") return null;

  const numericValue = Number(value);
  if (!Number.isFinite(numericValue)) return null;

  return Math.round(numericValue * 100) / 100;
}

function toCompactDeltaTable(
  delta: Record<string, unknown>,
  metrics: readonly string[],
): CompactDeltaTable {
  return {
    columns: ["metric", ...BODY_COMPOSITION_DELTA_PERIODS],
    rows: metrics.map((metric) => [
      metric,
      ...BODY_COMPOSITION_DELTA_PERIODS.map((period) =>
        compactDelta(delta[`${metric}_${period}_delta`]),
      ),
    ]),
  };
}

/**
 * Token-efficient form of getBodyCompositionMeasurementDelta.
 *
 * Each row is [metric, forever, last_year, last_30_days, last_7_days]. Values
 * are the latest measurement minus the corresponding period average.
 */
export async function getBodyCompositionMeasurementDeltaV2(profileId: string) {
  const delta = await getBodyCompositionMeasurementDelta(profileId);
  if (!delta) return null;

  return toCompactDeltaTable(delta, BODY_COMPOSITION_DELTA_METRICS);
}

export async function getBodyMeasurementDelta(profileId: string) {
  return await db
    .prepare(
      `
    WITH latest_measurement AS (
      SELECT *
      FROM body_measurements
      WHERE profile_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ),
    forever_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
    ),
    last_year_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    ),
    last_30_days_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-30 days')
    ),
    last_7_days_avg AS (
      SELECT
        AVG(neck_cm) AS neck_cm,
        AVG(shoulder_cm) AS shoulder_cm,
        AVG(chest_cm) AS chest_cm,
        AVG(stomach_cm) AS stomach_cm,
        AVG(waist_cm) AS waist_cm,
        AVG(calf_cm) AS calf_cm,
        AVG(thigh_cm) AS thigh_cm,
        AVG(bicep_cm) AS bicep_cm,
        AVG(forearm_cm) AS forearm_cm
      FROM body_measurements
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-7 days')
    )
    SELECT
      latest_measurement.neck_cm - forever_avg.neck_cm AS neck_cm_forever_delta,
      latest_measurement.neck_cm - last_year_avg.neck_cm AS neck_cm_last_year_delta,
      latest_measurement.neck_cm - last_30_days_avg.neck_cm AS neck_cm_last_30_days_delta,
      latest_measurement.neck_cm - last_7_days_avg.neck_cm AS neck_cm_last_7_days_delta,
      latest_measurement.shoulder_cm - forever_avg.shoulder_cm AS shoulder_cm_forever_delta,
      latest_measurement.shoulder_cm - last_year_avg.shoulder_cm AS shoulder_cm_last_year_delta,
      latest_measurement.shoulder_cm - last_30_days_avg.shoulder_cm AS shoulder_cm_last_30_days_delta,
      latest_measurement.shoulder_cm - last_7_days_avg.shoulder_cm AS shoulder_cm_last_7_days_delta,
      latest_measurement.chest_cm - forever_avg.chest_cm AS chest_cm_forever_delta,
      latest_measurement.chest_cm - last_year_avg.chest_cm AS chest_cm_last_year_delta,
      latest_measurement.chest_cm - last_30_days_avg.chest_cm AS chest_cm_last_30_days_delta,
      latest_measurement.chest_cm - last_7_days_avg.chest_cm AS chest_cm_last_7_days_delta,
      latest_measurement.stomach_cm - forever_avg.stomach_cm AS stomach_cm_forever_delta,
      latest_measurement.stomach_cm - last_year_avg.stomach_cm AS stomach_cm_last_year_delta,
      latest_measurement.stomach_cm - last_30_days_avg.stomach_cm AS stomach_cm_last_30_days_delta,
      latest_measurement.stomach_cm - last_7_days_avg.stomach_cm AS stomach_cm_last_7_days_delta,
      latest_measurement.waist_cm - forever_avg.waist_cm AS waist_cm_forever_delta,
      latest_measurement.waist_cm - last_year_avg.waist_cm AS waist_cm_last_year_delta,
      latest_measurement.waist_cm - last_30_days_avg.waist_cm AS waist_cm_last_30_days_delta,
      latest_measurement.waist_cm - last_7_days_avg.waist_cm AS waist_cm_last_7_days_delta,
      latest_measurement.calf_cm - forever_avg.calf_cm AS calf_cm_forever_delta,
      latest_measurement.calf_cm - last_year_avg.calf_cm AS calf_cm_last_year_delta,
      latest_measurement.calf_cm - last_30_days_avg.calf_cm AS calf_cm_last_30_days_delta,
      latest_measurement.calf_cm - last_7_days_avg.calf_cm AS calf_cm_last_7_days_delta,
      latest_measurement.thigh_cm - forever_avg.thigh_cm AS thigh_cm_forever_delta,
      latest_measurement.thigh_cm - last_year_avg.thigh_cm AS thigh_cm_last_year_delta,
      latest_measurement.thigh_cm - last_30_days_avg.thigh_cm AS thigh_cm_last_30_days_delta,
      latest_measurement.thigh_cm - last_7_days_avg.thigh_cm AS thigh_cm_last_7_days_delta,
      latest_measurement.bicep_cm - forever_avg.bicep_cm AS bicep_cm_forever_delta,
      latest_measurement.bicep_cm - last_year_avg.bicep_cm AS bicep_cm_last_year_delta,
      latest_measurement.bicep_cm - last_30_days_avg.bicep_cm AS bicep_cm_last_30_days_delta,
      latest_measurement.bicep_cm - last_7_days_avg.bicep_cm AS bicep_cm_last_7_days_delta,
      latest_measurement.forearm_cm - forever_avg.forearm_cm AS forearm_cm_forever_delta,
      latest_measurement.forearm_cm - last_year_avg.forearm_cm AS forearm_cm_last_year_delta,
      latest_measurement.forearm_cm - last_30_days_avg.forearm_cm AS forearm_cm_last_30_days_delta,
      latest_measurement.forearm_cm - last_7_days_avg.forearm_cm AS forearm_cm_last_7_days_delta
    FROM latest_measurement
    CROSS JOIN forever_avg
    CROSS JOIN last_year_avg
    CROSS JOIN last_30_days_avg
    CROSS JOIN last_7_days_avg
    `,
    )
    .get(profileId, profileId, profileId, profileId, profileId);
}

const BODY_MEASUREMENT_DELTA_METRICS = [
  "neck_cm",
  "shoulder_cm",
  "chest_cm",
  "stomach_cm",
  "waist_cm",
  "calf_cm",
  "thigh_cm",
  "bicep_cm",
  "forearm_cm",
] as const;

export async function getBodyMeasurementDeltaV2(profileId: string) {
  const delta = await getBodyMeasurementDelta(profileId);
  if (!delta) return null;

  return toCompactDeltaTable(delta, BODY_MEASUREMENT_DELTA_METRICS);
}

function deltaTableToTsv(table: CompactDeltaTable | null): string {
  if (!table) return "No measurements available.";

  return [
    table.columns.join("\t"),
    ...table.rows.map((row) =>
      row.map((value) => value ?? "NA").join("\t"),
    ),
  ].join("\n");
}

export function bodyMeasurementDeltasToLlmInput(
  bodyComposition: CompactDeltaTable | null,
  bodyMeasurements: CompactDeltaTable | null,
): string {
  return [
    "Deltas are latest measurement minus period average.",
    "[body_composition]",
    deltaTableToTsv(bodyComposition),
    "[body_measurements]",
    deltaTableToTsv(bodyMeasurements),
  ].join("\n");
}
