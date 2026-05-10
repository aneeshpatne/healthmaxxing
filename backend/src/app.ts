import Fastify from "fastify";
import ingestRoutes from "./routes/ingest.ts";

export function buildApp() {
  const app = Fastify({
    logger: true,
  });

  app.get("/health", async () => {
    return { ok: true };
  });

  app.register(ingestRoutes, {
    prefix: "/ingest",
  });

  return app;
}
