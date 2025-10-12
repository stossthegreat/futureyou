// src/controllers/brief.controller.ts
import { FastifyInstance, FastifyPluginOptions } from 'fastify';
import { prisma } from '../utils/db';

function getUserIdOr401(req: any): string {
  const uid = req?.user?.id || req.headers['x-user-id'];
  if (!uid || typeof uid !== 'string') {
    const err: any = new Error('Unauthorized: missing user id');
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export default async function briefRoutes(fastify: FastifyInstance, _opts: FastifyPluginOptions) {
  // GET /v1/brief/today
  fastify.get('/v1/brief/today', {
    schema: {
      tags: ['Brief'],
      summary: "Get today's morning brief bundle (no creation, just read + derive)",
      response: { 200: { type: 'object' }, 400: { type: 'object' } }
    },
  }, async (req, reply) => {
    try {
      const userId = getUserIdOr401(req);

      // Pull habits/tasks directly; do not create or mutate anything.
      const { habitsService } = await import('../services/habits.service');
      const { tasksService } = await import('../services/tasks.service');

      const habits = await habitsService.list(userId);
      const tasks = await tasksService.list(userId, true); // include completed for context

      // Today selections (if any exist)
      const todayIso = new Date().toISOString().split('T')[0];
      const todaySelections = await prisma.todaySelection.findMany({
        where: { userId, date: todayIso },
        include: { habit: true, task: true },
      });

      const today = todaySelections
        .map(sel => {
          if (sel.habit) {
            const completedToday = sel.habit.lastTick
              ? new Date(sel.habit.lastTick).toDateString() === new Date().toDateString()
              : false;
            return {
              id: sel.habit.id,
              name: sel.habit.title,
              type: 'habit',
              completed: completedToday,
              streak: sel.habit.streak,
              color: (sel.habit as any).color ?? 'emerald',
            };
          }
          if (sel.task) {
            return {
              id: sel.task.id,
              name: sel.task.title,
              type: 'task',
              // NOTE: sel.task may be JsonValue — cast to any to satisfy TS
              completed: (sel.task as any).completed,
              priority: (sel.task as any).priority,
            };
          }
          return null;
        })
        .filter(Boolean);

      // We only return the raw ingredients + derived "today" set.
      // No mock text; if you want a generated brief text, call AI on the client or via /api/v1/ai/reply
      return {
        habits,
        tasks,
        today,
      };
    } catch (e: any) {
      fastify.log.error(e);
      return reply.code(400).send({ error: e.message || String(e) });
    }
  });

  // GET /v1/brief/evening  — if you have a service that composes a debrief, call it here.
  fastify.get('/v1/brief/evening', {
    schema: {
      tags: ['Brief'],
      summary: 'Get evening debrief (read-only composition)',
      response: { 200: { type: 'object' }, 400: { type: 'object' } }
    },
  }, async (req, reply) => {
    try {
      const userId = getUserIdOr401(req);

      // Example shape: pull events/metrics to let the client format or request AI
      const events = await prisma.event.findMany({
        where: { userId },
        orderBy: { ts: 'desc' },
        take: 100,
      });

      // Cast payload checks to any to satisfy TypeScript for JsonValue
      const keptToday = events.filter(e => e.type === 'habit_action' && (e.payload as any)?.completed === true);
      const missedToday = events.filter(e => e.type === 'habit_action' && (e.payload as any)?.completed === false);

      return {
        stats: {
          actionsToday: keptToday.length + missedToday.length,
          kept: keptToday.length,
          missed: missedToday.length,
        },
        recentEvents: events,
      };
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // POST /v1/brief/today/select
  fastify.post('/v1/brief/today/select', {
    schema: {
      tags: ['Brief'],
      summary: 'Select a habit or task for today (read-driven list curation)',
      body: {
        type: 'object',
        properties: {
          habitId: { type: 'string' },
          taskId: { type: 'string' },
          date: { type: 'string' },
        },
      },
      response: { 200: { type: 'object' }, 400: { type: 'object' } },
    },
  }, async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const body = req.body as { habitId?: string; taskId?: string; date?: string };
      if (!body.habitId && !body.taskId) {
        return reply.code(400).send({ error: 'habitId or taskId is required' });
      }
      const { todayService } = await import('../services/today.service');
      const res = await todayService.selectForToday(userId, body.habitId, body.taskId, body.date);
      return res;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // POST /v1/brief/today/deselect
  fastify.post('/v1/brief/today/deselect', {
    schema: {
      tags: ['Brief'],
      summary: 'Deselect (remove) a habit or task from today',
      body: {
        type: 'object',
        properties: {
          habitId: { type: 'string' },
          taskId: { type: 'string' },
          date: { type: 'string' },
        },
      },
      response: { 200: { type: 'object' }, 400: { type: 'object' } },
    },
  }, async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const body = req.body as { habitId?: string; taskId?: string; date?: string };
      if (!body.habitId && !body.taskId) {
        return reply.code(400).send({ error: 'habitId or taskId is required' });
      }
      const { todayService } = await import('../services/today.service');
      const res = await todayService.deselectForToday(userId, body.habitId, body.taskId, body.date);
      return res;
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });
  }
