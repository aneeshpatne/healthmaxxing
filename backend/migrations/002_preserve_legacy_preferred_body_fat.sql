ALTER TABLE body_composition_metrics_new
  ADD COLUMN preferred_body_fat_pct double precision NOT NULL DEFAULT 18;
