import type { FastifyPluginAsync } from "fastify";

const injestRoutes: FastifyPluginAsync = async (app) => {
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
};

export default injestRoutes;
