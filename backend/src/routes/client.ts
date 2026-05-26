import type { FastifyPluginAsync } from "fastify";
import { v7 as uuidv7 } from "uuid";
import { RedisClient } from "bun";
import {
  addBodyMeasurement,
  initJob,
  jobExists,
  listUserBodyMeasurements,
  listUsers,
  listUserWeight,
  profileExists,
  registerProfileMetadata,
  registerUser,
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
          required: ["name", "mailAddress"],
          properties: {
            name: {
              type: "string",
            },
            mailAddress: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { name, mailAddress } = request.body as {
        name: string;
        mailAddress: string;
      };
      const id: ProfileId = registerUser({
        name,
        mailAddress,
      });

      app.log.info({ id, name, mailAddress }, "Registered user");

      return reply.code(201).send({
        ok: true,
        id,
        name,
        mailAddress,
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
      } = request.body as {
        profileId: string;
        heightCm: number;
        dateOfBirth: string;
        peopleType: "standard" | "athlete";
        gender: "male" | "female";
        profileImage?: string | null;
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
      });

      app.log.info(
        { profileId, heightCm, dateOfBirth, peopleType, gender, profileImage },
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

  app.post(
    "/body-measurements",
    {
      schema: {
        body: {
          type: "object",
          required: ["profileId"],
          anyOf: [{ required: ["waistCm"] }, { required: ["neckCm"] }],
          properties: {
            profileId: {
              type: "string",
            },
            waistCm: {
              type: "number",
            },
            neckCm: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const {
        profileId,
        waistCm = null,
        neckCm = null,
      } = request.body as {
        profileId: string;
        waistCm?: number | null;
        neckCm?: number | null;
      };

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const id = addBodyMeasurement(profileId, { waistCm, neckCm });

      app.log.info(
        { id, profileId, waistCm, neckCm },
        "Registered body measurement",
      );

      return reply.code(201).send({
        ok: true,
        id,
        profileId,
        waistCm,
        neckCm,
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
