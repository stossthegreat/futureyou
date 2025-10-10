import { FastifyInstance } from "fastify";
import { tasksService } from "../services/tasks.service";
import { prisma } from "../utils/db";

function getUserIdOrThrow(req: any): string {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    throw new Error("Unauthorized: missing user id");
  }
  return uid;
}

export async function tasksController(fastify: FastifyInstance) {
  const service = tasksService;

  // ✅ Ensure demo user exists (for dev mode)
  async function ensureDemoUser(userId: string) {
    if (userId === "demo-user-123") {
      const existingUser = await prisma.user.findUnique({ where: { id: userId } });
      if (!existingUser) {
        await prisma.user.create({
          data: {
            id: userId,
            email: "demo@drillsergeant.com",
            tz: "Europe/London",
            tone: "balanced",
            intensity: 2,
            consentRoast: false,
            plan: "FREE",
            mentorId: "marcus",
            nudgesEnabled: true,
            briefsEnabled: true,
            debriefsEnabled: true,
          },
        });
        console.log("✅ Created demo user:", userId);
      }
    }
  }

  // 📋 List tasks
  fastify.get("/api/v1/tasks", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      const includeCompleted =
        req.query.includeCompleted === "true" || req.query.includeCompleted === true;
      const result = await service.list(userId, includeCompleted);
      return result;
    } catch (e: any) {
      return reply.code(401).send({ error: e.message });
    }
  });

  // 🔍 Get task by ID
  fastify.get("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      const task = await service.getById(req.params.id, userId);
      if (!task) return reply.code(404).send({ error: "Task not found" });
      return task;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // ➕ Create task
  fastify.post("/api/v1/tasks", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      await ensureDemoUser(userId);
      const body = req.body || {};
      const task = await service.create(userId, {
        title: body.title,
        description: body.description,
        dueDate: body.dueDate ? new Date(body.dueDate) : undefined,
        priority: body.priority,
        category: body.category,
      });
      reply.code(201);
      return task;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // ✏️ Update task
  fastify.patch("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      const updated = await service.update(req.params.id, userId, req.body);
      return updated;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // ✅ Complete task
  fastify.post("/api/v1/tasks/:id/complete", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      await ensureDemoUser(userId);
      const result = await service.complete(req.params.id, userId);
      return result;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // ❌ Delete task
  fastify.delete("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOrThrow(req);
      await ensureDemoUser(userId);
      const result = await service.delete(req.params.id, userId);
      return result;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });
}
