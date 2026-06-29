CREATE TABLE profile_ai_report_jsonld (
  report_id text PRIMARY KEY REFERENCES profile_insight_reports(id) ON DELETE CASCADE,
  profile_id text NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_on timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data jsonb NOT NULL
);

CREATE INDEX idx_profile_ai_report_jsonld_profile_created
  ON profile_ai_report_jsonld(profile_id, created_on DESC);
