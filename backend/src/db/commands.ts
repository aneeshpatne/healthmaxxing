import { v7 as uuidv7 } from "uuid";
import { BODY_COMPOSITION_METRICS_NEW_FACTORS, db } from "./db";
import {
  calculateCompositionSummary,
  type CompositionSummary,
} from "../calculations/compositionSummary";
import {
  calculateFormaScore,
  type FormaScore,
} from "../calculations/formaScore";
import {
  calculateFfmi,
  calculateFmi,
  type ProprietaryBodyCompositionMetrics,
} from "../calculations/proprietaryMetrics";

type BodyCompositionMetricsNewRow = ProprietaryBodyCompositionMetrics & {
  desired_weight_kg: number;
};

type BodyCompositionMetricsNewWithCreatedAtRow = BodyCompositionMetricsNewRow & {
  createdAt: string;
};

export type JobId = string;
export type AccountId = string;
export type ProfileId = string;

export type UserWeight = {
  id: string;
  weight: number | null;
  createdAt: string;
};

export type BodyMeasurement = {
  id: string;
  neckCm: number | null;
  shoulderCm: number | null;
  chestCm: number | null;
  stomachCm: number | null;
  waistCm: number | null;
  calfCm: number | null;
  thighCm: number | null;
  bicepCm: number | null;
  forearmCm: number | null;
  createdAt: string;
};

export type BodyCompositionMetrics = {
  id?: string;
  profileId: ProfileId;
  bodyFatPct: number;
  muscleMassKg: number;
  waterPct: number;
  proteinPct: number;
  fatFreeMassKg: number;
  fatMassKg: number;
};

export type CalculatedBodyCompositionMetrics = {
  body_fat_pct: number;
  muscle_mass_kg: number;
  water_pct: number;
  protein_pct: number;
  fat_free_mass_kg: number;
  fat_mass_kg: number;
};

export type DerivedBodyCompositionMetrics = {
  fmi: number;
  ffmi: number;
};

export const TREND_COLUMNS = BODY_COMPOSITION_METRICS_NEW_FACTORS;

export const PERIODS = {
  "7d": "-7 days",
  "30d": "-30 days",
  all: null,
} as const;

export type BodyCompositionTrendMetric = (typeof TREND_COLUMNS)[number];
export type BodyCompositionMetricFactor = BodyCompositionTrendMetric;
export type BodyCompositionTrendPeriod = keyof typeof PERIODS;

export type BodyCompositionTrendPoint = {
  profileId: ProfileId;
  createdAt: string;
  value: number;
};

export type WeightTrendPoint = {
  weight: number;
  createdAt: string;
};

export type WeightSummary = {
  currentWeight: number | null;
  goalWeight: number | null;
  averageWeight30d: number | null;
  lowestWeight30d: number | null;
  last30DaysWeightTrend: WeightTrendPoint[];
};

export type LatestBodyCompositionSnapshot = {
  createdAt: string;
  metrics: BodyCompositionMetricsNewRow;
  compositionSummary: CompositionSummary;
};

export type CompositionTrendMassPoint = {
  createdAt: string;
  leanMassKg: number;
  fatMassKg: number;
};

export type BodyRatios = {
  waistHeight: number | null;
  shoulderWaist: number | null;
  chestWaist: number | null;
  bicepForearm: number | null;
  thighCalf: number | null;
  neckCalf: number | null;
};

export type ProfilePerformance = {
  ffmi: number | null;
  ffmiVsFmi: {
    ffmi: number | null;
    fmi: number | null;
  };
  bodyComposition: {
    leanMassKg: number | null;
    fatMassKg: number | null;
  };
  compositionTrends: {
    leanMass30Days: Array<{ createdAt: string; value: number }>;
    fatMass30Days: Array<{ createdAt: string; value: number }>;
  };
  weightPair: {
    target: {
      leanMassKg: number | null;
      fatMassKg: number | null;
    };
    current: {
      leanMassKg: number | null;
      fatMassKg: number | null;
    };
    initial: {
      leanMassKg: number | null;
      fatMassKg: number | null;
    };
  };
  excessFatGauge: {
    totalFatKg: number | null;
    targetFatKg: number | null;
    excessFatKg: number | null;
  };
  bodyMeasurements: BodyMeasurement[];
  lastBodyRatios: BodyRatios;
  comments: Omit<DerivedMetricsComments, "profileId" | "modelName"> | null;
};

export type DerivedMetricComment = {
  comment: string;
};

export type BodyRatioComment = {
  remark: string;
  comment: string;
};

export type BodyRatioComments = {
  waistHeight: BodyRatioComment;
  shoulderWaist: BodyRatioComment;
  chestWaist: BodyRatioComment;
  bicepForearm: BodyRatioComment;
  thighCalf: BodyRatioComment;
  neckCalf: BodyRatioComment;
};

export type DerivedMetricsComments = {
  profileId: ProfileId;
  ffmi: DerivedMetricComment;
  ffmiVsFmi: DerivedMetricComment;
  compositionFlow: DerivedMetricComment;
  compositionTrend: DerivedMetricComment;
  recompVector: DerivedMetricComment;
  excessFatGauge: DerivedMetricComment;
  bodyRatios: BodyRatioComments;
  modelName?: string | null;
};

export type Users = {
  id: string;
  accountId: string;
  name: string | null;
  mailAddress: string | null;
  isPrimary: boolean;
  heightCm: number | null;
  dateOfBirth: string | null;
  peopleType: "standard" | "athlete" | null;
  gender: "male" | "female" | null;
  profileImage: string | null;
  preferredBodyFatPct: number;
  createdAt: string;
};

type UserRow = Omit<Users, "isPrimary"> & {
  isPrimary: number;
};

export type RegisterUserInput = {
  mailAddress: string;
};

export type RegisterProfileInput = {
  accountId: AccountId;
  name: string;
  isPrimary?: boolean;
};

export type RegisterProfileMetadataInput = {
  profileId: ProfileId;
  dateOfBirth: string;
  gender: "male" | "female";
  heightCm: number;
  peopleType: "standard" | "athlete";
  profileImage?: string | null;
  preferredBodyFatPct?: number;
};

export type BodyMeasurementInput = {
  neckCm?: number | null;
  shoulderCm?: number | null;
  chestCm?: number | null;
  stomachCm?: number | null;
  waistCm?: number | null;
  calfCm?: number | null;
  thighCm?: number | null;
  bicepCm?: number | null;
  forearmCm?: number | null;
};

export type BodyMeasurementCreateResult = {
  id: string;
  createdAt: string;
};

export type ProgressMeasurement = {
  id?: string;
  profile_id: string;
  name: "bicep" | "chest" | "thigh" | "forearm" | "calf" | "shoulder";
  value: number;
  unit: string;
  notes: "postWorkOut" | "preWorkOut";
};

export type ProfileAiAnalysisBlock = {
  headline: string;
  supporting_description: string;
  actionable_insight: string;
  factors?: BodyCompositionMetricFactor[];
};

export type ProfileAiOverview = {
  profileId: ProfileId;
  overviewTitle: string;
  overviewRemarks: string;
  foundation: ProfileAiAnalysisBlock;
  momentum: ProfileAiAnalysisBlock;
  biggestLever: ProfileAiAnalysisBlock;
  physiqueArchetype: string;
  modelName?: string | null;
  updatedAt?: string;
};

type ProfileAiOverviewRow = {
  profileId: ProfileId;
  overviewTitle: string;
  overviewRemarks: string;
  foundation: string;
  momentum: string;
  biggestLever: string;
  physiqueArchetype: string;
  modelName: string | null;
  updatedAt: string;
};

function parseProfileAiAnalysisBlock(raw: string): ProfileAiAnalysisBlock {
  return JSON.parse(raw) as ProfileAiAnalysisBlock;
}

function parseProfileAiMomentumBlock(raw: string): ProfileAiAnalysisBlock {
  const block = JSON.parse(raw) as ProfileAiAnalysisBlock;

  return {
    ...block,
    factors: Array.isArray(block.factors) ? block.factors : [],
  };
}

export type profile = {
  id: string;
  accountId: string;
  name: string;
  mailAddress: string;
  isPrimary: boolean;
  heightCm: number;
  dateOfBirth: string;
  peopleType: "standard" | "athlete";
  gender: "male" | "female";
  profileImage: string | null;
  preferredBodyFatPct: number;
};

type ProfileRow = Omit<profile, "isPrimary"> & {
  isPrimary: number;
};

export function jobExists(jobId: JobId): boolean {
  const job = db
    .prepare(
      `
  SELECT 1
  FROM jobs
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(jobId);

  return job !== null;
}

export function profileExists(profileId: ProfileId): boolean {
  const profile = db
    .prepare(
      `
  SELECT 1
  FROM profiles
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(profileId);

  return profile !== null;
}

export function accountExists(accountId: AccountId): boolean {
  const account = db
    .prepare(
      `
  SELECT 1
  FROM accounts
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(accountId);

  return account !== null;
}

export function getProfileIdByJobId(jobId: JobId): ProfileId | null {
  const job = db
    .prepare(
      `
  SELECT profile_id
  FROM jobs
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(jobId) as { profile_id: ProfileId } | null;

  return job?.profile_id ?? null;
}

export function initJob(jobId: JobId, profileId: ProfileId): void {
  db.prepare(
    `
  INSERT INTO jobs (
    id,
    profile_id,
    status,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
`,
  ).run(jobId, profileId, "created");
}
export function addMeasurement(
  profileId: ProfileId,
  weight: number,
  heartbeat: number,
  impedance: number,
): string {
  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO measurements (
    id,
    profile_id,
    weight,
    heart_rate,
    impedance,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(id, profileId, weight, heartbeat, impedance);

  return id;
}
export function registerUser({ mailAddress }: RegisterUserInput): AccountId {
  const accountId: AccountId = uuidv7();

  db.prepare(
    `
  INSERT INTO accounts (
    id,
    mail_address,
    created_at
  )
  VALUES (?, ?, CURRENT_TIMESTAMP)
`,
  ).run(accountId, mailAddress);

  return accountId;
}

export function registerProfile({
  accountId,
  name,
  isPrimary = false,
}: RegisterProfileInput): ProfileId {
  const profileId: ProfileId = uuidv7();

  db.prepare(
    `
  INSERT INTO profiles (
    id,
    account_id,
    name,
    is_primary,
    created_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(profileId, accountId, name, isPrimary ? 1 : 0);

  return profileId;
}

export function registerProfileMetadata({
  profileId,
  dateOfBirth,
  gender,
  heightCm,
  peopleType,
  profileImage = null,
  preferredBodyFatPct = 18,
}: RegisterProfileMetadataInput): void {
  db.prepare(
    `
  INSERT INTO profile_metadata (
    profile_id,
    height_cm,
    date_of_birth,
    people_type,
    gender,
    profile_image,
    preferred_body_fat_pct,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  ON CONFLICT(profile_id) DO UPDATE SET
    height_cm = excluded.height_cm,
    date_of_birth = excluded.date_of_birth,
    people_type = excluded.people_type,
    gender = excluded.gender,
    profile_image = excluded.profile_image,
    preferred_body_fat_pct = excluded.preferred_body_fat_pct,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(
    profileId,
    heightCm,
    dateOfBirth,
    peopleType,
    gender,
    profileImage,
    preferredBodyFatPct,
  );
}

export function listUserWeight(profileId: ProfileId): UserWeight[] {
  return db
    .prepare(
      `
  SELECT
    id,
    weight,
    created_at AS createdAt
  FROM measurements
  WHERE profile_id = ?
  ORDER BY created_at DESC
`,
    )
    .all(profileId) as UserWeight[];
}

export function addBodyMeasurement(
  profileId: ProfileId,
  {
    neckCm = null,
    shoulderCm = null,
    chestCm = null,
    stomachCm = null,
    waistCm = null,
    calfCm = null,
    thighCm = null,
    bicepCm = null,
    forearmCm = null,
  }: BodyMeasurementInput,
): BodyMeasurementCreateResult {
  if (
    neckCm === null &&
    shoulderCm === null &&
    chestCm === null &&
    stomachCm === null &&
    waistCm === null &&
    calfCm === null &&
    thighCm === null &&
    bicepCm === null &&
    forearmCm === null
  ) {
    throw new Error("At least one body measurement is required");
  }

  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO body_measurements (
    id,
    profile_id,
    neck_cm,
    shoulder_cm,
    chest_cm,
    stomach_cm,
    waist_cm,
    calf_cm,
    thigh_cm,
    bicep_cm,
    forearm_cm,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    profileId,
    neckCm,
    shoulderCm,
    chestCm,
    stomachCm,
    waistCm,
    calfCm,
    thighCm,
    bicepCm,
    forearmCm,
  );

  const created = db
    .prepare(
      `
  SELECT created_at AS createdAt
  FROM body_measurements
  WHERE id = ?
  LIMIT 1
`,
    )
    .get(id) as { createdAt: string } | null;

  return {
    id,
    createdAt: created?.createdAt ?? new Date().toISOString(),
  };
}

export function listUserBodyMeasurements(
  profileId: ProfileId,
): BodyMeasurement[] {
  return db
    .prepare(
      `
  SELECT
    id,
    neck_cm AS neckCm,
    shoulder_cm AS shoulderCm,
    chest_cm AS chestCm,
    stomach_cm AS stomachCm,
    waist_cm AS waistCm,
    calf_cm AS calfCm,
    thigh_cm AS thighCm,
    bicep_cm AS bicepCm,
    forearm_cm AS forearmCm,
    created_at AS createdAt
  FROM body_measurements
  WHERE profile_id = ?
  ORDER BY created_at DESC
`,
    )
    .all(profileId) as BodyMeasurement[];
}

export function addBodyCompositionMetrics(
  metrics: BodyCompositionMetrics,
): string {
  const id = metrics.id ?? uuidv7();

  db.prepare(
    `
  INSERT INTO body_composition_metrics (
    id,
    profile_id,
    body_fat_pct,
    muscle_mass_kg,
    water_pct,
    protein_pct,
    fat_free_mass_kg,
    fat_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    metrics.profileId,
    metrics.bodyFatPct,
    metrics.muscleMassKg,
    metrics.waterPct,
    metrics.proteinPct,
    metrics.fatFreeMassKg,
    metrics.fatMassKg,
  );

  return id;
}

export function saveBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: CalculatedBodyCompositionMetrics,
): string {
  return addBodyCompositionMetrics({
    profileId,
    bodyFatPct: metrics.body_fat_pct,
    muscleMassKg: metrics.muscle_mass_kg,
    waterPct: metrics.water_pct,
    proteinPct: metrics.protein_pct,
    fatFreeMassKg: metrics.fat_free_mass_kg,
    fatMassKg: metrics.fat_mass_kg,
  });
}

export function addProprietaryBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: BodyCompositionMetricsNewRow,
): string {
  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO body_composition_metrics_new (
    id,
    profile_id,
    bmi,
    body_fat_pct,
    fat_mass_kg,
    fat_free_mass_kg,
    desired_weight_kg,
    body_score,
    body_age_years,
    water_pct,
    muscle_mass_kg,
    muscle_rate_pct,
    bmr_kcal,
    visceral_fat,
    ideal_weight_kg,
    protein_mass_kg,
    protein_pct,
    skeletal_muscle_kg,
    subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    profileId,
    metrics.bmi,
    metrics.body_fat_pct,
    metrics.fat_mass_kg,
    metrics.fat_free_mass_kg,
    metrics.desired_weight_kg,
    metrics.body_score,
    metrics.body_age_years,
    metrics.water_pct,
    metrics.muscle_mass_kg,
    metrics.muscle_rate_pct,
    metrics.bmr_kcal,
    metrics.visceral_fat,
    metrics.ideal_weight_kg,
    metrics.protein_mass_kg,
    metrics.protein_pct,
    metrics.skeletal_muscle_kg,
    metrics.subcutaneous_fat_pct,
    metrics.subcutaneous_fat_mass_kg,
    metrics.predicted_lean_mass_kg,
  );

  return id;
}

export function addDerivedBodyComposition(
  profileId: ProfileId,
  metrics: DerivedBodyCompositionMetrics,
): string {
  const id = uuidv7();

  db.prepare(
    `
  INSERT INTO derived_body_composition_metrics (
    id,
    profile_id,
    fmi,
    ffmi,
    created_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(id, profileId, metrics.fmi, metrics.ffmi);

  return id;
}

export function isBodyCompositionTrendMetric(
  metric: string,
): metric is BodyCompositionTrendMetric {
  return TREND_COLUMNS.includes(metric as BodyCompositionTrendMetric);
}

export function isBodyCompositionTrendPeriod(
  period: string,
): period is BodyCompositionTrendPeriod {
  return Object.hasOwn(PERIODS, period);
}

export function listBodyCompositionTrends({
  metric,
  period,
  profileId,
}: {
  metric: BodyCompositionTrendMetric;
  period: BodyCompositionTrendPeriod;
  profileId?: ProfileId;
}): BodyCompositionTrendPoint[] {
  const range = PERIODS[period];
  const profileFilter = profileId === undefined ? "" : "AND profile_id = ?";
  const rangeFilter = range === null ? "" : "AND created_at >= datetime('now', ?)";
  const params = [
    ...(profileId === undefined ? [] : [profileId]),
    ...(range === null ? [] : [range]),
  ];

  return db
    .prepare(
      `
  SELECT
    profile_id AS profileId,
    created_at AS createdAt,
    ${metric} AS value
  FROM body_composition_metrics_new
  WHERE 1 = 1
    ${profileFilter}
    ${rangeFilter}
  ORDER BY created_at ASC
`,
    )
    .all(...params) as BodyCompositionTrendPoint[];
}

export function addProgressMeasurement(
  measurement: ProgressMeasurement,
): string {
  const id = measurement.id ?? uuidv7();

  db.prepare(
    `
  INSERT INTO progress_measurements (
    id,
    profile_id,
    name,
    value,
    unit,
    notes,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`,
  ).run(
    id,
    measurement.profile_id,
    measurement.name,
    measurement.value,
    measurement.unit,
    measurement.notes,
  );

  return id;
}

export function upsertProfileAiOverview({
  profileId,
  overviewTitle,
  overviewRemarks,
  foundation,
  momentum,
  biggestLever,
  physiqueArchetype,
  modelName = null,
}: ProfileAiOverview): void {
  db.prepare(
    `
  INSERT INTO profile_ai_overviews (
    profile_id,
    overview_title,
    overview_remarks,
    foundation,
    momentum,
    biggest_lever,
    physique_archetype,
    model_name,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  ON CONFLICT(profile_id) DO UPDATE SET
    overview_title = excluded.overview_title,
    overview_remarks = excluded.overview_remarks,
    foundation = excluded.foundation,
    momentum = excluded.momentum,
    biggest_lever = excluded.biggest_lever,
    physique_archetype = excluded.physique_archetype,
    model_name = excluded.model_name,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(
    profileId,
    overviewTitle,
    overviewRemarks,
    JSON.stringify(foundation),
    JSON.stringify(momentum),
    JSON.stringify(biggestLever),
    physiqueArchetype,
    modelName,
  );
}

export function getProfileAiOverview(
  profileId: ProfileId,
): ProfileAiOverview | null {
  const row = db
    .prepare(
      `
  SELECT
    profile_id AS profileId,
    overview_title AS overviewTitle,
    overview_remarks AS overviewRemarks,
    foundation,
    momentum,
    biggest_lever AS biggestLever,
    physique_archetype AS physiqueArchetype,
    model_name AS modelName,
    updated_at AS updatedAt
  FROM profile_ai_overviews
  WHERE profile_id = ?
  LIMIT 1
`,
    )
    .get(profileId) as ProfileAiOverviewRow | null;

  if (!row) {
    return null;
  }

  return {
    ...row,
    foundation: parseProfileAiAnalysisBlock(row.foundation),
    momentum: parseProfileAiMomentumBlock(row.momentum),
    biggestLever: parseProfileAiAnalysisBlock(row.biggestLever),
  };
}

export type ProfileEffortScore = {
  profileId: ProfileId;
  score: number;
  remark: string;
  modelName?: string | null;
  updatedAt?: string;
};

export function upsertProfileEffortScore({
  profileId,
  score,
  remark,
  modelName = null,
}: ProfileEffortScore): void {
  db.prepare(
    `
  INSERT INTO profile_effort_scores (
    profile_id,
    score,
    remark,
    model_name,
    updated_at
  )
  VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
  ON CONFLICT(profile_id) DO UPDATE SET
    score = excluded.score,
    remark = excluded.remark,
    model_name = excluded.model_name,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(profileId, score, remark, modelName);
}

export function upsertDerivedMetricsComments({
  profileId,
  ffmi,
  ffmiVsFmi,
  compositionFlow,
  compositionTrend,
  recompVector,
  excessFatGauge,
  bodyRatios,
  modelName = null,
}: DerivedMetricsComments): void {
  db.prepare(
    `
  INSERT INTO derived_metrics_comments (
    id,
    profile_id,
    ffmi,
    ffmi_vs_fmi,
    composition_flow,
    composition_trend,
    recomp_vector,
    excess_fat_gauge,
    body_ratios,
    model_name,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  ON CONFLICT(profile_id) DO UPDATE SET
    ffmi = excluded.ffmi,
    ffmi_vs_fmi = excluded.ffmi_vs_fmi,
    composition_flow = excluded.composition_flow,
    composition_trend = excluded.composition_trend,
    recomp_vector = excluded.recomp_vector,
    excess_fat_gauge = excluded.excess_fat_gauge,
    body_ratios = excluded.body_ratios,
    model_name = excluded.model_name,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(
    uuidv7(),
    profileId,
    JSON.stringify(ffmi),
    JSON.stringify(ffmiVsFmi),
    JSON.stringify(compositionFlow),
    JSON.stringify(compositionTrend),
    JSON.stringify(recompVector),
    JSON.stringify(excessFatGauge),
    JSON.stringify(bodyRatios),
    modelName,
  );
}

export function getProfileEffortScore(
  profileId: ProfileId,
): ProfileEffortScore | null {
  return db
    .prepare(
      `
  SELECT
    profile_id AS profileId,
    score,
    remark,
    model_name AS modelName,
    updated_at AS updatedAt
  FROM profile_effort_scores
  WHERE profile_id = ?
  LIMIT 1
`,
    )
    .get(profileId) as ProfileEffortScore | null;
}

export function getProfileFormaScore(profileId: ProfileId): FormaScore | null {
  const metrics = db
    .prepare(
      `
  SELECT
    bmi,
    body_fat_pct,
    fat_mass_kg,
    fat_free_mass_kg,
    desired_weight_kg,
    body_score,
    body_age_years,
    water_pct,
    muscle_mass_kg,
    muscle_rate_pct,
    bmr_kcal,
    visceral_fat,
    ideal_weight_kg,
    protein_mass_kg,
    protein_pct,
    skeletal_muscle_kg,
    subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as BodyCompositionMetricsNewRow | null;

  if (!metrics) {
    return null;
  }

  return calculateFormaScore(metrics);
}

export function getLatestBodyCompositionSnapshot(
  profileId: ProfileId,
): LatestBodyCompositionSnapshot | null {
  const row = db
    .prepare(
      `
  SELECT
    bmi,
    body_fat_pct,
    fat_mass_kg,
    fat_free_mass_kg,
    desired_weight_kg,
    body_score,
    body_age_years,
    water_pct,
    muscle_mass_kg,
    muscle_rate_pct,
    bmr_kcal,
    visceral_fat,
    ideal_weight_kg,
    protein_mass_kg,
    protein_pct,
    skeletal_muscle_kg,
    subcutaneous_fat_pct,
    subcutaneous_fat_mass_kg,
    predicted_lean_mass_kg,
    created_at AS createdAt
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as BodyCompositionMetricsNewWithCreatedAtRow | null;

  if (!row) {
    return null;
  }

  const { createdAt, ...metrics } = row;

  return {
    createdAt,
    metrics,
    compositionSummary: calculateCompositionSummary(metrics),
  };
}

export function getLatestUserBodyMeasurement(
  profileId: ProfileId,
): BodyMeasurement | null {
  return db
    .prepare(
      `
  SELECT
    id,
    neck_cm AS neckCm,
    shoulder_cm AS shoulderCm,
    chest_cm AS chestCm,
    stomach_cm AS stomachCm,
    waist_cm AS waistCm,
    calf_cm AS calfCm,
    thigh_cm AS thighCm,
    bicep_cm AS bicepCm,
    forearm_cm AS forearmCm,
    created_at AS createdAt
  FROM body_measurements
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as BodyMeasurement | null;
}

function roundMetric(value: number, digits: number): number {
  return Number(value.toFixed(digits));
}

function ratioOrNull(
  numerator: number | null,
  denominator: number | null,
): number | null {
  if (
    numerator === null ||
    denominator === null ||
    !Number.isFinite(numerator) ||
    !Number.isFinite(denominator) ||
    denominator <= 0
  ) {
    return null;
  }

  return roundMetric(numerator / denominator, 2);
}

function normalizeTrend(
  points: Array<{ createdAt: string; value: number }>,
): Array<{ createdAt: string; value: number }> {
  const baseline = points[0]?.value;

  if (baseline === undefined || !Number.isFinite(baseline)) {
    return [];
  }

  return points.map((point) => ({
    createdAt: point.createdAt,
    value: roundMetric(point.value - baseline, 2),
  }));
}

type DerivedMetricsCommentsRow = {
  ffmi: string;
  ffmiVsFmi: string;
  compositionFlow: string;
  compositionTrend: string;
  recompVector: string;
  excessFatGauge: string;
  bodyRatios: string;
};

function parseJsonField<T>(raw: string): T | null {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

function normalizeDerivedComment(comment: unknown): DerivedMetricComment | null {
  if (comment === null || typeof comment !== "object") {
    return null;
  }

  const record = comment as Record<string, unknown>;

  if (typeof record.comment !== "string") {
    return null;
  }

  return {
    comment: record.comment,
  };
}

function normalizeRatioComment(comment: unknown): BodyRatioComment | null {
  if (comment === null || typeof comment !== "object") {
    return null;
  }

  const record = comment as Record<string, unknown>;

  if (typeof record.remark !== "string" || typeof record.comment !== "string") {
    return null;
  }

  return {
    remark: record.remark,
    comment: record.comment,
  };
}

function normalizeBodyRatioComments(
  comments: unknown,
): BodyRatioComments | null {
  if (comments === null || typeof comments !== "object") {
    return null;
  }

  const record = comments as Record<string, unknown>;
  const waistHeight = normalizeRatioComment(record.waistHeight);
  const shoulderWaist = normalizeRatioComment(record.shoulderWaist);
  const chestWaist = normalizeRatioComment(record.chestWaist);
  const bicepForearm = normalizeRatioComment(record.bicepForearm);
  const thighCalf = normalizeRatioComment(record.thighCalf);
  const neckCalf = normalizeRatioComment(record.neckCalf);

  if (
    waistHeight === null ||
    shoulderWaist === null ||
    chestWaist === null ||
    bicepForearm === null ||
    thighCalf === null ||
    neckCalf === null
  ) {
    return null;
  }

  return {
    waistHeight,
    shoulderWaist,
    chestWaist,
    bicepForearm,
    thighCalf,
    neckCalf,
  };
}

function parseDerivedMetricsComments(
  row: DerivedMetricsCommentsRow | null,
): Omit<DerivedMetricsComments, "profileId" | "modelName"> | null {
  if (row === null) {
    return null;
  }

  const ffmi = normalizeDerivedComment(parseJsonField<unknown>(row.ffmi));
  const ffmiVsFmi = normalizeDerivedComment(
    parseJsonField<unknown>(row.ffmiVsFmi),
  );
  const compositionFlow = normalizeDerivedComment(
    parseJsonField<unknown>(row.compositionFlow),
  );
  const compositionTrend = normalizeDerivedComment(
    parseJsonField<unknown>(row.compositionTrend),
  );
  const recompVector = normalizeDerivedComment(
    parseJsonField<unknown>(row.recompVector),
  );
  const excessFatGauge = normalizeDerivedComment(
    parseJsonField<unknown>(row.excessFatGauge),
  );
  const bodyRatios = normalizeBodyRatioComments(
    parseJsonField<unknown>(row.bodyRatios),
  );

  if (
    ffmi === null ||
    ffmiVsFmi === null ||
    compositionFlow === null ||
    compositionTrend === null ||
    recompVector === null ||
    excessFatGauge === null ||
    bodyRatios === null
  ) {
    return null;
  }

  return {
    ffmi,
    ffmiVsFmi,
    compositionFlow,
    compositionTrend,
    recompVector,
    excessFatGauge,
    bodyRatios,
  };
}

export function getProfilePerformance(
  profileId: ProfileId,
): ProfilePerformance {
  const latestComposition = db
    .prepare(
      `
  SELECT
    fat_mass_kg AS fatMassKg,
    fat_free_mass_kg AS leanMassKg,
    desired_weight_kg AS desiredWeightKg,
    created_at AS createdAt
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as {
    fatMassKg: number;
    leanMassKg: number;
    desiredWeightKg: number;
    createdAt: string;
  } | null;

  const initialComposition = db
    .prepare(
      `
  SELECT
    fat_mass_kg AS fatMassKg,
    fat_free_mass_kg AS leanMassKg,
    created_at AS createdAt
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at ASC
  LIMIT 1
`,
    )
    .get(profileId) as {
    fatMassKg: number;
    leanMassKg: number;
    createdAt: string;
  } | null;

  const derivedMetrics = db
    .prepare(
      `
  SELECT
    fmi,
    ffmi,
    created_at AS createdAt
  FROM derived_body_composition_metrics
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as {
    fmi: number;
    ffmi: number;
    createdAt: string;
  } | null;

  const compositionTrend = db
    .prepare(
      `
  SELECT
    created_at AS createdAt,
    fat_free_mass_kg AS leanMassKg,
    fat_mass_kg AS fatMassKg
  FROM body_composition_metrics_new
  WHERE profile_id = ?
    AND created_at >= datetime('now', '-30 days')
  ORDER BY created_at ASC
`,
    )
    .all(profileId) as CompositionTrendMassPoint[];

  const commentsRow = db
    .prepare(
      `
  SELECT
    ffmi,
    ffmi_vs_fmi AS ffmiVsFmi,
    composition_flow AS compositionFlow,
    composition_trend AS compositionTrend,
    recomp_vector AS recompVector,
    excess_fat_gauge AS excessFatGauge,
    body_ratios AS bodyRatios
  FROM derived_metrics_comments
  WHERE profile_id = ?
  LIMIT 1
`,
    )
    .get(profileId) as DerivedMetricsCommentsRow | null;

  const bodyMeasurements = listUserBodyMeasurements(profileId);
  const latestMeasurement = bodyMeasurements[0] ?? null;
  const profile = getProfileById(profileId);
  const fallbackFmi =
    latestComposition === null || profile.heightCm === null
      ? null
      : calculateFmi(latestComposition.fatMassKg, profile.heightCm);
  const fallbackFfmi =
    latestComposition === null || profile.heightCm === null
      ? null
      : calculateFfmi(latestComposition.leanMassKg, profile.heightCm);
  const fmi = derivedMetrics?.fmi ?? fallbackFmi;
  const ffmi = derivedMetrics?.ffmi ?? fallbackFfmi;
  const targetFatKg =
    latestComposition === null
      ? null
      : roundMetric(
          Math.max(
            latestComposition.desiredWeightKg - latestComposition.leanMassKg,
            0,
          ),
          2,
        );
  const excessFatKg =
    latestComposition === null || targetFatKg === null
      ? null
      : roundMetric(Math.max(latestComposition.fatMassKg - targetFatKg, 0), 2);
  const leanMass30Days = compositionTrend.map((point) => ({
    createdAt: point.createdAt,
    value: point.leanMassKg,
  }));
  const fatMass30Days = compositionTrend.map((point) => ({
    createdAt: point.createdAt,
    value: point.fatMassKg,
  }));

  return {
    ffmi,
    ffmiVsFmi: {
      ffmi,
      fmi,
    },
    bodyComposition: {
      leanMassKg: latestComposition?.leanMassKg ?? null,
      fatMassKg: latestComposition?.fatMassKg ?? null,
    },
    compositionTrends: {
      leanMass30Days: normalizeTrend(leanMass30Days),
      fatMass30Days: normalizeTrend(fatMass30Days),
    },
    weightPair: {
      target: {
        leanMassKg: latestComposition?.leanMassKg ?? null,
        fatMassKg: targetFatKg,
      },
      current: {
        leanMassKg: latestComposition?.leanMassKg ?? null,
        fatMassKg: latestComposition?.fatMassKg ?? null,
      },
      initial: {
        leanMassKg: initialComposition?.leanMassKg ?? null,
        fatMassKg: initialComposition?.fatMassKg ?? null,
      },
    },
    excessFatGauge: {
      totalFatKg: latestComposition?.fatMassKg ?? null,
      targetFatKg,
      excessFatKg,
    },
    bodyMeasurements,
    lastBodyRatios: {
      waistHeight: ratioOrNull(
        latestMeasurement?.waistCm ?? null,
        profile.heightCm,
      ),
      shoulderWaist: ratioOrNull(
        latestMeasurement?.shoulderCm ?? null,
        latestMeasurement?.waistCm ?? null,
      ),
      chestWaist: ratioOrNull(
        latestMeasurement?.chestCm ?? null,
        latestMeasurement?.waistCm ?? null,
      ),
      bicepForearm: ratioOrNull(
        latestMeasurement?.bicepCm ?? null,
        latestMeasurement?.forearmCm ?? null,
      ),
      thighCalf: ratioOrNull(
        latestMeasurement?.thighCm ?? null,
        latestMeasurement?.calfCm ?? null,
      ),
      neckCalf: ratioOrNull(
        latestMeasurement?.neckCm ?? null,
        latestMeasurement?.calfCm ?? null,
      ),
    },
    comments: parseDerivedMetricsComments(commentsRow),
  };
}

export function getWeightSummary(profileId: ProfileId): WeightSummary {
  const currentWeightRow = db
    .prepare(
      `
  SELECT
    weight
  FROM measurements
  WHERE profile_id = ?
    AND weight IS NOT NULL
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as { weight: number } | null;

  const goalWeightRow = db
    .prepare(
      `
  SELECT
    desired_weight_kg AS goalWeight
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as { goalWeight: number } | null;

  const summaryRow = db
    .prepare(
      `
  SELECT
    AVG(weight) AS averageWeight30d,
    MIN(weight) AS lowestWeight30d
  FROM measurements
  WHERE profile_id = ?
    AND weight IS NOT NULL
    AND created_at >= datetime('now', '-30 days')
`,
    )
    .get(profileId) as {
    averageWeight30d: number | null;
    lowestWeight30d: number | null;
  } | null;

  const last30DaysWeightTrend = db
    .prepare(
      `
  SELECT
    weight,
    created_at AS createdAt
  FROM measurements
  WHERE profile_id = ?
    AND weight IS NOT NULL
    AND created_at >= datetime('now', '-30 days')
  ORDER BY created_at ASC
`,
    )
    .all(profileId) as WeightTrendPoint[];

  return {
    currentWeight: currentWeightRow?.weight ?? null,
    goalWeight: goalWeightRow?.goalWeight ?? null,
    averageWeight30d: summaryRow?.averageWeight30d ?? null,
    lowestWeight30d: summaryRow?.lowestWeight30d ?? null,
    last30DaysWeightTrend,
  };
}

export function listUsers(): Users[] {
  const rows = db
    .prepare(
      `
  SELECT
    profiles.id,
    profiles.account_id AS accountId,
    profiles.name,
    accounts.mail_address AS mailAddress,
    profiles.is_primary AS isPrimary,
    profile_metadata.height_cm AS heightCm,
    profile_metadata.date_of_birth AS dateOfBirth,
    profile_metadata.people_type AS peopleType,
    profile_metadata.gender,
    profile_metadata.profile_image AS profileImage,
    profile_metadata.preferred_body_fat_pct AS preferredBodyFatPct,
    profiles.created_at AS createdAt
  FROM profiles
  INNER JOIN accounts
    ON accounts.id = profiles.account_id
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = profiles.id
  ORDER BY profiles.created_at DESC
`,
    )
    .all() as UserRow[];

  return rows.map((row) => ({
    ...row,
    isPrimary: row.isPrimary === 1,
  }));
}

export function getProfileById(id: ProfileId) {
  const row = db
    .prepare(
      `
  SELECT
    profiles.id,
    profiles.account_id AS accountId,
    profiles.name,
    accounts.mail_address AS mailAddress,
    profiles.is_primary AS isPrimary,
    profile_metadata.height_cm AS heightCm,
    profile_metadata.date_of_birth AS dateOfBirth,
    profile_metadata.people_type AS peopleType,
    profile_metadata.gender,
    profile_metadata.profile_image AS profileImage,
    profile_metadata.preferred_body_fat_pct AS preferredBodyFatPct
  FROM profiles
  INNER JOIN accounts
    ON accounts.id = profiles.account_id
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = profiles.id
  WHERE profiles.id = ? `,
    )
    .get(id) as ProfileRow;

  return {
    ...row,
    isPrimary: row.isPrimary === 1,
  };
}
