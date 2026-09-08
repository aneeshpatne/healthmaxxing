import type { FastifyPluginAsync, FastifyReply } from "fastify";
import { z } from "zod";
import { v7 as uuidv7 } from "uuid";
import { authMiddleware } from "../middleware/auth";
import { db } from "../db/db";
import { model } from "../ai/model";
import { profileBelongsToAccount, type ProfileId } from "../db/commands";

const macroSchema = z.object({
  name: z.string().trim().min(1).max(120),
  servingDescription: z.string().trim().min(1).max(120),
  servings: z.number().positive().max(100),
  meal: z.enum(["breakfast", "lunch", "dinner", "snack"]),
  calories: z.number().nonnegative().max(20_000),
  proteinG: z.number().nonnegative().max(2_000),
  carbsG: z.number().nonnegative().max(2_000),
  fatG: z.number().nonnegative().max(2_000),
  fiberG: z.number().nonnegative().max(1_000),
  saturatedFatG: z.number().nonnegative().max(2_000),
  transFatG: z.number().nonnegative().max(2_000),
  monounsaturatedFatG: z.number().nonnegative().max(2_000),
  polyunsaturatedFatG: z.number().nonnegative().max(2_000),
  sugarG: z.number().nonnegative().max(2_000),
  addedSugarG: z.number().nonnegative().max(2_000),
  sodiumMg: z.number().nonnegative().max(100_000),
  cholesterolMg: z.number().nonnegative().max(100_000),
});

// The Responses API structured-output format requires a single root object and
// does not accept the `oneOf` emitted by Zod discriminated unions. Keep every
// field required in JSON Schema and represent the question state with null.
const analysisSchema = z.object({
  action: z.enum(["ask", "propose"]),
  message: z.string().trim().min(1).max(300),
  food: macroSchema.nullable(),
});

async function authorized(profileId: ProfileId, accountId: string, reply: FastifyReply) {
  if (await profileBelongsToAccount(profileId, accountId)) return true;
  reply.code(404).send({ ok: false, error: "Profile id does not exist" });
  return false;
}

const foodRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authMiddleware);

  app.post("/analyze", async (request, reply) => {
    const body = request.body as { profileId?: string; messages?: Array<{ role: string; content: string }> };
    if (!body.profileId || !Array.isArray(body.messages) || body.messages.length === 0) {
      return reply.code(400).send({ ok: false, error: "profileId and messages are required" });
    }
    if (!await authorized(body.profileId, request.auth.account.id, reply)) return;

    const savedFoods = await db.prepare(
      `SELECT name, serving_description AS "servingDescription", calories,
        protein_g AS "proteinG", carbs_g AS "carbsG", fat_g AS "fatG", fiber_g AS "fiberG",
        saturated_fat_g AS "saturatedFatG", trans_fat_g AS "transFatG",
        monounsaturated_fat_g AS "monounsaturatedFatG", polyunsaturated_fat_g AS "polyunsaturatedFatG",
        sugar_g AS "sugarG", added_sugar_g AS "addedSugarG", sodium_mg AS "sodiumMg",
        cholesterol_mg AS "cholesterolMg"
       FROM foods WHERE profile_id = ? ORDER BY updated_at DESC LIMIT 50`,
    ).all(body.profileId);
    const conversation = body.messages.slice(-12).map((item) =>
      `${item.role === "assistant" ? "Assistant" : "User"}: ${item.content.slice(0, 1_000)}`,
    ).join("\n");

    const structuredModel = model.withStructuredOutput(analysisSchema, { name: "food_log_decision" });
    const result = await structuredModel.invoke(`You are Forma's concise food logging assistant. Extract one food or meal and estimate macros using standard nutrition knowledge. Reuse an exact saved food when clearly referenced. Macros are PER serving; servings is the amount eaten. Ask one short cross-question only when a material detail (food identity, amount, or preparation) prevents a reasonable estimate. Otherwise propose immediately. For action "ask", food must be null. For action "propose", food must be the complete nutrition object. Never claim the food was saved; the user must confirm first.\n\nSaved foods:\n${JSON.stringify(savedFoods)}\n\nConversation:\n${conversation}`);
    if (result.action === "propose" && !result.food) {
      request.log.error("Food model proposed an entry without nutrition data");
      return reply.code(502).send({ ok: false, error: "Food analysis returned incomplete nutrition data" });
    }
    return reply.send({ ok: true, ...result });
  });

  app.post("/confirm", async (request, reply) => {
    const parsed = z.object({ profileId: z.string().uuid(), food: macroSchema }).safeParse(request.body);
    if (!parsed.success) return reply.code(400).send({ ok: false, error: "Invalid food proposal" });
    const { profileId, food } = parsed.data;
    if (!await authorized(profileId, request.auth.account.id, reply)) return;

    const result = await db.transaction(async (tx) => {
      const existing = await tx.prepare(
        `SELECT id FROM foods WHERE profile_id = ? AND lower(name) = lower(?)
         AND lower(serving_description) = lower(?) ORDER BY updated_at DESC LIMIT 1`,
      ).get(profileId, food.name, food.servingDescription);
      const foodId = typeof existing?.id === "string" ? existing.id : uuidv7();
      if (existing) {
        await tx.prepare(`UPDATE foods SET calories = ?, protein_g = ?, carbs_g = ?, fat_g = ?, fiber_g = ?, saturated_fat_g = ?, trans_fat_g = ?, monounsaturated_fat_g = ?, polyunsaturated_fat_g = ?, sugar_g = ?, added_sugar_g = ?, sodium_mg = ?, cholesterol_mg = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
          .run(food.calories, food.proteinG, food.carbsG, food.fatG, food.fiberG, food.saturatedFatG, food.transFatG, food.monounsaturatedFatG, food.polyunsaturatedFatG, food.sugarG, food.addedSugarG, food.sodiumMg, food.cholesterolMg, foodId);
      } else {
        await tx.prepare(`INSERT INTO foods (id, profile_id, name, serving_description, calories, protein_g, carbs_g, fat_g, fiber_g, saturated_fat_g, trans_fat_g, monounsaturated_fat_g, polyunsaturated_fat_g, sugar_g, added_sugar_g, sodium_mg, cholesterol_mg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
          .run(foodId, profileId, food.name, food.servingDescription, food.calories, food.proteinG, food.carbsG, food.fatG, food.fiberG, food.saturatedFatG, food.transFatG, food.monounsaturatedFatG, food.polyunsaturatedFatG, food.sugarG, food.addedSugarG, food.sodiumMg, food.cholesterolMg);
      }
      const entryId = uuidv7();
      await tx.prepare(`INSERT INTO food_entries (id, profile_id, food_id, servings, meal) VALUES (?, ?, ?, ?, ?)`)
        .run(entryId, profileId, foodId, food.servings, food.meal);
      return { foodId, entryId };
    });
    return reply.code(201).send({ ok: true, ...result });
  });

  app.get("/saved/:profileId", async (request, reply) => {
    const { profileId } = request.params as { profileId: string };
    if (!await authorized(profileId, request.auth.account.id, reply)) return;
    const foods = await db.prepare(
      `SELECT id, name, serving_description AS "servingDescription", 1::double precision AS servings,
        'snack' AS meal, calories, protein_g AS "proteinG", carbs_g AS "carbsG",
        fat_g AS "fatG", fiber_g AS "fiberG", saturated_fat_g AS "saturatedFatG",
        trans_fat_g AS "transFatG", monounsaturated_fat_g AS "monounsaturatedFatG",
        polyunsaturated_fat_g AS "polyunsaturatedFatG", sugar_g AS "sugarG",
        added_sugar_g AS "addedSugarG", sodium_mg AS "sodiumMg", cholesterol_mg AS "cholesterolMg"
       FROM foods WHERE profile_id = ? ORDER BY updated_at DESC, name ASC`,
    ).all(profileId);
    return reply.send({ ok: true, foods });
  });

  app.get("/dashboard/:profileId", async (request, reply) => {
    const { profileId } = request.params as { profileId: string };
    if (!await authorized(profileId, request.auth.account.id, reply)) return;
    const entries = await db.prepare(
      `SELECT e.id, f.name, f.serving_description AS "servingDescription", e.servings, e.meal,
        e.logged_at AS "loggedAt", f.calories * e.servings AS calories,
        f.protein_g * e.servings AS "proteinG", f.carbs_g * e.servings AS "carbsG",
        f.fat_g * e.servings AS "fatG", f.fiber_g * e.servings AS "fiberG"
       FROM food_entries e JOIN foods f ON f.id = e.food_id
       WHERE e.profile_id = ? AND e.logged_at >= date_trunc('day', CURRENT_TIMESTAMP)
       ORDER BY e.logged_at DESC`,
    ).all(profileId);
    const trends = await db.prepare(
      `SELECT to_char(date_trunc('day', e.logged_at), 'YYYY-MM-DD') AS date,
        SUM(f.calories * e.servings)::double precision AS calories,
        SUM(f.protein_g * e.servings)::double precision AS "proteinG",
        SUM(f.carbs_g * e.servings)::double precision AS "carbsG",
        SUM(f.fat_g * e.servings)::double precision AS "fatG"
       FROM food_entries e JOIN foods f ON f.id = e.food_id
       WHERE e.profile_id = ? AND e.logged_at >= CURRENT_TIMESTAMP - INTERVAL '13 days'
       GROUP BY date_trunc('day', e.logged_at) ORDER BY date_trunc('day', e.logged_at)`,
    ).all(profileId);
    return reply.send({ ok: true, entries, trends, goals: { calories: 2200, proteinG: 160, carbsG: 240, fatG: 70 } });
  });
};

export default foodRoutes;
