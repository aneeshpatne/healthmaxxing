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

export const body_analysis = tool(
  ({ foundation, momentum, biggest_lever, physique_archetype }) => {
    console.log({ foundation, momentum, biggest_lever, physique_archetype });
  },
  {
    name: "body_analysis",
    description:
      "Structured body composition analysis: where the user stands, what's trending, and the single highest-impact next move.",
    schema: z.object({
      foundation: z
        .string()
        .describe(
          "One sentence on current physique quality — frame it as a base to build on, not a judgment.",
        ),
      momentum: z
        .string()
        .describe(
          "One sentence on what's actively changing or trending — recent progress, shifts in composition, or emerging patterns.",
        ),
      biggest_lever: z
        .string()
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
