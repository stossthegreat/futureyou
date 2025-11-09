import { FastifyInstance } from 'fastify';
import { FutureYouAIService } from '../services/ai.service';
import { PhasesService } from '../services/phases.service';
import { ChaptersService } from '../services/chapters.service';
import { EngineStartDTO } from '../dto/engine.dto';
import { purposeRepo } from '../repo/purpose.repo';
import { throttleService } from '../services/throttle.service';

export async function engineController(fastify: FastifyInstance) {
  const ai = new FutureYouAIService();
  const phases = new PhasesService();
  const chapters = new ChaptersService();

  fastify.post<{ Body: EngineStartDTO }>('/engine/phase', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    const { phase, scenes = [] } = req.body;
    if (!phase) {
      return reply.code(400).send({ error: 'Missing phase' });
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
      await throttleService.trackStart(userId);

      // Get profile
      const profile = await purposeRepo.getOrCreate(userId);

      // Build transcript
      const transcript = scenes.map(s => `${s.role}: ${s.text}`).join('\n\n');

      // Get coach response
      const response = await ai.coachTurn(userId, phase, transcript, profile);

      // Update artifacts if present
      if (response.artifacts) {
        await purposeRepo.updateArtifacts(userId, response.artifacts);
      }

      // Check if should generate chapter
      const shouldGenerate = phases.shouldGenerateChapter(phase, profile, scenes);
      response.shouldGenerateChapter = shouldGenerate;

      // If chapter needed, generate immediately
      let chapterId: string | undefined;
      if (shouldGenerate) {
        const chapter = await chapters.generateChapter(userId, phase, transcript);
        chapterId = chapter.id;
      }

      await throttleService.trackEnd(userId);

      return {
        ...response,
        chapterId
      };
    } catch (error: any) {
      await throttleService.trackEnd(userId);
      console.error('Engine phase error:', error);
      return reply.code(500).send({ error: error.message });
    }
  });
}

