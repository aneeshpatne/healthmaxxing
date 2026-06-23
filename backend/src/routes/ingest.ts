import type { FastifyPluginAsync } from "fastify";
import { RedisClient } from "bun";
import {
  addDerivedBodyComposition,
  addMeasurement,
  addProprietaryBodyCompositionMetrics,
  addWorkout,
  createSnapshotReports,
  getProfileById,
  profileExists,
  type WorkoutInput,
  type profile,
} from "../db/commands";
import { calculateDesiredWeightKg } from "../calculations/compositionSummary";
import {
  calculateFfmi,
  calculateFmi,
  calculateProprietaryMetrics,
} from "../calculations/proprietaryMetrics";
import { backfillBodyCompositionFromGrpc } from "../lib/backfillBodyComposition";
import { calculateAgeYears } from "../utils/calculateAgeYears";
const pub = new RedisClient("redis://localhost:6379");

const ingestRoutes: FastifyPluginAsync = async (app) => {
  app.post("/workouts", async (request, reply) => {
    const body = request.body as {
      data?: {
        workouts?: WorkoutInput[];
      };
    };
    const headerProfileId =
      request.headers.profileid ?? request.headers["x-profile-id"];
    const profileId = Array.isArray(headerProfileId)
      ? headerProfileId[0]
      : headerProfileId;
    const workouts = body.data?.workouts;

    if (!profileId) {
      return reply.code(400).send({
        ok: false,
        error: "profileId header is required",
      });
    }

    if (!profileExists(profileId)) {
      return reply.code(404).send({
        ok: false,
        error: "Profile id does not exist",
      });
    }

    if (!Array.isArray(workouts)) {
      return reply.code(400).send({
        ok: false,
        error: "data.workouts must be an array",
      });
    }

    const invalidWorkout = workouts.find(
      (workout) => typeof workout.id !== "string" || workout.id.length === 0,
    );
    if (invalidWorkout) {
      return reply.code(400).send({
        ok: false,
        error: "Each workout must include an id",
      });
    }

    const latestWorkoutsBySourceId = new Map<string, WorkoutInput>();
    for (const workout of workouts) {
      latestWorkoutsBySourceId.set(workout.id, workout);
    }

    const ids = Array.from(latestWorkoutsBySourceId.values()).map((workout) =>
      addWorkout(workout, profileId),
    );

    return {
      ok: true,
      received: workouts.length,
      count: ids.length,
      ids,
    };
  });

  app.post(
    "/backfill_body_composition",
    async (request, reply) => {
      const body = (request.body ?? {}) as { profileId?: string };
      const profileId = body.profileId?.trim();

      if (profileId && !profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const result = await backfillBodyCompositionFromGrpc({
        profileId: profileId || undefined,
      });

      return {
        ok: true,
        ...result,
      };
    },
  );

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
      const metricsBase = await calculateProprietaryMetrics({
        weight_kg: weight,
        impedance_ohms: impedance,
        height_cm: profile.heightCm,
        age_years: calculateAgeYears(profile.dateOfBirth),
        sex: profile.gender,
        people_type: profile.peopleType,
      });
      const metrics = {
        ...metricsBase,
        desired_weight_kg: calculateDesiredWeightKg({
          fat_free_mass_kg: metricsBase.fat_free_mass_kg,
          target_body_fat_pct: profile.preferredBodyFatPct,
        }),
      };
      const metricsId = addProprietaryBodyCompositionMetrics(
        profileId,
        metrics,
      );
      const derivedMetrics = {
        fmi: calculateFmi(metricsBase.fat_mass_kg, profile.heightCm),
        ffmi: calculateFfmi(metricsBase.fat_free_mass_kg, profile.heightCm),
      };
      addDerivedBodyComposition(profileId, derivedMetrics);
      createSnapshotReports({
        profileId,
        bodyCompositionMetricsId: metricsId,
        derivedMetrics,
      });

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
