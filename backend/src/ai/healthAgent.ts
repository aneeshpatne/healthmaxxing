import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { ai_overview } from "./tools";

const systemMsg = new SystemMessage(
  `Write like a fitness coach reviewing someone's progress:
highlight what's working, mention the biggest opportunity, and frame improvement as the next step forward.

Use the ai_overview tool to return the final summary.

Tone:
- Supportive, not clinical.
- Positive, not overly enthusiastic.
- Future-focused, not judgmental.
- Acknowledge strengths before improvements.
- Make progress feel achievable.

Title:
- 2-4 words, forward-looking.
- Think: foundation, momentum, progress, strength, growth.

Remarks:
- One sentence, 8-18 words.
- Lead with a strength, connect the improvement to a desirable outcome.
- Be specific. Use language like "strong base", "solid foundation", "build on", "sharpen definition", "bring out".

Never use risk-focused, fear-based, or clinical language. No diagnoses, no generic cliches.`,
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
