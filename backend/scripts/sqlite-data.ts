export const TABLES = [
  "accounts", "profiles", "profile_metadata", "jobs", "measurements",
  "body_measurements", "body_composition_metrics", "body_composition_metrics_new",
  "derived_body_composition_metrics", "progress_measurements", "workouts",
  "profile_ai_overviews", "profile_effort_scores", "derived_metrics_comments",
  "reports", "report_sections", "observation_fields", "observation_field_remarks",
  "observations", "performance_reports", "performance_report_comments",
  "profile_insight_reports", "profile_insight_report_comments", "fat_reports",
  "fat_report_comments", "muscle_reports", "muscle_report_comments",
] as const;

export const BOOLEAN_COLUMNS: Record<string, Set<string>> = {
  profiles: new Set(["is_primary"]),
  workouts: new Set(["is_indoor"]),
  observation_fields: new Set(["is_trendable"]),
};

export const JSON_COLUMNS: Record<string, Set<string>> = {
  workouts: new Set(["metadata", "raw_payload"]),
  profile_ai_overviews: new Set(["foundation", "momentum", "biggest_lever"]),
  derived_metrics_comments: new Set(["ffmi", "ffmi_vs_fmi", "composition_flow", "composition_trend", "recomp_vector", "excess_fat_gauge", "body_ratios"]),
  profile_insight_reports: new Set(["foundation", "momentum", "biggest_lever"]),
};
