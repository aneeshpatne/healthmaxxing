import { SystemMessage } from "langchain";
import { model } from "./model";

const systemMsg = new SystemMessage(
  "You are a fitness coach reviewing someone's progress.",
);
