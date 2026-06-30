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

export type ObservationFieldNameRow = {
  field_name_normalized: string;
};

export type TrendableObservationValueRow = {
  fieldName: string;
  fieldNameNormalized: string;
  explanation: string;
  defaultUnit: string | null;
  remark: string;
  valueRaw: string;
  valueNumeric: number | null;
  valueText: string | null;
  unitNormalized: string | null;
  inference: string;
  observedAt: string;
};

export type ReportSectionNameRow = {
  section_name_normalized: string | null;
};

export type InsertIntoLabReportInput = {
  lab_name: string;
  report_date: string;
  collection_date: string;
};

export type AddReportSectionInput = {
  report_id: string;
  section_name_raw: string;
  section_name_normalized: string;
};

export type AddObservationFieldInput = {
  field_name: string;
  field_name_normalized: string;
  explanation: string;
  default_unit?: string | null;
  is_trendable?: boolean;
};

export type AddObservationInput = {
  report_id: string;
  section_name_normalized: string;
  observation_field_name_normalized: string;
  test_name_raw: string;
  test_name_normalized: string;
  value_raw: string;
  value_numeric?: number | null;
  value_text?: string | null;
  unit_raw?: string | null;
  unit_normalized?: string | null;
  reference_range_raw?: string | null;
  ref_low?: number | null;
  ref_high?: number | null;
  inference: string;
  confidence_score?: number | null;
};

export type UpdateObservationFieldRemarkInput = {
  field_name_normalized: string;
  remark: string;
};

export type ProfileAiReportJsonLd = {
  reportId: string;
  profileId: ProfileId;
  data: unknown;
};

export type ProfileInsightGenerationStatus =
  | "pending"
  | "queued"
  | "running"
  | "completed"
  | "failed";

export type ProfileAiReportById = {
  reportId: string;
  profileId: ProfileId;
  generationStatus: ProfileInsightGenerationStatus;
  generationError: string | null;
  createdAt: string;
  updatedAt: string;
  data: unknown | null;
};

export type RecentProfileAiReport = Omit<ProfileAiReportById, "data"> & {
  hasData: boolean;
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

export async function createLabReport(profileId: ProfileId) {
  const reportId = uuidv7();

  await db.prepare(
    `
  INSERT INTO reports (id, profile_id)
  VALUES (?, ?)
`,
  ).run(reportId, profileId);

  return reportId;
}

export async function insertIntoLabReport(
  reportId: string,
  { lab_name, report_date, collection_date }: InsertIntoLabReportInput,
) {
  await db.prepare(
    `
  UPDATE reports
  SET
    lab_name = ?,
    report_date = ?,
    collection_date = ?
  WHERE id = ?
`,
  ).run(lab_name, report_date, collection_date, reportId);
}

export async function listObservationFieldNames() {
  return await db
    .prepare(
      `
  SELECT field_name_normalized
  FROM observation_fields
`,
    )
    .all() as ObservationFieldNameRow[];
}

export async function listTrendableObservationValuesLastYear(
  profileId: ProfileId,
) {
  return await db
    .prepare(
      `
  SELECT
    observation_fields.field_name AS fieldName,
    observation_fields.field_name_normalized AS fieldNameNormalized,
    observation_fields.explanation AS explanation,
    observation_fields.default_unit AS defaultUnit,
    COALESCE(observation_field_remarks.remark, '') AS remark,
    observations.value_raw AS valueRaw,
    observations.value_numeric AS valueNumeric,
    observations.value_text AS valueText,
    observations.unit_normalized AS unitNormalized,
    observations.inference AS inference,
    observations.created_at AS observedAt
  FROM observations
  INNER JOIN reports
    ON reports.id = observations.report_id
  INNER JOIN observation_fields
    ON observation_fields.id = observations.observation_field_id
  LEFT JOIN observation_field_remarks
    ON observation_field_remarks.observation_field_id = observation_fields.id
  WHERE reports.profile_id = ?
    AND observation_fields.is_trendable = 1
    AND observations.created_at >= datetime('now', '-1 year')
  ORDER BY observation_fields.field_name_normalized ASC, observations.created_at ASC
`,
    )
    .all(profileId) as TrendableObservationValueRow[];
}

export async function addObservationField({
  field_name,
  field_name_normalized,
  explanation,
  default_unit = null,
  is_trendable = false,
}: AddObservationFieldInput) {
  const observationFieldId = uuidv7();

  await db.prepare(
    `
  INSERT INTO observation_fields (
    id,
    field_name,
    field_name_normalized,
    explanation,
    default_unit,
    is_trendable
  )
  VALUES (?, ?, ?, ?, ?, ?)
`,
  ).run(
    observationFieldId,
    field_name,
    field_name_normalized,
    explanation,
    default_unit,
    is_trendable,
  );

  if (is_trendable) {
    await db.prepare(
      `
  INSERT INTO observation_field_remarks (
    id,
    observation_field_id,
    remark
  )
  VALUES (?, ?, '')
`,
    ).run(uuidv7(), observationFieldId);
  }

  return observationFieldId;
}

export async function updateObservationFieldRemark({
  field_name_normalized,
  remark,
}: UpdateObservationFieldRemarkInput) {
  const observationFieldId = await getObservationFieldId(field_name_normalized);

  if (observationFieldId === null) {
    throw new Error(`Unknown observation field: ${field_name_normalized}`);
  }

  await db.prepare(
    `
  INSERT INTO observation_field_remarks (
    id,
    observation_field_id,
    remark
  )
  VALUES (?, ?, ?)
  ON CONFLICT(observation_field_id)
  DO UPDATE SET remark = excluded.remark
`,
  ).run(uuidv7(), observationFieldId, remark);
}

export async function listReportSectionNames(
  reportId: string,
) {
  return await db
    .prepare(
      `
  SELECT DISTINCT section_name_normalized
  FROM report_sections
  WHERE report_id = ?
    AND section_name_normalized IS NOT NULL
  ORDER BY section_name_normalized ASC
`,
    )
    .all(reportId) as ReportSectionNameRow[];
}

export async function addReportSection({
  report_id,
  section_name_raw,
  section_name_normalized,
}: AddReportSectionInput) {
  const sectionId = uuidv7();

  await db.prepare(
    `
  INSERT INTO report_sections (
    id,
    report_id,
    section_name_raw,
    section_name_normalized
  )
  VALUES (?, ?, ?, ?)
`,
  ).run(sectionId, report_id, section_name_raw, section_name_normalized);

  return sectionId;
}

export async function getReportSectionId({
  report_id,
  section_name_normalized,
}: {
  report_id: string;
  section_name_normalized: string;
}) {
  const row = await db    .prepare(
      `
  SELECT id
  FROM report_sections
  WHERE report_id = ?
    AND section_name_normalized = ?
  LIMIT 1
`,
    )
    .get(report_id, section_name_normalized) as { id: string } | null;

  return row?.id ?? null;
}

export async function getObservationFieldId(
  field_name_normalized: string,
) {
  const row = await db    .prepare(
      `
  SELECT id
  FROM observation_fields
  WHERE field_name_normalized = ?
  LIMIT 1
`,
    )
    .get(field_name_normalized) as { id: string } | null;

  return row?.id ?? null;
}

export async function addObservation({
  report_id,
  section_name_normalized,
  observation_field_name_normalized,
  test_name_raw,
  test_name_normalized,
  value_raw,
  value_numeric = null,
  value_text = null,
  unit_raw = null,
  unit_normalized = null,
  reference_range_raw = null,
  ref_low = null,
  ref_high = null,
  inference,
  confidence_score = null,
}: AddObservationInput) {
  const sectionId = await getReportSectionId({
    report_id,
    section_name_normalized,
  });
  const observationFieldId = await getObservationFieldId(
    observation_field_name_normalized,
  );

  if (sectionId === null) {
    throw new Error(`Unknown report section: ${section_name_normalized}`);
  }

  if (observationFieldId === null) {
    throw new Error(
      `Unknown observation field: ${observation_field_name_normalized}`,
    );
  }

  const observationId = uuidv7();

  await db.prepare(
    `
  INSERT INTO observations (
    id,
    report_id,
    section_id,
    observation_field_id,
    test_name_raw,
    test_name_normalized,
    value_raw,
    value_numeric,
    value_text,
    unit_raw,
    unit_normalized,
    reference_range_raw,
    ref_low,
    ref_high,
    inference,
    confidence_score
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`,
  ).run(
    observationId,
    report_id,
    sectionId,
    observationFieldId,
    test_name_raw,
    test_name_normalized,
    value_raw,
    value_numeric,
    value_text,
    unit_raw,
    unit_normalized,
    reference_range_raw,
    ref_low,
    ref_high,
    inference,
    confidence_score,
  );

  return observationId;
}

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

type ReportComment = {
  factor: string;
  remark: string;
  comment: string;
};

export type FatReportFactor =
  | "fatPercent"
  | "visceralSubcutaneous30dDelta"
  | "fatMass"
  | "visceralFatMass"
  | "visceralFatPercent"
  | "subcutaneousFatMass"
  | "subcutaneousFatRatio";

export type FatReportComment = {
  remark: string;
  comment: string;
};

export type FatReportComments = Partial<Record<FatReportFactor, FatReportComment>>;

export type FatReportTrendPoint = {
  createdAt: string;
  value: number;
};

export type FatReport = {
  id: string;
  profileId: ProfileId;
  bodyCompositionMetricsId: string;
  createdAt: string;
  metrics: {
    fatPercent: number;
    visceralSubcutaneous30dDelta: {
      visceralFatDeltaKg: number;
      subcutaneousFatDeltaKg: number;
    };
    fatMassKg: number;
    visceralFatMassKg: number;
    visceralFatPercent: number;
    subcutaneousFatMassKg: number;
    subcutaneousFatRatio: number;
  };
  last30Days: {
    fatMassKg: FatReportTrendPoint[];
    visceralFatMassKg: FatReportTrendPoint[];
    subcutaneousFatMassKg: FatReportTrendPoint[];
    visceralFatPercent: FatReportTrendPoint[];
    subcutaneousFatPercent: FatReportTrendPoint[];
  };
  comments: FatReportComments;
};

export type FatReportCommentsInput = {
  profileId: ProfileId;
  comments: Record<FatReportFactor, FatReportComment>;
  modelName?: string | null;
};

export type MuscleReportFactor =
  | "totalMuscle"
  | "boneMass"
  | "muscleRatio"
  | "skeletalMuscleMass"
  | "skeletalMuscleRatio";

export type MuscleReportComment = {
  remark: string;
  comment: string;
};

export type MuscleReportComments = Partial<
  Record<MuscleReportFactor, MuscleReportComment>
>;

export type MuscleReportTrendPoint = {
  createdAt: string;
  value: number;
};

export type MuscleReport = {
  id: string;
  profileId: ProfileId;
  bodyCompositionMetricsId: string;
  createdAt: string;
  metrics: {
    totalMuscleKg: number;
    boneMassKg: number;
    muscleRatio: number;
    skeletalMuscleMassKg: number;
    skeletalMuscleRatio: number;
  };
  last30Days: {
    boneMassKg: MuscleReportTrendPoint[];
    muscleRatio: MuscleReportTrendPoint[];
    skeletalMuscleMassKg: MuscleReportTrendPoint[];
    skeletalMuscleRatio: MuscleReportTrendPoint[];
  };
  comments: MuscleReportComments;
};

export type MuscleReportCommentsInput = {
  profileId: ProfileId;
  comments: Record<MuscleReportFactor, MuscleReportComment>;
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

type QuantityValue = {
  qty?: number;
  units?: string;
};

export type WorkoutType =
  | "Traditional Strength Training"
  | "Indoor Walking"
  | "Outdoor Walking"
  | "Running"
  | "Cycling";

export type AppleHealthWorkoutName =
  | WorkoutType
  | "Indoor Cycling"
  | "Indoor Run"
  | "Outdoor Walk"
  | (string & {});

type WorkoutMetricsBase = {
  start?: string | null;
  end?: string | null;
  duration?: number | null;
  activeEnergyBurned?: QuantityValue | null;
  totalEnergy?: QuantityValue | null;
  avgHeartRate?: QuantityValue | null;
  heartRate?: {
    min?: QuantityValue | null;
    max?: QuantityValue | null;
    avg?: QuantityValue | null;
  } | null;
  maxHeartRate?: QuantityValue | null;
  intensity?: QuantityValue | null;
  temperature?: QuantityValue | null;
  humidity?: QuantityValue | null;
  metadata?: Record<string, unknown> | null;
};

export type StrengthMetrics = WorkoutMetricsBase & {
  stepCadence?: QuantityValue | null;
};

export type WalkingMetrics = WorkoutMetricsBase & {
  distance?: QuantityValue | null;
  speed?: QuantityValue | null;
  stepCadence?: QuantityValue | null;
};

export type RunningMetrics = WorkoutMetricsBase & {
  distance?: QuantityValue | null;
  speed?: QuantityValue | null;
  stepCadence?: QuantityValue | null;
};

export type CyclingMetrics = WorkoutMetricsBase & {
  distance?: QuantityValue | null;
  speed?: QuantityValue | null;
};

export type WorkoutMetrics =
  | StrengthMetrics
  | WalkingMetrics
  | RunningMetrics
  | CyclingMetrics;

export interface Workout {
  id: string;
  type: WorkoutType;
  metrics: WorkoutMetrics;
}

export interface WorkoutInput {
  id: string;
  name: AppleHealthWorkoutName;
  type?: WorkoutType;
  metrics?: WorkoutMetrics;
  location?: string | null;
  isIndoor?: boolean | null;
  start?: string | null;
  end?: string | null;
  duration?: number | null;
  distance?: QuantityValue | null;
  activeEnergyBurned?: QuantityValue | null;
  totalEnergy?: QuantityValue | null;
  avgHeartRate?: QuantityValue | null;
  heartRate?: {
    min?: QuantityValue | null;
    max?: QuantityValue | null;
    avg?: QuantityValue | null;
  } | null;
  maxHeartRate?: QuantityValue | null;
  speed?: QuantityValue | null;
  stepCadence?: QuantityValue | null;
  intensity?: QuantityValue | null;
  temperature?: QuantityValue | null;
  humidity?: QuantityValue | null;
  metadata?: Record<string, unknown> | null;
  [key: string]: unknown;
}

export type WorkoutData = WorkoutInput;

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

 function parseProfileAiAnalysisBlock(raw: unknown): ProfileAiAnalysisBlock {
  return (typeof raw === "string" ? JSON.parse(raw) : raw) as ProfileAiAnalysisBlock;
}

 function parseProfileAiMomentumBlock(raw: unknown): ProfileAiAnalysisBlock {
  const block = (typeof raw === "string" ? JSON.parse(raw) : raw) as ProfileAiAnalysisBlock;

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

export async function jobExists(jobId: JobId) {
  const job = await db    .prepare(
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

export async function profileExists(profileId: ProfileId) {
  const profile = await db    .prepare(
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

export async function profileBelongsToAccount(
  profileId: ProfileId,
  accountId: AccountId,
) {
  const profile = await db    .prepare(
      `
  SELECT 1
  FROM profiles
  WHERE id = ?
    AND account_id = ?
  LIMIT 1
`,
    )
    .get(profileId, accountId);

  return profile !== null;
}

export async function accountExists(accountId: AccountId) {
  const account = await db    .prepare(
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

export async function getProfileIdByJobId(jobId: JobId) {
  const job = await db    .prepare(
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

export async function initJob(jobId: JobId, profileId: ProfileId) {
  await db.prepare(
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
export async function addMeasurement(
  profileId: ProfileId,
  weight: number,
  heartbeat: number,
  impedance: number,
) {
  const id = uuidv7();

  await db.prepare(
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

 function quantityQty(value: QuantityValue | null | undefined): number | null {
  return typeof value?.qty === "number" ? value.qty : null;
}

 function quantityUnits(value: QuantityValue | null | undefined): string | null {
  return typeof value?.units === "string" ? value.units : null;
}

export  function workoutTypeFromName(name: AppleHealthWorkoutName): WorkoutType {
  switch (name) {
    case "Traditional Strength Training":
      return "Traditional Strength Training";
    case "Indoor Walking":
      return "Indoor Walking";
    case "Outdoor Walking":
    case "Outdoor Walk":
      return "Outdoor Walking";
    case "Running":
    case "Indoor Run":
      return "Running";
    case "Cycling":
    case "Indoor Cycling":
      return "Cycling";
    default:
      throw new Error(`Unsupported workout type: ${name}`);
  }
}

 function workoutMetricsFromInput(workout: WorkoutInput): WorkoutMetrics {
  const metrics = {
    start: workout.start ?? null,
    end: workout.end ?? null,
    duration: workout.duration ?? null,
    activeEnergyBurned: workout.activeEnergyBurned ?? null,
    totalEnergy: workout.totalEnergy ?? null,
    avgHeartRate: workout.avgHeartRate ?? workout.heartRate?.avg ?? null,
    heartRate: workout.heartRate ?? null,
    maxHeartRate: workout.maxHeartRate ?? workout.heartRate?.max ?? null,
    intensity: workout.intensity ?? null,
    temperature: workout.temperature ?? null,
    humidity: workout.humidity ?? null,
    metadata: workout.metadata ?? null,
  };

  switch (workout.type ?? workoutTypeFromName(workout.name)) {
    case "Traditional Strength Training":
      return {
        ...metrics,
        stepCadence: workout.stepCadence ?? null,
      };
    case "Indoor Walking":
    case "Outdoor Walking":
    case "Running":
      return {
        ...metrics,
        distance: workout.distance ?? null,
        speed: workout.speed ?? null,
        stepCadence: workout.stepCadence ?? null,
      };
    case "Cycling":
      return {
        ...metrics,
        distance: workout.distance ?? null,
        speed: workout.speed ?? null,
      };
  }
}

export  function normalizeWorkout(workout: WorkoutInput): Workout {
  return {
    id: workout.id,
    type: workout.type ?? workoutTypeFromName(workout.name),
    metrics: workout.metrics ?? workoutMetricsFromInput(workout),
  };
}

export async function addWorkout(workout: WorkoutInput, profileId?: ProfileId | null) {
  const id = uuidv7();
  const avgHeartRate = workout.avgHeartRate ?? workout.heartRate?.avg ?? null;
  const minHeartRate = workout.heartRate?.min ?? null;
  const maxHeartRate = workout.maxHeartRate ?? workout.heartRate?.max ?? null;

  await db.prepare(
    `
  INSERT INTO workouts (
    id,
    source_workout_id,
    profile_id,
    name,
    location,
    is_indoor,
    started_at,
    ended_at,
    duration_seconds,
    distance_qty,
    distance_units,
    active_energy_qty,
    active_energy_units,
    total_energy_qty,
    total_energy_units,
    avg_heart_rate_qty,
    avg_heart_rate_units,
    min_heart_rate_qty,
    min_heart_rate_units,
    max_heart_rate_qty,
    max_heart_rate_units,
    speed_qty,
    speed_units,
    step_cadence_qty,
    step_cadence_units,
    intensity_qty,
    intensity_units,
    temperature_qty,
    temperature_units,
    humidity_qty,
    humidity_units,
    metadata,
    raw_payload,
    created_at,
    updated_at
  )
  VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
    ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
  )
  ON CONFLICT(source_workout_id) DO UPDATE SET
    profile_id = excluded.profile_id,
    name = excluded.name,
    location = excluded.location,
    is_indoor = excluded.is_indoor,
    started_at = excluded.started_at,
    ended_at = excluded.ended_at,
    duration_seconds = excluded.duration_seconds,
    distance_qty = excluded.distance_qty,
    distance_units = excluded.distance_units,
    active_energy_qty = excluded.active_energy_qty,
    active_energy_units = excluded.active_energy_units,
    total_energy_qty = excluded.total_energy_qty,
    total_energy_units = excluded.total_energy_units,
    avg_heart_rate_qty = excluded.avg_heart_rate_qty,
    avg_heart_rate_units = excluded.avg_heart_rate_units,
    min_heart_rate_qty = excluded.min_heart_rate_qty,
    min_heart_rate_units = excluded.min_heart_rate_units,
    max_heart_rate_qty = excluded.max_heart_rate_qty,
    max_heart_rate_units = excluded.max_heart_rate_units,
    speed_qty = excluded.speed_qty,
    speed_units = excluded.speed_units,
    step_cadence_qty = excluded.step_cadence_qty,
    step_cadence_units = excluded.step_cadence_units,
    intensity_qty = excluded.intensity_qty,
    intensity_units = excluded.intensity_units,
    temperature_qty = excluded.temperature_qty,
    temperature_units = excluded.temperature_units,
    humidity_qty = excluded.humidity_qty,
    humidity_units = excluded.humidity_units,
    metadata = excluded.metadata,
    raw_payload = excluded.raw_payload,
    updated_at = CURRENT_TIMESTAMP
`,
  ).run(
    id,
    workout.id,
    profileId ?? null,
    workout.name,
    workout.location ?? null,
    typeof workout.isIndoor === "boolean" ? workout.isIndoor : null,
    workout.start ?? null,
    workout.end ?? null,
    typeof workout.duration === "number" ? workout.duration : null,
    quantityQty(workout.distance),
    quantityUnits(workout.distance),
    quantityQty(workout.activeEnergyBurned),
    quantityUnits(workout.activeEnergyBurned),
    quantityQty(workout.totalEnergy),
    quantityUnits(workout.totalEnergy),
    quantityQty(avgHeartRate),
    quantityUnits(avgHeartRate),
    quantityQty(minHeartRate),
    quantityUnits(minHeartRate),
    quantityQty(maxHeartRate),
    quantityUnits(maxHeartRate),
    quantityQty(workout.speed),
    quantityUnits(workout.speed),
    quantityQty(workout.stepCadence),
    quantityUnits(workout.stepCadence),
    quantityQty(workout.intensity),
    quantityUnits(workout.intensity),
    quantityQty(workout.temperature),
    quantityUnits(workout.temperature),
    quantityQty(workout.humidity),
    quantityUnits(workout.humidity),
    JSON.stringify(workout.metadata ?? {}),
    JSON.stringify(workout),
  );

  const savedWorkout = await db    .prepare(
      `
  SELECT id
  FROM workouts
  WHERE source_workout_id = ?
  LIMIT 1
`,
    )
    .get(workout.id) as { id: string } | null;

  return savedWorkout?.id ?? id;
}
export async function registerUser({ mailAddress }: RegisterUserInput) {
  const accountId: AccountId = uuidv7();

  await db.prepare(
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

export async function registerProfile({
  accountId,
  name,
  isPrimary = false,
}: RegisterProfileInput) {
  const profileId: ProfileId = uuidv7();

  await db.prepare(
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
  ).run(profileId, accountId, name, isPrimary);

  return profileId;
}

export async function registerProfileMetadata({
  profileId,
  dateOfBirth,
  gender,
  heightCm,
  peopleType,
  profileImage = null,
  preferredBodyFatPct = 18,
}: RegisterProfileMetadataInput) {
  await db.prepare(
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

export async function listUserWeight(profileId: ProfileId) {
  return await db
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

export async function addBodyMeasurement(
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
) {
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

  await db.prepare(
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

  const created = await db    .prepare(
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

export async function listUserBodyMeasurements(
  profileId: ProfileId,
) {
  return await db
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

export async function addBodyCompositionMetrics(
  metrics: BodyCompositionMetrics,
) {
  const id = metrics.id ?? uuidv7();

  await db.prepare(
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

export async  function saveBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: CalculatedBodyCompositionMetrics,
) {
  return await addBodyCompositionMetrics({
    profileId,
    bodyFatPct: metrics.body_fat_pct,
    muscleMassKg: metrics.muscle_mass_kg,
    waterPct: metrics.water_pct,
    proteinPct: metrics.protein_pct,
    fatFreeMassKg: metrics.fat_free_mass_kg,
    fatMassKg: metrics.fat_mass_kg,
  });
}

export async function addProprietaryBodyCompositionMetrics(
  profileId: ProfileId,
  metrics: BodyCompositionMetricsNewRow,
) {
  const id = uuidv7();

  await db.prepare(
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

export async function addDerivedBodyComposition(
  profileId: ProfileId,
  metrics: DerivedBodyCompositionMetrics,
) {
  const id = uuidv7();

  await db.prepare(
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

async function getLatestBodyCompositionMetricsId(profileId: ProfileId) {
  const row = await db    .prepare(
      `
  SELECT id
  FROM body_composition_metrics_new
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as { id: string } | null;

  return row?.id ?? null;
}

async function getOrCreatePerformanceReport(
  profileId: ProfileId,
  bodyCompositionMetricsId: string,
  metrics?: Partial<DerivedBodyCompositionMetrics>,
  modelName: string | null = null,
) {
  const existing = await db    .prepare(
      `
  SELECT id
  FROM performance_reports
  WHERE body_composition_metrics_id = ?
  LIMIT 1
`,
    )
    .get(bodyCompositionMetricsId) as { id: string } | null;

  if (existing !== null) {
    if (metrics?.fmi !== undefined || metrics?.ffmi !== undefined || modelName !== null) {
      await db.prepare(
        `
  UPDATE performance_reports
  SET
    fmi = COALESCE(?, fmi),
    ffmi = COALESCE(?, ffmi),
    model_name = COALESCE(?, model_name),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
      ).run(metrics?.fmi ?? null, metrics?.ffmi ?? null, modelName, existing.id);
    }

    return existing.id;
  }

  const id = uuidv7();

  await db.prepare(
    `
  INSERT INTO performance_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    fmi,
    ffmi,
    model_name,
    created_at,
    updated_at
  )
  SELECT
    ?,
    ?,
    ?,
    COALESCE(?, CASE
      WHEN profile_metadata.height_cm IS NULL OR profile_metadata.height_cm <= 0 THEN NULL
      ELSE ROUND(metrics.fat_mass_kg / ((profile_metadata.height_cm / 100.0) * (profile_metadata.height_cm / 100.0)), 2)
    END),
    COALESCE(?, CASE
      WHEN profile_metadata.height_cm IS NULL OR profile_metadata.height_cm <= 0 THEN NULL
      ELSE ROUND(metrics.fat_free_mass_kg / ((profile_metadata.height_cm / 100.0) * (profile_metadata.height_cm / 100.0)), 2)
    END),
    ?,
    metrics.created_at,
    CURRENT_TIMESTAMP
  FROM body_composition_metrics_new AS metrics
  LEFT JOIN profile_metadata
    ON profile_metadata.profile_id = metrics.profile_id
  WHERE metrics.id = ?
`,
  ).run(
    id,
    profileId,
    bodyCompositionMetricsId,
    metrics?.fmi ?? null,
    metrics?.ffmi ?? null,
    modelName,
    bodyCompositionMetricsId,
  );

  return id;
}

async function getOrCreateProfileInsightReport(
  profileId: ProfileId,
  bodyCompositionMetricsId: string,
) {
  const existing = await db    .prepare(
      `
  SELECT id
  FROM profile_insight_reports
  WHERE body_composition_metrics_id = ?
  LIMIT 1
`,
    )
    .get(bodyCompositionMetricsId) as { id: string } | null;

  if (existing !== null) {
    return existing.id;
  }

  const id = uuidv7();

  await db.prepare(
    `
  INSERT INTO profile_insight_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    generation_status,
    created_at,
    updated_at
  )
  SELECT ?, ?, ?, 'pending', created_at, CURRENT_TIMESTAMP
  FROM body_composition_metrics_new
  WHERE id = ?
`,
  ).run(id, profileId, bodyCompositionMetricsId, bodyCompositionMetricsId);

  return id;
}

async function getOrCreateFatReport(
  profileId: ProfileId,
  bodyCompositionMetricsId: string,
  modelName: string | null = null,
) {
  const existing = await db    .prepare(
      `
  SELECT id
  FROM fat_reports
  WHERE body_composition_metrics_id = ?
  LIMIT 1
`,
    )
    .get(bodyCompositionMetricsId) as { id: string } | null;

  if (existing !== null) {
    if (modelName !== null) {
      await db.prepare(
        `
  UPDATE fat_reports
  SET model_name = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
      ).run(modelName, existing.id);
    }

    return existing.id;
  }

  const id = uuidv7();

  await db.prepare(
    `
  INSERT INTO fat_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    fat_percent,
    visceral_fat_delta_30d_kg,
    subcutaneous_fat_delta_30d_kg,
    fat_mass_kg,
    visceral_fat_mass_kg,
    visceral_fat_percent,
    subcutaneous_fat_mass_kg,
    subcutaneous_fat_ratio,
    model_name,
    created_at,
    updated_at
  )
  SELECT
    ?,
    latest.profile_id,
    latest.id,
    latest.body_fat_pct,
    ROUND(
      (latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg) -
      (baseline.fat_mass_kg - baseline.subcutaneous_fat_mass_kg),
      2
    ),
    ROUND(latest.subcutaneous_fat_mass_kg - baseline.subcutaneous_fat_mass_kg, 2),
    latest.fat_mass_kg,
    ROUND(latest.fat_mass_kg - latest.subcutaneous_fat_mass_kg, 2),
    ROUND(latest.body_fat_pct - latest.subcutaneous_fat_pct, 2),
    latest.subcutaneous_fat_mass_kg,
    CASE
      WHEN latest.fat_mass_kg <= 0 THEN 0
      ELSE ROUND(latest.subcutaneous_fat_mass_kg / latest.fat_mass_kg, 2)
    END,
    ?,
    latest.created_at,
    CURRENT_TIMESTAMP
  FROM body_composition_metrics_new AS latest
  INNER JOIN body_composition_metrics_new AS baseline
    ON baseline.id = (
      SELECT oldest.id
      FROM body_composition_metrics_new AS oldest
      WHERE oldest.profile_id = latest.profile_id
        AND oldest.created_at >= datetime(latest.created_at, '-30 days')
        AND oldest.created_at <= latest.created_at
      ORDER BY oldest.created_at ASC
      LIMIT 1
    )
  WHERE latest.id = ?
    AND latest.profile_id = ?
`,
  ).run(id, modelName, bodyCompositionMetricsId, profileId);

  return id;
}

async function getOrCreateMuscleReport(
  profileId: ProfileId,
  bodyCompositionMetricsId: string,
  modelName: string | null = null,
) {
  const existing = await db    .prepare(
      `
  SELECT id
  FROM muscle_reports
  WHERE body_composition_metrics_id = ?
  LIMIT 1
`,
    )
    .get(bodyCompositionMetricsId) as { id: string } | null;

  if (existing !== null) {
    if (modelName !== null) {
      await db.prepare(
        `
  UPDATE muscle_reports
  SET model_name = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
      ).run(modelName, existing.id);
    }

    return existing.id;
  }

  const id = uuidv7();

  await db.prepare(
    `
  INSERT INTO muscle_reports (
    id,
    profile_id,
    body_composition_metrics_id,
    total_muscle_kg,
    bone_mass_kg,
    muscle_ratio,
    skeletal_muscle_mass_kg,
    skeletal_muscle_ratio,
    model_name,
    created_at,
    updated_at
  )
  SELECT
    ?,
    profile_id,
    id,
    muscle_mass_kg,
    ROUND(MAX(fat_free_mass_kg - muscle_mass_kg, 0), 2),
    muscle_rate_pct,
    skeletal_muscle_kg,
    CASE
      WHEN fat_mass_kg + fat_free_mass_kg <= 0 THEN 0
      ELSE ROUND(skeletal_muscle_kg / (fat_mass_kg + fat_free_mass_kg) * 100, 2)
    END,
    ?,
    created_at,
    CURRENT_TIMESTAMP
  FROM body_composition_metrics_new
  WHERE id = ?
    AND profile_id = ?
`,
  ).run(id, modelName, bodyCompositionMetricsId, profileId);

  return id;
}

export async  function createSnapshotReports({
  profileId,
  bodyCompositionMetricsId,
  derivedMetrics,
  modelName = null,
}: {
  profileId: ProfileId;
  bodyCompositionMetricsId: string;
  derivedMetrics?: DerivedBodyCompositionMetrics;
  modelName?: string | null;
}) {
  const performanceReportId = await getOrCreatePerformanceReport(
    profileId,
    bodyCompositionMetricsId,
    derivedMetrics,
    modelName,
  );
  const insightReportId = await getOrCreateProfileInsightReport(
    profileId,
    bodyCompositionMetricsId,
  );
  const fatReportId = await getOrCreateFatReport(
    profileId,
    bodyCompositionMetricsId,
    modelName,
  );
  const muscleReportId = await getOrCreateMuscleReport(
    profileId,
    bodyCompositionMetricsId,
    modelName,
  );

  return {
    performanceReportId,
    insightReportId,
    fatReportId,
    muscleReportId,
  };
}

  async function getLatestReportIds(profileId: ProfileId) {
  const bodyCompositionMetricsId = await getLatestBodyCompositionMetricsId(profileId);

  if (bodyCompositionMetricsId === null) {
    return null;
  }

  return {
    bodyCompositionMetricsId,
    performanceReportId: await getOrCreatePerformanceReport(
      profileId,
      bodyCompositionMetricsId,
    ),
    insightReportId: await getOrCreateProfileInsightReport(
      profileId,
      bodyCompositionMetricsId,
    ),
    fatReportId: await getOrCreateFatReport(profileId, bodyCompositionMetricsId),
    muscleReportId: await getOrCreateMuscleReport(
      profileId,
      bodyCompositionMetricsId,
    ),
  };
}

export  function isBodyCompositionTrendMetric(
  metric: string,
): metric is BodyCompositionTrendMetric {
  return TREND_COLUMNS.includes(metric as BodyCompositionTrendMetric);
}

export  function isBodyCompositionTrendPeriod(
  period: string,
): period is BodyCompositionTrendPeriod {
  return Object.hasOwn(PERIODS, period);
}

export async function listBodyCompositionTrends({
  metric,
  period,
  profileId,
  accountId,
}: {
  metric: BodyCompositionTrendMetric;
  period: BodyCompositionTrendPeriod;
  profileId?: ProfileId;
  accountId?: AccountId;
}) {
  const range = PERIODS[period];
  const profileFilter = profileId === undefined
    ? ""
    : "AND body_composition_metrics_new.profile_id = ?";
  const accountFilter = accountId === undefined ? "" : "AND profiles.account_id = ?";
  const rangeFilter = range === null
    ? ""
    : "AND body_composition_metrics_new.created_at >= datetime('now', ?)";
  const params = [
    ...(accountId === undefined ? [] : [accountId]),
    ...(profileId === undefined ? [] : [profileId]),
    ...(range === null ? [] : [range]),
  ];

  return await db
    .prepare(
      `
  SELECT
    profile_id AS profileId,
    body_composition_metrics_new.created_at AS createdAt,
    ${metric} AS value
  FROM body_composition_metrics_new
  INNER JOIN profiles
    ON profiles.id = body_composition_metrics_new.profile_id
  WHERE 1 = 1
    ${accountFilter}
    ${profileFilter}
    ${rangeFilter}
  ORDER BY body_composition_metrics_new.created_at ASC
`,
    )
    .all(...params) as BodyCompositionTrendPoint[];
}

export async function addProgressMeasurement(
  measurement: ProgressMeasurement,
) {
  const id = measurement.id ?? uuidv7();

  await db.prepare(
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

export async function upsertProfileAiOverview({
  profileId,
  overviewTitle,
  overviewRemarks,
  foundation,
  momentum,
  biggestLever,
  physiqueArchetype,
  modelName = null,
}: ProfileAiOverview) {
  const reportIds = await getLatestReportIds(profileId);

  if (reportIds === null) {
    return;
  }

  await db.prepare(
    `
  UPDATE profile_insight_reports
  SET
    overview_title = ?,
    overview_remarks = ?,
    foundation = ?,
    momentum = ?,
    biggest_lever = ?,
    physique_archetype = ?,
    model_name = ?,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
  ).run(
    overviewTitle,
    overviewRemarks,
    JSON.stringify(foundation),
    JSON.stringify(momentum),
    JSON.stringify(biggestLever),
    physiqueArchetype,
    modelName,
    reportIds.insightReportId,
  );
}

async function replaceReportComments(
  tableName:
    | "performance_report_comments"
    | "fat_report_comments"
    | "muscle_report_comments",
  reportId: string,
  comments: ReportComment[],
) {
  await db.transaction(async (tx) => {
    await tx.prepare(`DELETE FROM ${tableName} WHERE report_id = ?`).run(reportId);

    const insert = tx.prepare(`
  INSERT INTO ${tableName} (
    id,
    report_id,
    factor,
    remark,
    comment,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
`);

    for (const comment of comments) {
      await insert.run(
        uuidv7(),
        reportId,
        comment.factor,
        comment.remark,
        comment.comment,
      );
    }
  });
}

async function readReportComments(
  tableName:
    | "performance_report_comments"
    | "fat_report_comments"
    | "muscle_report_comments",
  reportId: string,
) {
  return await db
    .prepare(
      `
  SELECT
    factor,
    remark,
    comment
  FROM ${tableName}
  WHERE report_id = ?
`,
    )
    .all(reportId) as ReportComment[];
}

 function requireOneWordRemark(remark: string): string {
  const trimmed = remark.trim();

  if (!trimmed || /\s/.test(trimmed)) {
    throw new Error("remark must be exactly one word");
  }

  return trimmed;
}

export async function saveFatReportComments({
  profileId,
  comments,
  modelName = null,
}: FatReportCommentsInput) {
  const reportIds = await getLatestReportIds(profileId);

  if (reportIds === null) {
    return;
  }

  const rows: ReportComment[] = [
    { factor: "fat_percent", ...comments.fatPercent },
    {
      factor: "visceral_subcutaneous_30d_delta",
      ...comments.visceralSubcutaneous30dDelta,
    },
    { factor: "fat_mass", ...comments.fatMass },
    { factor: "visceral_fat_mass", ...comments.visceralFatMass },
    { factor: "visceral_fat_percent", ...comments.visceralFatPercent },
    { factor: "subcutaneous_fat_mass", ...comments.subcutaneousFatMass },
    { factor: "subcutaneous_fat_ratio", ...comments.subcutaneousFatRatio },
  ].map((row) => ({
    factor: row.factor,
    remark: requireOneWordRemark(row.remark),
    comment: row.comment,
  }));

  await db.prepare(
    `
  UPDATE fat_reports
  SET model_name = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
  ).run(modelName, reportIds.fatReportId);

  await replaceReportComments("fat_report_comments", reportIds.fatReportId, rows);
}

export async function saveMuscleReportComments({
  profileId,
  comments,
  modelName = null,
}: MuscleReportCommentsInput) {
  const reportIds = await getLatestReportIds(profileId);

  if (reportIds === null) {
    return;
  }

  const rows: ReportComment[] = [
    { factor: "total_muscle", ...comments.totalMuscle },
    { factor: "bone_mass", ...comments.boneMass },
    { factor: "muscle_ratio", ...comments.muscleRatio },
    { factor: "skeletal_muscle_mass", ...comments.skeletalMuscleMass },
    { factor: "skeletal_muscle_ratio", ...comments.skeletalMuscleRatio },
  ].map((row) => ({
    factor: row.factor,
    remark: requireOneWordRemark(row.remark),
    comment: row.comment,
  }));

  await db.prepare(
    `
  UPDATE muscle_reports
  SET model_name = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
  ).run(modelName, reportIds.muscleReportId);

  await replaceReportComments(
    "muscle_report_comments",
    reportIds.muscleReportId,
    rows,
  );
}

export async function getProfileAiOverview(
  profileId: ProfileId,
) {
  const row = await db    .prepare(
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
  FROM profile_insight_reports
  WHERE profile_id = ?
    AND overview_title IS NOT NULL
    AND overview_remarks IS NOT NULL
    AND foundation IS NOT NULL
    AND momentum IS NOT NULL
    AND biggest_lever IS NOT NULL
    AND physique_archetype IS NOT NULL
  ORDER BY created_at DESC
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

export async function upsertProfileEffortScore({
  profileId,
  score,
  remark,
  modelName = null,
}: ProfileEffortScore) {
  const reportIds = await getLatestReportIds(profileId);

  if (reportIds === null) {
    return;
  }

  await db.prepare(
    `
  UPDATE profile_insight_reports
  SET
    effort_score = ?,
    effort_remark = ?,
    model_name = ?,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
  ).run(score, remark, modelName, reportIds.insightReportId);
}

export async function upsertProfileAiReportJsonLd({
  reportId,
  profileId,
  data,
}: ProfileAiReportJsonLd) {
  await db.prepare(
    `
  INSERT INTO profile_ai_report_jsonld (
    report_id,
    profile_id,
    data
  )
  VALUES (?, ?, ?::jsonb)
  ON CONFLICT (report_id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    data = EXCLUDED.data,
    created_on = CURRENT_TIMESTAMP
`,
  ).run(reportId, profileId, JSON.stringify(data));
}

export async function updateProfileInsightReportGenerationStatus({
  reportId,
  profileId,
  status,
  error = null,
}: {
  reportId: string;
  profileId: ProfileId;
  status: ProfileInsightGenerationStatus;
  error?: string | null;
}) {
  await db.prepare(
    `
  UPDATE profile_insight_reports
  SET
    generation_status = ?,
    generation_error = ?,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
    AND profile_id = ?
`,
  ).run(status, error, reportId, profileId);
}

function parseJsonData(raw: unknown): unknown {
  return typeof raw === "string" ? JSON.parse(raw) : raw;
}

export async function getProfileAiReportById({
  profileId,
  reportId,
}: {
  profileId: ProfileId;
  reportId: string;
}): Promise<ProfileAiReportById | null> {
  const row = await db
    .prepare(
      `
  SELECT
    profile_insight_reports.id AS reportId,
    profile_insight_reports.profile_id AS profileId,
    profile_insight_reports.generation_status AS generationStatus,
    profile_insight_reports.generation_error AS generationError,
    profile_insight_reports.created_at AS createdAt,
    profile_insight_reports.updated_at AS updatedAt,
    profile_ai_report_jsonld.data AS data
  FROM profile_insight_reports
  LEFT JOIN profile_ai_report_jsonld
    ON profile_ai_report_jsonld.report_id = profile_insight_reports.id
  WHERE profile_insight_reports.id = ?
    AND profile_insight_reports.profile_id = ?
  LIMIT 1
`,
    )
    .get(reportId, profileId) as
    | (Omit<ProfileAiReportById, "data"> & { data: unknown | null })
    | null;

  if (row === null) {
    return null;
  }

  return {
    ...row,
    data: row.data === null ? null : parseJsonData(row.data),
  };
}

export async function listRecentProfileAiReports({
  profileId,
  limit = 5,
}: {
  profileId: ProfileId;
  limit?: number;
}): Promise<RecentProfileAiReport[]> {
  return await db
    .prepare(
      `
  SELECT
    profile_insight_reports.id AS reportId,
    profile_insight_reports.profile_id AS profileId,
    profile_insight_reports.generation_status AS generationStatus,
    profile_insight_reports.generation_error AS generationError,
    profile_insight_reports.created_at AS createdAt,
    profile_insight_reports.updated_at AS updatedAt,
    profile_ai_report_jsonld.report_id IS NOT NULL AS hasData
  FROM profile_insight_reports
  LEFT JOIN profile_ai_report_jsonld
    ON profile_ai_report_jsonld.report_id = profile_insight_reports.id
  WHERE profile_insight_reports.profile_id = ?
  ORDER BY profile_insight_reports.created_at DESC
  LIMIT ?
`,
    )
    .all(profileId, limit) as RecentProfileAiReport[];
}

export async function upsertDerivedMetricsComments({
  profileId,
  ffmi,
  ffmiVsFmi,
  compositionFlow,
  compositionTrend,
  recompVector,
  excessFatGauge,
  bodyRatios,
  modelName = null,
}: DerivedMetricsComments) {
  const reportIds = await getLatestReportIds(profileId);

  if (reportIds === null) {
    return;
  }

  await db.prepare(
    `
  UPDATE performance_reports
  SET model_name = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
`,
  ).run(modelName, reportIds.performanceReportId);

  await replaceReportComments("performance_report_comments", reportIds.performanceReportId, [
    { factor: "ffmi", remark: "", comment: ffmi.comment },
    { factor: "ffmi_vs_fmi", remark: "", comment: ffmiVsFmi.comment },
    { factor: "composition_flow", remark: "", comment: compositionFlow.comment },
    {
      factor: "composition_trend",
      remark: "",
      comment: compositionTrend.comment,
    },
    { factor: "recomp_vector", remark: "", comment: recompVector.comment },
    { factor: "excess_fat_gauge", remark: "", comment: excessFatGauge.comment },
    {
      factor: "body_ratio_waist_height",
      remark: bodyRatios.waistHeight.remark,
      comment: bodyRatios.waistHeight.comment,
    },
    {
      factor: "body_ratio_shoulder_waist",
      remark: bodyRatios.shoulderWaist.remark,
      comment: bodyRatios.shoulderWaist.comment,
    },
    {
      factor: "body_ratio_chest_waist",
      remark: bodyRatios.chestWaist.remark,
      comment: bodyRatios.chestWaist.comment,
    },
    {
      factor: "body_ratio_bicep_forearm",
      remark: bodyRatios.bicepForearm.remark,
      comment: bodyRatios.bicepForearm.comment,
    },
    {
      factor: "body_ratio_thigh_calf",
      remark: bodyRatios.thighCalf.remark,
      comment: bodyRatios.thighCalf.comment,
    },
    {
      factor: "body_ratio_neck_calf",
      remark: bodyRatios.neckCalf.remark,
      comment: bodyRatios.neckCalf.comment,
    },
  ]);
}

export async function getProfileEffortScore(
  profileId: ProfileId,
) {
  return await db
    .prepare(
      `
  SELECT
    profile_id AS profileId,
    effort_score AS score,
    effort_remark AS remark,
    model_name AS modelName,
    updated_at AS updatedAt
  FROM profile_insight_reports
  WHERE profile_id = ?
    AND effort_score IS NOT NULL
    AND effort_remark IS NOT NULL
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as ProfileEffortScore | null;
}

export async function getProfileFormaScore(profileId: ProfileId) {
  const metrics = await db    .prepare(
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

export async function getLatestBodyCompositionSnapshot(
  profileId: ProfileId,
) {
  const row = await db    .prepare(
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

export async function getLatestUserBodyMeasurement(
  profileId: ProfileId,
) {
  return await db
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

 function parseJsonField<T>(raw: unknown): T | null {
  try {
    return (typeof raw === "string" ? JSON.parse(raw) : raw) as T;
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

 function parsePerformanceReportComments(
  rows: ReportComment[],
): Omit<DerivedMetricsComments, "profileId" | "modelName"> | null {
  const byFactor = new Map(rows.map((row) => [row.factor, row]));
  const derivedComment = (factor: string): DerivedMetricComment | null => {
    const row = byFactor.get(factor);

    if (row === undefined || row.comment === "") {
      return null;
    }

    return { comment: row.comment };
  };
  const ratioComment = (factor: string): BodyRatioComment | null => {
    const row = byFactor.get(factor);

    if (row === undefined || row.remark === "" || row.comment === "") {
      return null;
    }

    return {
      remark: row.remark,
      comment: row.comment,
    };
  };
  const ffmi = derivedComment("ffmi");
  const ffmiVsFmi = derivedComment("ffmi_vs_fmi");
  const compositionFlow = derivedComment("composition_flow");
  const compositionTrend = derivedComment("composition_trend");
  const recompVector = derivedComment("recomp_vector");
  const excessFatGauge = derivedComment("excess_fat_gauge");
  const waistHeight = ratioComment("body_ratio_waist_height");
  const shoulderWaist = ratioComment("body_ratio_shoulder_waist");
  const chestWaist = ratioComment("body_ratio_chest_waist");
  const bicepForearm = ratioComment("body_ratio_bicep_forearm");
  const thighCalf = ratioComment("body_ratio_thigh_calf");
  const neckCalf = ratioComment("body_ratio_neck_calf");

  if (
    ffmi === null ||
    ffmiVsFmi === null ||
    compositionFlow === null ||
    compositionTrend === null ||
    recompVector === null ||
    excessFatGauge === null ||
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
    ffmi,
    ffmiVsFmi,
    compositionFlow,
    compositionTrend,
    recompVector,
    excessFatGauge,
    bodyRatios: {
      waistHeight,
      shoulderWaist,
      chestWaist,
      bicepForearm,
      thighCalf,
      neckCalf,
    },
  };
}

export async function getProfilePerformance(
  profileId: ProfileId,
) {
  const latestComposition = await db    .prepare(
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

  const initialComposition = await db    .prepare(
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

  const performanceReport = await db    .prepare(
      `
  SELECT
    id,
    fmi,
    ffmi,
    created_at AS createdAt
  FROM performance_reports
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as {
    id: string;
    fmi: number | null;
    ffmi: number | null;
    createdAt: string;
  } | null;

  const compositionTrend = await db    .prepare(
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

  const performanceComments =
    performanceReport === null
      ? []
      : await readReportComments(
          "performance_report_comments",
          performanceReport.id,
        );

  const bodyMeasurements = await listUserBodyMeasurements(profileId);
  const latestMeasurement = bodyMeasurements[0] ?? null;
  const profile = await getProfileById(profileId);
  const fallbackFmi =
    latestComposition === null || profile.heightCm === null
      ? null
      : calculateFmi(latestComposition.fatMassKg, profile.heightCm);
  const fallbackFfmi =
    latestComposition === null || profile.heightCm === null
      ? null
      : calculateFfmi(latestComposition.leanMassKg, profile.heightCm);
  const fmi = performanceReport?.fmi ?? fallbackFmi;
  const ffmi = performanceReport?.ffmi ?? fallbackFfmi;
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
    comments: parsePerformanceReportComments(performanceComments),
  };
}

 function parseFatReportComments(rows: ReportComment[]): FatReportComments {
  const factorMap: Record<string, FatReportFactor> = {
    fat_percent: "fatPercent",
    visceral_subcutaneous_30d_delta: "visceralSubcutaneous30dDelta",
    fat_mass: "fatMass",
    visceral_fat_mass: "visceralFatMass",
    visceral_fat_percent: "visceralFatPercent",
    subcutaneous_fat_mass: "subcutaneousFatMass",
    subcutaneous_fat_ratio: "subcutaneousFatRatio",
  };
  const comments: FatReportComments = {};

  for (const row of rows) {
    const factor = factorMap[row.factor];

    if (factor === undefined || row.remark === "" || row.comment === "") {
      continue;
    }

    comments[factor] = {
      remark: row.remark,
      comment: row.comment,
    };
  }

  return comments;
}

 function buildFatTrendPoints(
  rows: Array<{
    createdAt: string;
    fatMassKg: number;
    visceralFatMassKg: number;
    visceralFatPercent: number;
    subcutaneousFatMassKg: number;
    subcutaneousFatPercent: number;
  }>,
): FatReport["last30Days"] {
  return {
    fatMassKg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.fatMassKg,
    })),
    visceralFatMassKg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.visceralFatMassKg,
    })),
    subcutaneousFatMassKg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.subcutaneousFatMassKg,
    })),
    visceralFatPercent: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.visceralFatPercent,
    })),
    subcutaneousFatPercent: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.subcutaneousFatPercent,
    })),
  };
}

export async function getProfileFatReport(profileId: ProfileId): Promise<FatReport | null> {
  const row = await db    .prepare(
      `
  SELECT
    id,
    profile_id AS profileId,
    body_composition_metrics_id AS bodyCompositionMetricsId,
    fat_percent AS fatPercent,
    visceral_fat_delta_30d_kg AS visceralFatDelta30dKg,
    subcutaneous_fat_delta_30d_kg AS subcutaneousFatDelta30dKg,
    fat_mass_kg AS fatMassKg,
    visceral_fat_mass_kg AS visceralFatMassKg,
    visceral_fat_percent AS visceralFatPercent,
    subcutaneous_fat_mass_kg AS subcutaneousFatMassKg,
    subcutaneous_fat_ratio AS subcutaneousFatRatio,
    created_at AS createdAt
  FROM fat_reports
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as {
    id: string;
    profileId: ProfileId;
    bodyCompositionMetricsId: string;
    fatPercent: number;
    visceralFatDelta30dKg: number;
    subcutaneousFatDelta30dKg: number;
    fatMassKg: number;
    visceralFatMassKg: number;
    visceralFatPercent: number;
    subcutaneousFatMassKg: number;
    subcutaneousFatRatio: number;
    createdAt: string;
  } | null;

  if (row === null) {
    const bodyCompositionMetricsId = await getLatestBodyCompositionMetricsId(profileId);

    if (bodyCompositionMetricsId === null) {
      return null;
    }

    await getOrCreateFatReport(profileId, bodyCompositionMetricsId);
    return await getProfileFatReport(profileId);
  }

  const trendRows = await db    .prepare(
      `
  SELECT
    created_at AS createdAt,
    fat_mass_kg AS fatMassKg,
    ROUND(fat_mass_kg - subcutaneous_fat_mass_kg, 2) AS visceralFatMassKg,
    ROUND(body_fat_pct - subcutaneous_fat_pct, 2) AS visceralFatPercent,
    subcutaneous_fat_mass_kg AS subcutaneousFatMassKg,
    subcutaneous_fat_pct AS subcutaneousFatPercent
  FROM body_composition_metrics_new
  WHERE profile_id = ?
    AND created_at >= datetime('now', '-30 days')
  ORDER BY created_at ASC
`,
    )
    .all(profileId) as Array<{
    createdAt: string;
    fatMassKg: number;
    visceralFatMassKg: number;
    visceralFatPercent: number;
    subcutaneousFatMassKg: number;
    subcutaneousFatPercent: number;
  }>;

  return {
    id: row.id,
    profileId: row.profileId,
    bodyCompositionMetricsId: row.bodyCompositionMetricsId,
    createdAt: row.createdAt,
    metrics: {
      fatPercent: row.fatPercent,
      visceralSubcutaneous30dDelta: {
        visceralFatDeltaKg: row.visceralFatDelta30dKg,
        subcutaneousFatDeltaKg: row.subcutaneousFatDelta30dKg,
      },
      fatMassKg: row.fatMassKg,
      visceralFatMassKg: row.visceralFatMassKg,
      visceralFatPercent: row.visceralFatPercent,
      subcutaneousFatMassKg: row.subcutaneousFatMassKg,
      subcutaneousFatRatio: row.subcutaneousFatRatio,
    },
    last30Days: buildFatTrendPoints(trendRows),
    comments: parseFatReportComments(
      await readReportComments("fat_report_comments", row.id),
    ),
  };
}

 function parseMuscleReportComments(rows: ReportComment[]): MuscleReportComments {
  const factorMap: Record<string, MuscleReportFactor> = {
    total_muscle: "totalMuscle",
    bone_mass: "boneMass",
    muscle_ratio: "muscleRatio",
    skeletal_muscle_mass: "skeletalMuscleMass",
    skeletal_muscle_ratio: "skeletalMuscleRatio",
  };
  const comments: MuscleReportComments = {};

  for (const row of rows) {
    const factor = factorMap[row.factor];

    if (factor === undefined || row.remark === "" || row.comment === "") {
      continue;
    }

    comments[factor] = {
      remark: row.remark,
      comment: row.comment,
    };
  }

  return comments;
}

 function buildMuscleTrendPoints(
  rows: Array<{
    createdAt: string;
    boneMassKg: number;
    muscleRatio: number;
    skeletalMuscleMassKg: number;
    skeletalMuscleRatio: number;
  }>,
): MuscleReport["last30Days"] {
  return {
    boneMassKg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.boneMassKg,
    })),
    muscleRatio: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.muscleRatio,
    })),
    skeletalMuscleMassKg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.skeletalMuscleMassKg,
    })),
    skeletalMuscleRatio: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.skeletalMuscleRatio,
    })),
  };
}

export async function getProfileMuscleReport(
  profileId: ProfileId,
): Promise<MuscleReport | null> {
  const row = await db    .prepare(
      `
  SELECT
    id,
    profile_id AS profileId,
    body_composition_metrics_id AS bodyCompositionMetricsId,
    total_muscle_kg AS totalMuscleKg,
    bone_mass_kg AS boneMassKg,
    muscle_ratio AS muscleRatio,
    skeletal_muscle_mass_kg AS skeletalMuscleMassKg,
    skeletal_muscle_ratio AS skeletalMuscleRatio,
    created_at AS createdAt
  FROM muscle_reports
  WHERE profile_id = ?
  ORDER BY created_at DESC
  LIMIT 1
`,
    )
    .get(profileId) as {
    id: string;
    profileId: ProfileId;
    bodyCompositionMetricsId: string;
    totalMuscleKg: number;
    boneMassKg: number;
    muscleRatio: number;
    skeletalMuscleMassKg: number;
    skeletalMuscleRatio: number;
    createdAt: string;
  } | null;

  if (row === null) {
    const bodyCompositionMetricsId = await getLatestBodyCompositionMetricsId(profileId);

    if (bodyCompositionMetricsId === null) {
      return null;
    }

    await getOrCreateMuscleReport(profileId, bodyCompositionMetricsId);
    return await getProfileMuscleReport(profileId);
  }

  const trendRows = await db    .prepare(
      `
  SELECT
    created_at AS createdAt,
    ROUND(MAX(fat_free_mass_kg - muscle_mass_kg, 0), 2) AS boneMassKg,
    muscle_rate_pct AS muscleRatio,
    skeletal_muscle_kg AS skeletalMuscleMassKg,
    CASE
      WHEN fat_mass_kg + fat_free_mass_kg <= 0 THEN 0
      ELSE ROUND(skeletal_muscle_kg / (fat_mass_kg + fat_free_mass_kg) * 100, 2)
    END AS skeletalMuscleRatio
  FROM body_composition_metrics_new
  WHERE profile_id = ?
    AND created_at >= datetime('now', '-30 days')
  ORDER BY created_at ASC
`,
    )
    .all(profileId) as Array<{
    createdAt: string;
    boneMassKg: number;
    muscleRatio: number;
    skeletalMuscleMassKg: number;
    skeletalMuscleRatio: number;
  }>;

  return {
    id: row.id,
    profileId: row.profileId,
    bodyCompositionMetricsId: row.bodyCompositionMetricsId,
    createdAt: row.createdAt,
    metrics: {
      totalMuscleKg: row.totalMuscleKg,
      boneMassKg: row.boneMassKg,
      muscleRatio: row.muscleRatio,
      skeletalMuscleMassKg: row.skeletalMuscleMassKg,
      skeletalMuscleRatio: row.skeletalMuscleRatio,
    },
    last30Days: buildMuscleTrendPoints(trendRows),
    comments: parseMuscleReportComments(
      await readReportComments("muscle_report_comments", row.id),
    ),
  };
}

export async function getWeightSummary(profileId: ProfileId) {
  const currentWeightRow = await db    .prepare(
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

  const goalWeightRow = await db    .prepare(
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

  const summaryRow = await db    .prepare(
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

  const last30DaysWeightTrend = await db    .prepare(
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

export async function listUsers() {
  const rows = await db    .prepare(
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

export async function listUsersByAccountId(accountId: AccountId) {
  const rows = await db    .prepare(
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
  WHERE profiles.account_id = ?
  ORDER BY profiles.created_at DESC
`,
    )
    .all(accountId) as UserRow[];

  return rows.map((row) => ({
    ...row,
    isPrimary: row.isPrimary === 1,
  }));
}

export async function getProfileById(id: ProfileId) {
  const row = await db    .prepare(
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
