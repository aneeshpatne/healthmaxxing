import { initChatModel } from "langchain";

export const model = await initChatModel("openai:gpt-5.4-nano", {
  reasoningEffort: "low",
});
