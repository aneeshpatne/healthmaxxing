import { createAgent, HumanMessage, SystemMessage } from "langchain";

import { model } from "./model";
import { ai_overview } from "./tools";

const systemMsg = new SystemMessage(
  "You analyze health metrics and summarize them clearly. Use the ai_overview tool to return the final summary. The title is shown on a health tool tile, so write it as a concise, encouraging body-progress headline with a natural human tone. Avoid clinical metric names, labels, and report-style wording.",
);
const humanMsg = new HumanMessage(`Analyze this health data:
{
  bmi: 26.3,
  body_fat_pct: 22.6,
  fat_mass_kg: 17.62,
  fat_free_mass_kg: 60.33,
  body_score: 84,
  body_age_years: 27,
  water_pct: 50.9,
  muscle_mass_kg: 55.14,
  muscle_rate_pct: 70.73,
  bmr_kcal: 1690,
  visceral_fat: 9,
  ideal_weight_kg: 65,
  protein_mass_kg: 12.2,
  protein_pct: 15.6,
  skeletal_muscle_kg: 55.14,
  subcutaneous_fat_pct: 15.07,
  subcutaneous_fat_mass_kg: 11.74,
  predicted_lean_mass_kg: 60.33,
}`);

const messages = [systemMsg, humanMsg];

export const healthAgent = createAgent({
  model,
  tools: [ai_overview],
});

export const response = await healthAgent.invoke({ messages });
