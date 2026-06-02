import {
  getBodyCompositionMeasurementDelta,
  getBodyMeasurementDelta,
  getLatestBodyCompositionMeasurement,
  getLatestBodyMeasurement,
  getProfileMetadata,
} from "./db";

const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

const profileMetadata = getProfileMetadata(profileId);
const measurements = getLatestBodyCompositionMeasurement(profileId);
const latestMeasurement = getLatestBodyMeasurement(profileId);
const measurementDelta = getBodyCompositionMeasurementDelta(profileId);
const deltaMeasurements = getBodyMeasurementDelta(profileId);

console.log(profileMetadata);
console.log(measurements);
console.log(latestMeasurement);
console.log(measurementDelta);
console.log(deltaMeasurements);
