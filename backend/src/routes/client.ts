import type { FastifyPluginAsync, FastifyReply } from "fastify";
import { authMiddleware } from "../middleware/auth";
import {
  getProfileAiReportById,
  failStaleProfileInsightReportJobs,
  listActiveProfileAiReportJobs,
  listLatestCompletedProfileAiReportIds,
  listUsersByAccountId,
  profileBelongsToAccount,
  registerProfileMetadata,
  registerProfile,
  updateProfile,
  type ProfileId,
} from "../db/commands";

const LONG_POLL_DEFAULT_TIMEOUT_MS = 25_000;
const LONG_POLL_MAX_TIMEOUT_MS = 30_000;
const LONG_POLL_INTERVAL_MS = 1_000;

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseReportLimit(rawLimit: number | string | undefined) {
  const parsedLimit = Number(rawLimit ?? 5);
  return Number.isFinite(parsedLimit)
    ? Math.min(Math.max(Math.trunc(parsedLimit), 1), 20)
    : 5;
}

function parseLongPollTimeoutMs(rawTimeoutMs: number | string | undefined) {
  const parsedTimeoutMs = Number(rawTimeoutMs ?? LONG_POLL_DEFAULT_TIMEOUT_MS);
  return Number.isFinite(parsedTimeoutMs)
    ? Math.min(Math.max(Math.trunc(parsedTimeoutMs), 0), LONG_POLL_MAX_TIMEOUT_MS)
    : LONG_POLL_DEFAULT_TIMEOUT_MS;
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

  app.addHook("preHandler", async (request) => {
    if (
      typeof request.params === "object" &&
      request.params !== null &&
      "profileId" in request.params
    ) {
      const params = request.params as Record<string, unknown>;
      if (typeof params.profileId === "string") {
        params.profileId = params.profileId.toLowerCase();
      }
    }
  });

  app.post(
    "/register/profiles/v2",
    {
      schema: {
        body: {
          type: "object",
          required: [
            "name",
            "heightCm",
            "dateOfBirth",
            "peopleType",
            "gender",
            "muscularityGoal",
          ],
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
            muscularityGoal: {
              type: "string",
              enum: ["maintain", "athletic", "muscular", "very_muscular"],
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
        muscularityGoal,
      } = request.body as {
        name: string;
        isPrimary?: boolean;
        heightCm: number;
        dateOfBirth: string;
        peopleType: "standard" | "athlete";
        gender: "male" | "female";
        profileImage?: string | null;
        preferredBodyFatPct?: number;
        muscularityGoal: "maintain" | "athletic" | "muscular" | "very_muscular";
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
        muscularityGoal,
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
          muscularityGoal,
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
        muscularityGoal,
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
            muscularityGoal: {
              type: "string",
              enum: ["maintain", "athletic", "muscular", "very_muscular"],
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
        muscularityGoal,
      } = request.body as {
        name?: string;
        isPrimary?: boolean;
        heightCm?: number;
        dateOfBirth?: string;
        peopleType?: "standard" | "athlete";
        gender?: "male" | "female";
        profileImage?: string | null;
        preferredBodyFatPct?: number;
        muscularityGoal?: "maintain" | "athletic" | "muscular" | "very_muscular";
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
        muscularityGoal,
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
          muscularityGoal,
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
        muscularityGoal,
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
    "/profiles/:profileId/insights/jobs/active",
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

      await failStaleProfileInsightReportJobs(profileId);
      const jobs = await listActiveProfileAiReportJobs({ profileId });

      return reply.send({
        ok: true,
        profileId,
        jobs,
      });
    },
  );

  app.get(
    "/profiles/:profileId/insights/jobs/:jobId/wait",
    {
      schema: {
        params: {
          type: "object",
          required: ["profileId", "jobId"],
          properties: {
            profileId: {
              type: "string",
            },
            jobId: {
              type: "string",
            },
          },
        },
        querystring: {
          type: "object",
          properties: {
            timeoutMs: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId, jobId } = request.params as {
        profileId: string;
        jobId: string;
      };
      const { timeoutMs: rawTimeoutMs } = request.query as {
        timeoutMs?: number | string;
      };
      const timeoutMs = parseLongPollTimeoutMs(rawTimeoutMs);
      const deadline = Date.now() + timeoutMs;

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      let report = await getProfileAiReportById({ profileId, reportId: jobId });

      if (report === null) {
        return reply.code(404).send({
          ok: false,
          error: "Report job does not exist",
        });
      }

      while (
        report.generationStatus !== "completed" &&
        report.generationStatus !== "failed" &&
        Date.now() < deadline &&
        !reply.raw.destroyed
      ) {
        await sleep(Math.min(LONG_POLL_INTERVAL_MS, deadline - Date.now()));
        if (reply.raw.destroyed) return;
        report = await getProfileAiReportById({ profileId, reportId: jobId });

        if (report === null) {
          return reply.code(404).send({
            ok: false,
            error: "Report job does not exist",
          });
        }
      }

      return reply.send({
        ok: true,
        profileId,
        jobId,
        reportId: report.reportId,
        generationStatus: report.generationStatus,
        generationError: report.generationError,
        report,
      });
    },
  );

  app.get(
    "/profiles/:profileId/insights/report-ids/latest",
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
      const limit = parseReportLimit(rawLimit);

      if (
        await sendProfileNotFoundIfUnauthorized(
          profileId,
          request.auth.account.id,
          reply,
        )
      ) {
        return;
      }

      const reports = await listLatestCompletedProfileAiReportIds({
        profileId,
        limit,
      });

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


};

export default clientRoutes;
