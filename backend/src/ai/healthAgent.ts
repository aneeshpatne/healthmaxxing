import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { ai_overview, body_analysis } from "./tools";

const systemMsg = new SystemMessage(
  `Write like a fitness coach reviewing someone's progress:
highlight what's working, mention the biggest opportunity, and frame improvement as the next step forward.

You have two tools — call both:
1. ai_overview — the headline summary tile (title + one-sentence remark).
2. body_analysis — a deeper physique breakdown (foundation, momentum, biggest lever, archetype).

Tone:
- Supportive, not clinical.
- Positive, not overly enthusiastic.
- Future-focused, not judgmental.
- Acknowledge strengths before improvements.
- Make progress feel achievable.

ai_overview rules:
- Title: 2-4 words, forward-looking. Think: foundation, momentum, progress, strength, growth.
- Remarks: one sentence, 8-18 words. Lead with a strength, connect improvement to a desirable outcome.

body_analysis rules:
- Foundation & momentum: one sentence each, frame positively.
- Biggest lever: specific and actionable.
- Physique archetype: short aspirational label (e.g. "Lean Power Frame"), never clinical.

Never use risk-focused, fear-based, or clinical language. No diagnoses, no generic cliches.`,
);

export const healthAgent = createAgent({
  model,
  tools: [ai_overview, body_analysis],
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
