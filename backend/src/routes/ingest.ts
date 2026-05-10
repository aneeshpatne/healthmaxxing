import type { FastifyPluginAsync } from "fastify";
import { v7 as uuidv7 } from "uuid";
import websocket from "@fastify/websocket";

const ingestRoutes: FastifyPluginAsync = async (app) => {
  await app.register(websocket);

  app.post(
    "/",
    {
      schema: {
        body: {
          type: "object",
          required: ["weight", "heartbeat", "impedance"],
          properties: {
            weight: {
              type: "number",
            },
            heartbeat: {
              type: "number",
            },
            impedance: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { weight, heartbeat, impedance } = request.body as {
        weight: number;
        heartbeat: number;
        impedance: number;
      };
      app.log.info({
        weight,
        heartbeat,
        impedance,
      });
      return {
        ok: true,
      };
    },
  );
  app.post(
    "/start",
    {
      schema: {
        body: false,
      },
    },
    async (_request, reply) => {
      const response = await fetch("http://192.168.0.50/scale");

      if (response.ok) {
        const id = uuidv7();

        app.log.info({ id }, "Started ingest");

        return reply.code(response.status).send({
          ok: true,
          id,
        });
      }

      return reply.code(response.status).send({
        ok: false,
      });
    },
  );
  app.get("/ws/tool/:jobId", { websocket: true }, (socket, request) => {
    const { jobId } = request.params as { jobId: string };

    socket.on("message", async (raw: { toString(): string }) => {
      const message = raw.toString();
      console.log(message);
    });
  });
};

export default ingestRoutes;
