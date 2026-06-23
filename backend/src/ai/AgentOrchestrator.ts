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

export async function fetchHealthData(profileId: string) {
  const profileMetadata = await getProfileMetadata(profileId);
  const latestBodyCompositionMeasurement =
    await getLatestBodyCompositionMeasurement(profileId);

  return {
    profileMetadata,
    firstHealthDataEntry: await getFirstHealthDataEntry(profileId),
    latestBodyCompositionMeasurement,
    desiredWeightTarget: getDesiredWeightTarget(
      profileMetadata,
      latestBodyCompositionMeasurement,
    ),
    latestBodyMeasurement: await getLatestBodyMeasurement(profileId),
    latestWeightMeasurement: await getLatestWeightMeasurement(profileId),
    bodyCompositionMeasurementDelta:
      await getBodyCompositionMeasurementDelta(profileId),
    bodyMeasurementDelta: await getBodyMeasurementDelta(profileId),
    fatReport: await getProfileFatReport(profileId),
    muscleReport: await getProfileMuscleReport(profileId),
  };
}

export async function runHealthAgent(profileId = defaultProfileId) {
  const healthData = await fetchHealthData(profileId);

  return await analyzeHealthData(profileId, healthData);
}

export const response = await runHealthAgent();
