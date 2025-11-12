import { FastifyInstance } from "fastify";
import { NudgesService } from "../services/nudges.service";

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    const err: any = new Error("Unauthorized: missing user id");
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export async function nudgesController(fastify: FastifyInstance) {
  const nudgesService = new NudgesService();

  fastify.get("/api/v1/nudges", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      return await nudgesService.generateNudges(userId);
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });
}
