import {
  addReportSection,
  createLabReport,
  listObservationFieldNames,
} from "./commands";

const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";
const observationFields = listObservationFieldNames();
const reportId = createLabReport(profileId);
const sectionId = addReportSection({
  report_id: reportId,
  section_name_raw: "Complete Blood Count",
  section_name_normalized: "complete_blood_count",
});

console.log({ observationFields, reportId, sectionId });
