import type { FastifyPluginAsync } from "fastify";
import { v7 as uuidv7 } from "uuid";
import websocket from "@fastify/websocket";
import { RedisClient } from "bun";
import {
  initJob,
  registerUser,
  type JobId,
  type ProfileId,
} from "../db/commands";
const pub = new RedisClient("redis://localhost:6379");
const sub = new RedisClient("redis://localhost:6379");

const ingestRoutes: FastifyPluginAsync = async (app) => {
  await app.register(websocket);

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
      app.log.info({
        id,
        weight,
        heartbeat,
        impedance,
      });
      return {
        ok: true,
      };
    },
  );
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
      const id: JobId = uuidv7();

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
  app.get("/ws/tool/:jobId", { websocket: true }, (socket, request) => {
    const { jobId } = request.params as { jobId: string };

    socket.on("message", async (raw: { toString(): string }) => {
      const message = raw.toString();
      await pub.publish(`job:${jobId}`, message);
    });
  });

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

export default ingestRoutes;
