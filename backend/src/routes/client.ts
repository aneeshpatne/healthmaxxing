import type { FastifyPluginAsync } from "fastify";
import { v7 as uuidv7 } from "uuid";
import { RedisClient } from "bun";
import {
  addWaistMeasurement,
  initJob,
  jobExists,
  listUsers,
  listUserWaist,
  listUserWeight,
  profileExists,
  registerUser,
  type JobId,
  type ProfileId,
} from "../db/commands";

const sub = new RedisClient("redis://localhost:6379");

const clientRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    "/register",
    {
      schema: {
        body: {
          type: "object",
          required: ["name"],
          properties: {
            name: {
              type: "string",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { name } = request.body as {
        name: string;
      };
      const id: ProfileId = registerUser(name);

      app.log.info({ id, name }, "Registered user");

      return reply.code(201).send({
        ok: true,
        id,
        name,
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
    "/waist",
    {
      schema: {
        body: {
          type: "object",
          required: ["profileId", "waist"],
          properties: {
            profileId: {
              type: "string",
            },
            waist: {
              type: "number",
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { profileId, waist } = request.body as {
        profileId: string;
        waist: number;
      };

      if (!profileExists(profileId)) {
        return reply.code(404).send({
          ok: false,
          error: "Profile id does not exist",
        });
      }

      const id = addWaistMeasurement(profileId, waist);

      app.log.info({ id, profileId, waist }, "Registered waist measurement");

      return reply.code(201).send({
        ok: true,
        id,
        profileId,
        waist,
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
    "/waist/:profileId",
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

      const waists = listUserWaist(profileId);

      return reply.send({
        ok: true,
        profileId,
        waists,
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
