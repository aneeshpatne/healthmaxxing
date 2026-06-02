import { HumanMessage, initChatModel, SystemMessage } from "langchain";
import { ChatGoogle } from "@langchain/google";
import { ChatOpenRouter } from "@langchain/openrouter";

export const apiKey = process.env.DEEPSEEK_API_KEY;

if (!apiKey) {
  throw new Error("API KEY is not set");
}

export const model = await initChatModel("deepseek:deepseek-v4-flash", {
  apiKey,
});

const response = await model.invoke("Why do parrots talk?");

console.log(response);
