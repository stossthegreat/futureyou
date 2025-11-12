import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { GetProgressResponseDTO } from '../dto/chapter.dto';
import { chaptersRepo } from '../repo/chapters.repo';

/**
 * CHAPTERS CONTROLLER
 * Handles chapter retrieval and progress tracking
 */

export async function chaptersController(fastify: FastifyInstance) {
  
  /**
   * GET /api/lifetask/chapters/:chapterNumber
   * Get specific chapter
   */
  fastify.get<{ Params: { chapterNumber: string } }>(
    '/chapters/:chapterNumber',
    async (req: FastifyRequest<{ Params: { chapterNumber: string } }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const chapterNumber = parseInt(req.params.chapterNumber);

      if (isNaN(chapterNumber) || chapterNumber < 1 || chapterNumber > 7) {
        return reply.code(400).send({ error: 'Invalid chapter number (must be 1-7)' });
      }

      try {
        const chapter = await chaptersRepo.getChapter(userId, chapterNumber);
        
        if (!chapter) {
          return reply.code(404).send({ error: 'Chapter not found' });
        }

        return {
          chapter: {
            id: chapter.id,
            chapterNumber: chapter.chapterNumber,
            proseText: chapter.proseText,
            completedAt: chapter.completedAt,
            timeSpentMinutes: chapter.timeSpentMinutes,
            extractedPatterns: chapter.extractedPatterns,
          },
        };
      } catch (error: any) {
        console.error('[ChaptersController] Error fetching chapter:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch chapter' });
      }
    }
  );

  /**
   * GET /api/lifetask/chapters
   * Get all chapters
   */
  fastify.get(
    '/chapters',
    async (req: FastifyRequest, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      try {
        const chapters = await chaptersRepo.getAllChapters(userId);
        
        return {
          chapters: chapters.map(ch => ({
            id: ch.id,
            chapterNumber: ch.chapterNumber,
            proseText: ch.proseText,
            completedAt: ch.completedAt,
            timeSpentMinutes: ch.timeSpentMinutes,
          })),
        };
      } catch (error: any) {
        console.error('[ChaptersController] Error fetching chapters:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch chapters' });
      }
    }
  );

  /**
   * GET /api/lifetask/progress
   * Get user's progress through the journey
   */
  fastify.get(
    '/progress',
    async (req: FastifyRequest, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      try {
        const chapters = await chaptersRepo.getCompletedChapters(userId);
        const totalTimeSpent = chapters.reduce((sum, ch) => sum + ch.timeSpentMinutes, 0);

        const response: GetProgressResponseDTO = {
          chaptersCompleted: chapters.map(ch => ch.chapterNumber).sort(),
          totalChapters: 7,
          artifactsGenerated: [], // Would need to query artifacts
          bookCompiled: false, // Would need to query books
          totalTimeSpent,
        };

        return response;
      } catch (error: any) {
        console.error('[ChaptersController] Error fetching progress:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch progress' });
      }
    }
  );

  /**
   * DELETE /api/lifetask/chapters/:chapterNumber
   * Delete a chapter (for restart/reset)
   */
  fastify.delete<{ Params: { chapterNumber: string } }>(
    '/chapters/:chapterNumber',
    async (req: FastifyRequest<{ Params: { chapterNumber: string } }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const chapterNumber = parseInt(req.params.chapterNumber);

      if (isNaN(chapterNumber) || chapterNumber < 1 || chapterNumber > 7) {
        return reply.code(400).send({ error: 'Invalid chapter number (must be 1-7)' });
      }

      try {
        await chaptersRepo.deleteChapter(userId, chapterNumber);
        
        return { success: true, message: `Chapter ${chapterNumber} deleted` };
      } catch (error: any) {
        console.error('[ChaptersController] Error deleting chapter:', error);
        return reply.code(500).send({ error: error.message || 'Failed to delete chapter' });
      }
    }
  );
}

