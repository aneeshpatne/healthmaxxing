ALTER TABLE profile_insight_reports
  ADD COLUMN generation_status text NOT NULL DEFAULT 'pending',
  ADD COLUMN generation_error text;

CREATE INDEX idx_profile_insight_reports_generation_status
  ON profile_insight_reports(generation_status);
