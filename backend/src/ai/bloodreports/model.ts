import { initChatModel } from "langchain";
export const openaiApiKey = process.env.OPENAI_API_KEY;

export const model = await initChatModel("openai:gpt-5.5", {
  apiKey: openaiApiKey,
});
