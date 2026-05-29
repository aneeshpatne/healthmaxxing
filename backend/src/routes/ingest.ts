import type { FastifyPluginAsync } from "fastify";
import { RedisClient } from "bun";
import {
  addMeasurement,
  addProprietaryBodyCompositionMetrics,
  getProfileById,
  profileExists,
  type profile,
} from "../db/commands";
import { calculateProprietaryMetrics } from "../calculations/proprietaryMetrics";
const pub = new RedisClient("redis://localhost:6379");

function calculateAgeYears(dateOfBirth: string): number {
  const birthDate = new Date(dateOfBirth);
  const now = new Date();
  let age = now.getUTCFullYear() - birthDate.getUTCFullYear();
  const birthdayThisYear = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      birthDate.getUTCMonth(),
      birthDate.getUTCDate(),
    ),
  );

  if (now < birthdayThisYear) {
    age -= 1;
  }

  return age;
}

const ingestRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    "/add_measurement",
    {
      schema: {
        body: {
          type: "object",
          required: ["profileId", "weight", "heartbeat", "impedance"],
          properties: {
            profileId: {
              type: "string",
            },
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
      const { profileId, weight, heartbeat, impedance } = request.body as {
        profileId: string;
        weight: number;
        heartbeat: number;
        impedance: number;
      };

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const measurementId = addMeasurement(
        profileId,
        weight,
        heartbeat,
        impedance,
      );

      const profile: profile = getProfileById(profileId);

      // console.log(
      //   calculateHealthMetricsV2(
      //     weight,
      //     impedance,
      //     profile.heightCm,
      //     profile.heightCm,
      //     "male",
      //   ),
      // );
      const metrics = calculateProprietaryMetrics({
        weight_kg: weight,
        impedance_ohms: impedance,
        height_cm: profile.heightCm,
        age_years: calculateAgeYears(profile.dateOfBirth),
        sex: profile.gender,
        people_type: profile.peopleType,
      });
      const metricsId = addProprietaryBodyCompositionMetrics(
        profileId,
        metrics,
      );

      console.log(metrics);

      // app.log.info({
      //   measurementId,
      //   profileId,
      //   weight,
      //   heartbeat,
      //   impedance,
      //   metricsId,
      //   metrics,
      // });
      return {
        ok: true,
        id: measurementId,
      };
    },
  );

  app.get("/ws/tool/:jobId", { websocket: true }, async (socket, request) => {
    const { jobId } = request.params as { jobId: string };

    socket.on("message", async (raw: { toString(): string }) => {
      const message = raw.toString();
      await pub.publish(`job:${jobId}`, message);
    });
  });
};

export default ingestRoutes;
