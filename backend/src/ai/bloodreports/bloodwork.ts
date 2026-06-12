import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { makeReportTools } from "./tools";
import { createLabReport } from "../../db/commands";

const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";
const sampleReportText = `Apollo Diagnostics
Report Date: 2026-06-10
Collection Date: 2026-06-09
Patient: Test User
Section: Complete Blood Count
Hemoglobin: 13.5 g/dL
WBC: 7200 /uL

Section: Lipid Profile
Total Cholesterol: 182 mg/dL
HDL Cholesterol: 52 mg/dL`;

const systemMsg = new SystemMessage(
  `You extract lab report metadata and section names from blood test text.

You have three tools:
- saveReportMetaData
- getSavedSectionNames
- addReportSection

Execution order:
1. Call saveReportMetaData exactly once with:
- lab_name
- report_date
- collection_date
2. Call getSavedSectionNames exactly once to see which normalized section names already exist for this report.
3. For each section present in the report text, if its normalized section name is not already saved, call addReportSection once for that section.

Rules:
- Use the values exactly as written in the report when possible.
- If a date is missing, use an empty string.
- Normalize section names to lowercase snake_case.
- Do not create duplicate sections.
- Do not explain your work outside the tool call.`,
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
      new HumanMessage(`Extract lab report metadata from this text:

${reportText}`),
    ],
  });

  logTokenUsage(result);

  return { reportId, result };
}

if (import.meta.main) {
  const output = await createReport(sampleReportText);
  console.log(output);
}
