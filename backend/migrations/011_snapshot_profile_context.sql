ALTER TABLE body_composition_metrics_new
  ADD COLUMN IF NOT EXISTS profile_context jsonb;
