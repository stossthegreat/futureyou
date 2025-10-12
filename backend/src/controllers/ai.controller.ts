import { FastifyInstance, FastifyPluginOptions } from "fastify";
import { aiService } from "../services/ai.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    const err: any = new Error("Unauthorized: missing user id");
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export default async function aiController(fastify: FastifyInstance, _opts: FastifyPluginOptions) {
  // POST /api/v1/ai/reply  (explicit mentor)
  fastify.post("/api/v1/ai/reply", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { message, mentor } = req.body as { message: string; mentor: string };
      if (!message || !mentor) return reply.code(400).send({ error: "message and mentor are required" });

      const response = await aiService.generateMentorReply(userId, mentor as any, message);
      return { reply: response };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  // POST /v1/chat  (maps mode -> mentor)
  fastify.post("/v1/chat", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { message, mode, includeVoice } = req.body as {
        message: string;
        mode?: string;
        includeVoice?: boolean;
      };
      if (!message) return reply.code(400).send({ error: "message is required" });

      const mentor = mode === 'strict' ? 'drill' : mode === 'light' ? 'buddha' : 'marcus';
      const response = await aiService.generateMentorReply(userId, mentor as any, message);

      const result: any = { reply: response };

      if (includeVoice) {
        try {
          const { voiceService } = await import("../services/voice.service");
          const voiceResult = await voiceService.speak(userId, response, mentor);
          if (voiceResult?.url) result.voice = { url: voiceResult.url };
        } catch (voiceErr) {
          req.log.warn({ voiceErr }, "Voice generation failed");
        }
      }

      return result;
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });
}
