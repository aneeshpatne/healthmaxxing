import Fastify from "fastify";
import injestRoutes from "./routes/injest.ts";

export function buildApp() {
  const app = Fastify({
    logger: true,
  });

  app.get("/health", async () => {
    return { ok: true };
  });

  app.register(injestRoutes, {
    prefix: "/ingest",
  });

  return app;
}
