import { FastifyInstance } from "fastify";
import { notificationsService } from "../services/notifications.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    const err: any = new Error("Unauthorized: missing user id");
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export async function notificationsController(fastify: FastifyInstance) {
  fastify.post("/api/v1/notifications/send", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { title, body } = req.body as { title: string; body: string };
      if (!title || !body) return reply.code(400).send({ error: "title and body are required" });
      return await notificationsService.send(userId, title, body);
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  fastify.post("/api/v1/notifications/schedule", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { title, body, delaySeconds } = req.body as {
        title: string;
        body: string;
        delaySeconds: number;
      };
      if (!title || !body || typeof delaySeconds !== 'number') {
        return reply.code(400).send({ error: "title, body, and delaySeconds are required" });
      }
      return await notificationsService.schedule(userId, title, body, delaySeconds);
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });
}
