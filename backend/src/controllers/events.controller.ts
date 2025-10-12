import { FastifyInstance } from 'fastify';
import { EventsService } from '../services/events.service';

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers['x-user-id'];
  if (!uid || typeof uid !== 'string') {
    const err: any = new Error('Unauthorized: missing user id');
    err.statusCode = 401;
    throw err;
  }
  return uid;
}

export async function eventsController(fastify: FastifyInstance) {
  const eventsService = new EventsService();

  // Generic event logger (OS-level)
  fastify.post('/v1/events', {
    schema: {
      tags: ['Events'],
      summary: 'Log a new user event',
      body: {
        type: 'object',
        properties: {
          type: { type: 'string' },
          payload: { type: 'object' },
        },
        required: ['type'],
        additionalProperties: true,
      },
      response: { 201: { type: 'object' } }
    }
  }, async (request: any, reply) => {
    const userId = getUserIdOr401(request);
    const { type, payload } = request.body || {};
    const event = await eventsService.logEvent(userId, type, payload || {});
    reply.code(201);
    return event;
  });

  // 🔎 “Sensor” endpoint used by the app when a habit is toggled.
  // Matches frontend ApiClient.logAction('/habits/log')
  fastify.post('/habits/log', {
    schema: {
      tags: ['Events'],
      summary: 'Log a habit action (observer feed)',
      body: {
        type: 'object',
        properties: {
          habitId: { type: 'string' },
          completed: { type: 'boolean' },
          timestamp: { type: 'string' },
        },
        required: ['habitId', 'completed', 'timestamp'],
      },
      response: { 201: { type: 'object' } }
    }
  }, async (request: any, reply) => {
    const userId = getUserIdOr401(request);
    const { habitId, completed, timestamp } = request.body;
    const payload = { habitId, completed, timestamp };
    const event = await eventsService.logEvent(userId, 'habit_action', payload);
    reply.code(201);
    return event;
  });

  fastify.get('/v1/events/recent', {
    schema: {
      tags: ['Events'],
      summary: 'Get recent events',
      response: { 200: { type: 'array' } }
    }
  }, async (request: any) => {
    const userId = getUserIdOr401(request);
    return eventsService.getRecentEvents(userId, 20);
  });

  fastify.get('/v1/events/patterns', {
    schema: {
      tags: ['Events'],
      summary: 'Analyze user event patterns',
      response: { 200: { type: 'object' } }
    }
  }, async (request: any) => {
    const userId = getUserIdOr401(request);
    return eventsService.getPatterns(userId);
  });
}
