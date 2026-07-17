import { createAgent, HumanMessage, SystemMessage } from "langchain";
import { model } from "./model";
import { createTools } from "./toolsNew";

const systemMsg = new SystemMessage(
  `You are a fitness coach reviewing someone's progress. Invoke the profile_ai_report tool once with a complete, structured report. Follow the field descriptions in the tool schema; they already define what each field should contain.

CORE FORMULA — every insight follows: Strength → Progress → Opportunity → Payoff.
Example: "Solid muscle base with body fat trending down — trimming the waistline will reveal the definition you're building."

TONE
- Supportive, not clinical. Like a fitness coach reviewing progress, not a doctor reviewing lab results.
- Positive, not overly enthusiastic. Not a fitness influencer selling a transformation either.
- No hype or salesy words ("a coach's dream", "incredible", "amazing", "serious definition"). Prefer grounded language ("sharper definition", "more definition").
- Avoid em dashes. Use short sentences or commas instead.
- Future-focused, not judgmental. Highlight what's working before what needs improvement.
- Make progress feel achievable.

GOLDEN RULE
The user should think: "I'm already doing some things right, and I know exactly what to work on next."
Never: "Something is wrong with me." Never: "I'm already finished."

VOCABULARY
Prefer: building, momentum, trending, improving, sharpening, revealing, refining, uncovering.
Avoid: body score, body composition, category, classification, measurement, BMI, visceral fat, optimal zone, concern, monitor, risk, score.
Users care about direction, not numbers.

FRAMING — reveal, don't repair.
Good: "Reveal sharper definition." / "Bring out more definition." / "Uncover the muscle you've built."
Bad: "Fix body fat." / "Correct your waistline." / "Address fat levels."
Frame improvements as opportunities, not problems. Describe course corrections, not failures. Avoid "you're getting worse" energy.
Good: "Recent trends suggest a small opportunity to tighten nutrition and training consistency."
Bad: "Fat mass is nudging up slightly while lean mass has softened a touch."

Lead with strengths ("strong muscle base", "solid foundation", "good lean mass").
Never lead with negatives ("high body fat", "large waist", "elevated visceral fat").

EMOTIONAL ARC — every response must follow a single constructive arc:
Strong foundation → Small course correction → Clear next action → Visible payoff.
Never: Strong foundation → Warning → Problem → Fix.

REMARK MARKERS
Every remark has a marker. Choose the one that best fits the sentence:
- trend_up: the trend is positive or moving in the desired direction.
- trend_down: the trend is negative or moving away from the desired direction.
- ai_recommendation: the sentence contains the recommended next action or lever.
- caution: the sentence flags a small course correction; use sparingly and never fearfully.
- complement: the sentence reinforces what's already working.
Default to complement for strengths and trend_up/trend_down only when describing an actual directional trend.

FACTOR AND GAUGE STATUS
- Select one Insights factor from the available body composition metric keys. Choose the metric that is either the clearest current strength or offers the greatest visible improvement potential.
- Select factor_color for the FFMI, body-fat, and skeletal-muscle gauges from the current data: green for strong status, yellow for a mild opportunity, orange for a meaningful opportunity, and red only for the highest-priority opportunity.
- Keep gauge colors consistent with each gauge's title, comment, and remark. Do not use clinical or risk-based reasoning.

Never use risk-focused, fear-based, or clinical language. No diagnoses, no cliches. Keep every field concise — if a sentence needs a dash or semicolon, split it or cut it.`,
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
  profileMetadata: string;
  bodyCompositionDelta: string;
  bodyMeasurementDelta: string;
  firstHealthDataEntryDate: string;
  latestBodyMeasurement: string;
  latestBodyCompositionMeasurement: string;
}) {
  const healthAgent = createAgent({
    model,
    tools: createTools(input.reportId, input.profileId),
  });

  const result = await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(
        `User MetaData - ${input.profileMetadata}
Body Composition Delta - ${input.bodyCompositionDelta}
Body Measurement Delta - ${input.bodyMeasurementDelta}
First Health Data Entry - ${input.firstHealthDataEntryDate}
Latest Body Measurement - ${input.latestBodyMeasurement}
Latest Body Composition Measurement - ${input.latestBodyCompositionMeasurement}`,
      ),
    ],
  });

  const tokenUsage = getTokenUsage(result);
  // console.log("[healthAgentNew] token usage", tokenUsage);

  return { result, tokenUsage };
}
