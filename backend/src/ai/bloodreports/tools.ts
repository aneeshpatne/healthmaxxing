import { tool } from "langchain";
import * as z from "zod";
import { insertIntoLabReport } from "../../db/commands";

type MakeReportToolsArgs = {
  reportId: string;
};

export function makeReportTools({ reportId }: MakeReportToolsArgs) {
  return [
    tool(async ({ lab_name, report_date, collection_date }) => {
      insertIntoLabReport(reportId, {
        lab_name,
        report_date,
        collection_date,
      });

      return "Saved lab report metadata.";
    }, {
      name: "saveReportMetaData",
      description: "Save lab metadata on the current report.",
      schema: z.object({
        lab_name: z.string(),
        report_date: z.string(),
        collection_date: z.string(),
      }),
    }),
  ];
}
