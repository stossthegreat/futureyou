import { FastifyInstance } from "fastify";
import { tasksService } from "../services/tasks.service";

function getUserIdOr401(req: any): string {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid || typeof uid !== "string") {
    const err: any = new Error("Unauthorized: missing user id");
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export async function tasksController(fastify: FastifyInstance) {
  const service = tasksService;

  // List tasks
  fastify.get("/api/v1/tasks", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const includeCompleted =
        req.query.includeCompleted === "true" || req.query.includeCompleted === true;
      return await service.list(userId, includeCompleted);
    } catch (e: any) {
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // Get task by ID
  fastify.get("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const task = await service.getById(req.params.id, userId);
      if (!task) return reply.code(404).send({ error: "Task not found" });
      return task;
    } catch (e: any) {
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // Create task
  fastify.post("/api/v1/tasks", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
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
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // Update task
  fastify.patch("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      return await service.update(req.params.id, userId, req.body);
    } catch (e: any) {
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // Complete task
  fastify.post("/api/v1/tasks/:id/complete", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      return await service.complete(req.params.id, userId);
    } catch (e: any) {
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // Delete task
  fastify.delete("/api/v1/tasks/:id", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      return await service.delete(req.params.id, userId);
    } catch (e: any) {
      const code = e.statusCode || 400;
      return reply.code(code).send({ error: e.message });
    }
  });
}
