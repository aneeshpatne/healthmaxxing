import { createAgent, HumanMessage, SystemMessage } from "langchain";
import { model } from "./model";
import { createTools } from "./toolsNew";

const systemMsg = new SystemMessage(
  "This is a test run. Invoke the profile_ai_report tool with dummy structured profile report data.",
);

const dummyReportId = "dummy-report-id";
const dummyProfileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

export async function analyzeHealthDataNew() {
  const healthAgent = createAgent({
    model,
    tools: createTools(dummyReportId, dummyProfileId),
  });

  return await healthAgent.invoke({
    messages: [
      systemMsg,
      new HumanMessage(
        "Call the profile_ai_report tool now using realistic dummy values. Do not ask for more data.",
      ),
    ],
  });
}

const data = await analyzeHealthDataNew();
console.log(data);
