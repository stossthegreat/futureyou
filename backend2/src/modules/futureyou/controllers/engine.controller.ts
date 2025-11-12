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
      console.error('[Engine] No userId provided');
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    const { phase, scenes = [] } = req.body;
    if (!phase) {
      console.error('[Engine] No phase provided');
      return reply.code(400).send({ error: 'Missing phase' });
    }

    console.log(`[Engine] Phase request - user: ${userId}, phase: ${phase}, scenes: ${scenes.length}`);

    // Check throttle
    const throttle = await throttleService.canRun(userId);
    if (!throttle.ok) {
      console.log(`[Engine] Throttled - ${throttle.reason}`);
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
      console.log(`[Engine] Profile loaded for ${userId}`);

      // Build transcript
      const transcript = scenes.map(s => `${s.role}: ${s.text}`).join('\n\n');

      // Get coach response
      console.log(`[Engine] Calling AI for coach response...`);
      const response = await ai.coachTurn(userId, phase, transcript, profile);
      console.log(`[Engine] AI response received: ${response.coach?.substring(0, 50)}...`);

      // Update artifacts if present
      if (response.artifacts) {
        await purposeRepo.updateArtifacts(userId, response.artifacts);
        console.log(`[Engine] Artifacts updated`);
      }

      // Check if should generate chapter
      const shouldGenerate = phases.shouldGenerateChapter(phase, profile, scenes);
      response.shouldGenerateChapter = shouldGenerate;
      console.log(`[Engine] Should generate chapter: ${shouldGenerate}`);

      // If chapter needed, generate immediately
      let chapterId: string | undefined;
      if (shouldGenerate) {
        console.log(`[Engine] Generating chapter for ${phase}...`);
        const chapter = await chapters.generateChapter(userId, phase, transcript);
        chapterId = chapter.id;
        console.log(`[Engine] Chapter generated: ${chapterId}`);
      }

      await throttleService.trackEnd(userId);

      return {
        ...response,
        chapterId
      };
    } catch (error: any) {
      await throttleService.trackEnd(userId);
      console.error('[Engine] Error:', error);
      return reply.code(500).send({ error: error.message });
    }
  });
}

