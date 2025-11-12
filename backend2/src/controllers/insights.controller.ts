// src/controllers/insights.controller.ts
import { FastifyInstance } from "fastify";
import { insightsService } from "../services/insights.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

export async function insightsController(fastify: FastifyInstance) {
  // 📊 Get proactive insights for user
  fastify.get("/api/v1/insights", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const insights = await insightsService.analyzePatterns(userId);
      return { insights };
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });

  // 📅 Manually trigger weekly consolidation (for testing)
  fastify.post("/api/v1/insights/consolidate", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const result = await insightsService.weeklyConsolidation(userId);
      return result;
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });
}

