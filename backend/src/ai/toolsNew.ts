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

export const PROFILE_INSIGHT_TRENDS = [
  "body_fat_pct",
  "fat_mass_kg",
  "muscle_mass_kg",
  "skeletal_muscle_kg",
  "visceral_fat",
  "subcutaneous_fat_mass_kg",
] as const;
const insight_trends = z.enum(PROFILE_INSIGHT_TRENDS);

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

export type BodyCompositionInsightTrends = Record<
  (typeof PROFILE_INSIGHT_TRENDS)[number],
  BodyCompositionProgressTrendPoint[]
>;

export type ProfileAiTrendSources = {
  fullHistory: BodyCompositionInsightTrends;
  recent30Days: BodyCompositionInsightTrends;
};

type BodyCompositionInsightTrendRow = {
  createdAt: string;
  bodyFatPct: number;
  fatMassKg: number;
  muscleMassKg: number;
  skeletalMuscleKg: number;
  visceralFat: number;
  subcutaneousFatMassKg: number;
};

type ProfileAiReportPreprocessSources = {
  performanceReport?: ProfilePerformance | null;
  fatReport?: FatReport | null;
  muscleReport?: MuscleReport | null;
  trendSources?: ProfileAiTrendSources;
  latestBodyComposition?: Record<string, unknown> | null;
  evidence?: ReportEvidence;
};

type ProfileAiReportResolvedSources = {
  performanceReport: ProfilePerformance | null;
  fatReport: FatReport | null;
  muscleReport: MuscleReport | null;
  trendSources: ProfileAiTrendSources;
  latestBodyComposition: Record<string, unknown> | null;
  evidence: ReportEvidence;
};

const emptyInsightTrends: BodyCompositionInsightTrends = {
  body_fat_pct: [],
  fat_mass_kg: [],
  muscle_mass_kg: [],
  skeletal_muscle_kg: [],
  visceral_fat: [],
  subcutaneous_fat_mass_kg: [],
};

const emptyTrendSources: ProfileAiTrendSources = {
  fullHistory: emptyInsightTrends,
  recent30Days: emptyInsightTrends,
};

/**
 * Formats the lean non-muscle series used for muscle.bone_mass_trend so the
 * agent can write about it. Bone mass here is fat_free_mass - muscle_mass.
 */
export function formatBoneMassTrendForAgent(
  muscleReport: MuscleReport | null | undefined,
): string {
  const currentKg = muscleReport?.metrics.leanNonMuscleMassKg ?? null;
  const points = muscleReport?.last30Days.leanNonMuscleMassKg ?? [];

  if (currentKg === null && points.length === 0) {
    return "Bone Mass Trend - no lean non-muscle (bone-mass proxy) readings available yet.";
  }

  const lines = [
    "Bone Mass Trend - lean non-muscle mass kg (fat_free_mass_kg - muscle_mass_kg). Use this series for muscle.bone_mass_trend.",
    `current_kg\t${currentKg ?? "null"}`,
    "created_at\tvalue_kg",
    ...points.map((point) => `${point.createdAt}\t${point.value}`),
  ];

  return lines.join("\n");
}

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
    key_trend: insight_card_schema.extend({
      metric: insight_trends.describe(
        "One body-composition metric for the all-time trend",
      ),
    }).describe("One all-time body-composition trend"),
    progress: insight_card_schema
      .extend({
        trends: z
          .array(insight_trends)
          .min(1)
          .max(3)
          .describe("Body-comp metric keys supporting this progress read"),
      })
      .describe("Recent 30-day progress direction"),
  }).strict(),
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
      "Visceral device index and subcutaneous fat estimates shown separately; never compare their magnitudes because units differ",
    ),
    visceral_trend: display_card_schema.describe("Visceral fat trend"),
    subcutaneous_fat_mass_trend: display_card_schema.describe(
      "Subcutaneous fat mass trend",
    ),
    fat_mass_trend: display_card_schema.describe("Fat mass trend"),
  }),
  muscle: z.object({
    skeletal_muscle_gauge: z.object({
      heading: z
        .string()
        .describe("Short display heading for skeletal muscle percentage."),
      title: z
        .string()
        .describe("Short title interpreting skeletal muscle percentage."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the skeletal muscle percentage gauge result.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what skeletal muscle percentage means for the user's physique.",
      ),
      factor_color: factor_color_enum.describe(
        "AI-selected gauge status: green is strong, yellow is a mild opportunity, orange needs meaningful attention, and red is the highest-priority opportunity.",
      ),
    }),
    muscle_mass: z.object({
      heading: z.string().describe("Short display heading for muscle mass."),
      title: z
        .string()
        .describe("Short title interpreting the user's muscle mass."),
      comment: z
        .string()
        .describe("One concise sentence explaining the muscle mass result."),
      remark: remark_schema.describe(
        "One concise coaching sentence interpreting muscle mass in a supportive way.",
      ),
    }),
    bone_mass_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for bone mass trend."),
      title: z
        .string()
        .describe(
          "Short title interpreting bone mass trend from the provided lean non-muscle series. Never claim the series is missing when points are present.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how bone mass (lean non-muscle mass) is trending from the provided series.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the bone mass trend means.",
      ),
    }),
    muscle_ratio_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for muscle percentage trend."),
      title: z
        .string()
        .describe("Short title interpreting the muscle percentage trend."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how muscle percentage is trending.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the muscle percentage trend means.",
      ),
    }),
    skeletal_muscle_mass_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for skeletal muscle mass trend."),
      title: z
        .string()
        .describe("Short title interpreting skeletal muscle mass trend."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how skeletal muscle mass is trending.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the skeletal muscle mass trend means.",
      ),
    }),
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
  trendSources = emptyTrendSources,
  latestBodyComposition = null,
  evidence,
}: ProfileAiReportPreprocessSources = {}) {
  const selectedRecent = Object.fromEntries(
    insights.progress.trends.map((metric) => [
      metric,
      normalizeProgressTrend(trendSources.recent30Days[metric]),
    ]),
  );
  const keyTrendPoints = trendSources.fullHistory[insights.key_trend.metric];
  const progressEvidencePoints = insights.progress.trends
    .map((metric) => trendSources.recent30Days[metric])
    .sort((left, right) => right.length - left.length)[0] ?? [];
  return {
    insights: {
      factor: withValue(
        insights.factor,
        latestBodyComposition?.[insights.factor.factor] ?? null,
        evidence,
      ),
      key_trend: withTrends(
        withInsufficientHistoryCopy(insights.key_trend, keyTrendPoints.length),
        { [insights.key_trend.metric]: keyTrendPoints },
        trendEvidence(evidence, keyTrendPoints),
      ),
      progress: withTrends(
        withInsufficientHistoryCopy(
          insights.progress,
          Math.max(...insights.progress.trends.map(
            (metric) => trendSources.recent30Days[metric].length,
          )),
        ),
        selectedRecent,
        trendEvidence(evidence, progressEvidencePoints),
      ),
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
      visceral_vs_subcutaneous: withValueAndTrends(
        fat.visceral_vs_subcutaneous,
        fatReport?.metrics.fatDistribution30dDelta ?? null,
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
      bone_mass_trend: withValueAndTrends(
        muscle.bone_mass_trend,
        muscleReport?.metrics.leanNonMuscleMassKg ?? null,
        {
          leanNonMuscleMassKg:
            muscleReport?.last30Days.leanNonMuscleMassKg ?? [],
        },
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
    },
  };
}

export function normalizeProgressTrend(
  points: BodyCompositionProgressTrendPoint[],
): BodyCompositionProgressTrendPoint[] {
  const baseline = points[0]?.value;
  if (baseline === undefined) return [];
  return points.map((point) => ({
    createdAt: point.createdAt,
    value: Number((point.value - baseline).toFixed(2)),
  }));
}

function withInsufficientHistoryCopy<T extends { comment: string }>(
  card: T,
  readingCount: number,
): T {
  if (readingCount >= 2 || /insufficient history/i.test(card.comment)) return card;
  return {
    ...card,
    comment: "Insufficient history for a directional trend.",
  };
}

function trendEvidence(
  base: ReportEvidence | undefined,
  points: BodyCompositionProgressTrendPoint[],
): ReportEvidence | undefined {
  if (!base) return undefined;
  const readingCount = points.length;
  return {
    ...base,
    periodStart: points[0]?.createdAt ?? null,
    readingCount,
    confidence: readingCount >= 6 ? "high" : readingCount >= 3 ? "medium" : "low",
  };
}

export async function getProfileAiTrendSources(
  profileId: string,
  asOf: string = new Date().toISOString(),
): Promise<ProfileAiTrendSources> {
  const rows = (await db
    .prepare(
      `
  SELECT
    created_at AS createdAt,
    body_fat_pct AS bodyFatPct,
    fat_mass_kg AS fatMassKg,
    muscle_mass_kg AS muscleMassKg,
    skeletal_muscle_kg AS skeletalMuscleKg,
    visceral_fat AS visceralFat,
    subcutaneous_fat_mass_kg AS subcutaneousFatMassKg
  FROM body_composition_metrics_new
  WHERE profile_id = ?
    AND created_at <= ?
  ORDER BY created_at ASC
`,
    )
    .all(profileId, asOf)) as BodyCompositionInsightTrendRow[];
  return buildProfileAiTrendSources(rows, asOf);
}

export function buildProfileAiTrendSources(
  sourceRows: BodyCompositionInsightTrendRow[],
  asOf: string,
): ProfileAiTrendSources {
  const asOfTime = new Date(asOf).getTime();
  const rows = sourceRows
    .filter((row) => new Date(row.createdAt).getTime() <= asOfTime)
    .toSorted((left, right) =>
      new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime()
    );
  const build = (selectedRows: typeof rows): BodyCompositionInsightTrends => ({
    body_fat_pct: selectedRows.map((row) => ({
      createdAt: row.createdAt,
      value: row.bodyFatPct,
    })),
    fat_mass_kg: selectedRows.map((row) => ({
      createdAt: row.createdAt,
      value: row.fatMassKg,
    })),
    muscle_mass_kg: selectedRows.map((row) => ({
      createdAt: row.createdAt,
      value: row.muscleMassKg,
    })),
    skeletal_muscle_kg: selectedRows.map((row) => ({ createdAt: row.createdAt, value: row.skeletalMuscleKg })),
    visceral_fat: selectedRows.map((row) => ({ createdAt: row.createdAt, value: row.visceralFat })),
    subcutaneous_fat_mass_kg: selectedRows.map((row) => ({ createdAt: row.createdAt, value: row.subcutaneousFatMassKg })),
  });
  const cutoff = asOfTime - 30 * 24 * 60 * 60 * 1000;
  return {
    fullHistory: build(rows),
    recent30Days: build(rows.filter((row) => new Date(row.createdAt).getTime() >= cutoff)),
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
    trendSources,
    latestBodyComposition,
  ] =
    await Promise.all([
      getProfilePerformance(
        profileId,
        source.bodyCompositionMetricsId,
        source.profileContext ?? undefined,
      ),
      getProfileFatReport(profileId, source.bodyCompositionMetricsId),
      getProfileMuscleReport(profileId, source.bodyCompositionMetricsId),
      getProfileAiTrendSources(profileId, source.asOf),
      getBodyCompositionMeasurementByIdV2(
        profileId,
        source.bodyCompositionMetricsId,
      ).then((table) =>
        table === null ? null : Object.fromEntries(table.rows),
      ),
    ]);

  const readingCount = Math.max(
    ...Object.values(trendSources.recent30Days).map((points) => points.length),
  );
  return {
    performanceReport,
    fatReport,
    muscleReport,
    trendSources,
    latestBodyComposition,
    evidence: {
      asOf: source.asOf,
      periodStart: trendSources.recent30Days.body_fat_pct[0]?.createdAt ?? null,
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
        "Generate the complete structured profile AI report. Cards: short title/headline/heading, one-sentence comment, remark{marker,factor_color,text}. Markers: trend_up|trend_down|ai_recommendation|caution|complement. factor_color: green|yellow|orange|red (strong→highest priority). When a card also has a top-level factor_color, it must match remark.factor_color. Candid coach tone: supportive but direct about unfavorable or stalled results; no clinical/risk language.",
      schema: insights_schema,
    },
  );

  return [profile_ai_report];
}
