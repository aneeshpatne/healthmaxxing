import { tool } from "langchain";
import * as z from "zod";

export const ai_overview = tool(
  ({ title, remarks }) => {
    console.log({ title, remarks });
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

export const body_analysis = tool(
  ({ foundation, momentum, biggest_lever, physique_archetype }) => {
    console.log({ foundation, momentum, biggest_lever, physique_archetype });
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
