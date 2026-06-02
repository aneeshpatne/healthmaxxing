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
          "Short, human health-progress headline for a tool tile. Make it feel encouraging and body-aware, not clinical or metric-labeled. (maximum 4 words)",
        ),
      remarks: z
        .string()
        .describe(
          "Comment on the trends, values, and other indicator (maximum 11 words)",
        ),
    }),
  },
);
