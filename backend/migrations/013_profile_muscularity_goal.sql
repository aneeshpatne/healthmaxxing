ALTER TABLE profile_metadata
  ADD COLUMN IF NOT EXISTS muscularity_goal text NOT NULL DEFAULT 'maintain';

ALTER TABLE profile_metadata
  DROP CONSTRAINT IF EXISTS profile_metadata_muscularity_goal_check;

ALTER TABLE profile_metadata
  ADD CONSTRAINT profile_metadata_muscularity_goal_check
  CHECK (muscularity_goal IN ('maintain', 'athletic', 'muscular', 'very_muscular'));

ALTER TABLE profile_metadata
  ALTER COLUMN muscularity_goal SET DEFAULT 'athletic';
