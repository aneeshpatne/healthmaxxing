import type { FastifyPluginAsync } from "fastify";
import { RedisClient } from "bun";
import { addMeasurement, getProfileIdByJobId } from "../db/commands";
import { calculateHealthMetricsV2 } from "../calculations/metrics";
const pub = new RedisClient("redis://localhost:6379");

const ingestRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    "/:id",
    {
      schema: {
        params: {
          type: "object",
          required: ["id"],
          properties: {
            id: {
              type: "string",
            },
          },
        },
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
      const { id } = request.params as {
        id: string;
      };
      const { weight, heartbeat, impedance } = request.body as {
        weight: number;
        heartbeat: number;
        impedance: number;
      };
      const profileId = getProfileIdByJobId(id);

      if (profileId === null) {
        return reply.code(404).send({
          ok: false,
          error: "Job id does not exist",
        });
      }

      const measurementId = addMeasurement(
        profileId,
        weight,
        heartbeat,
        impedance,
      );

      console.log(calculateHealthMetricsV2(weight, impedance, 172, 25, "male"));

      app.log.info({
        id,
        measurementId,
        profileId,
        weight,
        heartbeat,
        impedance,
      });
      return {
        ok: true,
        id: measurementId,
      };
    },
  );

  app.get("/ws/tool/:jobId", { websocket: true }, (socket, request) => {
    const { jobId } = request.params as { jobId: string };

    socket.on("message", async (raw: { toString(): string }) => {
      const message = raw.toString();
      await pub.publish(`job:${jobId}`, message);
    });
  });
};

export default ingestRoutes;
