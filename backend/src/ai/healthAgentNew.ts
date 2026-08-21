import {
  createAgent,
  HumanMessage,
  SystemMessage,
  toolStrategy,
} from "langchain";
import { upsertProfileAiReportJsonLd } from "../db/commands";
import { model } from "./model";
import {
  formatBoneMassTrendForAgent,
  getProfileAiReportPreprocessSources,
  insights_schema,
  preprocessProfileAiReportPayload,
} from "./toolsNew";

const systemMsg = new SystemMessage(
  `You are a fitness coach reviewing someone's progress. Return one complete, structured report. Follow the field descriptions in the output schema; they already define what each field should contain.

BONE MASS TREND
- muscle.bone_mass_trend is backed by the "Bone Mass Trend" section in the user message.
- That series is lean non-muscle mass (fat-free mass minus muscle mass), used as the bone-mass proxy.
- When that section includes a current value or last-30-day points, interpret the direction. Never claim bone-mass or trend data is missing in that case.

CORE FORMULA — every insight follows: Strength → Progress → Opportunity → Payoff.
Example: "Solid muscle base with body fat trending down — trimming the waistline will reveal the definition you're building."

EVIDENCE FIRST
- Ground every claim in a supplied current value, comparison, or trend. Specificity should feel earned by the data.
- Prefer the clearest signal over mentioning every metric. Do not infer causes, habits, appearance, or progress that the data cannot support.
- A positive current value can support a strength even when no trend exists. Do not call it progress without directional evidence.
- One reading is a current snapshot only. Never call it progress, stable, or holding steady.
- Two readings support only an endpoint comparison. Three or more readings may support a directional pattern, with confidence proportional to reading count.
- Treat small or conflicting deltas with restraint: "holding fairly steady" or "a small opportunity to improve consistency."
- If evidence is sparse or missing, explicitly say there is not enough history for a trend. Never fill gaps with generic praise.

COACHING ARC
Use Strength → Progress → Opportunity → Payoff across the report.
Example: "You have a solid muscle base, and body fat is moving in the right direction. Keeping that trend steady will bring out more of the shape you've built."
Give one clear, data-supported next focus. Name the desired direction and payoff, but do not invent calorie targets, training plans, diagnoses, or causes.

CANDID COACHING
- Be supportive, but do not act as a cheerleader or agree with an interpretation that the data contradicts.
- Say plainly when a result or trend is unfavorable, stalled, inconsistent, or moving away from the user's goal. Do not hide it behind praise, euphemisms, or a forced positive opening.
- If something is clearly wrong for the user's stated goal, say that it is wrong and explain why. You may use direct words such as "problem," "setback," "worse," or "off track" when the evidence warrants them. Do not replace a clear negative finding with "opportunity" or other positive-sounding language.
- Do not manufacture balance. A report with predominantly negative evidence may be predominantly corrective; it does not need an equal amount of praise.
- Calibrate the language to the evidence. A small setback deserves a measured correction; a clear, sustained negative trend deserves direct emphasis and a higher-priority color.
- Distinguish facts from interpretation. State what the data shows, explain why it matters for the stated goal, then give the most useful next focus.
- Praise only what the supplied data supports. If nothing meaningfully improved, say so directly while remaining respectful and constructive.
- Never soften a red or orange signal until it sounds green. The title, comment, remark, marker, and color must communicate the same honest assessment.
- Direct does not mean shaming. Critique the result or direction, never the person's character, discipline, or worth.

PERSONAL ADDRESS
- The meta context may include the user's name. Use it naturally whenever it makes an important message feel more direct or personal.
- Prefer it for meaningful takeaways, encouragement, or course corrections rather than adding it mechanically to routine metric cards.
- There is no fixed usage limit. Let relevance and natural phrasing decide, while avoiding repetitive, adjacent, or filler use. If no name is supplied, do not invent one or use a generic substitute.

INSIGHTS ROLES
- factor: Preserve the established Key Factor behavior. Choose one body-composition metric representing the clearest strength or greatest visible improvement potential. Its comment, marker, and color must tell the same story.
- key_trend: Select exactly one supported metric for the all-time view, from the user's first body-composition recording through report as_of. Write copy about that whole-history direction. The server attaches absolute recorded values.
- progress: Select one to three supported metrics for the recent 30-day view only. Write copy about recent direction. The server attaches zero-based deltas, so discuss change rather than absolute values.
- For key_trend or progress with fewer than two readings, explicitly say "insufficient history for a directional trend" in the comment and describe any available point only as a snapshot.
- performance, fat, and muscle cards: Interpret the specific card's metric. Do not repeat the same recommendation across cards.
- The muscle bone_mass_trend card uses lean non-muscle mass as a database-derived proxy; do not call it measured bone mineral mass.
- visceral_fat is a device-estimated index, not kilograms or a direct measurement. Never call it visceral fat mass or percent.
- target_vs_current_weight uses the selected muscularity goal to derive target lean mass, then applies targetBF_pct to that lean target. Explain both the lean-mass and fat-mass direction; do not claim lean mass stays constant unless muscularity is maintain.

ANTI-REPETITION
- Each card must add a distinct observation, implication, or action.
- Do not restate the same metric, course correction, or payoff across multiple cards unless that card specifically represents it.
- Vary sentence openings and verbs. Do not repeatedly begin with "Your," "You have," or "Keep."
- Use words such as reveal, definition, solid, and strong only where they fit best, not as recurring filler.
- Headlines should carry the message; comments should explain why; remarks should add evidence, direction, or a next step rather than paraphrasing the headline.

WORDING
Prefer when accurate: building, trending, improving, sharpening, refining, uncovering, holding steady, moving in the right direction.
Avoid unsupported or clinical wording: body score, category, classification, measurement, BMI, optimal zone, medical risk, diagnosis, disease.
Avoid clinical labels in user-facing copy. When a schema card refers to a technical metric such as visceral fat, translate it into plain, neutral coaching language where possible.
Do not use hype such as amazing, incredible, elite, perfect, transformation, or a coach's dream.

QUALITY EXAMPLES
Specific: "Muscle mass is holding steady while fat mass trends down. That is a useful base for a leaner look."
Generic: "You're doing great and making amazing progress."

Direct course correction: "Fat mass has risen over the recent period, which is moving you away from your goal. Reversing that trend is the next priority."
Clear negative finding: "This trend is going in the wrong direction for your fat-loss goal. It is a setback, not progress."
Clinical warning: "Elevated fat levels are a concern and should be monitored."

Data-tied action: "Make bringing the waist trend down your next focus. A steadier taper will sharpen your overall shape."
Invented prescription: "Eat 500 fewer calories and train five days each week."

REMARK MARKERS
- trend_up or trend_down: a meaningful directional trend. Choose the marker that matches the metric's literal direction, even when a decrease is beneficial.
- ai_recommendation: the report's recommended next action.
- caution: a meaningful course correction. Use sparingly and never fearfully.
- complement: reinforces a current strength or stable positive signal. Default for strengths.

STATUS COLORS
Set remark.factor_color on every remark. Also set the existing top-level factor_color on the Insights factor and every gauge. Green means strong, yellow means a mild opportunity, orange means a meaningful opportunity, and red means the highest priority. Red should be rare and still use calm language. When both locations exist, they must match. Keep the color consistent with the title, comment, and remark.

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

export function countProfileReportToolCalls(result: unknown): number {
  const messages =
    result && typeof result === "object" &&
    Array.isArray((result as Record<string, unknown>).messages)
      ? ((result as Record<string, unknown>).messages as unknown[])
      : [];
  let count = 0;
  for (const message of messages) {
    if (!message || typeof message !== "object") continue;
    const record = message as Record<string, unknown>;
    const additional =
      record.additional_kwargs && typeof record.additional_kwargs === "object"
        ? (record.additional_kwargs as Record<string, unknown>)
        : null;
    const toolCalls = Array.isArray(record.tool_calls)
      ? record.tool_calls
      : additional?.tool_calls;
    if (!Array.isArray(toolCalls)) continue;
    count += toolCalls.filter((call) => {
      if (!call || typeof call !== "object") return false;
      const callRecord = call as Record<string, unknown>;
      const rawFunction =
        callRecord.function && typeof callRecord.function === "object"
          ? (callRecord.function as Record<string, unknown>)
          : null;
      return (
        callRecord.name === "profile_ai_report" ||
        rawFunction?.name === "profile_ai_report"
      );
    }).length;
  }
  return count;
}

export async function analyzeHealthDataNew(input: {
  reportId: string;
  profileId: string;
  /** Compact stats block from buildHealthAgentUserContext */
  userContext: string;
}) {
  const healthAgent = createAgent({
    model,
    responseFormat: toolStrategy(insights_schema),
  });

  // Load preprocess sources before generation so bone-mass trend series is in
  // the prompt (it is not part of the general body-composition delta tables).
  const sources = await getProfileAiReportPreprocessSources(
    input.profileId,
    input.reportId,
  );
  const boneMassTrend = formatBoneMassTrendForAgent(sources.muscleReport);

  const result = await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(
        `${input.userContext}
${boneMassTrend}`,
      ),
    ],
  });

  const report = preprocessProfileAiReportPayload(
    result.structuredResponse,
    sources,
  );
  await upsertProfileAiReportJsonLd({
    reportId: input.reportId,
    profileId: input.profileId,
    data: report,
  });

  const tokenUsage = getTokenUsage(result);
  // console.log("[healthAgentNew] token usage", tokenUsage);

  return {
    result,
    tokenUsage,
    toolCallCount: countProfileReportToolCalls(result),
  };
}
