import type { FastifyPluginAsync } from "fastify";

const ingestRoutes: FastifyPluginAsync = async (app) => {
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
        return reply.send({
          ok: true,
          note: "scale_read_queued",
          timeoutMs: 60000,
        });
      }

      return reply.code(response.status).send({
        ok: false,
      });
    },
  );
};

export default ingestRoutes;
