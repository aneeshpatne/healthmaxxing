import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { createProfileAiTools } from "./tools";

const systemMsg = new SystemMessage(
  `You are a fitness coach reviewing someone's progress. Call all three tools: ai_overview, body_analysis, and effort_score.

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

ai_overview RULES
- Title (headline): a short, positive, complete sentence summarizing the user's achievement. This is the primary message they see. Good: "You're making excellent progress.", "Your foundation is getting stronger." Avoid labels or report-style titles.
- Remarks (supporting explanation): one sentence displayed below the headline in smaller text. Explains why they're progressing or what specific metric/result supports the headline. Keep it grounded and specific when possible.

body_analysis RULES
Each of foundation, momentum, and biggest_lever is an object with headline, supporting_description, and actionable_insight:
- Headline: one short sentence, max 12 words. The primary message.
- Supporting description: one sentence, max 18 words. Why it matters.
- Actionable insight: one sentence, max 18 words. A specific next action.

Section guidance:
- Foundation: describe what's already working. Frame the physique as a base to build on, not a judgment. Use personalized measurements when available (e.g. "54 kg lean mass", "broad shoulders at 103 cm") — specific numbers make the insight feel earned. Avoid body-part claims you aren't confident in.
- Momentum: highlight trends and direction. Keep it constructive, not alarming. Focus on outcomes ("body fat is trending down"), not nutrition science ("create a calorie deficit"). If trends are negative, frame as a small course correction opportunity, never a warning.
- Momentum factors: include at most 3 body_composition_metrics_new metric keys most responsible for the momentum insight. These exact factors will be plotted for the user, so choose metrics that visually support the momentum story.
- Biggest lever: the single highest-ROI next move. Must be outcome-oriented — focus on what the user gains, not abstract phrasing. Good: "A leaner waistline will make your chest and shoulder development stand out more." Bad: "Waist at 90 cm is where definition hides." "Reveal" and "stand out" work better than abstract descriptions.
- Physique archetype: 2-3 word positive, identity-based label. Good: "Strong Foundation Frame", "Athletic Foundation", "Muscle-First Build". Never clinical or negative.

effort_score RULES
- Score: an integer 0-100 reflecting how well the user's recent trends align with positive progress. Base it on the direction and consistency of trends across all available data, not a single metric.
- Remark: one coaching sentence explaining the score. Reference the strongest trend signal. Same supportive tone as all other tools.

Never use risk-focused, fear-based, or clinical language. No diagnoses, no cliches. Keep every field concise — if a sentence needs a dash or semicolon, split it or cut it.`,
);

function getNumericField(record: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "number") {
      return value;
    }
  }

  return 0;
}

function logTokenUsage(result: unknown) {
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

  console.log("[healthAgent] token usage", {
    input: tokenUsage.input,
    output: tokenUsage.output,
    reasoning: tokenUsage.reasoning,
    total: tokenUsage.input + tokenUsage.output,
  });
}

export async function analyzeHealthData(profileId: string, healthData: unknown) {
  const healthDataRecord =
    healthData && typeof healthData === "object"
      ? (healthData as Record<string, unknown>)
      : null;
  const firstHealthDataEntry =
    healthDataRecord?.firstHealthDataEntry &&
    typeof healthDataRecord.firstHealthDataEntry === "object"
      ? (healthDataRecord.firstHealthDataEntry as Record<string, unknown>)
      : null;
  const trackingStartDate =
    typeof firstHealthDataEntry?.createdAt === "string"
      ? firstHealthDataEntry.createdAt
      : "unknown";
  const todayDate = new Date().toISOString().slice(0, 10);

  const healthAgent = createAgent({
    model,
    tools: createProfileAiTools(profileId, "deepseek:deepseek-v4-pro"),
  });

  const result = await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(`The user is tracking from this date -> ${trackingStartDate}
Today's date -> ${todayDate}

Analyze this fetched health data:
${JSON.stringify(healthData, null, 2)}`),
    ],
  });

  logTokenUsage(result);

  return result;
}
