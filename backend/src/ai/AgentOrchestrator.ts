import { analyzeHealthData } from "./healthAgent";
import {
  getBodyCompositionMeasurementDelta,
  getBodyMeasurementDelta,
  getLatestBodyCompositionMeasurement,
  getLatestBodyMeasurement,
  getProfileMetadata,
} from "../db/db";

const defaultProfileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

export function fetchHealthData(profileId: string) {
  return {
    profileMetadata: getProfileMetadata(profileId),
    latestBodyCompositionMeasurement:
      getLatestBodyCompositionMeasurement(profileId),
    latestBodyMeasurement: getLatestBodyMeasurement(profileId),
    bodyCompositionMeasurementDelta:
      getBodyCompositionMeasurementDelta(profileId),
    bodyMeasurementDelta: getBodyMeasurementDelta(profileId),
  };
}

export async function runHealthAgent(profileId = defaultProfileId) {
  const healthData = fetchHealthData(profileId);

  return analyzeHealthData(profileId, healthData);
}

export const response = await runHealthAgent();
