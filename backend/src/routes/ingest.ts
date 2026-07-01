import type { FastifyPluginAsync, FastifyReply } from "fastify";
import { authMiddleware } from "../middleware/auth";
import {
  addDerivedBodyComposition,
  addMeasurement,
  addProprietaryBodyCompositionMetrics,
  addWorkout,
  createSnapshotReports,
  getProfileById,
  profileBelongsToAccount,
  updateProfileInsightReportGenerationStatus,
  type ProfileId,
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
import { addQueueItem } from "../bull/queue";

async function sendProfileNotFoundIfUnauthorized(
  profileId: ProfileId,
  accountId: string,
  reply: FastifyReply,
) {
  if (await profileBelongsToAccount(profileId, accountId)) {
    return false;
  }

  reply.code(404).send({
    ok: false,
    error: "Profile id does not exist",
  });
  return true;
}

const ingestRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authMiddleware);

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

    if (
      await sendProfileNotFoundIfUnauthorized(
        profileId,
        request.auth.account.id,
        reply,
      )
    ) {
      return;
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

    const ids = Array.from(latestWorkoutsBySourceId.values()).map(
      async (workout) => await addWorkout(workout, profileId),
    );

    return {
      ok: true,
      received: workouts.length,
      count: ids.length,
      ids,
    };
  });

  app.post("/backfill_body_composition", async (request, reply) => {
    const body = (request.body ?? {}) as { profileId?: string };
    const profileId = body.profileId?.trim();

    if (
      profileId &&
      await sendProfileNotFoundIfUnauthorized(
        profileId,
        request.auth.account.id,
        reply,
      )
    ) {
      return;
    }

    const result = await backfillBodyCompositionFromGrpc({
      accountId: request.auth.account.id,
      profileId: profileId || undefined,
    });

    return {
      ok: true,
      ...result,
    };
  });

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
      const { profileId: rawProfileId, weight, heartbeat, impedance } = request.body as {
        profileId: string;
        weight: number;
        heartbeat: number;
        impedance: number;
      };
      const profileId = rawProfileId.toLowerCase();

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const measurementId = await addMeasurement(
        profileId,
        weight,
        heartbeat,
        impedance,
      );

      const profile: profile = await getProfileById(profileId);

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
      const metricsId = await addProprietaryBodyCompositionMetrics(
        profileId,
        metrics,
      );
      const derivedMetrics = {
        fmi: calculateFmi(metricsBase.fat_mass_kg, profile.heightCm),
        ffmi: calculateFfmi(metricsBase.fat_free_mass_kg, profile.heightCm),
      };
      await addDerivedBodyComposition(profileId, derivedMetrics);
      const reports = await createSnapshotReports({
        profileId,
        bodyCompositionMetricsId: metricsId,
        derivedMetrics,
      });
      await updateProfileInsightReportGenerationStatus({
        reportId: reports.insightReportId,
        profileId,
        status: "queued",
      });
      try {
        await addQueueItem(reports.insightReportId, profileId);
      } catch (error) {
        await updateProfileInsightReportGenerationStatus({
          reportId: reports.insightReportId,
          profileId,
          status: "failed",
          error: error instanceof Error ? error.message : String(error),
        });
        throw error;
      }

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
        jobId: reports.insightReportId,
        reportId: reports.insightReportId,
        reportStatus: "queued",
        reports,
      };
    },
  );

  app.post(
    "/add_measurement/v2",
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
      const { profileId: rawProfileId, weight, heartbeat, impedance } = request.body as {
        profileId: string;
        weight: number;
        heartbeat: number;
        impedance: number;
      };
      const profileId = rawProfileId.toLowerCase();

      request.log.info(
        {
          route: "/ingest/add_measurement/v2",
          profileId,
          weight,
          heartbeat,
          impedance,
        },
        "received add_measurement/v2 request",
      );

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const measurementId = await addMeasurement(
        profileId,
        weight,
        heartbeat,
        impedance,
      );

      const profile: profile = await getProfileById(profileId);

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
      const metricsId = await addProprietaryBodyCompositionMetrics(
        profileId,
        metrics,
      );
      const derivedMetrics = {
        fmi: calculateFmi(metricsBase.fat_mass_kg, profile.heightCm),
        ffmi: calculateFfmi(metricsBase.fat_free_mass_kg, profile.heightCm),
      };
      await addDerivedBodyComposition(profileId, derivedMetrics);
      const reports = await createSnapshotReports({
        profileId,
        bodyCompositionMetricsId: metricsId,
        derivedMetrics,
      });
      await updateProfileInsightReportGenerationStatus({
        reportId: reports.insightReportId,
        profileId,
        status: "queued",
      });
      try {
        await addQueueItem(reports.insightReportId, profileId);
      } catch (error) {
        await updateProfileInsightReportGenerationStatus({
          reportId: reports.insightReportId,
          profileId,
          status: "failed",
          error: error instanceof Error ? error.message : String(error),
        });
        throw error;
      }

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
        jobId: reports.insightReportId,
        reportId: reports.insightReportId,
        reportStatus: "queued",
        reports,
      };
    },
  );

};

export default ingestRoutes;
