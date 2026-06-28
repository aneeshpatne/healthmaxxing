import {
  formatBodyCompositionMeasurementDelta,
  formatBodyMeasurementDelta,
  formatLatestBodyCompositionMeasurement,
  formatLatestBodyMeasurement,
  formatRecordAsTsv,
  getBodyCompositionMeasurementDeltaV2,
  getBodyMeasurementDeltaV2,
  getFirstHealthDataEntry,
  getLatestBodyCompositionMeasurementV2,
  getLatestBodyMeasurementV2,
  getProfileMetadata,
} from "../db/db";

const data = await getBodyCompositionMeasurementDeltaV2(
  "019e8724-ccf0-73cb-9c7d-822478474e90",
);

const data2 = await getBodyMeasurementDeltaV2(
  "019e8724-ccf0-73cb-9c7d-822478474e90",
);

const data3 = await getFirstHealthDataEntry(
  "019e8724-ccf0-73cb-9c7d-822478474e90",
);

const data4 = await getLatestBodyMeasurementV2(
  "019e8724-ccf0-73cb-9c7d-822478474e90",
);

const data5 = await getLatestBodyCompositionMeasurementV2(
  "019e8724-ccf0-73cb-9c7d-822478474e90",
);

const data7 = await getProfileMetadata("019e8724-ccf0-73cb-9c7d-822478474e90");

console.log(formatBodyCompositionMeasurementDelta(data));
console.log(formatBodyMeasurementDelta(data2));
console.log(
  data3?.createdAt
    ? new Date(String(data3.createdAt)).toLocaleDateString("en-IN", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : "No health data available.",
);
console.log(formatLatestBodyMeasurement(data4));
console.log(formatLatestBodyCompositionMeasurement(data5));
console.log(formatRecordAsTsv(data7 as Record<string, unknown> | null));
