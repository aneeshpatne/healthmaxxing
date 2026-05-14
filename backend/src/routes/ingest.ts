import type { FastifyPluginAsync } from "fastify";
import { redis, RedisClient } from "bun";
import {
  addMeasurement,
  getProfileById,
  getProfileIdByJobId,
  saveBodyCompositionMetrics,
  type profile,
} from "../db/commands";
import { calculateHealthMetricsV2 } from "../calculations/metrics";
import { publishJobStatus } from "../lib/redis";
const pub = new RedisClient("redis://localhost:6379");

function calculateAgeYears(dateOfBirth: string): number {
  const birthDate = new Date(dateOfBirth);
  const now = new Date();
  let age = now.getUTCFullYear() - birthDate.getUTCFullYear();
  const birthdayThisYear = new Date(
    Date.UTC(now.getUTCFullYear(), birthDate.getUTCMonth(), birthDate.getUTCDate()),
  );

  if (now < birthdayThisYear) {
    age -= 1;
  }

  return age;
}

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

      const profile: profile = getProfileById(profileId);
      await publishJobStatus(id, "calculating");

      // console.log(
      //   calculateHealthMetricsV2(
      //     weight,
      //     impedance,
      //     profile.heightCm,
      //     profile.heightCm,
      //     "male",
      //   ),
      // );
      const metrics = calculateHealthMetricsV2(
        weight,
        impedance,
        profile.heightCm,
        calculateAgeYears(profile.dateOfBirth),
        profile.gender,
      );
      const metricsId = saveBodyCompositionMetrics(profileId, metrics);

      await publishJobStatus(id, "report generated.");

      app.log.info({
        id,
        measurementId,
        profileId,
        weight,
        heartbeat,
        impedance,
        metricsId,
        metrics,
      });
      return {
        ok: true,
        id: measurementId,
      };
    },
  );

  app.get("/ws/tool/:jobId", { websocket: true }, async (socket, request) => {
    const { jobId } = request.params as { jobId: string };
    await publishJobStatus(jobId, "streaming");

    socket.on("message", async (raw: { toString(): string }) => {
      const message = raw.toString();
      await pub.publish(`job:${jobId}`, message);
    });
  });
};

export default ingestRoutes;
