import { tool } from "langchain";
import * as z from "zod";
import {
  BODY_COMPOSITION_METRICS_NEW_FACTORS,
  db,
  getLatestBodyCompositionMeasurement,
} from "../db/db";
import {
  getProfileFatReport,
  getProfileMuscleReport,
  getProfilePerformance,
  upsertProfileAiReportJsonLd,
  type FatReport,
  type MuscleReport,
  type ProfilePerformance,
} from "../db/commands";

const marker_enum = z.enum([
  "trend_up",
  "trend_down",
  "ai_recommendation",
  "caution",
  "complement",
]);

const body_type_enum = z.enum([
  "muscular",
  "fit",
  "normal",
  "skinny fat",
  "overweight",
  "obese",
]);

/** green=strong, yellow=mild opp, orange=meaningful, red=highest priority */
const factor_color_enum = z.enum(["red", "orange", "yellow", "green"]);
const trends = z.enum(BODY_COMPOSITION_METRICS_NEW_FACTORS);

const remark_schema = z.object({
  marker: marker_enum,
  text: z.string(),
});

/** Shared insight card: short title/headline, one-sentence comment + remark. */
const insight_card_schema = z.object({
  title: z.string(),
  headline: z.string(),
  comment: z.string(),
  remark: remark_schema,
});

/** Shared display card for performance/fat/muscle sections. */
const display_card_schema = z.object({
  heading: z.string(),
  title: z.string(),
  comment: z.string(),
  remark: remark_schema,
});

const gauge_card_schema = display_card_schema.extend({
  factor_color: factor_color_enum,
});

const PROFILE_PROGRESS_TRENDS = [
  "body_fat_pct",
  "fat_mass_kg",
  "muscle_mass_kg",
] as const;

type ProfileAiReportPayload = z.infer<typeof insights_schema>;
type PreprocessMetadata = {
  value?: unknown;
  trends?: unknown;
};
type WithPreprocess<T> = T & {
  preprocess: PreprocessMetadata;
};

function withValue<T extends Record<string, unknown>>(
  factor: T,
  value: unknown,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { value },
  };
}

function withTrends<T extends Record<string, unknown>>(
  factor: T,
  trends: unknown,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { trends },
  };
}

function withValueAndTrends<T extends Record<string, unknown>>(
  factor: T,
  value: unknown,
  trends: unknown,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { value, trends },
  };
}

type BodyCompositionProgressTrendPoint = {
  createdAt: string;
  value: number;
};

type BodyCompositionProgressTrends = Record<
  (typeof PROFILE_PROGRESS_TRENDS)[number],
  BodyCompositionProgressTrendPoint[]
>;

type ProfileAiReportPreprocessSources = {
  performanceReport?: ProfilePerformance | null;
  fatReport?: FatReport | null;
  muscleReport?: MuscleReport | null;
  progressTrends?: BodyCompositionProgressTrends;
  latestBodyComposition?: Record<string, unknown> | null;
};

type ProfileAiReportResolvedSources = {
  performanceReport: ProfilePerformance | null;
  fatReport: FatReport | null;
  muscleReport: MuscleReport | null;
  progressTrends: BodyCompositionProgressTrends;
  latestBodyComposition: Record<string, unknown> | null;
};

const emptyProgressTrends: BodyCompositionProgressTrends = {
  body_fat_pct: [],
  fat_mass_kg: [],
  muscle_mass_kg: [],
};

function logOptionalSourceError(source: string, error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  console.warn(`[profile_ai_report] ${source} unavailable`, { message });
}

async function optionalSource<T>(
  source: string,
  load: () => Promise<T>,
  fallback: T,
): Promise<T> {
  try {
    return await load();
  } catch (error) {
    logOptionalSourceError(source, error);
    return fallback;
  }
}

export const insights_schema = z.object({
  insights: z.object({
    overview: insight_card_schema.describe(
      "Achievement / potential overview",
    ),
    foundation: insight_card_schema.describe("What is already working"),
    momentum: insight_card_schema.describe("Strongest recent trend signal"),
    progress: insight_card_schema
      .extend({
        trends: z
          .array(trends)
          .describe("Body-comp metric keys supporting this progress read"),
      })
      .describe("Overall progress pattern"),
    lever: insight_card_schema.describe("Single highest-ROI next move"),
    factor: z.object({
      factor: trends.describe(
        "Outstanding metric key or best improvement potential",
      ),
      factor_color: factor_color_enum,
      comment: z.string(),
      remark: remark_schema,
    }),
    physique_archetype: z.object({
      title: z.string(),
      headline: z.string(),
      comment: z.string(),
      body_type: body_type_enum,
    }),
    effort_score: z.object({
      title: z.string(),
      headline: z.string(),
      score: z.number().int().min(0).max(100),
      comment: z.string(),
      remark: remark_schema,
    }),
  }),
  performance: z.object({
    ffmi_gauge: gauge_card_schema.describe("FFMI lean-mass gauge"),
    fmi_vs_ffmi: display_card_schema.describe("FMI vs FFMI map"),
    body_composition_flow: display_card_schema.describe(
      "Lean vs fat contribution to weight",
    ),
    composition_trends: display_card_schema.describe(
      "Recent lean change vs fat change",
    ),
    target_vs_current_weight: display_card_schema.describe(
      "Current vs target weight gap",
    ),
    excess_fat_gauge: display_card_schema.describe(
      "Excess fat vs target (supportive)",
    ),
  }),
  fat: z.object({
    fat_ratio: gauge_card_schema.describe("Fat ratio gauge"),
    fat_ratio_trend: display_card_schema.describe("Fat ratio trend"),
    visceral_vs_subcutaneous: display_card_schema.describe(
      "Visceral vs subcutaneous balance",
    ),
    visceral_trend: display_card_schema.describe("Visceral fat trend"),
    subcutaneous_fat_mass_trend: display_card_schema.describe(
      "Subcutaneous fat mass trend",
    ),
    fat_mass_trend: display_card_schema.describe("Fat mass trend"),
  }),
  muscle: z.object({
    skeletal_muscle_gauge: gauge_card_schema.describe(
      "Skeletal muscle % gauge",
    ),
    muscle_mass: display_card_schema.describe("Muscle mass"),
    bone_mass_trend: display_card_schema.describe("Bone mass trend"),
    muscle_ratio_trend: display_card_schema.describe("Muscle % trend"),
    skeletal_muscle_mass_trend: display_card_schema.describe(
      "Skeletal muscle mass trend",
    ),
  }),
});

export function preprocessProfileAiReportPayload({
  insights,
  performance,
  fat,
  muscle,
}: ProfileAiReportPayload, {
  performanceReport = null,
  fatReport = null,
  muscleReport = null,
  progressTrends = emptyProgressTrends,
  latestBodyComposition = null,
}: ProfileAiReportPreprocessSources = {}) {
  return {
    insights: {
      ...insights,
      factor: withValue(
        insights.factor,
        latestBodyComposition?.[insights.factor.factor] ?? null,
      ),
      progress: withTrends(
        {
          ...insights.progress,
          trends: [...PROFILE_PROGRESS_TRENDS],
        },
        progressTrends,
      ),
    },
    performance: {
      ffmi_gauge: withValue(performance.ffmi_gauge, performanceReport?.ffmi ?? null),
      fmi_vs_ffmi: withValue(
        performance.fmi_vs_ffmi,
        performanceReport?.ffmiVsFmi ?? null,
      ),
      body_composition_flow: withValue(
        performance.body_composition_flow,
        performanceReport?.bodyComposition ?? null,
      ),
      composition_trends: withTrends(
        performance.composition_trends,
        performanceReport?.compositionTrends ?? {
          leanMass30Days: [],
          fatMass30Days: [],
        },
      ),
      target_vs_current_weight: withValue(
        performance.target_vs_current_weight,
        performanceReport?.weightPair ?? null,
      ),
      excess_fat_gauge: withValue(
        performance.excess_fat_gauge,
        performanceReport?.excessFatGauge ?? null,
      ),
    },
    fat: {
      fat_ratio: withValueAndTrends(
        fat.fat_ratio,
        fatReport?.metrics.fatPercent ?? null,
        { fatPercent: fatReport?.last30Days.fatPercent ?? [] },
      ),
      fat_ratio_trend: withValueAndTrends(
        fat.fat_ratio_trend,
        fatReport?.metrics.fatPercent ?? null,
        { fatPercent: fatReport?.last30Days.fatPercent ?? [] },
      ),
      visceral_vs_subcutaneous: withValueAndTrends(
        fat.visceral_vs_subcutaneous,
        fatReport?.metrics.visceralSubcutaneous30dDelta ?? null,
        {
          visceralFatMassKg: fatReport?.last30Days.visceralFatMassKg ?? [],
          subcutaneousFatMassKg:
            fatReport?.last30Days.subcutaneousFatMassKg ?? [],
        },
      ),
      visceral_trend: withValueAndTrends(
        fat.visceral_trend,
        fatReport?.metrics.visceralFatMassKg ?? null,
        {
          visceralFatMassKg: fatReport?.last30Days.visceralFatMassKg ?? [],
          visceralFatPercent: fatReport?.last30Days.visceralFatPercent ?? [],
        },
      ),
      subcutaneous_fat_mass_trend: withValueAndTrends(
        fat.subcutaneous_fat_mass_trend,
        fatReport?.metrics.subcutaneousFatMassKg ?? null,
        {
          subcutaneousFatMassKg:
            fatReport?.last30Days.subcutaneousFatMassKg ?? [],
          subcutaneousFatPercent:
            fatReport?.last30Days.subcutaneousFatPercent ?? [],
        },
      ),
      fat_mass_trend: withValueAndTrends(
        fat.fat_mass_trend,
        fatReport?.metrics.fatMassKg ?? null,
        { fatMassKg: fatReport?.last30Days.fatMassKg ?? [] },
      ),
    },
    muscle: {
      skeletal_muscle_gauge: withValue(
        muscle.skeletal_muscle_gauge,
        muscleReport?.metrics.skeletalMuscleRatio ?? null,
      ),
      muscle_mass: withValueAndTrends(
        muscle.muscle_mass,
        muscleReport?.metrics.totalMuscleKg ?? null,
        { muscleMassKg: muscleReport?.last30Days.muscleMassKg ?? [] },
      ),
      bone_mass_trend: withValueAndTrends(
        muscle.bone_mass_trend,
        muscleReport?.metrics.boneMassKg ?? null,
        { boneMassKg: muscleReport?.last30Days.boneMassKg ?? [] },
      ),
      muscle_ratio_trend: withValueAndTrends(
        muscle.muscle_ratio_trend,
        muscleReport?.metrics.muscleRatio ?? null,
        { muscleRatio: muscleReport?.last30Days.muscleRatio ?? [] },
      ),
      skeletal_muscle_mass_trend: withValueAndTrends(
        muscle.skeletal_muscle_mass_trend,
        muscleReport?.metrics.skeletalMuscleMassKg ?? null,
        {
          skeletalMuscleMassKg:
            muscleReport?.last30Days.skeletalMuscleMassKg ?? [],
          skeletalMuscleRatio:
            muscleReport?.last30Days.skeletalMuscleRatio ?? [],
        },
      ),
    },
  };
}

export async function getProfileAiProgressTrends(
  profileId: string,
): Promise<BodyCompositionProgressTrends> {
  const rows = (await db
    .prepare(
      `
  SELECT
    created_at AS createdAt,
    body_fat_pct AS bodyFatPct,
    fat_mass_kg AS fatMassKg,
    muscle_mass_kg AS muscleMassKg
  FROM body_composition_metrics_new
  WHERE profile_id = ?
    AND created_at >= datetime('now', '-30 days')
  ORDER BY created_at ASC
`,
    )
    .all(profileId)) as Array<{
    createdAt: string;
    bodyFatPct: number;
    fatMassKg: number;
    muscleMassKg: number;
  }>;

  return {
    body_fat_pct: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.bodyFatPct,
    })),
    fat_mass_kg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.fatMassKg,
    })),
    muscle_mass_kg: rows.map((row) => ({
      createdAt: row.createdAt,
      value: row.muscleMassKg,
    })),
  };
}

export async function getProfileAiReportPreprocessSources(
  profileId: string,
): Promise<ProfileAiReportResolvedSources> {
  const [
    performanceReport,
    fatReport,
    muscleReport,
    progressTrends,
    latestBodyComposition,
  ] =
    await Promise.all([
      optionalSource("performance report", () => getProfilePerformance(profileId), null),
      optionalSource("fat report", () => getProfileFatReport(profileId), null),
      optionalSource("muscle report", () => getProfileMuscleReport(profileId), null),
      optionalSource(
        "progress trends",
        () => getProfileAiProgressTrends(profileId),
        emptyProgressTrends,
      ),
      optionalSource(
        "latest body composition",
        async () =>
          (await getLatestBodyCompositionMeasurement(profileId)) as Record<
            string,
            unknown
          > | null,
        null,
      ),
    ]);

  return {
    performanceReport,
    fatReport,
    muscleReport,
    progressTrends,
    latestBodyComposition,
  };
}

export function createTools(reportId: string, profileId: string) {
  const profile_ai_report = tool(
    async ({ insights, performance, fat, muscle }) => {
      // console.log({ reportId, profileId, insights, performance, fat, muscle });
      const sources = await getProfileAiReportPreprocessSources(profileId);
      const preprocessed = preprocessProfileAiReportPayload({
        insights,
        performance,
        fat,
        muscle,
      }, sources);
      await upsertProfileAiReportJsonLd({
        reportId,
        profileId,
        data: preprocessed,
      });
      console.log(JSON.stringify({ preprocessed }, null, 2));

      return "Generated insights.";
    },
    {
      name: "profile_ai_report",
      description:
        "Generate the complete structured profile AI report. Cards: short title/headline/heading, one-sentence comment, remark{marker,text}. Markers: trend_up|trend_down|ai_recommendation|caution|complement. factor_color: green|yellow|orange|red (strong→highest priority). Supportive coach tone; no clinical/risk language.",
      schema: insights_schema,
    },
  );

  return [profile_ai_report];
}
