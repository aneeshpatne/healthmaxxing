import { tool } from "langchain";
import * as z from "zod";
import { BODY_COMPOSITION_METRICS_NEW_FACTORS, db } from "../db/db";
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

const trends = z.enum(BODY_COMPOSITION_METRICS_NEW_FACTORS);
const remark_schema = z.object({
  marker: marker_enum,
  text: z.string(),
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
};

type ProfileAiReportResolvedSources = {
  performanceReport: ProfilePerformance | null;
  fatReport: FatReport | null;
  muscleReport: MuscleReport | null;
  progressTrends: BodyCompositionProgressTrends;
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
    overview: z.object({
      title: z
        .string()
        .describe(
          "Title which builds upon the user's achievement, or potential of what the user can achieve.",
        ),
      headline: z
        .string()
        .describe(
          "Headline progress statement summarizing the user's achievement. A short, positive, complete sentence.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence expanding the overview with the clearest supporting context.",
        ),
      remark: remark_schema.describe(
        "Supporting explanation displayed below the headline in smaller text. Explains why they're making progress or what specific metric/result supports the headline. One sentence, coaching tone.",
      ),
    }),
    foundation: z.object({
      title: z
        .string()
        .describe(
          "Short title for what is already working well in the user's current physique.",
        ),
      headline: z
        .string()
        .describe(
          "Short headline summarizing the user's strongest current foundation.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the main strength behind the user's current foundation.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence describing the user's current base and what it gives them to build on.",
      ),
    }),
    momentum: z.object({
      title: z
        .string()
        .describe(
          "Short title for what is actively improving or shifting in the user's recent data.",
        ),
      headline: z
        .string()
        .describe(
          "Short headline summarizing the user's strongest current momentum signal.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the recent pattern behind the momentum signal.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining the strongest recent trend and why it matters.",
      ),
    }),
    progress: z.object({
      title: z
        .string()
        .describe("Short title for the user's overall progress signal."),
      headline: z
        .string()
        .describe(
          "Short headline summarizing the user's most important progress pattern.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how the selected trends support the progress read.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence interpreting the user's progress.",
      ),
      trends: z
        .array(trends)
        .describe(
          "Selectable body composition metric trends that support this progress insight.",
        ),
    }),
    lever: z.object({
      title: z
        .string()
        .describe("Short title for the single highest-impact next move."),
      headline: z
        .string()
        .describe("Short headline summarizing the highest-impact next move."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining why this lever has the highest payoff.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence naming the highest-ROI action and the visible payoff it should create.",
      ),
    }),
    physique_archetype: z.object({
      title: z
        .string()
        .describe("Short label introducing the user's current body type."),
      headline: z
        .string()
        .describe(
          "Short headline describing the user's current physique archetype in supportive language.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining why this body type classification fits the current data.",
        ),
      body_type: body_type_enum.describe("Current body type classification."),
    }),
    effort_score: z.object({
      title: z
        .string()
        .describe("Short label introducing the user's effort score."),
      headline: z
        .string()
        .describe(
          "Short headline summarizing what the effort score says about the user's current progress.",
        ),
      score: z
        .number()
        .int()
        .min(0)
        .max(100)
        .describe("Effort score from 0 to 100."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the main evidence behind the effort score.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining the score and its main driver.",
      ),
    }),
  }),
  performance: z.object({
    ffmi_gauge: z.object({
      heading: z.string().describe("Short display heading for the FFMI gauge."),
      title: z
        .string()
        .describe("Short title interpreting the user's FFMI level."),
      comment: z
        .string()
        .describe("One concise sentence explaining the FFMI gauge result."),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the FFMI gauge says about lean mass.",
      ),
    }),
    fmi_vs_ffmi: z.object({
      heading: z
        .string()
        .describe("Short display heading for the FMI vs FFMI composition map."),
      title: z
        .string()
        .describe(
          "Short title interpreting the user's fat mass index against fat-free mass index.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the FMI vs FFMI composition map result.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining the user's composition map position.",
      ),
    }),
    body_composition_flow: z.object({
      heading: z
        .string()
        .describe("Short display heading for body composition flow."),
      title: z
        .string()
        .describe(
          "Short title interpreting lean mass and fat mass contribution to total weight.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining lean mass and fat mass contribution to total weight.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining how lean mass and fat mass are shaping total weight.",
      ),
    }),
    composition_trends: z.object({
      heading: z
        .string()
        .describe("Short display heading for composition trends."),
      title: z
        .string()
        .describe("Short title comparing lean change against fat change."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining recent lean change versus fat change.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining whether recent change is moving toward more lean mass, less fat, or a better balance.",
      ),
    }),
    target_vs_current_weight: z.object({
      heading: z
        .string()
        .describe("Short display heading for target versus current weight."),
      title: z
        .string()
        .describe(
          "Short title interpreting the gap between current weight and target weight.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining current weight relative to target weight.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining the practical meaning of the current-to-target weight gap.",
      ),
    }),
    excess_fat_gauge: z.object({
      heading: z
        .string()
        .describe("Short display heading for the excess fat gauge."),
      title: z
        .string()
        .describe("Short title interpreting excess fat relative to target."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the excess fat gauge result.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining how much fat loss opportunity remains in a supportive way.",
      ),
    }),
  }),
  fat: z.object({
    fat_ratio: z.object({
      heading: z.string().describe("Short display heading for fat ratio."),
      title: z
        .string()
        .describe("Short title interpreting the user's fat ratio."),
      comment: z
        .string()
        .describe("One concise sentence explaining the fat ratio result."),
      remark: remark_schema.describe(
        "One concise coaching sentence interpreting fat ratio in a supportive way.",
      ),
    }),
    fat_ratio_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for fat ratio trend."),
      title: z
        .string()
        .describe("Short title interpreting the fat ratio trend."),
      comment: z
        .string()
        .describe("One concise sentence explaining how fat ratio is trending."),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the fat ratio trend means.",
      ),
    }),
    visceral_vs_subcutaneous: z.object({
      heading: z
        .string()
        .describe(
          "Short display heading for visceral versus subcutaneous fat.",
        ),
      title: z
        .string()
        .describe(
          "Short title comparing visceral fat against subcutaneous fat.",
        ),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining the visceral versus subcutaneous fat balance.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence interpreting visceral versus subcutaneous fat.",
      ),
    }),
    visceral_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for visceral fat trend."),
      title: z
        .string()
        .describe("Short title interpreting visceral fat trend."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how visceral fat is trending.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the visceral fat trend means.",
      ),
    }),
    subcutaneous_fat_mass_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for subcutaneous fat mass trend."),
      title: z
        .string()
        .describe("Short title interpreting subcutaneous fat mass trend."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how subcutaneous fat mass is trending.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the subcutaneous fat mass trend means.",
      ),
    }),
    fat_mass_trend: z.object({
      heading: z.string().describe("Short display heading for fat mass trend."),
      title: z.string().describe("Short title interpreting fat mass trend."),
      comment: z
        .string()
        .describe("One concise sentence explaining how fat mass is trending."),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the fat mass trend means.",
      ),
    }),
  }),
  muscle: z.object({
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
      title: z.string().describe("Short title interpreting bone mass trend."),
      comment: z
        .string()
        .describe("One concise sentence explaining how bone mass is trending."),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the bone mass trend means.",
      ),
    }),
    muscle_mass_trend: z.object({
      heading: z
        .string()
        .describe("Short display heading for muscle mass trend."),
      title: z.string().describe("Short title interpreting muscle mass trend."),
      comment: z
        .string()
        .describe(
          "One concise sentence explaining how muscle mass is trending.",
        ),
      remark: remark_schema.describe(
        "One concise coaching sentence explaining what the muscle mass trend means.",
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
  progressTrends = emptyProgressTrends,
}: ProfileAiReportPreprocessSources = {}) {
  return {
    insights: {
      ...insights,
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
        { fatMassKg: fatReport?.last30Days.fatMassKg ?? [] },
      ),
      fat_ratio_trend: withValueAndTrends(
        fat.fat_ratio_trend,
        fatReport?.metrics.fatPercent ?? null,
        { fatMassKg: fatReport?.last30Days.fatMassKg ?? [] },
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
      muscle_mass: withValueAndTrends(
        muscle.muscle_mass,
        muscleReport?.metrics.totalMuscleKg ?? null,
        { muscleRatio: muscleReport?.last30Days.muscleRatio ?? [] },
      ),
      bone_mass_trend: withValueAndTrends(
        muscle.bone_mass_trend,
        muscleReport?.metrics.boneMassKg ?? null,
        { boneMassKg: muscleReport?.last30Days.boneMassKg ?? [] },
      ),
      muscle_mass_trend: withValueAndTrends(
        muscle.muscle_mass_trend,
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
  const [performanceReport, fatReport, muscleReport, progressTrends] =
    await Promise.all([
      optionalSource("performance report", () => getProfilePerformance(profileId), null),
      optionalSource("fat report", () => getProfileFatReport(profileId), null),
      optionalSource("muscle report", () => getProfileMuscleReport(profileId), null),
      optionalSource(
        "progress trends",
        () => getProfileAiProgressTrends(profileId),
        emptyProgressTrends,
      ),
    ]);

  return {
    performanceReport,
    fatReport,
    muscleReport,
    progressTrends,
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
        "Generate the complete structured profile AI report payload.",
      schema: insights_schema,
    },
  );

  return [profile_ai_report];
}
