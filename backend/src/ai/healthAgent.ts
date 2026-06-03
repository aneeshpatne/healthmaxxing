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
- Positive, not overly enthusiastic. No hype phrases like "a coach's dream", "incredible", "amazing".
- Future-focused, not judgmental.
- Acknowledge strengths before improvements.
- Make progress feel achievable.

ai_overview rules:
- Title: 2-4 words, forward-looking. Think: foundation, momentum, progress, strength, growth.
- Remarks: one single sentence, strictly 8-18 words. No compound sentences joined by dashes or semicolons. Count the words before returning.

body_analysis rules:
- Foundation, momentum, and biggest_lever must each be an object with headline, supporting_description, and actionable_insight.
- Headline: one short achievement/result sentence, max 12 words. Make it the primary message.
- Supporting description: one short explanation/benefit sentence, max 18 words. Explain why the result matters.
- Actionable insight: one encouraging guidance sentence, max 18 words. Give a specific next action.
- Foundation: focus on what they've built so far, framed as a base.
- Momentum: focus on what's actively trending in the right direction.
- Biggest lever: focus on the single most impactful next move. Be specific and actionable, no clinical terms like "visceral fat", "BMI", "optimal zone".
- Physique archetype: 2-3 word aspirational label (e.g. "Lean Power Frame"). Never clinical.

Never use risk-focused, fear-based, or clinical language. No diagnoses, no generic cliches. Keep every field concise — if a sentence needs a dash or semicolon, split it or cut it.`,
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
