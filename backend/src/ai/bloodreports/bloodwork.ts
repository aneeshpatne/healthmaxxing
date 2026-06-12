import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { makeReportTools } from "./tools";
import { createLabReport } from "../../db/commands";

const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";
const reportPath = new URL("./report.md", import.meta.url);

const systemMsg = new SystemMessage(
  `You extract structured lab report metadata, section names, and observation field names from blood test text.

Available tools:
- saveReportMetaData
- getSavedSectionNames
- addReportSection
- getSavedObservationFieldNames
- addObservationField
- addObservation

Execution flow:
1. Call saveReportMetaData exactly once.
   Required values:
   - lab_name
   - report_date
   - collection_date
2. Call getSavedSectionNames exactly once.
3. For each section present in the report:
   - normalize it to lowercase snake_case
   - if that normalized name is not already returned by getSavedSectionNames, call addReportSection once
4. Call getSavedObservationFieldNames exactly once.
5. For each observation/test name present in the report:
   - normalize it to lowercase snake_case
   - if that normalized field name is not already returned by getSavedObservationFieldNames, call addObservationField once
   - include a dense explanation of what the field measures, what specimen/context it belongs to, and how it is typically interpreted structurally
6. After all required sections and observation fields exist, call addObservation once for each observation row in the report.
   Required values:
   - section_name_normalized
   - observation_field_name_normalized
   - test_name_raw
   - test_name_normalized
   - value_raw
   Optional values:
   - value_numeric
   - value_text
   - unit_raw
   - unit_normalized
   - reference_range_raw
   - ref_low
   - ref_high
   - confidence_score

Normalization examples:
- "Complete Blood Count" -> "complete_blood_count"
- "Lipid Profile" -> "lipid_profile"
- "HDL Cholesterol" -> "hdl_cholesterol"
- "Total Cholesterol" -> "total_cholesterol"

Rules:
- Use values exactly as written when possible.
- If a date is missing, use an empty string.
- Observation field explanations must be 1-2 dense sentences, specific to the biomarker or ratio, and should define the measurement rather than interpret this patient's result.
- Good explanation style: "Low-density lipoprotein cholesterol measured in serum, representing cholesterol carried by LDL particles and commonly used as a core lipid marker for atherogenic cholesterol burden."
- Put numeric measurement values in value_numeric when a clear number is present.
- Put non-numeric measurements in value_text.
- Keep value_raw as the original report value with unit when present.
- Use null or omit optional values when they are not present in the report text.
- Do not create duplicate sections.
- Do not create duplicate observation fields.
- Only call addObservation after the matching section and observation field have been created or confirmed to exist.
- Do not explain your work outside tool calls.`,
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

      const inputTokens =
        getNumericField(usageMetadata ?? {}, ["input_tokens"]) ||
        getNumericField(tokenUsageMetadata ?? {}, ["promptTokens"]);
      const outputTokens =
        getNumericField(usageMetadata ?? {}, ["output_tokens"]) ||
        getNumericField(tokenUsageMetadata ?? {}, ["completionTokens"]);

      return {
        input: totals.input + inputTokens,
        output: totals.output + outputTokens,
      };
    },
    { input: 0, output: 0 },
  );

  console.log("[bloodwork] token usage", {
    input: tokenUsage.input,
    output: tokenUsage.output,
    total: tokenUsage.input + tokenUsage.output,
  });
}

export async function createReport(reportText: string) {
  const reportId = createLabReport(profileId);

  const bloodworkAgent = createAgent({
    model,
    tools: makeReportTools({ reportId }),
  });

  const result = await bloodworkAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(`Extract report metadata, sections, observation field names, and observations from this text:

${reportText}`),
    ],
  });

  logTokenUsage(result);

  return { reportId, result };
}

if (import.meta.main) {
  const reportText = await Bun.file(reportPath).text();
  const output = await createReport(reportText);
  console.log(output);
}
