import { prisma } from '../../../utils/db';

export type ArtifactType =
  | 'story_map'
  | 'shadow_map'
  | 'strengths_grid'
  | 'flow_map'
  | 'odyssey_plans'
  | 'job_crafting'
  | 'purpose_card'
  | 'mastery_path';

export class ArtifactsRepository {
  async createOrUpdateArtifact(
    userId: string,
    artifactType: ArtifactType,
    data: Record<string, any>
  ) {
    return await prisma.lifeTaskArtifact.upsert({
      where: {
        userId_artifactType: {
          userId,
          artifactType,
        },
      },
      create: {
        userId,
        artifactType,
        data,
      },
      update: {
        data,
        updatedAt: new Date(),
      },
    });
  }

  async getArtifact(userId: string, artifactType: ArtifactType) {
    return await prisma.lifeTaskArtifact.findUnique({
      where: {
        userId_artifactType: {
          userId,
          artifactType,
        },
      },
    });
  }

  async getAllArtifacts(userId: string) {
    return await prisma.lifeTaskArtifact.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async deleteArtifact(userId: string, artifactType: ArtifactType) {
    return await prisma.lifeTaskArtifact.delete({
      where: {
        userId_artifactType: {
          userId,
          artifactType,
        },
      },
    });
  }

  async deleteAllArtifacts(userId: string) {
    return await prisma.lifeTaskArtifact.deleteMany({
      where: { userId },
    });
  }
}

export const artifactsRepo = new ArtifactsRepository();

