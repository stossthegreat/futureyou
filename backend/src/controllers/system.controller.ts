import { FastifyInstance } from 'fastify';
import { prisma } from '../utils/db';
import { checkDependencies } from '../utils/health';
import { memoryIntelligence } from '../services/memory-intelligence.service';
import { memoryService } from '../services/memory.service';

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

  /**
   * 🧠 Manual trigger for pattern analysis
   */
  fastify.post('/admin/analyze-patterns/:userId', async (req, reply) => {
    const { userId } = req.params as { userId: string };
    
    try {
      await memoryIntelligence.extractPatternsFromEvents(userId);
      return { success: true, message: `Pattern analysis complete for user ${userId}` };
    } catch (error: any) {
      return reply.status(500).send({ success: false, error: error.message });
    }
  });

  /**
   * 🎭 Manual phase evaluation (no forced transition logic)
   * — The new OS decides phase through determinePhase()
   */
  fastify.post('/admin/check-phase-transition/:userId', async (req, reply) => {
    const { userId } = req.params as { userId: string };

    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const currentPhase = consciousness.phase;

      // Ask OS Brain what phase they *should* be in
      const recomputedPhase = memoryIntelligence.determinePhase(
        { 
          behaviorPatterns: consciousness.patterns,
          reflectionHistory: consciousness.reflectionHistory,
          os_phase: consciousness.os_phase
        },
        consciousness.identity,
        consciousness.os_phase.started_at
      );

      if (recomputedPhase !== currentPhase) {
        // Perform transition
        await memoryService.upsertFacts(userId, {
          os_phase: {
            current_phase: recomputedPhase,
            started_at: new Date(),
            days_in_phase: 0,
            phase_transitions: [
              ...consciousness.os_phase.phase_transitions,
              { from: currentPhase, to: recomputedPhase, at: new Date() },
            ],
          },
        });

        return {
          transitioned: true,
          from: currentPhase,
          to: recomputedPhase,
          message: `User transitioned from ${currentPhase} to ${recomputedPhase}`,
        };
      }

      return {
        transitioned: false,
        current: currentPhase,
        reason: "OS Brain indicates no phase change",
        details: {
          discoveryCompleted: consciousness.identity.discoveryCompleted,
          reflectionCount: consciousness.reflectionHistory.themes.length,
          reflectionDepth: consciousness.reflectionHistory.depth_score,
          consistency: consciousness.patterns.consistency_score,
          daysInPhase: consciousness.os_phase.days_in_phase,
        },
      };
    } catch (error: any) {
      return reply.status(500).send({ success: false, error: error.message });
    }
  });

  /**
   * 🔍 View user consciousness (debug mode)
   */
  fastify.get('/admin/consciousness/:userId', async (req, reply) => {
    const { userId } = req.params as { userId: string };

    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      return consciousness;
    } catch (error: any) {
      return reply.status(500).send({ success: false, error: error.message });
    }
  });
}
