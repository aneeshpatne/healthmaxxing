ALTER TABLE profile_insight_report_comments ADD COLUMN profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE;
CREATE INDEX idx_profile_insight_report_comments_profile ON profile_insight_report_comments(profile_id);
