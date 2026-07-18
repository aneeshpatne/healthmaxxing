ALTER TABLE measurements
  ADD COLUMN IF NOT EXISTS calculation_status text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS calculation_error text;

ALTER TABLE body_composition_metrics_new
  ADD COLUMN IF NOT EXISTS measurement_id uuid REFERENCES measurements(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX idx_body_composition_metrics_new_measurement
  ON body_composition_metrics_new(measurement_id)
  WHERE measurement_id IS NOT NULL;

ALTER TABLE derived_body_composition_metrics
  ADD COLUMN IF NOT EXISTS body_composition_metrics_id uuid
    REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX idx_derived_body_composition_snapshot
  ON derived_body_composition_metrics(body_composition_metrics_id)
  WHERE body_composition_metrics_id IS NOT NULL;
