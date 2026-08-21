ALTER TABLE profile_insight_reports
  ADD COLUMN IF NOT EXISTS schema_version integer NOT NULL DEFAULT 1;

ALTER TABLE profile_ai_report_jsonld
  ADD COLUMN IF NOT EXISTS schema_version integer NOT NULL DEFAULT 1;
