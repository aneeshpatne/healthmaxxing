import { analyzeHealthData } from "./healthAgent";
import { getProfileFatReport, getProfileMuscleReport } from "../db/commands";
import {
  getBodyCompositionMeasurementDelta,
  getBodyMeasurementDelta,
  getFirstHealthDataEntry,
  getLatestBodyCompositionMeasurement,
  getLatestBodyMeasurement,
  getLatestWeightMeasurement,
  getProfileMetadata,
} from "../db/db";

const defaultProfileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

function getDesiredWeightTarget(
  profileMetadata: unknown,
  latestBodyCompositionMeasurement: unknown,
) {
  const metadata =
    profileMetadata && typeof profileMetadata === "object"
      ? (profileMetadata as Record<string, unknown>)
      : null;
  const measurement =
    latestBodyCompositionMeasurement &&
    typeof latestBodyCompositionMeasurement === "object"
      ? (latestBodyCompositionMeasurement as Record<string, unknown>)
      : null;

  return {
    preferredBodyFatPct: metadata?.preferredBodyFatPct ?? 18,
    desiredWeightKg: measurement?.desired_weight_kg ?? null,
    formula:
      "desired_weight_kg = fat_free_mass_kg / (1 - preferred_body_fat_pct / 100)",
  };
}

export function fetchHealthData(profileId: string) {
  const profileMetadata = getProfileMetadata(profileId);
  const latestBodyCompositionMeasurement =
    getLatestBodyCompositionMeasurement(profileId);

  return {
    profileMetadata,
    firstHealthDataEntry: getFirstHealthDataEntry(profileId),
    latestBodyCompositionMeasurement,
    desiredWeightTarget: getDesiredWeightTarget(
      profileMetadata,
      latestBodyCompositionMeasurement,
    ),
    latestBodyMeasurement: getLatestBodyMeasurement(profileId),
    latestWeightMeasurement: getLatestWeightMeasurement(profileId),
    bodyCompositionMeasurementDelta:
      getBodyCompositionMeasurementDelta(profileId),
    bodyMeasurementDelta: getBodyMeasurementDelta(profileId),
    fatReport: getProfileFatReport(profileId),
    muscleReport: getProfileMuscleReport(profileId),
  };
}

export async function runHealthAgent(profileId = defaultProfileId) {
  const healthData = fetchHealthData(profileId);

  return analyzeHealthData(profileId, healthData);
}

export const response = await runHealthAgent();
