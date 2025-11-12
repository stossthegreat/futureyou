import { FastifyInstance } from "fastify";
import { whatIfService } from "../services/whatif.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

export async function whatIfController(fastify: FastifyInstance) {
  fastify.get("/api/v1/whatif/purpose-goals", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const goals = await whatIfService.generatePurposeAlignedGoals(userId);
      return { goals };
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });
}

