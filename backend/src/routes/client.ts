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
  registerUser,
  type JobId,
  type ProfileId,
} from "../db/commands";

const redis = new RedisClient("redis://localhost:6379");
const sub = new RedisClient("redis://localhost:6379");

const clientRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    "/register",
    {
      schema: {
        body: {
          type: "object",
          required: ["name", "heightCm", "dateOfBirth", "gender"],
          properties: {
            name: {
              type: "string",
            },
            heightCm: {
              type: "number",
            },
            dateOfBirth: {
              type: "string",
            },
            gender: {
              type: "string",
              enum: ["male", "female"],
            },
          },
        },
      },
    },
    async (request, reply) => {
      const {
        name,
        heightCm,
        dateOfBirth,
        gender,
      } = request.body as {
        name: string;
        heightCm: number;
        dateOfBirth: string;
        gender: "male" | "female";
      };
      const id: ProfileId = registerUser({
        name,
        heightCm,
        dateOfBirth,
        gender,
      });

      app.log.info({ id, name, heightCm, dateOfBirth, gender }, "Registered user");

      return reply.code(201).send({
        ok: true,
        id,
        name,
        heightCm,
        dateOfBirth,
        gender,
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
