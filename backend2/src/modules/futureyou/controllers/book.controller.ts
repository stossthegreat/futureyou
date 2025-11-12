import { FastifyInstance } from 'fastify';
import { bookService } from '../services/book.service';
import { BookCompileDTO } from '../dto/engine.dto';
import { throttleService } from '../services/throttle.service';

export async function bookController(fastify: FastifyInstance) {
  fastify.post<{ Body: BookCompileDTO }>('/book/compile', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

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
      await throttleService.trackStart(userId, 5000); // Book compilation uses ~5k tokens
      
      const { includePhases, title } = req.body;
      const edition = await bookService.compile(userId, includePhases, title);

      await throttleService.trackEnd(userId);

      return {
        edition,
        skipped: edition.skipped,
        reason: edition.reason
      };
    } catch (error: any) {
      await throttleService.trackEnd(userId);
      console.error('Book compile error:', error);
      return reply.code(500).send({ error: error.message });
    }
  });

  fastify.get('/book/latest', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    const edition = await bookService.getLatest(userId);
    
    if (!edition) {
      return reply.code(404).send({ error: 'No book found' });
    }

    return { edition };
  });
}

