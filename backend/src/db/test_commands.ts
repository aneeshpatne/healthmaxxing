import { createLabReport, listObservationFieldNames } from "./commands";

const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";
const observationFields = listObservationFieldNames();
const reportId = createLabReport(profileId);

console.log({ observationFields, reportId });
