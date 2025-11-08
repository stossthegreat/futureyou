import { FastifyInstance } from 'fastify';
import { FutureYouAIService } from '../services/ai.service';
import { PhasesService } from '../services/phases.service';
import { ChaptersService } from '../services/chapters.service';
import { PurposeService } from '../services/purpose.service';
import { EngineStartDTO } from '../dto/engine.dto';

export async function engineController(fastify: FastifyInstance) {
  const ai = new FutureYouAIService();
  const phases = new PhasesService();
  const chapters = new ChaptersService();
  const purpose = new PurposeService();

  fastify.post<{ Body: EngineStartDTO }>('/engine/phase', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    const { phase, scenes = [] } = req.body;
    if (!phase) {
      return reply.code(400).send({ error: 'Missing phase' });
    }

    // Get profile
    const profile = await purpose.getOrCreateProfile(userId);

    // Build transcript
    const transcript = scenes.map(s => `${s.role}: ${s.text}`).join('\n\n');

    // Get coach response
    const response = await ai.coachTurn(userId, phase, transcript, profile);

    // Update artifacts if present
    if (response.artifacts) {
      await purpose.updateArtifacts(userId, response.artifacts);
    }

    // Check if should generate chapter
    const shouldGenerate = phases.shouldGenerateChapter(phase, profile, scenes);
    response.shouldGenerateChapter = shouldGenerate;

    // If chapter needed, generate immediately (Phase 1: sync)
    let chapterId: string | undefined;
    if (shouldGenerate) {
      const chapter = await chapters.generateChapter(userId, phase, transcript);
      chapterId = chapter.id;
    }

    return {
      ...response,
      chapterId
    };
  });
}

