import { expect, test } from "bun:test";

// Static registration contract; no private modules or live services required.
async function declaredRoutes(file: string, prefix: string) {
  const source = await Bun.file(new URL(file, import.meta.url)).text();
  return [...source.matchAll(/app\.(get|post|patch|put|delete)\(\s*"([^"]+)"/g)]
    .map((match) => `${match[1]!.toUpperCase()} ${prefix}${match[2]}`).sort();
}

test("client retains the profile and asynchronous report contracts", async () => {
  expect(await declaredRoutes("./client.ts", "/client")).toEqual([
    "GET /client/profiles",
    "GET /client/profiles/:profileId/insights/:reportId",
    "GET /client/profiles/:profileId/insights/jobs/:jobId/wait",
    "GET /client/profiles/:profileId/insights/jobs/active",
    "GET /client/profiles/:profileId/insights/report-ids/latest",
    "PATCH /client/profiles/:profileId",
    "POST /client/register/profiles/v2",
  ].sort());
});

test("ingest exposes only the current idempotent measurement contract", async () => {
  expect(await declaredRoutes("./ingest.ts", "/ingest")).toEqual([
    "POST /ingest/add_measurement/v2",
  ]);
  const source = await Bun.file(new URL("./ingest.ts", import.meta.url)).text();
  expect(source).toContain('request.headers["idempotency-key"]');
  expect(source).toContain('app.addHook("preHandler", authMiddleware)');
});

test("food routes remain intact", async () => {
  expect(await declaredRoutes("./food.ts", "/client/food")).toEqual([
    "GET /client/food/dashboard/:profileId",
    "GET /client/food/saved/:profileId",
    "POST /client/food/analyze",
    "POST /client/food/confirm",
  ]);

  const source = await Bun.file(new URL("./food.ts", import.meta.url)).text();
  expect(source).not.toContain('z.discriminatedUnion("action"');
  expect(source).toContain("food: macroSchema.nullable()");
});
