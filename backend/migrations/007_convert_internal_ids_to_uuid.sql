CREATE OR REPLACE FUNCTION migrate_text_to_uuid(value text)
RETURNS uuid
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  normalized text;
BEGIN
  IF value IS NULL THEN
    RETURN NULL;
  END IF;

  normalized := lower(trim(value));

  IF normalized ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN normalized::uuid;
  END IF;

  IF normalized ~ '^[0-9a-f]{32}$' THEN
    RETURN (
      substr(normalized, 1, 8) || '-' ||
      substr(normalized, 9, 4) || '-' ||
      substr(normalized, 13, 4) || '-' ||
      substr(normalized, 17, 4) || '-' ||
      substr(normalized, 21, 12)
    )::uuid;
  END IF;

  RAISE EXCEPTION 'Cannot convert value to uuid: %', value;
END;
$$;

DO $$
DECLARE
  column_record record;
  invalid_count bigint;
  duplicate_count bigint;
BEGIN
  FOR column_record IN
    SELECT *
    FROM (
      VALUES
        ('accounts', 'id', true),
        ('profiles', 'id', true),
        ('profiles', 'account_id', false),
        ('profile_metadata', 'profile_id', true),
        ('jobs', 'id', true),
        ('jobs', 'profile_id', false),
        ('measurements', 'id', true),
        ('measurements', 'profile_id', false),
        ('body_measurements', 'id', true),
        ('body_measurements', 'profile_id', false),
        ('body_composition_metrics', 'id', true),
        ('body_composition_metrics', 'profile_id', false),
        ('body_composition_metrics_new', 'id', true),
        ('body_composition_metrics_new', 'profile_id', false),
        ('derived_body_composition_metrics', 'id', true),
        ('derived_body_composition_metrics', 'profile_id', false),
        ('progress_measurements', 'id', true),
        ('progress_measurements', 'profile_id', false),
        ('workouts', 'id', true),
        ('workouts', 'profile_id', false),
        ('profile_ai_overviews', 'profile_id', true),
        ('profile_effort_scores', 'profile_id', true),
        ('derived_metrics_comments', 'id', true),
        ('derived_metrics_comments', 'profile_id', false),
        ('reports', 'id', true),
        ('reports', 'profile_id', false),
        ('report_sections', 'id', true),
        ('report_sections', 'report_id', false),
        ('observation_fields', 'id', true),
        ('observation_field_remarks', 'id', true),
        ('observation_field_remarks', 'observation_field_id', false),
        ('observations', 'id', true),
        ('observations', 'report_id', false),
        ('observations', 'section_id', false),
        ('observations', 'observation_field_id', false),
        ('performance_reports', 'id', true),
        ('performance_reports', 'profile_id', false),
        ('performance_reports', 'body_composition_metrics_id', false),
        ('performance_report_comments', 'id', true),
        ('performance_report_comments', 'report_id', false),
        ('profile_insight_reports', 'id', true),
        ('profile_insight_reports', 'profile_id', false),
        ('profile_insight_reports', 'body_composition_metrics_id', false),
        ('profile_insight_report_comments', 'id', true),
        ('profile_insight_report_comments', 'report_id', false),
        ('profile_insight_report_comments', 'profile_id', false),
        ('fat_reports', 'id', true),
        ('fat_reports', 'profile_id', false),
        ('fat_reports', 'body_composition_metrics_id', false),
        ('fat_report_comments', 'id', true),
        ('fat_report_comments', 'report_id', false),
        ('muscle_reports', 'id', true),
        ('muscle_reports', 'profile_id', false),
        ('muscle_reports', 'body_composition_metrics_id', false),
        ('muscle_report_comments', 'id', true),
        ('muscle_report_comments', 'report_id', false),
        ('profile_ai_report_jsonld', 'report_id', true),
        ('profile_ai_report_jsonld', 'profile_id', false)
    ) AS columns(table_name, column_name, is_unique)
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = current_schema()
        AND table_name = column_record.table_name
        AND column_name = column_record.column_name
    ) THEN
      CONTINUE;
    END IF;

    EXECUTE format(
      'SELECT COUNT(*) FROM %I WHERE %I IS NOT NULL AND %I::text !~ %L AND %I::text !~ %L',
      column_record.table_name,
      column_record.column_name,
      column_record.column_name,
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      column_record.column_name,
      '^[0-9a-fA-F]{32}$'
    )
    INTO invalid_count;

    IF invalid_count > 0 THEN
      RAISE EXCEPTION 'Cannot convert %.% to uuid; % invalid values found',
        column_record.table_name,
        column_record.column_name,
        invalid_count;
    END IF;

    IF column_record.is_unique THEN
      EXECUTE format(
        'SELECT COUNT(*) FROM (
           SELECT migrate_text_to_uuid(%I::text) AS id
           FROM %I
           WHERE %I IS NOT NULL
           GROUP BY migrate_text_to_uuid(%I::text)
           HAVING COUNT(*) > 1
         ) AS duplicates',
        column_record.column_name,
        column_record.table_name,
        column_record.column_name,
        column_record.column_name
      )
      INTO duplicate_count;

      IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'Cannot convert %.% to uuid; % duplicate normalized ids found',
          column_record.table_name,
          column_record.column_name,
          duplicate_count;
      END IF;
    END IF;
  END LOOP;
END;
$$;

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_account_id_fkey;
ALTER TABLE profile_metadata DROP CONSTRAINT IF EXISTS profile_metadata_profile_id_fkey;
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_profile_id_fkey;
ALTER TABLE measurements DROP CONSTRAINT IF EXISTS measurements_profile_id_fkey;
ALTER TABLE body_measurements DROP CONSTRAINT IF EXISTS body_measurements_profile_id_fkey;
ALTER TABLE body_composition_metrics DROP CONSTRAINT IF EXISTS body_composition_metrics_profile_id_fkey;
ALTER TABLE body_composition_metrics_new DROP CONSTRAINT IF EXISTS body_composition_metrics_new_profile_id_fkey;
ALTER TABLE derived_body_composition_metrics DROP CONSTRAINT IF EXISTS derived_body_composition_metrics_profile_id_fkey;
ALTER TABLE progress_measurements DROP CONSTRAINT IF EXISTS progress_measurements_profile_id_fkey;
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_profile_id_fkey;
ALTER TABLE profile_ai_overviews DROP CONSTRAINT IF EXISTS profile_ai_overviews_profile_id_fkey;
ALTER TABLE profile_effort_scores DROP CONSTRAINT IF EXISTS profile_effort_scores_profile_id_fkey;
ALTER TABLE derived_metrics_comments DROP CONSTRAINT IF EXISTS derived_metrics_comments_profile_id_fkey;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_profile_id_fkey;
ALTER TABLE report_sections DROP CONSTRAINT IF EXISTS report_sections_report_id_fkey;
ALTER TABLE observation_field_remarks DROP CONSTRAINT IF EXISTS observation_field_remarks_observation_field_id_fkey;
ALTER TABLE observations DROP CONSTRAINT IF EXISTS observations_report_id_fkey;
ALTER TABLE observations DROP CONSTRAINT IF EXISTS observations_section_id_fkey;
ALTER TABLE observations DROP CONSTRAINT IF EXISTS observations_observation_field_id_fkey;
ALTER TABLE performance_reports DROP CONSTRAINT IF EXISTS performance_reports_profile_id_fkey;
ALTER TABLE performance_reports DROP CONSTRAINT IF EXISTS performance_reports_body_composition_metrics_id_fkey;
ALTER TABLE performance_report_comments DROP CONSTRAINT IF EXISTS performance_report_comments_report_id_fkey;
ALTER TABLE profile_insight_reports DROP CONSTRAINT IF EXISTS profile_insight_reports_profile_id_fkey;
ALTER TABLE profile_insight_reports DROP CONSTRAINT IF EXISTS profile_insight_reports_body_composition_metrics_id_fkey;
ALTER TABLE profile_insight_report_comments DROP CONSTRAINT IF EXISTS profile_insight_report_comments_report_id_fkey;
ALTER TABLE profile_insight_report_comments DROP CONSTRAINT IF EXISTS profile_insight_report_comments_profile_id_fkey;
ALTER TABLE fat_reports DROP CONSTRAINT IF EXISTS fat_reports_profile_id_fkey;
ALTER TABLE fat_reports DROP CONSTRAINT IF EXISTS fat_reports_body_composition_metrics_id_fkey;
ALTER TABLE fat_report_comments DROP CONSTRAINT IF EXISTS fat_report_comments_report_id_fkey;
ALTER TABLE muscle_reports DROP CONSTRAINT IF EXISTS muscle_reports_profile_id_fkey;
ALTER TABLE muscle_reports DROP CONSTRAINT IF EXISTS muscle_reports_body_composition_metrics_id_fkey;
ALTER TABLE muscle_report_comments DROP CONSTRAINT IF EXISTS muscle_report_comments_report_id_fkey;
ALTER TABLE profile_ai_report_jsonld DROP CONSTRAINT IF EXISTS profile_ai_report_jsonld_report_id_fkey;
ALTER TABLE profile_ai_report_jsonld DROP CONSTRAINT IF EXISTS profile_ai_report_jsonld_profile_id_fkey;

ALTER TABLE accounts ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE profiles ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE profiles ALTER COLUMN account_id TYPE uuid USING migrate_text_to_uuid(account_id::text);
ALTER TABLE profile_metadata ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE jobs ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE jobs ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE measurements ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE measurements ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE body_measurements ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE body_measurements ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE body_composition_metrics ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE body_composition_metrics ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE body_composition_metrics_new ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE body_composition_metrics_new ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE derived_body_composition_metrics ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE derived_body_composition_metrics ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE progress_measurements ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE progress_measurements ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE workouts ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE workouts ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE profile_ai_overviews ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE profile_effort_scores ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE derived_metrics_comments ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE derived_metrics_comments ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE reports ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE reports ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE report_sections ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE report_sections ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE observation_fields ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE observation_field_remarks ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE observation_field_remarks ALTER COLUMN observation_field_id TYPE uuid USING migrate_text_to_uuid(observation_field_id::text);
ALTER TABLE observations ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE observations ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE observations ALTER COLUMN section_id TYPE uuid USING migrate_text_to_uuid(section_id::text);
ALTER TABLE observations ALTER COLUMN observation_field_id TYPE uuid USING migrate_text_to_uuid(observation_field_id::text);
ALTER TABLE performance_reports ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE performance_reports ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE performance_reports ALTER COLUMN body_composition_metrics_id TYPE uuid USING migrate_text_to_uuid(body_composition_metrics_id::text);
ALTER TABLE performance_report_comments ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE performance_report_comments ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE profile_insight_reports ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE profile_insight_reports ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE profile_insight_reports ALTER COLUMN body_composition_metrics_id TYPE uuid USING migrate_text_to_uuid(body_composition_metrics_id::text);
ALTER TABLE profile_insight_report_comments ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE profile_insight_report_comments ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE profile_insight_report_comments ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE fat_reports ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE fat_reports ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE fat_reports ALTER COLUMN body_composition_metrics_id TYPE uuid USING migrate_text_to_uuid(body_composition_metrics_id::text);
ALTER TABLE fat_report_comments ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE fat_report_comments ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE muscle_reports ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE muscle_reports ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);
ALTER TABLE muscle_reports ALTER COLUMN body_composition_metrics_id TYPE uuid USING migrate_text_to_uuid(body_composition_metrics_id::text);
ALTER TABLE muscle_report_comments ALTER COLUMN id TYPE uuid USING migrate_text_to_uuid(id::text);
ALTER TABLE muscle_report_comments ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE profile_ai_report_jsonld ALTER COLUMN report_id TYPE uuid USING migrate_text_to_uuid(report_id::text);
ALTER TABLE profile_ai_report_jsonld ALTER COLUMN profile_id TYPE uuid USING migrate_text_to_uuid(profile_id::text);

ALTER TABLE profiles ADD CONSTRAINT profiles_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id);
ALTER TABLE profile_metadata ADD CONSTRAINT profile_metadata_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE jobs ADD CONSTRAINT jobs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE measurements ADD CONSTRAINT measurements_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE body_measurements ADD CONSTRAINT body_measurements_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE body_composition_metrics ADD CONSTRAINT body_composition_metrics_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE body_composition_metrics_new ADD CONSTRAINT body_composition_metrics_new_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE derived_body_composition_metrics ADD CONSTRAINT derived_body_composition_metrics_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE progress_measurements ADD CONSTRAINT progress_measurements_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);
ALTER TABLE workouts ADD CONSTRAINT workouts_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE profile_ai_overviews ADD CONSTRAINT profile_ai_overviews_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE profile_effort_scores ADD CONSTRAINT profile_effort_scores_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE derived_metrics_comments ADD CONSTRAINT derived_metrics_comments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE reports ADD CONSTRAINT reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE report_sections ADD CONSTRAINT report_sections_report_id_fkey FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE;
ALTER TABLE observation_field_remarks ADD CONSTRAINT observation_field_remarks_observation_field_id_fkey FOREIGN KEY (observation_field_id) REFERENCES observation_fields(id) ON DELETE CASCADE;
ALTER TABLE observations ADD CONSTRAINT observations_report_id_fkey FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE;
ALTER TABLE observations ADD CONSTRAINT observations_section_id_fkey FOREIGN KEY (section_id) REFERENCES report_sections(id) ON DELETE SET NULL;
ALTER TABLE observations ADD CONSTRAINT observations_observation_field_id_fkey FOREIGN KEY (observation_field_id) REFERENCES observation_fields(id) ON DELETE SET NULL;
ALTER TABLE performance_reports ADD CONSTRAINT performance_reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE performance_reports ADD CONSTRAINT performance_reports_body_composition_metrics_id_fkey FOREIGN KEY (body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE;
ALTER TABLE performance_report_comments ADD CONSTRAINT performance_report_comments_report_id_fkey FOREIGN KEY (report_id) REFERENCES performance_reports(id) ON DELETE CASCADE;
ALTER TABLE profile_insight_reports ADD CONSTRAINT profile_insight_reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE profile_insight_reports ADD CONSTRAINT profile_insight_reports_body_composition_metrics_id_fkey FOREIGN KEY (body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE;
ALTER TABLE profile_insight_report_comments ADD CONSTRAINT profile_insight_report_comments_report_id_fkey FOREIGN KEY (report_id) REFERENCES profile_insight_reports(id) ON DELETE CASCADE;
ALTER TABLE profile_insight_report_comments ADD CONSTRAINT profile_insight_report_comments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE fat_reports ADD CONSTRAINT fat_reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE fat_reports ADD CONSTRAINT fat_reports_body_composition_metrics_id_fkey FOREIGN KEY (body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE;
ALTER TABLE fat_report_comments ADD CONSTRAINT fat_report_comments_report_id_fkey FOREIGN KEY (report_id) REFERENCES fat_reports(id) ON DELETE CASCADE;
ALTER TABLE muscle_reports ADD CONSTRAINT muscle_reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE muscle_reports ADD CONSTRAINT muscle_reports_body_composition_metrics_id_fkey FOREIGN KEY (body_composition_metrics_id) REFERENCES body_composition_metrics_new(id) ON DELETE CASCADE;
ALTER TABLE muscle_report_comments ADD CONSTRAINT muscle_report_comments_report_id_fkey FOREIGN KEY (report_id) REFERENCES muscle_reports(id) ON DELETE CASCADE;
ALTER TABLE profile_ai_report_jsonld ADD CONSTRAINT profile_ai_report_jsonld_report_id_fkey FOREIGN KEY (report_id) REFERENCES profile_insight_reports(id) ON DELETE CASCADE;
ALTER TABLE profile_ai_report_jsonld ADD CONSTRAINT profile_ai_report_jsonld_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;

DROP FUNCTION migrate_text_to_uuid(text);
