import {
  formatIsoDate,
  formatProfileMetadataCompact,
  formatSnapshotWithDeltas,
  getBodyCompositionEndpointTrendsV2,
  getBodyCompositionMeasurementByIdV2,
  getBodyMeasurementEndpointTrendsV2,
  getFirstHealthDataEntry,
  getLatestBodyMeasurementAtV2,
  getProfileMetadata,
} from "../db/db";
import { getProfileInsightReportSource } from "../db/commands";
import { analyzeHealthDataNew, type TokenUsage } from "./healthAgentNew";

export type AgentOrchestratorNewResult = {
  result: unknown;
  tokenUsage: TokenUsage;
  toolCallCount: number;
};

/**
 * Build compact LLM context.
 * Legend (sent once in human message): m=metric, v=current,
 * all/y1/d30/d7 = current − earliest reading in the period.
 */
export function buildHealthAgentUserContext(input: {
  profileMetadata: Record<string, unknown> | null;
  bodyCompositionDelta: Awaited<
    ReturnType<typeof getBodyCompositionEndpointTrendsV2>
  >;
  bodyMeasurementDelta: Awaited<
    ReturnType<typeof getBodyMeasurementEndpointTrendsV2>
  >;
  latestBodyComposition: Awaited<
    ReturnType<typeof getBodyCompositionMeasurementByIdV2>
  >;
  latestBodyMeasurement: Awaited<
    ReturnType<typeof getLatestBodyMeasurementAtV2>
  >;
  firstHealthDataEntry: Awaited<ReturnType<typeof getFirstHealthDataEntry>>;
}): string {
  const lines: string[] = [];

  const meta = formatProfileMetadataCompact(input.profileMetadata);
  if (meta) lines.push(`meta: ${meta}`);

  const since = formatIsoDate(input.firstHealthDataEntry?.createdAt);
  if (since) lines.push(`since: ${since}`);
  lines.push(
    `report: as_of=${formatIsoDate(input.bodyCompositionDelta.asOf) ?? input.bodyCompositionDelta.asOf} ` +
      `bc_readings=${input.bodyCompositionDelta.readingCount} ` +
      `bm_readings=${input.bodyMeasurementDelta.readingCount}`,
  );

  const bodyComposition = formatSnapshotWithDeltas(
    input.latestBodyComposition,
    input.bodyCompositionDelta.table,
  );
  if (bodyComposition) {
    lines.push("bc:");
    lines.push(bodyComposition);
  }

  const bodyMeasurements = formatSnapshotWithDeltas(
    input.latestBodyMeasurement,
    input.bodyMeasurementDelta.table,
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
  const source = await getProfileInsightReportSource({
    reportId,
    profileId: userId,
  });
  const [
    bodyCompositionDelta,
    bodyMeasurementDelta,
    firstHealthDataEntry,
    latestBodyMeasurement,
    latestBodyCompositionMeasurement,
  ] = await Promise.all([
    getBodyCompositionEndpointTrendsV2(userId, source.asOf),
    getBodyMeasurementEndpointTrendsV2(userId, source.asOf),
    getFirstHealthDataEntry(userId),
    getLatestBodyMeasurementAtV2(userId, source.asOf),
    getBodyCompositionMeasurementByIdV2(
      userId,
      source.bodyCompositionMetricsId,
    ),
  ]);
  const profileMetadata =
    source.profileContext ?? await getProfileMetadata(userId);

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
