import { HumanMessage, initChatModel, SystemMessage } from "langchain";
import { ChatGoogle } from "@langchain/google";
import { ChatOpenRouter } from "@langchain/openrouter";
import { ChatDeepSeek } from "@langchain/deepseek";

export const apiKey = process.env.DEEPSEEK_API_KEY;
export const openaiApiKey = process.env.OPENAI_API_KEY;
export const googleApiKey = process.env.GOOGLE_API_KEY;
export const openRouterApiKey = process.env.OPENROUTER_API_KEY;

if (!apiKey) {
  throw new Error("API KEY is not set");
}

export const model = new ChatDeepSeek("deepseek-v4-pro", {
  apiKey,
  modelKwargs: {
    reasoning_effort: "high",
  },
});

// export const model = await initChatModel("openai:gpt-5.5", {
//   apiKey: openaiApiKey,
// });

// export const model = new ChatGoogle({
//   apiKey: googleApiKey,
//   model: "gemma-4-31b-it",
// });

// export const model = new ChatOpenRouter({
//   apiKey: openRouterApiKey,
//   model: "google/gemini-3.5-flash",
// });

// const response = await model.invoke("Why do parrots talk?");

// console.log(response);
