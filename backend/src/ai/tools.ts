import { tool } from "langchain";
import * as z from "zod";
import {
  type ProfileAiAnalysisBlock,
  type ProfileId,
  TREND_COLUMNS,
  saveFatReportComments,
  saveMuscleReportComments,
  upsertDerivedMetricsComments,
  upsertProfileAiOverview,
  upsertProfileEffortScore,
} from "../db/commands";

type AiOverviewPayload = {
  title: string;
  remarks: string;
};

const analysisMessageSchema = z.object({
  headline: z
    .string()
    .describe(
      "Primary achievement or result message. Make it the most attention-grabbing text, one short sentence.",
    ),
  supporting_description: z
    .string()
    .describe(
      "Brief explanation of why the result matters. Add context and highlight the practical benefit.",
    ),
  actionable_insight: z
    .string()
    .describe(
      "Encouraging interpretation plus one specific next action. Reinforce the behavior to continue.",
    ),
});

const momentumAnalysisMessageSchema = analysisMessageSchema.extend({
  factors: z
    .array(z.enum(TREND_COLUMNS))
    .max(3)
    .describe(
      "At most 3 body_composition_metrics_new metric columns most responsible for the momentum insight. These exact metrics will be plotted for the user.",
    ),
});

const derivedMetricCommentSchema = z.object({
  comment: z.string().describe("Concise coaching comment. No word limit."),
});

const bodyRatioCommentSchema = z.object({
  remark: z.string().describe("Exactly 1 word. Positive or neutral tone."),
  comment: z
    .string()
    .describe("Exactly 4 words. Concise coaching comment."),
});

const bodyRatioCommentsSchema = z.object({
  waist_height: bodyRatioCommentSchema.describe("Waist divided by height."),
  shoulder_waist: bodyRatioCommentSchema.describe(
    "Shoulder divided by waist.",
  ),
  chest_waist: bodyRatioCommentSchema.describe("Chest divided by waist."),
  bicep_forearm: bodyRatioCommentSchema.describe(
    "Bicep divided by forearm.",
  ),
  thigh_calf: bodyRatioCommentSchema.describe("Thigh divided by calf."),
  neck_calf: bodyRatioCommentSchema.describe("Neck divided by calf."),
});

const fatReportCommentSchema = z.object({
  remark: z.string().describe("Exactly 1 word. Positive or neutral tone."),
  comment: z.string().describe("Concise coaching comment. No word limit."),
});

const muscleReportCommentSchema = z.object({
  remark: z.string().describe("Exactly 1 word. Positive or neutral tone."),
  comment: z.string().describe("Concise coaching comment. No word limit."),
});

type BodyAnalysisPayload = {
  foundation: ProfileAiAnalysisBlock;
  momentum: ProfileAiAnalysisBlock;
  biggest_lever: ProfileAiAnalysisBlock;
  physique_archetype: string;
};

type EffortScorePayload = {
  score: number;
  remark: string;
};

type PendingProfileAiOverview = {
  overview?: AiOverviewPayload;
  analysis?: BodyAnalysisPayload;
  effortScore?: EffortScorePayload;
};

const pendingProfileAiOverviews = new Map<ProfileId, PendingProfileAiOverview>();

function saveWhenComplete(profileId: ProfileId, modelName?: string | null) {
  const pending = pendingProfileAiOverviews.get(profileId);

  if (!pending?.overview || !pending.analysis || !pending.effortScore) {
    return;
  }

  upsertProfileAiOverview({
    profileId,
    overviewTitle: pending.overview.title,
    overviewRemarks: pending.overview.remarks,
    foundation: pending.analysis.foundation,
    momentum: pending.analysis.momentum,
    biggestLever: pending.analysis.biggest_lever,
    physiqueArchetype: pending.analysis.physique_archetype,
    modelName,
  });

  upsertProfileEffortScore({
    profileId,
    score: pending.effortScore.score,
    remark: pending.effortScore.remark,
    modelName,
  });

  pendingProfileAiOverviews.delete(profileId);
}

export function createProfileAiTools(
  profileId: ProfileId,
  modelName?: string | null,
) {
  const ai_overview = tool(
    ({ title, remarks }) => {
      console.log({ profileId, title, remarks });

      const pending = pendingProfileAiOverviews.get(profileId) ?? {};

      pending.overview = { title, remarks };
      pendingProfileAiOverviews.set(profileId, pending);
      saveWhenComplete(profileId, modelName);

      return "Saved profile AI overview.";
    },
    {
      name: "ai_overview",
      description: "ai overview of the health metrics provided to you.",
      schema: z.object({
        title: z
          .string()
          .describe(
            "Headline progress statement summarizing the user's achievement. A short, positive, complete sentence (e.g. \"You're making excellent progress.\"). This is the primary message the user sees first.",
          ),
        remarks: z
          .string()
          .describe(
            "Supporting explanation displayed below the headline in smaller text. Explains why they're making progress or what specific metric/result supports the headline. One sentence, coaching tone.",
          ),
      }),
    },
  );

  const body_analysis = tool(
    ({ foundation, momentum, biggest_lever, physique_archetype }) => {
      console.log({
        profileId,
        foundation,
        momentum,
        biggest_lever,
        physique_archetype,
      });

      const pending = pendingProfileAiOverviews.get(profileId) ?? {};

      pending.analysis = {
        foundation,
        momentum,
        biggest_lever,
        physique_archetype,
      };
      pendingProfileAiOverviews.set(profileId, pending);
      saveWhenComplete(profileId, modelName);

      return "Saved profile body analysis.";
    },
    {
      name: "body_analysis",
      description:
        "Structured body composition analysis: where the user stands, what's trending, and the single highest-impact next move.",
      schema: z.object({
        foundation: analysisMessageSchema
          .describe(
            "Current physique quality framed as a base to build on, not a judgment.",
          ),
        momentum: momentumAnalysisMessageSchema
          .describe(
            "What's actively changing or trending: recent progress, shifts in composition, or emerging patterns.",
          ),
        biggest_lever: analysisMessageSchema
          .describe(
            "The single most impactful change they could make next. Be specific and actionable.",
          ),
        physique_archetype: z
          .string()
          .describe(
            "A short, aspirational archetype label for their current build (e.g. 'Athletic Endomorph', 'Lean Power Frame'). Positive and descriptive, never clinical.",
          ),
      }),
    },
  );

  const effort_score = tool(
    ({ score, remark }) => {
      console.log({ profileId, score, remark });

      const pending = pendingProfileAiOverviews.get(profileId) ?? {};

      pending.effortScore = { score, remark };
      pendingProfileAiOverviews.set(profileId, pending);
      saveWhenComplete(profileId, modelName);

      return "Saved profile effort score.";
    },
    {
      name: "effort_score",
      description:
        "Progress alignment score: how well current trends indicate the user's effort is moving them in the right direction.",
      schema: z.object({
        score: z
          .number()
          .int()
          .min(0)
          .max(100)
          .describe(
            "A 0-100 score reflecting how well the user's recent trends align with positive progress. Higher means trends are strongly moving in the right direction.",
          ),
        remark: z
          .string()
          .describe(
            "One coaching sentence summarizing why the score is what it is. Reference the strongest trend signal. Keep the same supportive tone as other tools.",
          ),
      }),
    },
  );

  const derived_metrics_comments = tool(
    ({
      ffmi,
      ffmi_vs_fmi,
      composition_flow,
      composition_trend,
      recomp_vector,
      excess_fat_gauge,
      body_ratios,
    }) => {
      console.log({
        profileId,
        ffmi,
        ffmi_vs_fmi,
        composition_flow,
        composition_trend,
        recomp_vector,
        excess_fat_gauge,
        body_ratios,
      });

      upsertDerivedMetricsComments({
        profileId,
        ffmi,
        ffmiVsFmi: ffmi_vs_fmi,
        compositionFlow: composition_flow,
        compositionTrend: composition_trend,
        recompVector: recomp_vector,
        excessFatGauge: excess_fat_gauge,
        bodyRatios: {
          waistHeight: body_ratios.waist_height,
          shoulderWaist: body_ratios.shoulder_waist,
          chestWaist: body_ratios.chest_waist,
          bicepForearm: body_ratios.bicep_forearm,
          thighCalf: body_ratios.thigh_calf,
          neckCalf: body_ratios.neck_calf,
        },
        modelName,
      });

      return "Saved derived metrics comments.";
    },
    {
      name: "derived_metrics_comments",
      description:
        "Concise AI comments for performance-derived metrics. Use the provided performance values: FFMI, FFMI vs FMI, lean vs fat flow, 30-day lean/fat trends, target/current/initial lean/fat pairs, excess fat gauge, and body ratios.",
      schema: z.object({
        ffmi: derivedMetricCommentSchema.describe("FFMI value comment."),
        ffmi_vs_fmi: derivedMetricCommentSchema.describe(
          "Comment comparing FFMI against FMI.",
        ),
        composition_flow: derivedMetricCommentSchema.describe(
          "Lean mass versus fat mass comment.",
        ),
        composition_trend: derivedMetricCommentSchema.describe(
          "30-day lean mass versus fat mass trend comment.",
        ),
        recomp_vector: derivedMetricCommentSchema.describe(
          "Target, current, and initial lean mass/fat mass pair comment.",
        ),
        excess_fat_gauge: derivedMetricCommentSchema.describe(
          "Total fat, target fat, and excess fat comment.",
        ),
        body_ratios: bodyRatioCommentsSchema.describe(
          "Separate comments for each latest body ratio.",
        ),
      }),
    },
  );

  const fat_report_comments = tool(
    ({
      fat_percent,
      visceral_subcutaneous_30d_delta,
      fat_mass,
      visceral_fat_mass,
      visceral_fat_percent,
      subcutaneous_fat_mass,
      subcutaneous_fat_ratio,
    }) => {
      console.log({
        profileId,
        fat_percent,
        visceral_subcutaneous_30d_delta,
        fat_mass,
        visceral_fat_mass,
        visceral_fat_percent,
        subcutaneous_fat_mass,
        subcutaneous_fat_ratio,
      });

      saveFatReportComments({
        profileId,
        comments: {
          fatPercent: fat_percent,
          visceralSubcutaneous30dDelta: visceral_subcutaneous_30d_delta,
          fatMass: fat_mass,
          visceralFatMass: visceral_fat_mass,
          visceralFatPercent: visceral_fat_percent,
          subcutaneousFatMass: subcutaneous_fat_mass,
          subcutaneousFatRatio: subcutaneous_fat_ratio,
        },
        modelName,
      });

      return "Saved fat report comments.";
    },
    {
      name: "fat_report_comments",
      description:
        "AI remarks and comments for the latest fat report factors. Every remark must be exactly one word.",
      schema: z.object({
        fat_percent: fatReportCommentSchema.describe("Body fat percentage."),
        visceral_subcutaneous_30d_delta: fatReportCommentSchema.describe(
          "30-day visceral fat mass delta and subcutaneous fat mass delta.",
        ),
        fat_mass: fatReportCommentSchema.describe("Total fat mass."),
        visceral_fat_mass: fatReportCommentSchema.describe("Visceral fat mass."),
        visceral_fat_percent: fatReportCommentSchema.describe(
          "Visceral fat percentage.",
        ),
        subcutaneous_fat_mass: fatReportCommentSchema.describe(
          "Subcutaneous fat mass.",
        ),
        subcutaneous_fat_ratio: fatReportCommentSchema.describe(
          "Subcutaneous fat mass divided by total fat mass.",
        ),
      }),
    },
  );

  const muscle_report_comments = tool(
    ({
      total_muscle,
      bone_mass,
      muscle_ratio,
      skeletal_muscle_mass,
      skeletal_muscle_ratio,
    }) => {
      console.log({
        profileId,
        total_muscle,
        bone_mass,
        muscle_ratio,
        skeletal_muscle_mass,
        skeletal_muscle_ratio,
      });

      saveMuscleReportComments({
        profileId,
        comments: {
          totalMuscle: total_muscle,
          boneMass: bone_mass,
          muscleRatio: muscle_ratio,
          skeletalMuscleMass: skeletal_muscle_mass,
          skeletalMuscleRatio: skeletal_muscle_ratio,
        },
        modelName,
      });

      return "Saved muscle report comments.";
    },
    {
      name: "muscle_report_comments",
      description:
        "AI remarks and comments for the latest muscle report factors. Every remark must be exactly one word.",
      schema: z.object({
        total_muscle: muscleReportCommentSchema.describe("Total muscle mass."),
        bone_mass: muscleReportCommentSchema.describe(
          "Estimated bone and non-muscle lean mass.",
        ),
        muscle_ratio: muscleReportCommentSchema.describe(
          "Muscle mass as a percentage of body weight.",
        ),
        skeletal_muscle_mass: muscleReportCommentSchema.describe(
          "Skeletal muscle mass.",
        ),
        skeletal_muscle_ratio: muscleReportCommentSchema.describe(
          "Skeletal muscle mass as a percentage of body weight.",
        ),
      }),
    },
  );

  return [
    ai_overview,
    body_analysis,
    effort_score,
    derived_metrics_comments,
    fat_report_comments,
    muscle_report_comments,
  ];
}
