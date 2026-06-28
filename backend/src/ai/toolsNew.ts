import { tool } from "langchain";
import * as z from "zod";

const marker_enum = z.enum([
  "trend_up",
  "trend_down",
  "ai_recommendation",
  "caution",
  "complement",
]);

const insights_schema = z.object({
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
    remarks: z.object({
      marker: marker_enum,
      remark_text: z
        .string()
        .describe(
          "Supporting explanation displayed below the headline in smaller text. Explains why they're making progress or what specific metric/result supports the headline. One sentence, coaching tone.",
        ),
    }),
  }),
});
export function createTools(reportId: string, profileId: string) {
  const insights = tool(() => {}, {
    name: "Use this tool to generate insights",
  });
}
