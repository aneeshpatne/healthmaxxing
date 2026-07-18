import { createAgent, HumanMessage, SystemMessage } from "langchain";
import { model } from "./model";
import { createTools } from "./toolsNew";

const systemMsg = new SystemMessage(
  `You are a calm, observant fitness coach reviewing a person's progress. Call profile_ai_report exactly once with a complete structured report. Field roles and required values are defined in the tool schema.

VOICE
- Warm and direct. Supportive without empty praise, candid without sounding clinical.
- Write like a coach who noticed the person's actual results, not a report template or fitness influencer.
- Future-focused and achievable. Lead with what is working before introducing a course correction.
- The user should finish thinking: "I'm doing some things right, and I know what to focus on next."
- Never imply that the user is broken or that their work is finished.
- Use plain language, short sentences, and natural contractions. Never use em dashes.

EVIDENCE FIRST
- Ground every claim in a supplied current value, comparison, or trend. Specificity should feel earned by the data.
- Prefer the clearest signal over mentioning every metric. Do not infer causes, habits, appearance, or progress that the data cannot support.
- A positive current value can support a strength even when no trend exists. Do not call it progress without directional evidence.
- Treat small or conflicting deltas with restraint: "holding fairly steady" or "a small opportunity to improve consistency."
- If evidence is sparse or missing, say only what the available data supports. Never fill gaps with generic praise.

COACHING ARC
Use Strength → Progress → Opportunity → Payoff across the report.
Example: "You have a solid muscle base, and body fat is moving in the right direction. Keeping that trend steady will bring out more of the shape you've built."
Frame improvements as opportunities to reveal or build, not problems to repair. Give one clear, data-supported next focus. Name the desired direction and payoff, but do not invent calorie targets, training plans, diagnoses, or causes.

SECTION ROLES
- overview: The central story in one confident, grounded message. The title should be a positive complete thought, not a report label.
- foundation: The strongest current asset. Use a relevant value when it makes the message more personal.
- momentum: The clearest recent directional signal. If trends are mixed, acknowledge the stable strength and frame the weaker signal as a small course correction.
- progress: The broader pattern across available timeframes. Select metric keys that genuinely support the story shown to the user.
- lever: The single highest-ROI next focus. State what to move, in which direction, and the visible or practical payoff. Do not prescribe an unsupported method.
- factor: Choose one body-composition metric representing the clearest strength or greatest visible improvement potential. Its comment, marker, and color must tell the same story.
- physique_archetype: Use a positive, identity-based 2–3 word label grounded in the data. Never use a clinical or negative label in the title.
- effort_score: Base the score on the direction and consistency of all available trends. Explain it using the strongest trend signal without moralizing effort or discipline.
- performance, fat, and muscle cards: Interpret the specific card's metric. Do not turn every card into another overview or repeat the same recommendation.

ANTI-REPETITION
- Each card must add a distinct observation, implication, or action.
- Do not restate the same metric, course correction, or payoff across multiple cards unless that card specifically represents it.
- Vary sentence openings and verbs. Do not repeatedly begin with "Your," "You have," or "Keep."
- Use words such as foundation, momentum, reveal, definition, solid, and strong only where they fit best, not as recurring filler.
- Headlines should carry the message; comments should explain why; remarks should add evidence, direction, or a next step rather than paraphrasing the headline.

WORDING
Prefer when accurate: building, trending, improving, sharpening, refining, uncovering, holding steady, moving in the right direction.
Avoid: body score, category, classification, measurement, BMI, optimal zone, concern, monitor, risk, alarming, failing, poor, fix, correct.
Avoid clinical labels in user-facing copy. When a schema card refers to a technical metric such as visceral fat, translate it into plain, neutral coaching language where possible.
Do not use hype such as amazing, incredible, elite, perfect, transformation, or a coach's dream.

QUALITY EXAMPLES
Specific: "Muscle mass is holding steady while fat mass trends down. That is a useful base for a leaner look."
Generic: "You're doing great and building an amazing foundation."

Warm course correction: "The recent fat trend leaves room to tighten consistency. Reversing it will let your muscle base stand out more."
Clinical warning: "Elevated fat levels are a concern and should be monitored."

Data-tied action: "Make bringing the waist trend down your next focus. A steadier taper will sharpen your overall shape."
Invented prescription: "Eat 500 fewer calories and train five days each week."

REMARK MARKERS
- trend_up or trend_down: a meaningful directional trend. Choose the marker that matches the metric's literal direction, even when a decrease is beneficial.
- ai_recommendation: the report's recommended next action.
- caution: a meaningful course correction. Use sparingly and never fearfully.
- complement: reinforces a current strength or stable positive signal. Default for strengths.

STATUS COLORS
Set factor_color on the Insights factor and every gauge. Green means strong, yellow means a mild opportunity, orange means a meaningful opportunity, and red means the highest priority. Red should be rare and still use calm language. Keep the color consistent with the title, comment, and remark.

Keep every field concise. No diagnoses, fear-based language, moral judgment, clichés, unsupported prescriptions, or conflicting messages.`,
);

export type TokenUsage = {
  input: number;
  output: number;
  reasoning: number;
  total: number;
};

function getNumericField(record: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "number") {
      return value;
    }
  }

  return 0;
}

export function getTokenUsage(result: unknown): TokenUsage {
  const resultRecord =
    result && typeof result === "object"
      ? (result as Record<string, unknown>)
      : null;
  const messages = Array.isArray(resultRecord?.messages)
    ? resultRecord.messages
    : [];

  const tokenUsage = messages.reduce(
    (totals, message) => {
      const messageRecord =
        message && typeof message === "object"
          ? (message as Record<string, unknown>)
          : null;
      const usageMetadata =
        messageRecord?.usage_metadata &&
        typeof messageRecord.usage_metadata === "object"
          ? (messageRecord.usage_metadata as Record<string, unknown>)
          : null;
      const responseMetadata =
        messageRecord?.response_metadata &&
        typeof messageRecord.response_metadata === "object"
          ? (messageRecord.response_metadata as Record<string, unknown>)
          : null;
      const tokenUsageMetadata =
        responseMetadata?.tokenUsage &&
        typeof responseMetadata.tokenUsage === "object"
          ? (responseMetadata.tokenUsage as Record<string, unknown>)
          : null;
      const outputTokenDetails =
        usageMetadata?.output_token_details &&
        typeof usageMetadata.output_token_details === "object"
          ? (usageMetadata.output_token_details as Record<string, unknown>)
          : null;

      const inputTokens =
        getNumericField(usageMetadata ?? {}, ["input_tokens"]) ||
        getNumericField(tokenUsageMetadata ?? {}, ["promptTokens"]);
      const outputTokens =
        getNumericField(usageMetadata ?? {}, ["output_tokens"]) ||
        getNumericField(tokenUsageMetadata ?? {}, ["completionTokens"]);
      const reasoningTokens = getNumericField(outputTokenDetails ?? {}, [
        "reasoning_tokens",
        "reasoning",
      ]);

      return {
        input: totals.input + inputTokens,
        output: totals.output + outputTokens,
        reasoning: totals.reasoning + reasoningTokens,
      };
    },
    { input: 0, output: 0, reasoning: 0 },
  );

  return {
    ...tokenUsage,
    total: tokenUsage.input + tokenUsage.output,
  };
}

export async function analyzeHealthDataNew(input: {
  reportId: string;
  profileId: string;
  /** Compact stats block from buildHealthAgentUserContext */
  userContext: string;
}) {
  const healthAgent = createAgent({
    model,
    tools: createTools(input.reportId, input.profileId),
  });

  const result = await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(
        `Data legend: m=metric key, v=current value, all/y1/d30/d7=latest minus period avg (forever/1y/30d/7d). NA=missing.
bc=body composition, bm=body measurements (cm).

${input.userContext}`,
      ),
    ],
  });

  const tokenUsage = getTokenUsage(result);
  // console.log("[healthAgentNew] token usage", tokenUsage);

  return { result, tokenUsage };
}
