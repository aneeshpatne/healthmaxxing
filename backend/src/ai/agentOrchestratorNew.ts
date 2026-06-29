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
import { analyzeHealthDataNew, type TokenUsage } from "./healthAgentNew";

export type AgentOrchestratorNewResult = {
  result: unknown;
  tokenUsage: TokenUsage;
};

export async function runAgentOrchestratorNew(
  userId: string,
  reportId: string,
): Promise<AgentOrchestratorNewResult> {
  const bodyCompositionDelta =
    await getBodyCompositionMeasurementDeltaV2(userId);

  const bodyMeasurementDelta = await getBodyMeasurementDeltaV2(userId);

  const firstHealthDataEntry = await getFirstHealthDataEntry(userId);

  const latestBodyMeasurement = await getLatestBodyMeasurementV2(userId);

  const latestBodyCompositionMeasurement =
    await getLatestBodyCompositionMeasurementV2(userId);

  const profileMetadata = await getProfileMetadata(userId);

  const formattedBodyCompositionDelta =
    formatBodyCompositionMeasurementDelta(bodyCompositionDelta);
  const formattedBodyMeasurementDelta =
    formatBodyMeasurementDelta(bodyMeasurementDelta);
  const formattedFirstHealthDataEntryDate = firstHealthDataEntry?.createdAt
    ? new Date(String(firstHealthDataEntry.createdAt)).toLocaleDateString(
        "en-IN",
        {
          year: "numeric",
          month: "long",
          day: "numeric",
        },
      )
    : "No health data available.";
  const formattedLatestBodyMeasurement = formatLatestBodyMeasurement(
    latestBodyMeasurement,
  );
  const formattedLatestBodyCompositionMeasurement =
    formatLatestBodyCompositionMeasurement(latestBodyCompositionMeasurement);
  const formattedProfileMetadata = formatRecordAsTsv(
    profileMetadata as Record<string, unknown> | null,
  );

  const data = await analyzeHealthDataNew({
    reportId,
    profileId: userId,
    profileMetadata: formattedProfileMetadata,
    bodyCompositionDelta: formattedBodyCompositionDelta,
    bodyMeasurementDelta: formattedBodyMeasurementDelta,
    firstHealthDataEntryDate: formattedFirstHealthDataEntryDate,
    latestBodyMeasurement: formattedLatestBodyMeasurement,
    latestBodyCompositionMeasurement: formattedLatestBodyCompositionMeasurement,
  });

  console.log("[agentOrchestratorNew] total token spend", {
    total: data.tokenUsage.total,
    input: data.tokenUsage.input,
    output: data.tokenUsage.output,
    reasoning: data.tokenUsage.reasoning,
  });

  return data;
}
