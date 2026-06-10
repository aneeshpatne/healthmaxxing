import type { FastifyPluginAsync } from "fastify";
import { v7 as uuidv7 } from "uuid";
import { RedisClient } from "bun";
import {
  addBodyMeasurement,
  accountExists,
  getLatestBodyCompositionSnapshot,
  getLatestUserBodyMeasurement,
  getProfileById,
  initJob,
  jobExists,
  getProfileAiOverview,
  getProfileEffortScore,
  getProfileFatReport,
  getProfileFormaScore,
  getProfileMuscleReport,
  getProfilePerformance,
  getWeightSummary,
  isBodyCompositionTrendMetric,
  isBodyCompositionTrendPeriod,
  listBodyCompositionTrends,
  listUserBodyMeasurements,
  listUsers,
  listUserWeight,
  profileExists,
  registerProfileMetadata,
  registerProfile,
  registerUser,
  PERIODS,
  TREND_COLUMNS,
  type AccountId,
  type JobId,
  type ProfileId,
} from "../db/commands";

const redis = new RedisClient("redis://localhost:6379");
const sub = new RedisClient("redis://localhost:6379");
const LONG_POLL_TIMEOUT_MS = 25_000;

type JobStatusState = {
  status?: string;
  version?: number;
  updatedAt?: number;
};

function parseJobStatus(raw: string): JobStatusState | null {
  try {
    return JSON.parse(raw) as JobStatusState;
  } catch {
    return null;
  }
}

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

const clientRoutes: FastifyPluginAsync = async (app) => {
  app.get("/state/:id/poll", async (req, reply) => {
    const { id } = req.params as { id: string };
    const { version } = req.query as { version: string };
    const clientVersion = Number(version ?? 0);
    const stateKey = `status:${id}`;
    const channel = `status:${id}`;

    const currentRaw = await redis.get(stateKey);

    if (currentRaw === null) {
      return reply.code(404).send({
        ok: false,
        error: "Job status does not exist",
      });
    }

    const currentState = parseJobStatus(currentRaw);

    if (currentState === null) {
      return reply.code(500).send({
        ok: false,
        error: "Job status is invalid",
      });
    }

    if ((currentState.version ?? 0) > clientVersion) {
      return reply.send({
        ok: true,
        changed: true,
        state: currentState,
      });
    }

    const nextState = await new Promise<JobStatusState | null>(
      (resolve, reject) => {
        let settled = false;
        let timeout: ReturnType<typeof setTimeout>;

        const settle = (state: JobStatusState | null) => {
          if (settled) {
            return;
          }

          settled = true;
          clearTimeout(timeout);
          sub.unsubscribe(channel, listener).catch((error) => {
            app.log.warn({ error, channel }, "Failed to unsubscribe long poll");
          });
          resolve(state);
        };

        const listener = (message: string) => {
          const state = parseJobStatus(message);

          if (state !== null && (state.version ?? 0) > clientVersion) {
            settle(state);
          }
        };

        timeout = setTimeout(() => {
          settle(null);
        }, LONG_POLL_TIMEOUT_MS);

        sub
          .subscribe(channel, listener)
          .then(async () => {
            const latestRaw = await redis.get(stateKey);
            const latestState =
              latestRaw === null ? null : parseJobStatus(latestRaw);

            if (
              latestState !== null &&
              (latestState.version ?? 0) > clientVersion
            ) {
              settle(latestState);
            }
          })
          .catch((error) => {
            if (!settled) {
              settled = true;
              clearTimeout(timeout);
              reject(error);
            }
          });
      },
    );

    if (nextState === null) {
      return reply.send({
        ok: true,
        changed: false,
        state: currentState,
      });
    }

    return reply.send({
      ok: true,
      changed: true,
      state: nextState,
    });
  });
  app.post(
    "/register",
    {
      schema: {
        body: {
          type: "object",
          required: ["mailAddress"],
          properties: {
            mailAddress: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { mailAddress } = request.body as {
        mailAddress: string;
      };
      const id: AccountId = registerUser({
        mailAddress,
      });

      app.log.info({ id, mailAddress }, "Registered account");

      return reply.code(201).send({
        ok: true,
        id,
        mailAddress,
      });
    },
  );

  app.post(
    "/register/profiles",
    {
      schema: {
        body: {
          type: "object",
          required: ["accountId", "name"],
          properties: {
            accountId: {
              type: "string",
            },
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
      const { accountId, name, isPrimary = false } = request.body as {
        accountId: string;
        name: string;
        isPrimary?: boolean;
      };

      if (!accountExists(accountId)) {
        return reply.code(404).send({
          ok: false,
          error: "Account id does not exist",
        });
      }

      const id: ProfileId = registerProfile({
        accountId,
        name,
        isPrimary,
      });

      app.log.info({ id, accountId, name, isPrimary }, "Registered profile");

      return reply.code(201).send({
        ok: true,
        id,
        accountId,
        name,
        isPrimary,
      });
    },
  );

  app.post(
    "/register/metadata",
    {
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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      registerProfileMetadata({
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

  app.get("/users", async (_request, reply) => {
    const users = listUsers();

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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const profile = getProfileById(profileId);
      const formaScore = getProfileFormaScore(profileId);
      const bodyComposition = getLatestBodyCompositionSnapshot(profileId);
      const measurements = getLatestUserBodyMeasurement(profileId);
      const weight = getWeightSummary(profileId);

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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      return reply.send({
        ok: true,
        profileId,
        performance: getProfilePerformance(profileId),
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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const fat = getProfileFatReport(profileId);

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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const muscle = getProfileMuscleReport(profileId);

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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const insights = getProfileAiOverview(profileId);
      const effortScore = getProfileEffortScore(profileId);

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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const { id, createdAt } = addBodyMeasurement(profileId, {
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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const bodyMeasurements = listUserBodyMeasurements(profileId);

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

      if (profileId !== undefined && !profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const points = listBodyCompositionTrends({
        metric,
        period,
        profileId,
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
    {
      schema: {
        body: {
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
      const { profileId } = request.body as {
        profileId: string;
      };

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const id: JobId = uuidv7();

      if (jobExists(id)) {
        return reply.code(409).send({
          ok: false,
          error: "Job id already exists",
        });
      }

      await redis.set(
        `status:${id}`,
        JSON.stringify({
          status: "starting",
          version: 1,
          updatedAt: Date.now(),
        }),
      );

      const response = await fetch(
        `http://192.168.0.50/scale?id=${encodeURIComponent(id)}`,
      );

      if (response.ok) {
        initJob(id, profileId);
        app.log.info({ id, profileId }, "Started ingest");

        return reply.code(response.status).send({
          ok: true,
          id,
          profileId,
        });
      }

      return reply.code(response.status).send({
        ok: false,
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

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const weights = listUserWeight(profileId);

      return reply.send({
        ok: true,
        profileId,
        weights,
      });
    },
  );

  app.get("/ws/sub/:jobId", { websocket: true }, async (socket, request) => {
    const { jobId } = request.params as { jobId: string };
    const channel = `job:${jobId}`;
    const listener = (message: string) => {
      socket.send(message);
    };

    socket.on("close", async () => {
      await sub.unsubscribe(channel, listener);
    });

    await sub.subscribe(channel, listener);
  });
};

export default clientRoutes;
