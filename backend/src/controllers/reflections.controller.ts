// backend/src/controllers/reflections.controller.ts
// API endpoints for user reflection capture
// Allows users to answer brief/debrief questions

import { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../utils/db";
import { semanticMemory } from "../services/semanticMemory.service";

interface ReflectionBody {
  source: "morning_brief" | "evening_debrief";
  dayKey: string; // YYYY-MM-DD
  answer: string;
  questionsSnapshot?: string;
}

interface HistoryQuery {
  limit?: string;
  cursor?: string;
}

export async function reflectionsController(app: FastifyInstance) {
  //
  // POST /api/os/reflections
  // Submit a reflection answer
  //
  app.post("/api/os/reflections", async (req: FastifyRequest<{ Body: ReflectionBody }>, reply: FastifyReply) => {
    try {
      const userId = (req as any).userId;
      if (!userId) {
        return reply.code(401).send({ ok: false, error: "Unauthorized" });
      }

      const { source, dayKey, answer, questionsSnapshot } = req.body;

      // Validate input
      if (!source || !dayKey || !answer) {
        return reply.code(400).send({ ok: false, error: "Missing required fields: source, dayKey, answer" });
      }

      if (source !== "morning_brief" && source !== "evening_debrief") {
        return reply.code(400).send({ ok: false, error: "Invalid source. Must be morning_brief or evening_debrief" });
      }

      if (!answer.trim() || answer.trim().length < 3) {
        return reply.code(400).send({ ok: false, error: "Answer must be at least 3 characters" });
      }

      // Create event
      const event = await prisma.event.create({
        data: {
          userId,
          type: "reflection_answer",
          payload: {
            source,
            dayKey,
            answer: answer.trim(),
            questionsSnapshot: questionsSnapshot || null,
            createdAt: new Date(),
          },
        },
      });

      // Store in semantic memory
      await semanticMemory.storeMemory({
        userId,
        type: "reflection",
        text: answer.trim(),
        metadata: {
          source,
          dayKey,
          questionsSnapshot,
          createdAt: new Date().toISOString(),
        },
        importance: 4, // Reflections are high importance
      });

      console.log(`✅ [Reflections] Stored reflection for user ${userId.substring(0, 8)} (${source}, ${dayKey})`);

      return reply.send({ ok: true, id: event.id });
    } catch (err) {
      console.error("❌ [Reflections] POST failed:", err);
      return reply.code(500).send({ ok: false, error: "Internal server error" });
    }
  });

  //
  // GET /api/os/reflections/today
  // Get today's reflections
  //
  app.get("/api/os/reflections/today", async (req: FastifyRequest, reply: FastifyReply) => {
    try {
      const userId = (req as any).userId;
      if (!userId) {
        return reply.code(401).send({ ok: false, error: "Unauthorized" });
      }

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const events = await prisma.event.findMany({
        where: {
          userId,
          type: "reflection_answer",
          ts: {
            gte: today,
            lt: tomorrow,
          },
        },
        orderBy: { ts: "desc" },
      });

      const items = events.map((e) => {
        const payload = e.payload as any;
        return {
          id: e.id,
          source: payload.source,
          dayKey: payload.dayKey,
          answer: payload.answer,
          questionsSnapshot: payload.questionsSnapshot,
          createdAt: e.ts.toISOString(),
        };
      });

      return reply.send({ ok: true, items });
    } catch (err) {
      console.error("❌ [Reflections] GET today failed:", err);
      return reply.code(500).send({ ok: false, error: "Internal server error" });
    }
  });

  //
  // GET /api/os/reflections/history
  // Get reflection history (paginated)
  //
  app.get("/api/os/reflections/history", async (req: FastifyRequest<{ Querystring: HistoryQuery }>, reply: FastifyReply) => {
    try {
      const userId = (req as any).userId;
      if (!userId) {
        return reply.code(401).send({ ok: false, error: "Unauthorized" });
      }

      const limit = parseInt(req.query.limit || "50", 10);
      const cursor = req.query.cursor;

      const where: any = {
        userId,
        type: "reflection_answer",
      };

      if (cursor) {
        where.ts = { lt: new Date(cursor) };
      }

      const events = await prisma.event.findMany({
        where,
        orderBy: { ts: "desc" },
        take: limit + 1, // Fetch one extra to determine if there are more
      });

      const hasMore = events.length > limit;
      const items = events.slice(0, limit).map((e) => {
        const payload = e.payload as any;
        return {
          id: e.id,
          source: payload.source,
          dayKey: payload.dayKey,
          answer: payload.answer,
          questionsSnapshot: payload.questionsSnapshot,
          createdAt: e.ts.toISOString(),
        };
      });

      const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].createdAt : null;

      return reply.send({
        ok: true,
        items,
        hasMore,
        nextCursor,
      });
    } catch (err) {
      console.error("❌ [Reflections] GET history failed:", err);
      return reply.code(500).send({ ok: false, error: "Internal server error" });
    }
  });
}

