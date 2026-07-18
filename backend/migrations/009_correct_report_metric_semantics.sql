ALTER TABLE fat_reports
  RENAME COLUMN visceral_fat_delta_30d_kg TO visceral_fat_index_delta_30d;

ALTER TABLE fat_reports
  RENAME COLUMN visceral_fat_mass_kg TO visceral_fat_index;

UPDATE fat_reports AS report
SET
  visceral_fat_index = current_metrics.visceral_fat,
  visceral_fat_index_delta_30d = current_metrics.visceral_fat - COALESCE(
    (
      SELECT baseline.visceral_fat
      FROM body_composition_metrics_new AS baseline
      WHERE baseline.profile_id = current_metrics.profile_id
        AND baseline.created_at >= current_metrics.created_at - INTERVAL '30 days'
        AND baseline.created_at <= current_metrics.created_at
      ORDER BY baseline.created_at ASC
      LIMIT 1
    ),
    current_metrics.visceral_fat
  )
FROM body_composition_metrics_new AS current_metrics
WHERE current_metrics.id = report.body_composition_metrics_id;

ALTER TABLE fat_reports
  DROP COLUMN visceral_fat_percent;

ALTER TABLE muscle_reports
  RENAME COLUMN bone_mass_kg TO lean_non_muscle_mass_kg;
