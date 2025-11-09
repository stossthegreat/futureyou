import { FastifyInstance } from 'fastify';
import { engineController } from './controllers/engine.controller';
import { chaptersController } from './controllers/chapters.controller';
import { bookController } from './controllers/book.controller';

export async function futureYouRouter(fastify: FastifyInstance) {
  // Guard: only register if explicitly disabled (default: ENABLED)
  if (process.env.FUTUREYOU_ENABLED === 'false') {
    fastify.get('/api/futureyou/status', async () => ({ enabled: false }));
    return;
  }

  fastify.get('/api/futureyou/status', async () => ({ enabled: true }));
  
  await fastify.register(engineController, { prefix: '/api/futureyou' });
  await fastify.register(chaptersController, { prefix: '/api/futureyou' });
  await fastify.register(bookController, { prefix: '/api/futureyou' });
}

