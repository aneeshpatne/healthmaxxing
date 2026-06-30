import type { FastifyPluginAsync, FastifyReply } from "fastify";
import { authMiddleware } from "../middleware/auth";
import { v7 as uuidv7 } from "uuid";
import {
  addBodyMeasurement,
  getLatestBodyCompositionSnapshot,
  getLatestUserBodyMeasurement,
  getProfileById,
  initJob,
  jobExists,
  getProfileAiOverview,
  getProfileAiReportById,
  getProfileEffortScore,
  getProfileFatReport,
  getProfileFormaScore,
  getProfileMuscleReport,
  getProfilePerformance,
  getWeightSummary,
  isBodyCompositionTrendMetric,
  isBodyCompositionTrendPeriod,
  listBodyCompositionTrends,
  listRecentProfileAiReports,
  listUserBodyMeasurements,
  listUsers,
  listUsersByAccountId,
  listUserWeight,
  profileBelongsToAccount,
  registerProfileMetadata,
  registerProfile,
  updateProfile,
  PERIODS,
  TREND_COLUMNS,
  type JobId,
  type ProfileId,
} from "../db/commands";

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

const clientRoutes: FastifyPluginAsync = async (app) => {
  app.addHook("preHandler", authMiddleware);

  app.post(
    "/register",
    async (request, reply) => {
      const {
        account,
        clerkUserId,
      } = request.auth;

      app.log.info(
        { id: account.id, clerkUserId },
        "Resolved account from auth middleware",
      );

      return reply.code(201).send({
        ok: true,
        id: account.id,
        account,
      });
    },
  );

  app.post(
    "/register/profiles",
    {
      config: {
        deprecated: true,
      },
      schema: {
        body: {
          type: "object",
          required: ["name"],
          properties: {
            name: {
              type: "string",
            },
            isPrimary: {
              type: "boolean",
            },
          },
        },
      },
    },
    async (request, reply) => {
      reply.header("Deprecation", "true");
      reply.header("Sunset", "Tue, 30 Jun 2026 23:59:59 GMT");
      reply.header("Link", '</client/register/profiles/v2>; rel="successor-version"');

      const { name, isPrimary = false } = request.body as {
        name: string;
        isPrimary?: boolean;
      };
      const accountId = request.auth.account.id;

      const { id, isPrimary: registeredIsPrimary } = await registerProfile({
        accountId,
        name,
        isPrimary,
      });

      app.log.info(
        { id, accountId, name, isPrimary: registeredIsPrimary },
        "Registered profile",
      );

      return reply.code(201).send({
        ok: true,
        id,
        accountId,
        name,
        isPrimary: registeredIsPrimary,
      });
    },
  );

  app.post(
    "/register/metadata",
    {
      config: {
        deprecated: true,
      },
      schema: {
        body: {
          type: "object",
          required: [
            "profileId",
            "heightCm",
            "dateOfBirth",
            "peopleType",
            "gender",
          ],
          properties: {
            profileId: {
              type: "string",
            },
            heightCm: {
              type: "number",
            },
            dateOfBirth: {
              type: "string",
            },
            peopleType: {
              type: "string",
              enum: ["standard", "athlete"],
            },
            gender: {
              type: "string",
              enum: ["male", "female"],
            },
            profileImage: {
              type: "string",
              nullable: true,
            },
            preferredBodyFatPct: {
              type: "number",
              default: 18,
            },
          },
        },
      },
    },
    async (request, reply) => {
      reply.header("Deprecation", "true");
      reply.header("Sunset", "Tue, 30 Jun 2026 23:59:59 GMT");
      reply.header("Link", '</client/register/profiles/v2>; rel="successor-version"');

      const {
        profileId,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage = null,
        preferredBodyFatPct = 18,
      } = request.body as {
        profileId: string;
        heightCm: number;
        dateOfBirth: string;
        peopleType: "standard" | "athlete";
        gender: "male" | "female";
        profileImage?: string | null;
        preferredBodyFatPct?: number;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      await registerProfileMetadata({
        profileId,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });

      app.log.info(
        {
          profileId,
          heightCm,
          dateOfBirth,
          peopleType,
          gender,
          profileImage,
          preferredBodyFatPct,
        },
        "Registered profile metadata",
      );

      return reply.code(201).send({
        ok: true,
        profileId,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });
    },
  );

  app.post(
    "/register/profiles/v2",
    {
      schema: {
        body: {
          type: "object",
          required: ["name", "heightCm", "dateOfBirth", "peopleType", "gender"],
          properties: {
            name: {
              type: "string",
            },
            isPrimary: {
              type: "boolean",
              default: false,
            },
            heightCm: {
              type: "number",
            },
            dateOfBirth: {
              type: "string",
            },
            peopleType: {
              type: "string",
              enum: ["standard", "athlete"],
            },
            gender: {
              type: "string",
              enum: ["male", "female"],
            },
            profileImage: {
              type: "string",
              nullable: true,
            },
            preferredBodyFatPct: {
              type: "number",
              default: 18,
            },
          },
        },
      },
    },
    async (request, reply) => {
      const {
        name,
        isPrimary = false,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage = null,
        preferredBodyFatPct = 18,
      } = request.body as {
        name: string;
        isPrimary?: boolean;
        heightCm: number;
        dateOfBirth: string;
        peopleType: "standard" | "athlete";
        gender: "male" | "female";
        profileImage?: string | null;
        preferredBodyFatPct?: number;
      };
      const accountId = request.auth.account.id;

      const {
        id: profileId,
        isPrimary: registeredIsPrimary,
      } = await registerProfile({
        accountId,
        name,
        isPrimary,
      });

      await registerProfileMetadata({
        profileId,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });

      app.log.info(
        {
          profileId,
          accountId,
          name,
          isPrimary: registeredIsPrimary,
          heightCm,
          dateOfBirth,
          peopleType,
          gender,
          profileImage,
          preferredBodyFatPct,
        },
        "Registered profile with metadata",
      );

      return reply.code(201).send({
        ok: true,
        profileId,
        accountId,
        name,
        isPrimary: registeredIsPrimary,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });
    },
  );

  app.patch(
    "/profiles/:profileId",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
        body: {
          type: "object",
          properties: {
            name: {
              type: "string",
            },
            isPrimary: {
              type: "boolean",
            },
            heightCm: {
              type: "number",
            },
            dateOfBirth: {
              type: "string",
            },
            peopleType: {
              type: "string",
              enum: ["standard", "athlete"],
            },
            gender: {
              type: "string",
              enum: ["male", "female"],
            },
            profileImage: {
              type: "string",
              nullable: true,
            },
            preferredBodyFatPct: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };
      const accountId = request.auth.account.id;
      const {
        name,
        isPrimary,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      } = request.body as {
        name?: string;
        isPrimary?: boolean;
        heightCm?: number;
        dateOfBirth?: string;
        peopleType?: "standard" | "athlete";
        gender?: "male" | "female";
        profileImage?: string | null;
        preferredBodyFatPct?: number;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          accountId,
          reply,
        )
      ) {
        return;
      }

      await updateProfile({
        profileId,
        accountId,
        name,
        isPrimary,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });

      app.log.info(
        {
          profileId,
          name,
          isPrimary,
          heightCm,
          dateOfBirth,
          peopleType,
          gender,
          profileImage,
          preferredBodyFatPct,
        },
        "Updated profile",
      );

      return reply.send({
        ok: true,
        profileId,
        name,
        isPrimary,
        heightCm,
        dateOfBirth,
        peopleType,
        gender,
        profileImage,
        preferredBodyFatPct,
      });
    },
  );

  app.get(
    "/users",
    {
      config: {
        deprecated: true,
      },
    },
    async (_request, reply) => {
      reply.header("Deprecation", "true");
      reply.header("Sunset", "Tue, 30 Jun 2026 23:59:59 GMT");
      reply.header("Link", '</client/profiles>; rel="successor-version"');

      const users = await listUsers();

      return reply.send({
        ok: true,
        users,
      });
    },
  );

  app.get("/profiles", async (request, reply) => {
    const users = await listUsersByAccountId(request.auth.account.id);

    return reply.send({
      ok: true,
      users,
    });
  });

  app.get(
    "/profiles/:profileId/essentials",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const profile = await getProfileById(profileId);
      const formaScore = await getProfileFormaScore(profileId);
      const bodyComposition = await getLatestBodyCompositionSnapshot(profileId);
      const measurements = await getLatestUserBodyMeasurement(profileId);
      const weight = await getWeightSummary(profileId);

      return reply.send({
        ok: true,
        profileId,
        essentials: {
          formaScore,
          bodyAge: bodyComposition?.metrics.body_age_years ?? null,
          realAge:
            profile.dateOfBirth === null
              ? null
              : calculateAgeYears(profile.dateOfBirth),
          compositionSummary: bodyComposition?.compositionSummary ?? null,
          measurements,
          currentWeight: weight.currentWeight,
          goalWeight: weight.goalWeight,
          averageWeight30d: weight.averageWeight30d,
          lowestWeight30d: weight.lowestWeight30d,
          last30DaysWeightTrend: weight.last30DaysWeightTrend,
        },
      });
    },
  );

  app.get(
    "/profiles/:profileId/performance",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      return reply.send({
        ok: true,
        profileId,
        performance: await getProfilePerformance(profileId),
      });
    },
  );

  app.get(
    "/profiles/:profileId/fat",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const fat = await getProfileFatReport(profileId);

      if (fat === null) {
        return reply.code(404).send({
          ok: false,
          error: "Fat report does not exist",
        });
      }

      return reply.send({
        ok: true,
        profileId,
        fat,
      });
    },
  );

  app.get(
    "/profiles/:profileId/muscle",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const muscle = await getProfileMuscleReport(profileId);

      if (muscle === null) {
        return reply.code(404).send({
          ok: false,
          error: "Muscle report does not exist",
        });
      }

      return reply.send({
        ok: true,
        profileId,
        muscle,
      });
    },
  );

  app.get(
    "/profiles/:profileId/insights",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const insights = await getProfileAiOverview(profileId);
      const effortScore = await getProfileEffortScore(profileId);

      if (insights === null) {
        return reply.code(404).send({
          ok: false,
          error: "Profile insights do not exist",
        });
      }

      return reply.send({
        ok: true,
        profileId,
        insights,
        effortScore,
      });
    },
  );

  app.get(
    "/profiles/:profileId/insights/recent",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
        querystring: {
          type: "object",
          properties: {
            limit: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };
      const { limit: rawLimit } = request.query as {
        limit?: number | string;
      };
      const parsedLimit = Number(rawLimit ?? 5);
      const limit = Number.isFinite(parsedLimit)
        ? Math.min(Math.max(Math.trunc(parsedLimit), 1), 20)
        : 5;

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const reports = await listRecentProfileAiReports({ profileId, limit });

      return reply.send({
        ok: true,
        profileId,
        reports,
      });
    },
  );

  app.get(
    "/profiles/:profileId/insights/:reportId",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId", "reportId"],
          properties: {
            profileId: {
              type: "string",
            },
            reportId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId, reportId } = request.params as {
        profileId: string;
        reportId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const report = await getProfileAiReportById({ profileId, reportId });

      if (report === null) {
        return reply.code(404).send({
          ok: false,
          error: "Report does not exist",
        });
      }

      return reply.send({
        ok: true,
        report,
      });
    },
  );

  app.post(
    "/body-measurements",
    {
      schema: {
        body: {
          type: "object",
          required: ["profileId"],
          anyOf: [
            { required: ["neckCm"] },
            { required: ["shoulderCm"] },
            { required: ["chestCm"] },
            { required: ["stomachCm"] },
            { required: ["waistCm"] },
            { required: ["calfCm"] },
            { required: ["thighCm"] },
            { required: ["bicepCm"] },
            { required: ["forearmCm"] },
          ],
          properties: {
            profileId: {
              type: "string",
            },
            neckCm: {
              type: "number",
            },
            shoulderCm: {
              type: "number",
            },
            chestCm: {
              type: "number",
            },
            stomachCm: {
              type: "number",
            },
            waistCm: {
              type: "number",
            },
            calfCm: {
              type: "number",
            },
            thighCm: {
              type: "number",
            },
            bicepCm: {
              type: "number",
            },
            forearmCm: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const {
        profileId,
        neckCm = null,
        shoulderCm = null,
        chestCm = null,
        stomachCm = null,
        waistCm = null,
        calfCm = null,
        thighCm = null,
        bicepCm = null,
        forearmCm = null,
      } = request.body as {
        profileId: string;
        neckCm?: number | null;
        shoulderCm?: number | null;
        chestCm?: number | null;
        stomachCm?: number | null;
        waistCm?: number | null;
        calfCm?: number | null;
        thighCm?: number | null;
        bicepCm?: number | null;
        forearmCm?: number | null;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const { id, createdAt } = await addBodyMeasurement(profileId, {
        neckCm,
        shoulderCm,
        chestCm,
        stomachCm,
        waistCm,
        calfCm,
        thighCm,
        bicepCm,
        forearmCm,
      });

      app.log.info(
        {
          id,
          createdAt,
          profileId,
          neckCm,
          shoulderCm,
          chestCm,
          stomachCm,
          waistCm,
          calfCm,
          thighCm,
          bicepCm,
          forearmCm,
        },
        "Registered body measurement",
      );

      return reply.code(201).send({
        ok: true,
        id,
        createdAt,
        profileId,
        neckCm,
        shoulderCm,
        chestCm,
        stomachCm,
        waistCm,
        calfCm,
        thighCm,
        bicepCm,
        forearmCm,
      });
    },
  );

  app.get(
    "/body-measurements/:profileId",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const bodyMeasurements = await listUserBodyMeasurements(profileId);

      return reply.send({
        ok: true,
        profileId,
        bodyMeasurements,
      });
    },
  );

  app.get(
    "/body-composition/trends",
    {
      schema: {
        querystring: {
          type: "object",
          required: ["metric", "period"],
          properties: {
            metric: {
              type: "string",
              enum: TREND_COLUMNS,
            },
            period: {
              type: "string",
              enum: Object.keys(PERIODS),
            },
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { metric, period, profileId } = request.query as {
        metric: string;
        period: string;
        profileId?: string;
      };

      if (!isBodyCompositionTrendMetric(metric)) {
        return reply.code(400).send({
          ok: false,
          error: "Invalid body composition trend metric",
          acceptedMetrics: TREND_COLUMNS,
        });
      }

      if (!isBodyCompositionTrendPeriod(period)) {
        return reply.code(400).send({
          ok: false,
          error: "Invalid body composition trend period",
          acceptedPeriods: Object.keys(PERIODS),
        });
      }

      if (
        profileId !== undefined &&
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const points = await listBodyCompositionTrends({
        metric,
        period,
        profileId,
        accountId: request.auth.account.id,
      });

      return reply.send({
        ok: true,
        metric,
        period,
        profileId,
        points,
      });
    },
  );

  app.post(
    "/start",
    async (_request, reply) => {
      return reply.code(410).send({
        ok: false,
        error: "/start is deprecated. Use the ingest endpoints instead.",
      });
    },
  );

  app.get(
    "/weight/:profileId",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId"],
          properties: {
            profileId: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId } = request.params as {
        profileId: string;
      };

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const weights = await listUserWeight(profileId);

      return reply.send({
        ok: true,
        profileId,
        weights,
      });
    },
  );

};

export default clientRoutes;
