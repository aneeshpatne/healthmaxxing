import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { makeReportTools } from "./tools";
import {
  createLabReport,
  listTrendableObservationValuesLastYear,
} from "../../db/commands";

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
- updateObservationFieldRemark

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
   - set is_trendable to true when the field is a repeatable numeric biomarker, numeric ratio, calculated value, or lab metric that would be meaningful to plot over time for the user
   - set is_trendable to false only for fields that are textual, one-off, administrative, categorical, or not useful as a time-series chart
6. After all required sections and observation fields exist, call addObservation once for each observation row in the report.
   Required values:
   - section_name_normalized
   - observation_field_name_normalized
   - test_name_raw
   - test_name_normalized
   - value_raw
   - inference
   Optional values:
   - value_numeric
   - value_text
   - unit_raw
   - unit_normalized
   - reference_range_raw
   - ref_low
   - ref_high
   - confidence_score
7. Review the supplied one-year trendable observation context.
   - These are the fields that already have is_trendable turned on.
   - For each listed trendable field, call updateObservationFieldRemark once.
   - Use the last-year values and inferences to write a dense one-sentence trend remark.
   - If no trendable fields are listed, do not call updateObservationFieldRemark.

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
- Mark cholesterol fractions, triglycerides, lipid ratios, apolipoproteins, lipoprotein(a), blood counts, hormones, vitamins, enzymes, electrolytes, kidney markers, liver markers, inflammatory markers, and other numeric biomarkers as is_trendable true when they can be compared across future reports.
- A field does not need a perfect reference range to be trendable; it only needs to be a stable repeatable measurement with numeric values that can show meaningful direction over time.
- Put numeric measurement values in value_numeric when a clear number is present.
- Put non-numeric measurements in value_text.
- Keep value_raw as the original report value with unit when present.
- Inference is required for every observation. It should be one concise sentence explaining this value relative to its reference range, for example whether it is within range, above range, below range, or ratio-favorable/unfavorable when a range is provided.
- Use null or omit optional values when they are not present in the report text.
- Do not create duplicate sections.
- Do not create duplicate observation fields.
- Only call addObservation after the matching section and observation field have been created or confirmed to exist.
- Only call updateObservationFieldRemark for fields listed in the trendable observation context.
- Do not explain your work outside tool calls.`,
);

 async function formatTrendableObservationContext(profileId: string) {
  const trendableValues = await listTrendableObservationValuesLastYear(profileId);

  if (trendableValues.length === 0) {
    return "No trendable observation values found in the last year.";
  }

  const grouped = new Map<
    string,
    {
      fieldName: string;
      explanation: string;
      defaultUnit: string | null;
      remark: string;
      values: string[];
    }
  >();

  for (const value of trendableValues) {
    const group = grouped.get(value.fieldNameNormalized) ?? {
      fieldName: value.fieldName,
      explanation: value.explanation,
      defaultUnit: value.defaultUnit,
      remark: value.remark,
      values: [],
    };

    group.values.push(
      [
        value.observedAt,
        value.valueRaw,
        value.unitNormalized,
        value.inference,
      ]
        .filter(Boolean)
        .join(" | "),
    );
    grouped.set(value.fieldNameNormalized, group);
  }

  return Array.from(grouped.entries())
    .map(([fieldNameNormalized, group]) =>
      [
        `field_name_normalized: ${fieldNameNormalized}`,
        `field_name: ${group.fieldName}`,
        `default_unit: ${group.defaultUnit ?? ""}`,
        `current_remark: ${group.remark}`,
        `explanation: ${group.explanation}`,
        `last_year_values:`,
        ...group.values.map((value) => `- ${value}`),
      ].join("\n"),
    )
    .join("\n\n");
}

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
  const reportId = await createLabReport(profileId);
  const trendableObservationContext =
    await formatTrendableObservationContext(profileId);

  const bloodworkAgent = createAgent({
    model,
    tools: await makeReportTools({ reportId }),
  });

  const result = await bloodworkAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(`Extract report metadata, sections, observation field names, and observations from this text:

${reportText}

Trendable observation context from the last year:
${trendableObservationContext}`),
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
