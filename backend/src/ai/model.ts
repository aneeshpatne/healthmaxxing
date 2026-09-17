import { ChatOpenRouter } from "@langchain/openrouter";

export const openaiApiKey = process.env.OPENAI_API_KEY;
export const googleApiKey = process.env.GOOGLE_API_KEY;
export const openRouterApiKey = process.env.OPENROUTER_API_KEY;
export const ollamaApiKey = process.env.OLLAMA_API_KEY;
export const ollamaBaseUrl =
  process.env.OLLAMA_BASE_URL ?? "http://localhost:11434/v1";

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

// Prefer OpenAI Flex, fall back to standard OpenAI (not other providers).
// Tier slugs like openai/flex are not matched by the base "openai" slug.
export const model = new ChatOpenRouter({
  apiKey: openRouterApiKey,
  model: "openai/gpt-6-astra",
  provider: {
    order: ["openai/flex", "openai"],
    only: ["openai/flex", "openai"],
  },
});

// export const model = new ChatGoogle({
//   apiKey: googleApiKey,
//   model: "gemma-4-31b-it",
// });

// export const model = new ChatOpenRouter({
//   apiKey: openRouterApiKey,
//   model: "google/gemini-3.5-flash",
// });

// export const model = new ChatOpenAI({
//   apiKey: ollamaApiKey ?? "ollama",
//   model: "gpt-oss:20b-cloud",
//   configuration: {
//     baseURL: ollamaBaseUrl,
//   },
// });

// const response = await model.invoke("Why do parrots talk?");

// console.log(response);
