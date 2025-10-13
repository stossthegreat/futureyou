import { FastifyInstance } from "fastify";
import { chatService } from "../services/chat.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

export async function chatController(fastify: FastifyInstance) {
  fastify.post("/api/v1/chat", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { message } = req.body;
      const res = await chatService.nextMessage(userId, message);
      return res;
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });
}
