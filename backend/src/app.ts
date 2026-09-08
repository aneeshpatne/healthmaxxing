import Fastify from "fastify";
import { clerkPlugin } from "@clerk/fastify";
import clientRoutes from "./routes/client.ts";
import foodRoutes from "./routes/food.ts";
import ingestRoutes from "./routes/ingest.ts";
import { checkDatabase } from "./db/client.ts";

export function buildApp() {
  const app = Fastify({
    logger: true,
    bodyLimit: 10 * 1024 * 1024,
  });

  app.register(clerkPlugin);
  app.get("/health", async (_request, reply) => {
    try {
      await checkDatabase();
      return { ok: true, database: "up" };
    } catch {
      return reply.code(503).send({ ok: false, database: "down" });
    }
  });

  app.register(ingestRoutes, {
    prefix: "/ingest",
  });

  app.register(clientRoutes, {
    prefix: "/client",
  });
  app.register(foodRoutes, {
    prefix: "/client/food",
  });

  return app;
}
