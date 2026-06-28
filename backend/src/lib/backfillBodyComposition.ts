import { v7 as uuidv7 } from "uuid";
import { calculateDesiredWeightKg } from "../calculations/compositionSummary";
import {
  calculateFfmi,
  calculateFmi,
  calculateProprietaryMetrics,
} from "../calculations/proprietaryMetrics";
import { db } from "../db/db";
import type { DatabaseClient } from "../db/client";
import { calculateAgeYears } from "../utils/calculateAgeYears";

type BackfillOptions = {
  profileId?: string;
};

type MeasurementRow = {
  id: string;
  profileId: string;
  weight: number;
  impedance: number;
  createdAt: string;
  heightCm: number;
  dateOfBirth: string;
  gender: string;
  peopleType: string | null;
  preferredBodyFatPct: number;
};

type ExistingMetricRow = {
  id: string;
};

type BackfillResult = {
  processed: number;
  skipped: number;
  bodyCompositionMetrics: {
    upserted: number;
    deleted: number;
  };
  bodyCompositionMetricsNew: {
    upserted: number;
    deleted: number;
  };
  derivedBodyCompositionMetrics: {
    upserted: number;
    deleted: number;
  };
};

async function listMeasurements(profileId?: string) {
  const profileFilter = profileId !== undefined
    ? "AND measurements.profile_id = ?"
    : "";
  const params = profileId !== undefined ? [profileId] : [];

  return await db
    .prepare(
      `
  SELECT
    measurements.id,
    measurements.profile_id AS profileId,
    measurements.weight,
    measurements.impedance,
    measurements.created_at AS createdAt,
    profile_metadata.height_cm AS heightCm,
    profile_metadata.date_of_birth AS dateOfBirth,
    profile_metadata.gender,
    profile_metadata.people_type AS peopleType,
    profile_metadata.preferred_body_fat_pct AS preferredBodyFatPct
  FROM measurements
  INNER JOIN profile_metadata
    ON profile_metadata.profile_id = measurements.profile_id
  WHERE measurements.weight IS NOT NULL
    AND measurements.impedance IS NOT NULL
    AND profile_metadata.height_cm IS NOT NULL
    AND profile_metadata.date_of_birth IS NOT NULL
    AND profile_metadata.gender IS NOT NULL
    ${profileFilter}
  ORDER BY measurements.profile_id ASC, measurements.created_at ASC, measurements.id ASC
`,
    )
    .all(...params) as MeasurementRow[];
}

async function listExistingRows(table: string, profileId: string) {
  return await db
    .prepare(
      `
  SELECT id
  FROM ${table}
  WHERE profile_id = ?
  ORDER BY created_at ASC, id ASC
`,
    )
    .all(profileId) as ExistingMetricRow[];
}

async function deleteRows(table: string, ids: string[], client: DatabaseClient = db) {
  if (ids.length === 0) {
    return;
  }

  const placeholders = ids.map(() => "?").join(", ");
  await client.prepare(`DELETE FROM ${table} WHERE id IN (${placeholders})`).run(...ids);
}

export async function backfillBodyCompositionFromGrpc({
  profileId,
}: BackfillOptions = {}) {
  const measurements = await listMeasurements(profileId);
  const measurementsByProfile = Map.groupBy(
    measurements,
    (measurement) => measurement.profileId,
  );

  const result: BackfillResult = {
    processed: 0,
    skipped: 0,
    bodyCompositionMetrics: {
      upserted: 0,
      deleted: 0,
    },
    bodyCompositionMetricsNew: {
      upserted: 0,
      deleted: 0,
    },
    derivedBodyCompositionMetrics: {
      upserted: 0,
      deleted: 0,
    },
  };

  for (const [currentProfileId, profileMeasurements] of measurementsByProfile) {
    const bodyRows = await listExistingRows(
      "body_composition_metrics",
      currentProfileId,
    );
    const bodyNewRows = await listExistingRows(
      "body_composition_metrics_new",
      currentProfileId,
    );
    const derivedRows = await listExistingRows(
      "derived_body_composition_metrics",
      currentProfileId,
    );

    for (const [index, measurement] of profileMeasurements.entries()) {
      try {
        const metricsBase = await calculateProprietaryMetrics({
          weight_kg: measurement.weight,
          impedance_ohms: measurement.impedance,
          height_cm: measurement.heightCm,
          age_years: calculateAgeYears(
            measurement.dateOfBirth,
            new Date(measurement.createdAt),
          ),
          sex: measurement.gender,
          people_type: measurement.peopleType,
        });
        const desiredWeightKg = calculateDesiredWeightKg({
          fat_free_mass_kg: metricsBase.fat_free_mass_kg,
          target_body_fat_pct: measurement.preferredBodyFatPct,
        });
        const fmi = calculateFmi(metricsBase.fat_mass_kg, measurement.heightCm);
        const ffmi = calculateFfmi(
          metricsBase.fat_free_mass_kg,
          measurement.heightCm,
        );

        await db.transaction(async (tx) => {
          await tx.prepare(
            `
  INSERT INTO body_composition_metrics (
    id,
    profile_id,
    body_fat_pct,
    muscle_mass_kg,
    water_pct,
    protein_pct,
    fat_free_mass_kg,
    fat_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ON CONFLICT(id) DO UPDATE SET
    body_fat_pct = excluded.body_fat_pct,
    muscle_mass_kg = excluded.muscle_mass_kg,
    water_pct = excluded.water_pct,
    protein_pct = excluded.protein_pct,
    fat_free_mass_kg = excluded.fat_free_mass_kg,
    fat_mass_kg = excluded.fat_mass_kg,
    created_at = excluded.created_at
`,
          ).run(
            bodyRows[index]?.id ?? uuidv7(),
            currentProfileId,
            metricsBase.body_fat_pct,
            metricsBase.muscle_mass_kg,
            metricsBase.water_pct,
            metricsBase.protein_pct,
            metricsBase.fat_free_mass_kg,
            metricsBase.fat_mass_kg,
            measurement.createdAt,
          );

          await tx.prepare(
            `
  INSERT INTO body_composition_metrics_new (
    id,
    profile_id,
    bmi,
    body_fat_pct,
    fat_mass_kg,
    fat_free_mass_kg,
    desired_weight_kg,
    body_score,
    body_age_years,
    water_pct,
    muscle_mass_kg,
    muscle_rate_pct,
    bmr_kcal,
    visceral_fat,
    ideal_weight_kg,
    protein_mass_kg,
    protein_pct,
    skeletal_muscle_kg,
    subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ON CONFLICT(id) DO UPDATE SET
    bmi = excluded.bmi,
    body_fat_pct = excluded.body_fat_pct,
    fat_mass_kg = excluded.fat_mass_kg,
    fat_free_mass_kg = excluded.fat_free_mass_kg,
    desired_weight_kg = excluded.desired_weight_kg,
    body_score = excluded.body_score,
    body_age_years = excluded.body_age_years,
    water_pct = excluded.water_pct,
    muscle_mass_kg = excluded.muscle_mass_kg,
    muscle_rate_pct = excluded.muscle_rate_pct,
    bmr_kcal = excluded.bmr_kcal,
    visceral_fat = excluded.visceral_fat,
    ideal_weight_kg = excluded.ideal_weight_kg,
    protein_mass_kg = excluded.protein_mass_kg,
    protein_pct = excluded.protein_pct,
    skeletal_muscle_kg = excluded.skeletal_muscle_kg,
    subcutaneous_fat_pct = excluded.subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg = excluded.subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg = excluded.predicted_lean_mass_kg,
    created_at = excluded.created_at
`,
          ).run(
            bodyNewRows[index]?.id ?? uuidv7(),
            currentProfileId,
            metricsBase.bmi,
            metricsBase.body_fat_pct,
            metricsBase.fat_mass_kg,
            metricsBase.fat_free_mass_kg,
            desiredWeightKg,
            metricsBase.body_score,
            metricsBase.body_age_years,
            metricsBase.water_pct,
            metricsBase.muscle_mass_kg,
            metricsBase.muscle_rate_pct,
            metricsBase.bmr_kcal,
            metricsBase.visceral_fat,
            metricsBase.ideal_weight_kg,
            metricsBase.protein_mass_kg,
            metricsBase.protein_pct,
            metricsBase.skeletal_muscle_kg,
            metricsBase.subcutaneous_fat_pct,
            metricsBase.subcutaneous_fat_mass_kg,
            metricsBase.predicted_lean_mass_kg,
            measurement.createdAt,
          );

          await tx.prepare(
            `
  INSERT INTO derived_body_composition_metrics (
    id,
    profile_id,
    fmi,
    ffmi,
    created_at
  )
  VALUES (?, ?, ?, ?, ?)
  ON CONFLICT(id) DO UPDATE SET
    fmi = excluded.fmi,
    ffmi = excluded.ffmi,
    created_at = excluded.created_at
`,
          ).run(
            derivedRows[index]?.id ?? uuidv7(),
            currentProfileId,
            fmi,
            ffmi,
            measurement.createdAt,
          );
        });

        result.processed += 1;
        result.bodyCompositionMetrics.upserted += 1;
        result.bodyCompositionMetricsNew.upserted += 1;
        result.derivedBodyCompositionMetrics.upserted += 1;
      } catch (error) {
        result.skipped += 1;
        console.error(
          `Failed to backfill body composition for measurement ${measurement.id}:`,
          error,
        );
      }
    }

    const extraBodyRows = bodyRows
      .slice(profileMeasurements.length)
      .map((row) => row.id);
    const extraBodyNewRows = bodyNewRows
      .slice(profileMeasurements.length)
      .map((row) => row.id);
    const extraDerivedRows = derivedRows
      .slice(profileMeasurements.length)
      .map((row) => row.id);

    await db.transaction(async (tx) => {
      await deleteRows("body_composition_metrics", extraBodyRows, tx);
      await deleteRows("body_composition_metrics_new", extraBodyNewRows, tx);
      await deleteRows("derived_body_composition_metrics", extraDerivedRows, tx);
    });

    result.bodyCompositionMetrics.deleted += extraBodyRows.length;
    result.bodyCompositionMetricsNew.deleted += extraBodyNewRows.length;
    result.derivedBodyCompositionMetrics.deleted += extraDerivedRows.length;
  }

  return result;
}
