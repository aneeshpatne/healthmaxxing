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
- One reading is a current snapshot only. Never call it progress, momentum, stable, or holding steady.
- Two readings support only an endpoint comparison. Three or more readings may support a directional pattern, with confidence proportional to reading count.
- Treat small or conflicting deltas with restraint: "holding fairly steady" or "a small opportunity to improve consistency."
- If evidence is sparse or missing, explicitly say there is not enough history for a trend. Never fill gaps with generic praise.

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
- effort_score: Treat this as progress consistency, not effort or discipline. Base it only on available directional evidence and say when history is sparse.
- performance, fat, and muscle cards: Interpret the specific card's metric. Do not turn every card into another overview or repeat the same recommendation.
- The muscle lean_mass_balance card is fat-free mass not classified as muscle. Never call it bone or bone mineral mass.
- visceral_fat is a device-estimated index, not kilograms or a direct measurement. Never call it visceral fat mass or percent.
- desired_weight_kg assumes current fat-free mass stays unchanged while body fat moves to targetBF_pct. State that assumption when discussing the target.

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
  const sources = await getProfileAiReportPreprocessSources(input.profileId);
  const boneMassTrend = formatBoneMassTrendForAgent(sources.muscleReport);

  const result = await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(
        `User MetaData - ${input.profileMetadata}
Body Composition Delta - ${input.bodyCompositionDelta}
Body Measurement Delta - ${input.bodyMeasurementDelta}
First Health Data Entry - ${input.firstHealthDataEntryDate}
Latest Body Measurement - ${input.latestBodyMeasurement}
Latest Body Composition Measurement - ${input.latestBodyCompositionMeasurement}
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
