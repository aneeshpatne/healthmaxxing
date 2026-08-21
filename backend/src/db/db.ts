export { db } from "./client";
import { db } from "./client";

export const BODY_COMPOSITION_METRICS_NEW_FACTORS = [
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
  "skeletal_muscle_kg",
  "protein_pct",
  "subcutaneous_fat_pct",
  "subcutaneous_fat_mass_kg",
  "predicted_lean_mass_kg",
] as const;


export async function getLatestBodyCompositionMeasurement(profileId: string) {
  return await db
    .prepare(
      "SELECT * FROM body_composition_metrics_new WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export async function getLatestBodyCompositionMeasurementV2(profileId: string) {
  const measurement = await db
    .prepare(
      "SELECT bmi, body_fat_pct, fat_mass_kg, fat_free_mass_kg, desired_weight_kg, body_score, body_age_years, water_pct, muscle_mass_kg, muscle_rate_pct, bmr_kcal, visceral_fat, ideal_weight_kg, protein_mass_kg, protein_pct, skeletal_muscle_kg, subcutaneous_fat_pct, subcutaneous_fat_mass_kg, predicted_lean_mass_kg FROM body_composition_metrics_new WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);

  if (!measurement) return null;

  return toCompactMetricTable(
    measurement as Record<string, unknown>,
    BODY_COMPOSITION_METRICS_NEW_FACTORS,
  );
}

export async function getBodyCompositionMeasurementByIdV2(
  profileId: string,
  bodyCompositionMetricsId: string,
) {
  const measurement = await db.prepare(
    `SELECT bmi, body_fat_pct, fat_mass_kg, fat_free_mass_kg, desired_weight_kg,
      body_score, body_age_years, water_pct, muscle_mass_kg, muscle_rate_pct,
      bmr_kcal, visceral_fat, ideal_weight_kg, protein_mass_kg, protein_pct,
      skeletal_muscle_kg, subcutaneous_fat_pct, subcutaneous_fat_mass_kg,
      predicted_lean_mass_kg
     FROM body_composition_metrics_new
     WHERE profile_id = ? AND id = ?
     LIMIT 1`,
  ).get(profileId, bodyCompositionMetricsId);

  if (!measurement) return null;
  return toCompactMetricTable(
    measurement as Record<string, unknown>,
    BODY_COMPOSITION_METRICS_NEW_FACTORS,
  );
}

type ReportTrendBundle = {
  table: CompactDeltaTable | null;
  asOf: string;
  firstReadingAt: string | null;
  readingCount: number;
};

export function buildEndpointDeltaTable(
  rows: Array<Record<string, unknown> & { createdAt: string }>,
  metrics: readonly string[],
  asOf: string,
): ReportTrendBundle {
  const latest = rows.at(-1);
  if (!latest) {
    return { table: null, asOf, firstReadingAt: null, readingCount: 0 };
  }

  const asOfTime = new Date(asOf).getTime();
  const periods = [
    Number.NEGATIVE_INFINITY,
    asOfTime - 365 * 24 * 60 * 60 * 1000,
    asOfTime - 30 * 24 * 60 * 60 * 1000,
    asOfTime - 7 * 24 * 60 * 60 * 1000,
  ];
  const baselines = periods.map((cutoff) =>
    rows.find((row) => new Date(row.createdAt).getTime() >= cutoff),
  );

  return {
    asOf,
    firstReadingAt: rows[0]?.createdAt ?? null,
    readingCount: rows.length,
    table: {
      columns: ["metric", ...BODY_COMPOSITION_DELTA_PERIODS],
      rows: metrics.map((metric) => [
        metric,
        ...baselines.map((baseline) => {
          if (!baseline || baseline === latest) return null;
          const current = compactDelta(latest[metric]);
          const initial = compactDelta(baseline[metric]);
          return current === null || initial === null
            ? null
            : compactDelta(current - initial);
        }),
      ]),
    },
  };
}

export async function getBodyCompositionEndpointTrendsV2(
  profileId: string,
  asOf: string,
): Promise<ReportTrendBundle> {
  const rows = await db.prepare(
    `SELECT *, created_at AS createdAt
     FROM body_composition_metrics_new
     WHERE profile_id = ? AND created_at <= ?
     ORDER BY created_at ASC`,
  ).all(profileId, asOf) as Array<Record<string, unknown> & { createdAt: string }>;
  return buildEndpointDeltaTable(rows, BODY_COMPOSITION_DELTA_METRICS, asOf);
}

export async function getLatestBodyMeasurement(profileId: string) {
  return await db
    .prepare(
      "SELECT * FROM body_measurements WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);
}

export async function getLatestBodyMeasurementV2(profileId: string) {
  const measurement = await db
    .prepare(
      "SELECT neck_cm, shoulder_cm, chest_cm, stomach_cm, waist_cm, calf_cm, thigh_cm, bicep_cm, forearm_cm FROM body_measurements WHERE profile_id = ? ORDER BY created_at DESC LIMIT 1",
    )
    .get(profileId);

  if (!measurement) return null;

  return toCompactMetricTable(
    measurement as Record<string, unknown>,
    BODY_MEASUREMENT_DELTA_METRICS,
  );
}

export async function getLatestBodyMeasurementAtV2(
  profileId: string,
  asOf: string,
) {
  const measurement = await db.prepare(
    `SELECT neck_cm, shoulder_cm, chest_cm, stomach_cm, waist_cm, calf_cm,
      thigh_cm, bicep_cm, forearm_cm
     FROM body_measurements
     WHERE profile_id = ? AND created_at <= ?
     ORDER BY created_at DESC LIMIT 1`,
  ).get(profileId, asOf);
  if (!measurement) return null;
  return toCompactMetricTable(
    measurement as Record<string, unknown>,
    BODY_MEASUREMENT_DELTA_METRICS,
  );
}

export async function getBodyMeasurementEndpointTrendsV2(
  profileId: string,
  asOf: string,
): Promise<ReportTrendBundle> {
  const rows = await db.prepare(
    `SELECT *, created_at AS createdAt
     FROM body_measurements
     WHERE profile_id = ? AND created_at <= ?
     ORDER BY created_at ASC`,
  ).all(profileId, asOf) as Array<Record<string, unknown> & { createdAt: string }>;
  return buildEndpointDeltaTable(rows, BODY_MEASUREMENT_DELTA_METRICS, asOf);
}

export async function getProfileMetadata(profileId: string) {
  return await db
    .prepare(
      `
    SELECT
      profiles.name,
      height_cm AS heightCm,
      date_of_birth AS dateOfBirth,
      people_type AS peopleType,
      gender,
      preferred_body_fat_pct AS preferredBodyFatPct,
      muscularity_goal AS muscularityGoal
    FROM profile_metadata
    INNER JOIN profiles ON profiles.id = profile_metadata.profile_id
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

async function getFmiFfmiDelta(profileId: string) {
  return await db
    .prepare(
      `
    WITH latest_measurement AS (
      SELECT fmi, ffmi
      FROM derived_body_composition_metrics
      WHERE profile_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ),
    forever_avg AS (
      SELECT
        AVG(fmi) AS fmi,
        AVG(ffmi) AS ffmi
      FROM derived_body_composition_metrics
      WHERE profile_id = ?
    ),
    last_year_avg AS (
      SELECT
        AVG(fmi) AS fmi,
        AVG(ffmi) AS ffmi
      FROM derived_body_composition_metrics
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-1 year')
    ),
    last_30_days_avg AS (
      SELECT
        AVG(fmi) AS fmi,
        AVG(ffmi) AS ffmi
      FROM derived_body_composition_metrics
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-30 days')
    ),
    last_7_days_avg AS (
      SELECT
        AVG(fmi) AS fmi,
        AVG(ffmi) AS ffmi
      FROM derived_body_composition_metrics
      WHERE profile_id = ?
        AND created_at >= datetime('now', '-7 days')
    )
    SELECT
      latest_measurement.fmi - forever_avg.fmi AS fmi_forever_delta,
      latest_measurement.fmi - last_year_avg.fmi AS fmi_last_year_delta,
      latest_measurement.fmi - last_30_days_avg.fmi AS fmi_last_30_days_delta,
      latest_measurement.fmi - last_7_days_avg.fmi AS fmi_last_7_days_delta,
      latest_measurement.ffmi - forever_avg.ffmi AS ffmi_forever_delta,
      latest_measurement.ffmi - last_year_avg.ffmi AS ffmi_last_year_delta,
      latest_measurement.ffmi - last_30_days_avg.ffmi AS ffmi_last_30_days_delta,
      latest_measurement.ffmi - last_7_days_avg.ffmi AS ffmi_last_7_days_delta
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

type CompactMetricRow = [string, number | null];

export type CompactMetricTable = {
  columns: ["metric", "value"];
  rows: CompactMetricRow[];
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

function toCompactMetricTable(
  measurement: Record<string, unknown>,
  metrics: readonly string[],
): CompactMetricTable {
  return {
    columns: ["metric", "value"],
    rows: metrics.map((metric) => [metric, compactDelta(measurement[metric])]),
  };
}

/**
 * Token-efficient form of getBodyCompositionMeasurementDelta.
 *
 * Each row is [metric, forever, last_year, last_30_days, last_7_days]. Values
 * are the latest measurement minus the corresponding period average.
 * Kept for backward-compatible client queries; AI reports use endpoint trends.
 */
export async function getBodyCompositionMeasurementDeltaV2(profileId: string) {
  const [delta, fmiFfmiDelta] = await Promise.all([
    getBodyCompositionMeasurementDelta(profileId),
    getFmiFfmiDelta(profileId),
  ]);
  if (!delta) return null;

  const combinedDelta = { ...delta, ...(fmiFfmiDelta as Record<string, unknown>) };

  return toCompactDeltaTable(combinedDelta, [
    ...BODY_COMPOSITION_DELTA_METRICS,
    "fmi",
    "ffmi",
  ]);
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

function cell(value: unknown): string {
  if (value == null) return "NA";
  return String(value);
}

function deltaTableToTsv(table: CompactDeltaTable | null): string {
  if (!table) return "";

  return [
    table.columns.join("\t"),
    ...table.rows.map((row) =>
      row.map((value) => cell(value)).join("\t"),
    ),
  ].join("\n");
}

function metricTableToTsv(table: CompactMetricTable | null): string {
  if (!table) return "";

  return [
    table.columns.join("\t"),
    ...table.rows.map((row) =>
      row.map((value) => cell(value)).join("\t"),
    ),
  ].join("\n");
}

/** YYYY-MM-DD when parseable; otherwise original string or null. */
export function formatIsoDate(value: unknown): string | null {
  if (value == null || value === "") return null;
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toISOString().slice(0, 10);
}

/**
 * Compact profile line for LLM input.
 * Example: h_cm=165 age_y=57 type=standard sex=male targetBF_pct=18
 */
export function formatProfileMetadataCompact(
  record: Record<string, unknown> | null | undefined,
): string {
  if (!record) return "";

  const parts: string[] = [];
  const name = typeof record.name === "string" ? record.name.trim() : "";
  const height = record.heightCm;
  const dob = record.dateOfBirth == null ? null : new Date(String(record.dateOfBirth));
  const storedAge = Number(record.ageYears);
  const age = Number.isFinite(storedAge)
    ? storedAge
    : dob !== null && !Number.isNaN(dob.getTime())
      ? Math.max(
          0,
          new Date().getUTCFullYear() - dob.getUTCFullYear() -
            (new Date().getUTCMonth() < dob.getUTCMonth() ||
            (new Date().getUTCMonth() === dob.getUTCMonth() &&
              new Date().getUTCDate() < dob.getUTCDate())
              ? 1
              : 0),
        )
        : null;
  const peopleType = record.peopleType;
  const gender = record.gender;
  const targetBf = record.preferredBodyFatPct;
  const muscularityGoal = record.muscularityGoal;

  if (name) parts.push(`name=${JSON.stringify(name)}`);
  if (height != null) parts.push(`h_cm=${height}`);
  if (age != null) parts.push(`age_y=${age}`);
  if (peopleType != null) parts.push(`type=${peopleType}`);
  if (gender != null) parts.push(`sex=${gender}`);
  if (targetBf != null) parts.push(`targetBF_pct=${targetBf}`);
  if (muscularityGoal != null) parts.push(`muscularity=${muscularityGoal}`);

  return parts.join(" ");
}

/**
 * Merge current snapshot + period deltas into one TSV.
 * Columns: m (metric), v (current), all/y1/d30/d7 (latest − period avg).
 * Omits empty tables. Keeps full metric keys (tool enums).
 */
export function formatSnapshotWithDeltas(
  latest: CompactMetricTable | null,
  delta: CompactDeltaTable | null,
): string {
  if (!latest && !delta) return "";

  const valueByMetric = new Map<string, number | null>(
    (latest?.rows ?? []).map(([metric, value]) => [metric, value]),
  );

  if (delta) {
    const header = "m\tv\tall\ty1\td30\td7";
    const seen = new Set<string>();
    const lines: string[] = [header];

    for (const row of delta.rows) {
      const metric = row[0];
      seen.add(metric);
      const current = valueByMetric.has(metric)
        ? cell(valueByMetric.get(metric))
        : "NA";
      lines.push(
        [metric, current, ...row.slice(1).map((value) => cell(value))].join(
          "\t",
        ),
      );
    }

    for (const [metric, value] of valueByMetric) {
      if (seen.has(metric)) continue;
      lines.push([metric, cell(value), "NA", "NA", "NA", "NA"].join("\t"));
    }

    return lines.join("\n");
  }

  return [
    "m\tv",
    ...(latest?.rows ?? []).map(
      ([metric, value]) => `${metric}\t${cell(value)}`,
    ),
  ].join("\n");
}

export function formatRecordAsTsv(
  record: Record<string, unknown> | null | undefined,
): string {
  if (!record) return "";

  const formatValue = (key: string, value: unknown) => {
    if (value == null) return "NA";

    if (key === "dateOfBirth") {
      return formatIsoDate(value) ?? "NA";
    }

    return String(value);
  };

  return [
    "key\tvalue",
    ...Object.entries(record).map(
      ([key, value]) => `${key}\t${formatValue(key, value)}`,
    ),
  ].join("\n");
}

export function formatBodyCompositionMeasurementDelta(
  table: CompactDeltaTable | null,
): string {
  return deltaTableToTsv(table);
}

export function formatBodyMeasurementDelta(
  table: CompactDeltaTable | null,
): string {
  return deltaTableToTsv(table);
}

export function formatLatestBodyMeasurement(
  table: CompactMetricTable | null,
): string {
  return metricTableToTsv(table);
}

export function formatLatestBodyCompositionMeasurement(
  table: CompactMetricTable | null,
): string {
  return metricTableToTsv(table);
}

export function bodyMeasurementDeltasToLlmInput(
  bodyComposition: CompactDeltaTable | null,
  bodyMeasurements: CompactDeltaTable | null,
): string {
  return [
    "[body_composition]",
    deltaTableToTsv(bodyComposition),
    "[body_measurements]",
    deltaTableToTsv(bodyMeasurements),
  ].join("\n");
}
