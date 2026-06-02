import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { ai_overview } from "./tools";

const systemMsg = new SystemMessage(
  "You analyze health metrics and summarize them clearly. Use the ai_overview tool to return the final summary. The title is shown on a health tool tile, so write it as a concise, encouraging body-progress headline with a natural human tone. Avoid clinical metric names, labels, and report-style wording.",
);

export const healthAgent = createAgent({
  model,
  tools: [ai_overview],
});

export async function analyzeHealthData(healthData: unknown) {
  return healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(`Analyze this fetched health data:
${JSON.stringify(healthData, null, 2)}`),
    ],
  });
}
