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
    description: "analysis of body",
    schema: z.object({
      foundation: z.string().describe("Current physique quality"),
      momentum: z.string().describe("What's changing?"),
      biggest_lever: z.string().describe("Biggest Lever"),
      physique_archetype: z.string().describe(""),
    }),
  },
);
