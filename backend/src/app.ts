import Fastify from "fastify";
import websocket from "@fastify/websocket";
import clientRoutes from "./routes/client.ts";
import ingestRoutes from "./routes/ingest.ts";

export function buildApp() {
  const app = Fastify({
    logger: true,
  });

  app.get("/health", async () => {
    return { ok: true };
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
