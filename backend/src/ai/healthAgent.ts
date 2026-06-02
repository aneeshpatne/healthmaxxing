import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { ai_overview } from "./tools";
import {
  getBodyCompositionMeasurementDelta,
  getBodyMeasurementDelta,
  getLatestBodyCompositionMeasurement,
  getLatestBodyMeasurement,
  getProfileMetadata,
} from "../db/db";

const defaultProfileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

const systemMsg = new SystemMessage(
  "You analyze health metrics and summarize them clearly. Use the ai_overview tool to return the final summary. The title is shown on a health tool tile, so write it as a concise, encouraging body-progress headline with a natural human tone. Avoid clinical metric names, labels, and report-style wording.",
);

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

export function buildHealthMessages(
  healthData: ReturnType<typeof fetchHealthData>,
) {
  return [
    systemMsg,
    new HumanMessage(`Analyze this fetched health data:
${JSON.stringify(healthData, null, 2)}`),
  ];
}

export const healthAgent = createAgent({
  model,
  tools: [ai_overview],
});

export async function runHealthAgent(profileId = defaultProfileId) {
  const healthData = fetchHealthData(profileId);
  const messages = buildHealthMessages(healthData);

  return healthAgent.invoke({ messages });
}

export const response = await runHealthAgent();
