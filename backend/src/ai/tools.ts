import { tool } from "langchain";
import * as z from "zod";
import {
  type ProfileAiAnalysisBlock,
  type ProfileId,
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
        momentum: analysisMessageSchema
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

  return [ai_overview, body_analysis, effort_score];
}
