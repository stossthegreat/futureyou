import { FastifyInstance } from "fastify";
import { prisma } from "../utils/db";
import { aiService } from "../services/ai.service";
import { notificationsService } from "../services/notifications.service";

function getUserIdOr401(req: any): string {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    const err: any = new Error("Unauthorized: missing user id");
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export default async function coachController(fastify: FastifyInstance) {

  /**
   * ✅ Sync frontend state (habits + completions)
   * This does not mutate habits — it just writes observer data into the event log.
   */
  fastify.post("/api/v1/coach/sync", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { habits, completions } = req.body as {
        habits: any[];
        completions: { habitId: string; date: string; done: boolean }[];
      };

      // Write completions as events (observer feed)
      if (Array.isArray(completions) && completions.length > 0) {
        const writes = completions.map((c) =>
          prisma.event.create({
            data: {
              userId,
              type: "habit_action",
              payload: {
                habitId: c.habitId,
                date: c.date,
                completed: c.done,
              },
            },
          })
        );
        await Promise.allSettled(writes);
      }

      // We don’t store habits here; they live only client-side.
      return { ok: true, logged: completions?.length ?? 0 };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  /**
   * ✅ Fetch OS-generated mentor messages (nudges, briefs, letters, mirror)
   * Reads the same events that the schedulers and AI jobs create.
   */
  fastify.get("/api/v1/coach/messages", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);

      // Pull latest OS events tagged as coach content
      const events = await prisma.event.findMany({
        where: {
          userId,
          type: { in: ["morning_brief", "evening_debrief", "nudge", "letter", "mirror"] },
        },
        orderBy: { ts: "desc" },
        take: 30,
      });

      // Convert to frontend shape (CoachMessage)
      const messages = events.map((e) => ({
        id: e.id,
        userId,
        kind: mapEventTypeToKind(e.type),
        title: titleForKind(e.type),
        body: e.payload?.text ?? "",
        meta: e.payload,
        createdAt: e.ts,
        readAt: null,
      }));

      return { messages };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  /**
   * 🧠 POST /api/v1/coach/reflect
   * Optional: generate a one-off reflective “letter from Future You”.
   */
  fastify.post("/api/v1/coach/reflect", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { topic } = req.body as { topic: string };
      const user = await prisma.user.findUnique({ where: { id: userId } });
      const mentor = (user as any)?.mentorId || "marcus";

      const prompt = `Write a reflective short letter from Future You about: ${topic}`;
      const text = await aiService.generateMentorReply(userId, mentor, prompt, {
        purpose: "letter",
        maxChars: 800,
      });

      const event = await prisma.event.create({
        data: {
          userId,
          type: "letter",
          payload: { text, topic },
        },
      });

      await notificationsService.send(userId, "Letter from Future You", text.slice(0, 180));

      return { ok: true, message: text, id: event.id };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });
}

/** Helper mappers */
function mapEventTypeToKind(type: string): string {
  switch (type) {
    case "morning_brief": return "brief";
    case "evening_debrief": return "brief";
    case "nudge": return "nudge";
    case "letter": return "letter";
    case "mirror": return "mirror";
    default: return "nudge";
  }
}

function titleForKind(type: string): string {
  switch (type) {
    case "morning_brief": return "Morning Brief";
    case "evening_debrief": return "Evening Debrief";
    case "nudge": return "Nudge";
    case "letter": return "Letter from Future You";
    case "mirror": return "Mirror Reflection";
    default: return "Message";
  }
  }
