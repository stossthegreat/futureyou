import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { GetArtifactsResponseDTO } from '../dto/chapter.dto';
import { artifactsRepo, ArtifactType } from '../repo/artifacts.repo';

/**
 * ARTIFACTS CONTROLLER
 * Handles vault artifacts retrieval
 */

export async function artifactsController(fastify: FastifyInstance) {
  
  /**
   * GET /api/lifetask/artifacts
   * Get all artifacts for user
   */
  fastify.get(
    '/artifacts',
    async (req: FastifyRequest, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      try {
        const artifacts = await artifactsRepo.getAllArtifacts(userId);
        
        const response: GetArtifactsResponseDTO = {
          artifacts: artifacts.map(art => ({
            artifactType: art.artifactType,
            data: art.data as Record<string, any>,
            updatedAt: art.updatedAt.toISOString(),
          })),
        };

        return response;
      } catch (error: any) {
        console.error('[ArtifactsController] Error fetching artifacts:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch artifacts' });
      }
    }
  );

  /**
   * GET /api/lifetask/artifacts/:artifactType
   * Get specific artifact
   */
  fastify.get<{ Params: { artifactType: string } }>(
    '/artifacts/:artifactType',
    async (req: FastifyRequest<{ Params: { artifactType: string } }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const artifactType = req.params.artifactType as ArtifactType;

      const validTypes: ArtifactType[] = [
        'story_map',
        'shadow_map',
        'strengths_grid',
        'flow_map',
        'odyssey_plans',
        'job_crafting',
        'purpose_card',
        'mastery_path',
      ];

      if (!validTypes.includes(artifactType)) {
        return reply.code(400).send({ error: 'Invalid artifact type' });
      }

      try {
        const artifact = await artifactsRepo.getArtifact(userId, artifactType);
        
        if (!artifact) {
          return reply.code(404).send({ error: 'Artifact not found' });
        }

        return {
          artifact: {
            artifactType: artifact.artifactType,
            data: artifact.data,
            updatedAt: artifact.updatedAt.toISOString(),
          },
        };
      } catch (error: any) {
        console.error('[ArtifactsController] Error fetching artifact:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch artifact' });
      }
    }
  );
}

