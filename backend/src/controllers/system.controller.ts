import { FastifyInstance } from 'fastify';
import { prisma } from '../utils/db';
import { checkDependencies } from '../utils/health';

export async function systemController(fastify: FastifyInstance) {
  fastify.get('/v1/system/alerts', async (req) => {
    const userId = (req as any).user?.id || (req.headers['x-user-id'] as string) || 'system';
    const alerts = await prisma.event.findMany({
      where: { type: 'system_alert', userId },
      orderBy: { ts: 'desc' },
      take: 10,
    });
    return alerts;
  });

  fastify.get('/v1/system/health', async () => {
    return await checkDependencies();
  });
}
