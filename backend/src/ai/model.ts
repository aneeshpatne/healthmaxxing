import { HumanMessage, initChatModel, SystemMessage } from "langchain";
import { ChatGoogle } from "@langchain/google";
import { ChatOpenRouter } from "@langchain/openrouter";

export const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  throw new Error("OPENAI_API_KEY is not set");
}

export const googleApiKey = process.env.GOOGLE_API_KEY;

if (!googleApiKey) {
  throw new Error("GOOGLE_API_KEY is not set");
}

export const openRouterApiKey = process.env.OPENROUTER_API_KEY;

if (!openRouterApiKey) {
  throw new Error("OPENROUTER_API_KEY is not set");
}

export const model = await initChatModel("openai:gpt-5.4-nano", {
  apiKey,
  reasoningEffort: "low",
});

export const secondaryModel = new ChatOpenRouter({
  model: "deepseek/deepseek-v4-flash",
  apiKey: openRouterApiKey,
});

const llm = new ChatGoogle({
  apiKey: googleApiKey,
  model: "gemma-4-31b-it",
  //   model: "gemini-3.1-flash-lite",
  maxRetries: 2,
});
