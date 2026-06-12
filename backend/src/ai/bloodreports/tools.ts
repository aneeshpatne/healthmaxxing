import { tool } from "langchain";
import * as z from "zod";
import {
  addReportSection,
  insertIntoLabReport,
  listReportSectionNames,
} from "../../db/commands";

type MakeReportToolsArgs = {
  reportId: string;
};

export function makeReportTools({ reportId }: MakeReportToolsArgs) {
  const knownSectionNames = listReportSectionNames(reportId)
    .map((row) => row.section_name_normalized)
    .filter((name): name is string => name !== null);

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
  ];
}
