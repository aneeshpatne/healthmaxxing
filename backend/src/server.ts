import { buildApp } from "./app.ts";
import { closeDatabase } from "./db/client.ts";
import { migrateDatabase } from "./db/migrate.ts";

await migrateDatabase();
const app = buildApp();
const port = Number(process.env.PORT ?? 3030);
const host = process.env.HOST ?? "0.0.0.0";

try {
  await app.listen({ port, host });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.once(signal, async () => {
    await app.close();
    await closeDatabase();
    process.exit(0);
  });
}
