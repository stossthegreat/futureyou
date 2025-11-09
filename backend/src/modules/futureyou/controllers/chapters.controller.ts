import { FastifyInstance } from 'fastify';
import { ChaptersService } from '../services/chapters.service';
import { ChapterDTO } from '../dto/engine.dto';
import { throttleService } from '../services/throttle.service';

export async function chaptersController(fastify: FastifyInstance) {
  const chapters = new ChaptersService();

  fastify.post<{ Body: ChapterDTO }>('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const { phase, title, body } = req.body;
    if (!phase) return reply.code(400).send({ error: 'Missing phase' });

    // Check throttle
    const throttle = await throttleService.canRun(userId);
    if (!throttle.ok) {
      return reply.code(202).send({
        queued: true,
        reason: throttle.reason,
        etaMs: throttle.waitMs
      });
    }

    try {
      await throttleService.trackStart(userId, 1000);
      
      const chapter = await chapters.generateChapter(userId, phase, body);
      
      await throttleService.trackEnd(userId);
      
      return { chapter };
    } catch (error: any) {
      await throttleService.trackEnd(userId);
      return reply.code(500).send({ error: error.message });
    }
  });

  fastify.get('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const list = await chapters.listChapters(userId);
    return { chapters: list };
  });
}

