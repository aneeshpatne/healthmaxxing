import { initChatModel } from "langchain";
export const openaiApiKey = process.env.OPENAI_API_KEY;

if (!openaiApiKey) {
  throw new Error("OPENAI_API_KEY is not set");
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

// export const model = new ChatDeepSeek("deepseek-v4-pro", {
//   apiKey: deepSeekApiKey,
//   modelKwargs: {
//     reasoning_effort: "high",
//   },
// });

export const model = await initChatModel("gpt-5.6-terra", {
  modelProvider: "openai",
  apiKey: openaiApiKey,
  useResponsesApi: true,
  reasoningEffort: "low",
  promptCacheKey: "healthmaxxing-report-agent-v2",
  promptCacheRetention: "24h",
});

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
