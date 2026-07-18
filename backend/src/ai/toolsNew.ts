import { tool } from "langchain";
import * as z from "zod";
import {
  BODY_COMPOSITION_METRICS_NEW_FACTORS,
  db,
  getBodyCompositionMeasurementByIdV2,
} from "../db/db";
import {
  getProfileInsightReportSource,
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
  "balanced",
  "lean",
  "building",
]);

/** green=strong, yellow=mild opp, orange=meaningful, red=highest priority */
const factor_color_enum = z.enum(["red", "orange", "yellow", "green"]);
const trends = z.enum(BODY_COMPOSITION_METRICS_NEW_FACTORS);

const concise = z.string().trim().min(1).max(180);
const shortLabel = z.string().trim().min(1).max(60);

const remark_schema = z.object({
  marker: marker_enum,
  factor_color: factor_color_enum,
  text: concise,
});

/** Shared insight card: short title/headline, one-sentence comment + remark. */
const insight_card_schema = z.object({
  title: shortLabel,
  headline: concise,
  comment: concise,
  remark: remark_schema,
});

/** Shared display card for performance/fat/muscle sections. */
const display_card_schema = z.object({
  heading: shortLabel,
  title: shortLabel,
  comment: concise,
  remark: remark_schema,
});

const gauge_card_schema = display_card_schema.extend({
  factor_color: factor_color_enum,
}).refine(
  (card) => card.factor_color === card.remark.factor_color,
  {
    message: "factor_color must match remark.factor_color",
    path: ["remark", "factor_color"],
  },
);

const PROFILE_PROGRESS_TRENDS = [
  "body_fat_pct",
  "fat_mass_kg",
  "muscle_mass_kg",
] as const;
const progress_trends = z.enum(PROFILE_PROGRESS_TRENDS);

type ProfileAiReportPayload = z.infer<typeof insights_schema>;
type PreprocessMetadata = {
  value?: unknown;
  trends?: unknown;
  evidence?: ReportEvidence;
};
type ReportEvidence = {
  asOf: string;
  periodStart?: string | null;
  periodEnd?: string;
  readingCount: number;
  confidence: "low" | "medium" | "high";
};
type WithPreprocess<T> = T & {
  preprocess: PreprocessMetadata;
};

function withValue<T extends Record<string, unknown>>(
  factor: T,
  value: unknown,
  evidence?: ReportEvidence,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { value, ...(evidence ? { evidence } : {}) },
  };
}

function withTrends<T extends Record<string, unknown>>(
  factor: T,
  trends: unknown,
  evidence?: ReportEvidence,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { trends, ...(evidence ? { evidence } : {}) },
  };
}

function withValueAndTrends<T extends Record<string, unknown>>(
  factor: T,
  value: unknown,
  trends: unknown,
  evidence?: ReportEvidence,
): WithPreprocess<T> {
  return {
    ...factor,
    preprocess: { value, trends, ...(evidence ? { evidence } : {}) },
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
  evidence?: ReportEvidence;
};

type ProfileAiReportResolvedSources = {
  performanceReport: ProfilePerformance | null;
  fatReport: FatReport | null;
  muscleReport: MuscleReport | null;
  progressTrends: BodyCompositionProgressTrends;
  latestBodyComposition: Record<string, unknown> | null;
  evidence: ReportEvidence;
};

const emptyProgressTrends: BodyCompositionProgressTrends = {
  body_fat_pct: [],
  fat_mass_kg: [],
  muscle_mass_kg: [],
};

function progressConsistency(
  progressTrends: BodyCompositionProgressTrends,
): { score: number; signals: Record<string, number | null> } {
  const delta = (points: BodyCompositionProgressTrendPoint[]) =>
    points.length < 2
      ? null
      : Number((points.at(-1)!.value - points[0]!.value).toFixed(2));
  const signals = {
    body_fat_pct: delta(progressTrends.body_fat_pct),
    fat_mass_kg: delta(progressTrends.fat_mass_kg),
    muscle_mass_kg: delta(progressTrends.muscle_mass_kg),
  };
  const directions = [
    signals.body_fat_pct === null ? null : -Math.sign(signals.body_fat_pct),
    signals.fat_mass_kg === null ? null : -Math.sign(signals.fat_mass_kg),
    signals.muscle_mass_kg === null ? null : Math.sign(signals.muscle_mass_kg),
  ].filter((value): value is number => value !== null);
  const score = directions.length === 0
    ? 50
    : Math.round(
        50 + directions.reduce((sum, direction) => sum + direction * 12, 0),
      );
  return { score: Math.min(100, Math.max(0, score)), signals };
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
          .array(progress_trends)
          .max(3)
          .describe("Body-comp metric keys supporting this progress read"),
      })
      .describe("Overall progress pattern"),
    lever: insight_card_schema.describe("Single highest-ROI next move"),
    factor: z.object({
      factor: trends.describe(
        "Outstanding metric key or best improvement potential",
      ),
      factor_color: factor_color_enum,
      comment: concise,
      remark: remark_schema,
    }).refine(
      (factor) => factor.factor_color === factor.remark.factor_color,
      {
        message: "factor_color must match remark.factor_color",
        path: ["remark", "factor_color"],
      },
    ),
    physique_archetype: z.object({
      title: shortLabel,
      headline: concise,
      comment: concise,
      body_type: body_type_enum,
    }),
    effort_score: z.object({
      title: shortLabel,
      headline: concise,
      score: z.number().int().min(0).max(100),
      comment: concise,
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
    body_ratios: display_card_schema.describe(
      "Available waist-to-height and torso ratios; acknowledge missing values",
    ),
  }),
  fat: z.object({
    fat_ratio: gauge_card_schema.describe("Fat ratio gauge"),
    fat_ratio_trend: display_card_schema.describe("Fat ratio trend"),
    fat_distribution_context: display_card_schema.describe(
      "Visceral device index and subcutaneous fat estimates shown separately; never compare their magnitudes because units differ",
    ),
    visceral_trend: display_card_schema.describe("Visceral fat trend"),
    subcutaneous_fat_mass_trend: display_card_schema.describe(
      "Subcutaneous fat mass trend",
    ),
    fat_mass_trend: display_card_schema.describe("Fat mass trend"),
    waist_context: display_card_schema.describe(
      "Waist-to-height context when circumference data is available",
    ),
  }),
  muscle: z.object({
    skeletal_muscle_gauge: gauge_card_schema.describe(
      "Skeletal muscle % gauge",
    ),
    muscle_mass: display_card_schema.describe("Muscle mass"),
    lean_mass_balance: display_card_schema.describe(
      "Fat-free mass not classified as muscle; never call this bone mass",
    ),
    muscle_ratio_trend: display_card_schema.describe("Muscle % trend"),
    skeletal_muscle_mass_trend: display_card_schema.describe(
      "Skeletal muscle mass trend",
    ),
    hydration_context: display_card_schema.describe(
      "Water and protein percentages as supporting BIA context, not a diagnosis",
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
  evidence,
}: ProfileAiReportPreprocessSources = {}) {
  const consistency = progressConsistency(progressTrends);
  return {
    insights: {
      ...insights,
      report_context: evidence ?? null,
      factor: withValue(
        insights.factor,
        latestBodyComposition?.[insights.factor.factor] ?? null,
        evidence,
      ),
      progress: withTrends(
        insights.progress,
        Object.fromEntries(
          insights.progress.trends.map((metric) => [metric, progressTrends[metric]]),
        ),
        evidence,
      ),
      effort_score: {
        ...insights.effort_score,
        score: consistency.score,
        preprocess: {
          trends: consistency.signals,
          ...(evidence ? { evidence } : {}),
        },
      },
    },
    performance: {
      ffmi_gauge: withValue(performance.ffmi_gauge, performanceReport?.ffmi ?? null, evidence),
      fmi_vs_ffmi: withValue(
        performance.fmi_vs_ffmi,
        performanceReport?.ffmiVsFmi ?? null,
        evidence,
      ),
      body_composition_flow: withValue(
        performance.body_composition_flow,
        performanceReport?.bodyComposition ?? null,
        evidence,
      ),
      composition_trends: withTrends(
        performance.composition_trends,
        performanceReport?.compositionTrends ?? {
          leanMass30Days: [],
          fatMass30Days: [],
        },
        evidence,
      ),
      target_vs_current_weight: withValue(
        performance.target_vs_current_weight,
        performanceReport?.weightPair ?? null,
        evidence,
      ),
      excess_fat_gauge: withValue(
        performance.excess_fat_gauge,
        performanceReport?.excessFatGauge ?? null,
        evidence,
      ),
      body_ratios: withValue(
        performance.body_ratios,
        performanceReport?.lastBodyRatios ?? null,
        evidence,
      ),
    },
    fat: {
      fat_ratio: withValueAndTrends(
        fat.fat_ratio,
        fatReport?.metrics.fatPercent ?? null,
        { fatPercent: fatReport?.last30Days.fatPercent ?? [] },
        evidence,
      ),
      fat_ratio_trend: withValueAndTrends(
        fat.fat_ratio_trend,
        fatReport?.metrics.fatPercent ?? null,
        { fatPercent: fatReport?.last30Days.fatPercent ?? [] },
        evidence,
      ),
      fat_distribution_context: withValueAndTrends(
        fat.fat_distribution_context,
        {
          visceralFatIndex: fatReport?.metrics.visceralFatIndex ?? null,
          subcutaneousFatMassKg:
            fatReport?.metrics.subcutaneousFatMassKg ?? null,
          subcutaneousFatRatio:
            fatReport?.metrics.subcutaneousFatRatio ?? null,
          deltas: fatReport?.metrics.fatDistribution30dDelta ?? null,
        },
        {
          visceralFatIndex: fatReport?.last30Days.visceralFatIndex ?? [],
          subcutaneousFatMassKg:
            fatReport?.last30Days.subcutaneousFatMassKg ?? [],
        },
        evidence,
      ),
      visceral_trend: withValueAndTrends(
        fat.visceral_trend,
        fatReport?.metrics.visceralFatIndex ?? null,
        {
          visceralFatIndex: fatReport?.last30Days.visceralFatIndex ?? [],
        },
        evidence,
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
        evidence,
      ),
      fat_mass_trend: withValueAndTrends(
        fat.fat_mass_trend,
        fatReport?.metrics.fatMassKg ?? null,
        { fatMassKg: fatReport?.last30Days.fatMassKg ?? [] },
        evidence,
      ),
      waist_context: withValue(
        fat.waist_context,
        performanceReport?.lastBodyRatios.waistHeight ?? null,
        evidence,
      ),
    },
    muscle: {
      skeletal_muscle_gauge: withValue(
        muscle.skeletal_muscle_gauge,
        muscleReport?.metrics.skeletalMuscleRatio ?? null,
        evidence,
      ),
      muscle_mass: withValueAndTrends(
        muscle.muscle_mass,
        muscleReport?.metrics.totalMuscleKg ?? null,
        { muscleMassKg: muscleReport?.last30Days.muscleMassKg ?? [] },
        evidence,
      ),
      lean_mass_balance: withValueAndTrends(
        muscle.lean_mass_balance,
        muscleReport?.metrics.leanNonMuscleMassKg ?? null,
        { leanNonMuscleMassKg: muscleReport?.last30Days.leanNonMuscleMassKg ?? [] },
        evidence,
      ),
      muscle_ratio_trend: withValueAndTrends(
        muscle.muscle_ratio_trend,
        muscleReport?.metrics.muscleRatio ?? null,
        { muscleRatio: muscleReport?.last30Days.muscleRatio ?? [] },
        evidence,
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
        evidence,
      ),
      hydration_context: withValue(
        muscle.hydration_context,
        {
          waterPct: latestBodyComposition?.water_pct ?? null,
          proteinPct: latestBodyComposition?.protein_pct ?? null,
        },
        evidence,
      ),
    },
  };
}

export async function getProfileAiProgressTrends(
  profileId: string,
  asOf: string = new Date().toISOString(),
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
    AND created_at <= ?
    AND created_at >= ?::timestamptz - INTERVAL '30 days'
  ORDER BY created_at ASC
`,
    )
    .all(profileId, asOf, asOf)) as Array<{
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
  reportId: string,
): Promise<ProfileAiReportResolvedSources> {
  const source = await getProfileInsightReportSource({ reportId, profileId });
  const [
    performanceReport,
    fatReport,
    muscleReport,
    progressTrends,
    latestBodyComposition,
  ] =
    await Promise.all([
      getProfilePerformance(
        profileId,
        source.bodyCompositionMetricsId,
        typeof source.profileContext?.heightCm === "number"
          ? source.profileContext.heightCm
          : null,
      ),
      getProfileFatReport(profileId, source.bodyCompositionMetricsId),
      getProfileMuscleReport(profileId, source.bodyCompositionMetricsId),
      getProfileAiProgressTrends(profileId, source.asOf),
      getBodyCompositionMeasurementByIdV2(
        profileId,
        source.bodyCompositionMetricsId,
      ).then((table) =>
        table === null ? null : Object.fromEntries(table.rows),
      ),
    ]);

  const readingCount = Math.max(
    progressTrends.body_fat_pct.length,
    progressTrends.fat_mass_kg.length,
    progressTrends.muscle_mass_kg.length,
  );
  return {
    performanceReport,
    fatReport,
    muscleReport,
    progressTrends,
    latestBodyComposition,
    evidence: {
      asOf: source.asOf,
      periodStart: progressTrends.body_fat_pct[0]?.createdAt ?? null,
      periodEnd: source.asOf,
      readingCount,
      confidence: readingCount >= 6 ? "high" : readingCount >= 3 ? "medium" : "low",
    },
  };
}

export function createTools(reportId: string, profileId: string) {
  const profile_ai_report = tool(
    async ({ insights, performance, fat, muscle }) => {
      // console.log({ reportId, profileId, insights, performance, fat, muscle });
      const sources = await getProfileAiReportPreprocessSources(profileId, reportId);
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
        "Generate the complete structured profile AI report. Cards: short title/headline/heading, one-sentence comment, remark{marker,factor_color,text}. Markers: trend_up|trend_down|ai_recommendation|caution|complement. factor_color: green|yellow|orange|red (strong→highest priority). When a card also has a top-level factor_color, it must match remark.factor_color. Supportive coach tone; no clinical/risk language.",
      schema: insights_schema,
    },
  );

  return [profile_ai_report];
}
