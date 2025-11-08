import { FastifyInstance } from "fastify";
import { whatIfV2Service } from "../services/what-if-v2.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

export async function whatIfChatControllerV2(fastify: FastifyInstance) {
  // Main coaching endpoint
  fastify.post("/api/v2/what-if/coach", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { message } = req.body || {};
      
      if (!message || typeof message !== "string") {
        return reply.code(400).send({ error: "Message required" });
      }
      
      const response = await whatIfV2Service.chat(userId, message);
      
      // Response can be { message } or { message, suggestedPlan }
      return response;
    } catch (err: any) {
      console.error("What‑If v2 error:", err);
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });

  // Clear chat history
  fastify.post("/api/v2/what-if/clear-history", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      return await whatIfV2Service.clearHistory(userId);
    } catch (err: any) {
      console.error("What‑If v2 clear error:", err);
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });
}

