import { backfillBodyCompositionFromGrpc } from "../src/lib/backfillBodyComposition";
import { sql } from "../src/db/client";

async function updatePerformanceReports() {
  const result = await sql.unsafe(`
    UPDATE performance_reports
    SET
      fmi = CASE
        WHEN pm.height_cm IS NULL OR pm.height_cm <= 0 THEN NULL
        ELSE ROUND((metrics.fat_mass_kg / ((pm.height_cm / 100.0) * (pm.height_cm / 100.0)))::numeric, 2)
      END,
      ffmi = CASE
        WHEN pm.height_cm IS NULL OR pm.height_cm <= 0 THEN NULL
        ELSE ROUND((metrics.fat_free_mass_kg / ((pm.height_cm / 100.0) * (pm.height_cm / 100.0)))::numeric, 2)
      END,
      updated_at = CURRENT_TIMESTAMP
    FROM body_composition_metrics_new AS metrics
    LEFT JOIN profile_metadata AS pm ON pm.profile_id = metrics.profile_id
    WHERE metrics.id = performance_reports.body_composition_metrics_id
  `);
  console.log(`Updated ${result.count ?? 0} performance_reports`);
}

async function updateFatReports() {
  const result = await sql.unsafe(`
    UPDATE fat_reports
    SET
      fat_percent = latest.body_fat_pct,
      fat_mass_kg = latest.fat_mass_kg,
      visceral_fat_mass_kg = ROUND((latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg)::numeric, 2),
      visceral_fat_percent = ROUND((latest.body_fat_pct - latest.subcutaneous_fat_pct)::numeric, 2),
      subcutaneous_fat_mass_kg = latest.subcutaneous_fat_mass_kg,
      subcutaneous_fat_ratio = CASE
        WHEN latest.fat_mass_kg <= 0 THEN 0
        ELSE ROUND((latest.subcutaneous_fat_mass_kg / latest.fat_mass_kg)::numeric, 2)
      END,
      visceral_fat_delta_30d_kg = ROUND(
        ((latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg) -
         (base.fat_mass_kg - base.subcutaneous_fat_mass_kg))::numeric,
        2
      ),
      subcutaneous_fat_delta_30d_kg = ROUND(
        (latest.subcutaneous_fat_mass_kg - base.subcutaneous_fat_mass_kg)::numeric,
        2
      ),
      updated_at = CURRENT_TIMESTAMP
    FROM body_composition_metrics_new AS latest
    INNER JOIN LATERAL (
      SELECT oldest.fat_mass_kg, oldest.subcutaneous_fat_mass_kg
      FROM body_composition_metrics_new AS oldest
      WHERE oldest.profile_id = latest.profile_id
        AND oldest.created_at >= latest.created_at - INTERVAL '30 days'
        AND oldest.created_at <= latest.created_at
      ORDER BY oldest.created_at ASC
      LIMIT 1
    ) AS base ON TRUE
    WHERE latest.id = fat_reports.body_composition_metrics_id
  `);
  console.log(`Updated ${result.count ?? 0} fat_reports`);
}

async function updateMuscleReports() {
  const result = await sql.unsafe(`
    UPDATE muscle_reports
    SET
      total_muscle_kg = metrics.muscle_mass_kg,
      bone_mass_kg = ROUND(GREATEST(metrics.fat_free_mass_kg - metrics.muscle_mass_kg, 0)::numeric, 2),
      muscle_ratio = metrics.muscle_rate_pct,
      skeletal_muscle_mass_kg = metrics.skeletal_muscle_kg,
      skeletal_muscle_ratio = CASE
        WHEN metrics.fat_mass_kg + metrics.fat_free_mass_kg <= 0 THEN 0
        ELSE ROUND((metrics.skeletal_muscle_kg / (metrics.fat_mass_kg + metrics.fat_free_mass_kg) * 100)::numeric, 2)
      END,
      updated_at = CURRENT_TIMESTAMP
    FROM body_composition_metrics_new AS metrics
    WHERE metrics.id = muscle_reports.body_composition_metrics_id
  `);
  console.log(`Updated ${result.count ?? 0} muscle_reports`);
}

async function main() {
  console.log("Starting metrics recalculation...");

  console.log("\n--- Phase 1: Backfilling body composition metrics via gRPC ---");
  const result = await backfillBodyCompositionFromGrpc();
  console.log("Backfill result:", JSON.stringify(result, null, 2));

  console.log("\n--- Phase 2: Updating snapshot report metrics ---");
  await updatePerformanceReports();
  await updateFatReports();
  await updateMuscleReports();

  console.log("\nDone. All metrics recalculated.");
  await sql.close({ timeout: 5 });
  process.exit(0);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
