import { tool } from "langchain";
import * as z from "zod";
import {
  addObservation,
  addObservationField,
  addReportSection,
  insertIntoLabReport,
  listObservationFieldNames,
  listReportSectionNames,
  updateObservationFieldRemark,
} from "../../db/commands";

type MakeReportToolsArgs = {
  reportId: string;
};

export function makeReportTools({ reportId }: MakeReportToolsArgs) {
  const knownSectionNames = listReportSectionNames(reportId)
    .map((row) => row.section_name_normalized)
    .filter((name): name is string => name !== null);
  const knownObservationFieldNames = listObservationFieldNames().map(
    (row) => row.field_name_normalized,
  );

  return [
    tool(
      async ({ lab_name, report_date, collection_date }) => {
        insertIntoLabReport(reportId, {
          lab_name,
          report_date,
          collection_date,
        });

        return "Saved lab report metadata.";
      },
      {
        name: "saveReportMetaData",
        description: "Save lab metadata on the current report.",
        schema: z.object({
          lab_name: z.string(),
          report_date: z.string(),
          collection_date: z.string(),
        }),
      },
    ),
    tool(
      async () => {
        return knownSectionNames;
      },
      {
        name: "getSavedSectionNames",
        description:
          "Return the normalized section names already saved for this report so duplicates are not created.",
        schema: z.object({}),
      },
    ),
    tool(
      async ({ section_name_raw, section_name_normalized }) => {
        const sectionId = addReportSection({
          report_id: reportId,
          section_name_raw,
          section_name_normalized,
        });

        return {
          sectionId,
          section_name_normalized,
        };
      },
      {
        name: "addReportSection",
        description:
          "Add one report section for the current report using the raw section title and required normalized section name.",
        schema: z.object({
          section_name_raw: z.string(),
          section_name_normalized: z.string(),
        }),
      },
    ),
    tool(
      async () => {
        return knownObservationFieldNames;
      },
      {
        name: "getSavedObservationFieldNames",
        description:
          "Return the normalized observation field names already saved so duplicates are not created.",
        schema: z.object({}),
      },
    ),
    tool(
      async ({
        field_name,
        field_name_normalized,
        explanation,
        default_unit,
        is_trendable,
      }) => {
        const observationFieldId = addObservationField({
          field_name,
          field_name_normalized,
          explanation,
          default_unit,
          is_trendable,
        });

        return {
          observationFieldId,
          field_name_normalized,
        };
      },
      {
        name: "addObservationField",
        description:
          "Add one observation field using the raw field name, normalized field name, and dense explanation.",
        schema: z.object({
          field_name: z.string(),
          field_name_normalized: z.string(),
          explanation: z.string(),
          default_unit: z.string().nullable().optional(),
          is_trendable: z.boolean().optional(),
        }),
      },
    ),
    tool(
      async ({
        section_name_normalized,
        observation_field_name_normalized,
        test_name_raw,
        test_name_normalized,
        value_raw,
        value_numeric,
        value_text,
        unit_raw,
        unit_normalized,
        reference_range_raw,
        ref_low,
        ref_high,
        inference,
        confidence_score,
      }) => {
        const observationId = addObservation({
          report_id: reportId,
          section_name_normalized,
          observation_field_name_normalized,
          test_name_raw,
          test_name_normalized,
          value_raw,
          value_numeric,
          value_text,
          unit_raw,
          unit_normalized,
          reference_range_raw,
          ref_low,
          ref_high,
          inference,
          confidence_score,
        });

        return {
          observationId,
          test_name_normalized,
        };
      },
      {
        name: "addObservation",
        description:
          "Add one extracted lab observation to the current report. The referenced section and observation field must already exist.",
        schema: z.object({
          section_name_normalized: z.string(),
          observation_field_name_normalized: z.string(),
          test_name_raw: z.string(),
          test_name_normalized: z.string(),
          value_raw: z.string(),
          value_numeric: z.number().nullable().optional(),
          value_text: z.string().nullable().optional(),
          unit_raw: z.string().nullable().optional(),
          unit_normalized: z.string().nullable().optional(),
          reference_range_raw: z.string().nullable().optional(),
          ref_low: z.number().nullable().optional(),
          ref_high: z.number().nullable().optional(),
          inference: z.string(),
          confidence_score: z.number().min(0).max(1).nullable().optional(),
        }),
      },
    ),
    tool(
      async ({ field_name_normalized, remark }) => {
        updateObservationFieldRemark({
          field_name_normalized,
          remark,
        });

        return `Saved trend remark for ${field_name_normalized}.`;
      },
      {
        name: "updateObservationFieldRemark",
        description:
          "Populate or update the trend remark for one trendable observation field.",
        schema: z.object({
          field_name_normalized: z.string(),
          remark: z
            .string()
            .describe(
              "Dense one-sentence trend remark based on the last year of values for this normalized observation field.",
            ),
        }),
      },
    ),
  ];
}
