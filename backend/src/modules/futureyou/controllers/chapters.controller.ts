import { FastifyInstance } from 'fastify';
import { ChaptersService } from '../services/chapters.service';
import { ChapterDTO } from '../dto/engine.dto';

export async function chaptersController(fastify: FastifyInstance) {
  const chapters = new ChaptersService();

  fastify.post<{ Body: ChapterDTO }>('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const { phase, title, body } = req.body;
    if (!phase) return reply.code(400).send({ error: 'Missing phase' });

    const chapter = await chapters.generateChapter(userId, phase, body);
    return { chapter };
  });

  fastify.get('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const list = await chapters.listChapters(userId);
    return { chapters: list };
  });
}

