import { tool } from "langchain";
import * as z from "zod";
import {
  type ProfileAiAnalysisBlock,
  type ProfileId,
  upsertProfileAiOverview,
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

type PendingProfileAiOverview = {
  overview?: AiOverviewPayload;
  analysis?: BodyAnalysisPayload;
};

const pendingProfileAiOverviews = new Map<ProfileId, PendingProfileAiOverview>();

function saveWhenComplete(profileId: ProfileId, modelName?: string | null) {
  const pending = pendingProfileAiOverviews.get(profileId);

  if (!pending?.overview || !pending.analysis) {
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

  pendingProfileAiOverviews.delete(profileId);
}

export function createProfileAiTools(
  profileId: ProfileId,
  modelName?: string | null,
) {
  const ai_overview = tool(
    ({ title, remarks }) => {
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
            "Positive, forward-looking fitness-coach title for a tool tile. Use 2-4 words, prefer themes like foundation, momentum, progress, strength, definition, and growth, and avoid labels, diagnoses, or static descriptions.",
          ),
        remarks: z
          .string()
          .describe(
            "One-sentence coaching remark, 8-18 words. Mention a strength before any improvement area, connect the improvement area to a desirable outcome, and be specific when possible. Sound like an experienced fitness coach helping someone continue a successful journey. Avoid risk-focused, fear-based, clinical, diagnostic, judgmental, or generic motivational language.",
          ),
      }),
    },
  );

  const body_analysis = tool(
    ({ foundation, momentum, biggest_lever, physique_archetype }) => {
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

  return [ai_overview, body_analysis];
}
