import Fastify from "fastify";
import websocket from "@fastify/websocket";
import clientRoutes from "./routes/client.ts";
import ingestRoutes from "./routes/ingest.ts";
import { checkDatabase } from "./db/client.ts";

export function buildApp() {
  const app = Fastify({
    logger: true,
    bodyLimit: 10 * 1024 * 1024,
  });

  app.get("/health", async (_request, reply) => {
    try {
      await checkDatabase();
      return { ok: true, database: "up" };
    } catch {
      return reply.code(503).send({ ok: false, database: "down" });
    }
  });

  app.register(websocket);

  app.register(ingestRoutes, {
    prefix: "/ingest",
  });

  app.register(clientRoutes, {
    prefix: "/client",
  });

  return app;
}
