import { FastifyInstance } from "fastify";
import { futureYouChatService } from "../services/future-you-chat.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

/**
 * 🎯 FUTURE-YOU FREEFORM CHAT CONTROLLER
 * 
 * Separate from discovery chat (/api/v1/chat)
 * This is for ongoing purpose conversations with 7 lenses
 */
export async function futureYouChatController(fastify: FastifyInstance) {
  // Freeform chat with Future-You (GPT-5 Deep Discovery)
  fastify.post("/api/v1/future-you/freeform", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { message } = req.body;

      if (!message || typeof message !== "string") {
        return reply.code(400).send({ error: "Message required" });
      }

      const response = await futureYouChatService.chat(userId, message);
      
      // Return full structured response (chat, insightCards, commitCard, progress, nextQuestion, lensUsed)
      // Also include legacy 'message' field for backwards compatibility
      return {
        ...response,
        message: response.chat?.[0]?.text || "",
      };
    } catch (err: any) {
      console.error("Future-You chat error:", err);
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });

  // Clear conversation history
  fastify.post("/api/v1/future-you/clear-history", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const result = await futureYouChatService.clearHistory(userId);
      return result;
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });
}

