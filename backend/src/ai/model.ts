import { ChatGoogle } from "@langchain/google";
import { ChatOpenRouter } from "@langchain/openrouter";
import { ChatDeepSeek } from "@langchain/deepseek";
import { ChatOpenAI } from "@langchain/openai";
import { initChatModel } from "langchain";
export const apiKey = process.env.NVIDIA_API_KEY;
export const deepSeekApiKey = process.env.DEEPSEEK_API_KEY;
export const openaiApiKey = process.env.OPENAI_API_KEY;
export const googleApiKey = process.env.GOOGLE_API_KEY;
export const openRouterApiKey = process.env.OPENROUTER_API_KEY;

if (!apiKey) {
  throw new Error("NVIDIA_API_KEY is not set");
}

// export const model = new ChatOpenAI({
//   apiKey: process.env.CEREBRAS_API_KEY,
//   model: "gpt-oss-120b",
//   temperature: 1,
//   maxTokens: 65536,
//   configuration: {
//     baseURL: "https://api.cerebras.ai/v1",
//     defaultHeaders: {
//       Accept: "application/json",
//     },
//   },
// });

export const model = new ChatDeepSeek("deepseek-v4-pro", {
  apiKey: deepSeekApiKey,
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
