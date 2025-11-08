import { FastifyInstance } from 'fastify';
import { engineController } from './controllers/engine.controller';
import { chaptersController } from './controllers/chapters.controller';

export async function futureYouRouter(fastify: FastifyInstance) {
  // Guard: only register if enabled
  if (process.env.FUTUREYOU_ENABLED !== 'true') {
    fastify.get('/api/futureyou/status', async () => ({ enabled: false }));
    return;
  }

  fastify.get('/api/futureyou/status', async () => ({ enabled: true }));
  
  await fastify.register(engineController, { prefix: '/api/futureyou' });
  await fastify.register(chaptersController, { prefix: '/api/futureyou' });
}

