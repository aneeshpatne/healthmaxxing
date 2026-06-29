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
  const formattedLatestBodyMeasurement =
    formatLatestBodyMeasurement(latestBodyMeasurement);
  const formattedLatestBodyCompositionMeasurement =
    formatLatestBodyCompositionMeasurement(latestBodyCompositionMeasurement);
  const formattedProfileMetadata = formatRecordAsTsv(
    profileMetadata as Record<string, unknown> | null,
  );

  console.log(formattedBodyCompositionDelta);
  console.log(formattedBodyMeasurementDelta);
  console.log(formattedFirstHealthDataEntryDate);
  console.log(formattedLatestBodyMeasurement);
  console.log(formattedLatestBodyCompositionMeasurement);
  console.log(formattedProfileMetadata);

  const data = await analyzeHealthDataNew({
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

await runAgentOrchestratorNew("019e8724-ccf0-73cb-9c7d-822478474e90");
