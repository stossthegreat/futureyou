// src/modules/coach/coach.controller.ts
import { FastifyInstance } from "fastify";
import { prisma } from "../../utils/db";
import { aiService } from "../../services/ai.service";
import { notificationsService } from "../../services/notifications.service";

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
   * 🔁 Observer sync: log completions to events
   */
  fastify.post("/api/v1/coach/sync", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { completions } = req.body as {
        completions: { habitId: string; date: string; done: boolean }[];
      };

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

      return { ok: true, logged: completions?.length ?? 0 };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  /**
   * 🧠 Fetch coach messages (nudges, briefs, letters)
   */
  fastify.get("/api/v1/coach/messages", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const events = await prisma.event.findMany({
        where: {
          userId,
          type: { in: ["morning_brief", "evening_debrief", "nudge", "coach", "mirror"] },
        },
        orderBy: { ts: "desc" },
        take: 30,
      });

      const messages = events.map((e) => ({
        id: e.id,
        userId,
        kind: mapEventTypeToKind(e.type),
        title: titleForKind(e.type),
        body: (e.payload as any)?.text ?? "",
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
   * 💌 Generate one-off reflective letter (AI)
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
          type: "coach", // ✅ matches Prisma enum
          payload: { text, topic },
        },
      });

      await notificationsService.send(
        userId,
        "Letter from Future You",
        text.slice(0, 180)
      );

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
    case "evening_debrief": return "debrief";  // ✅ FIXED: was "brief"
    case "nudge": return "nudge";
    case "coach": return "letter";
    case "mirror": return "mirror";
    default: return "nudge";
  }
}

function titleForKind(type: string): string {
  switch (type) {
    case "morning_brief": return "Morning Brief";
    case "evening_debrief": return "Evening Debrief";
    case "nudge": return "Nudge";
    case "coach": return "Letter from Future You";
    case "mirror": return "Mirror Reflection";
    default: return "Message";
  }
}
