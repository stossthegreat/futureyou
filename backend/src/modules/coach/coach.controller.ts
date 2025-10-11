import { FastifyInstance } from "fastify";
import { coachService } from "./coach.service";

export default async function coachController(fastify: FastifyInstance) {

  // ✅ Sync frontend state (habits + completions)
  fastify.post("/api/v1/coach/sync", async (req, reply) => {
    const userId = req.headers["x-user-id"];
    if (!userId) return reply.code(401).send({ error: "Unauthorized" });

    const { habits, completions } = req.body as any;
    await coachService.sync(userId as string, habits, completions);
    return { ok: true };
  });

  // ✅ Fetch mentor messages (nudges, letters)
  fastify.get("/api/v1/coach/messages", async (req, reply) => {
    const userId = req.headers["x-user-id"];
    if (!userId) return reply.code(401).send({ error: "Unauthorized" });

    const messages = await coachService.getMessages(userId as string);
    return { messages };
  });
}
