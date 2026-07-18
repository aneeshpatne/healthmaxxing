import {
  formatIsoDate,
  formatProfileMetadataCompact,
  formatSnapshotWithDeltas,
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

/**
 * Build compact LLM context.
 * Legend (sent once in human message): m=metric, v=current,
 * all/y1/d30/d7 = latest − period average.
 */
export function buildHealthAgentUserContext(input: {
  profileMetadata: Record<string, unknown> | null;
  bodyCompositionDelta: Awaited<
    ReturnType<typeof getBodyCompositionMeasurementDeltaV2>
  >;
  bodyMeasurementDelta: Awaited<
    ReturnType<typeof getBodyMeasurementDeltaV2>
  >;
  latestBodyComposition: Awaited<
    ReturnType<typeof getLatestBodyCompositionMeasurementV2>
  >;
  latestBodyMeasurement: Awaited<
    ReturnType<typeof getLatestBodyMeasurementV2>
  >;
  firstHealthDataEntry: Awaited<ReturnType<typeof getFirstHealthDataEntry>>;
}): string {
  const lines: string[] = [];

  const meta = formatProfileMetadataCompact(input.profileMetadata);
  if (meta) lines.push(`meta: ${meta}`);

  const since = formatIsoDate(input.firstHealthDataEntry?.createdAt);
  if (since) lines.push(`since: ${since}`);

  const bodyComposition = formatSnapshotWithDeltas(
    input.latestBodyComposition,
    input.bodyCompositionDelta,
  );
  if (bodyComposition) {
    lines.push("bc:");
    lines.push(bodyComposition);
  }

  const bodyMeasurements = formatSnapshotWithDeltas(
    input.latestBodyMeasurement,
    input.bodyMeasurementDelta,
  );
  if (bodyMeasurements) {
    lines.push("bm:");
    lines.push(bodyMeasurements);
  }

  return lines.join("\n") || "No health data available.";
}

export async function runAgentOrchestratorNew(
  userId: string,
  reportId: string,
): Promise<AgentOrchestratorNewResult> {
  const [
    bodyCompositionDelta,
    bodyMeasurementDelta,
    firstHealthDataEntry,
    latestBodyMeasurement,
    latestBodyCompositionMeasurement,
    profileMetadata,
  ] = await Promise.all([
    getBodyCompositionMeasurementDeltaV2(userId),
    getBodyMeasurementDeltaV2(userId),
    getFirstHealthDataEntry(userId),
    getLatestBodyMeasurementV2(userId),
    getLatestBodyCompositionMeasurementV2(userId),
    getProfileMetadata(userId),
  ]);

  const userContext = buildHealthAgentUserContext({
    profileMetadata: profileMetadata as Record<string, unknown> | null,
    bodyCompositionDelta,
    bodyMeasurementDelta,
    latestBodyComposition: latestBodyCompositionMeasurement,
    latestBodyMeasurement,
    firstHealthDataEntry,
  });

  const data = await analyzeHealthDataNew({
    reportId,
    profileId: userId,
    userContext,
  });

  console.log("[agentOrchestratorNew] total token spend", {
    total: data.tokenUsage.total,
    input: data.tokenUsage.input,
    output: data.tokenUsage.output,
    reasoning: data.tokenUsage.reasoning,
  });

  return data;
}
