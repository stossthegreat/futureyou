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
   * 🧠 NEW: Manual trigger for pattern analysis
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
   * 🎭 NEW: Manual trigger for phase transition check
   */
  fastify.post('/admin/check-phase-transition/:userId', async (req, reply) => {
    const { userId } = req.params as { userId: string };

    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const currentPhase = consciousness.phase;

      // Check if ready for next phase
      const shouldTransition = memoryIntelligence.shouldTransitionPhase(consciousness);

      if (shouldTransition) {
        const nextPhase = currentPhase === "observer" ? "architect" : "oracle";
        
        await memoryService.upsertFacts(userId, {
          os_phase: {
            current_phase: nextPhase,
            started_at: new Date(),
            days_in_phase: 0,
            phase_transitions: [
              ...consciousness.os_phase.phase_transitions,
              { from: currentPhase, to: nextPhase, at: new Date() },
            ],
          },
        });

        return {
          transitioned: true,
          from: currentPhase,
          to: nextPhase,
          message: `User transitioned from ${currentPhase} to ${nextPhase}`,
        };
      }

      return {
        transitioned: false,
        current: currentPhase,
        reason: "Milestones not met",
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
   * 🔍 NEW: View user consciousness (for debugging)
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
