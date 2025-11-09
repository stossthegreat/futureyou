import { prisma } from '../../../utils/db';

export class PurposeRepo {
  async getOrCreate(userId: string): Promise<any> {
    let profile = await prisma.futureYouPurposeProfile.findUnique({
      where: { userId }
    });

    if (!profile) {
      profile = await prisma.futureYouPurposeProfile.create({
        data: { userId }
      });
    }

    return profile;
  }

  async update(userId: string, data: any): Promise<void> {
    await prisma.futureYouPurposeProfile.update({
      where: { userId },
      data
    });
  }

  async updateArtifacts(userId: string, artifacts: any): Promise<void> {
    const updates: any = {};
    
    if (artifacts.snapshot) updates.lifeTask = artifacts.snapshot;
    if (artifacts.strengths) updates.strengths = artifacts.strengths;
    if (artifacts.values_rank) updates.valuesRank = artifacts.values_rank;
    if (artifacts.flow_contexts) updates.flowContexts = artifacts.flow_contexts;
    if (artifacts.red_tags) updates.redTags = artifacts.red_tags;
    if (artifacts.sdt) {
      if (artifacts.sdt.autonomy !== undefined) updates.sdtAutonomy = artifacts.sdt.autonomy;
      if (artifacts.sdt.competence !== undefined) updates.sdtCompetence = artifacts.sdt.competence;
      if (artifacts.sdt.relatedness !== undefined) updates.sdtRelatedness = artifacts.sdt.relatedness;
    }

    if (Object.keys(updates).length > 0) {
      await this.update(userId, updates);
    }
  }
}

export const purposeRepo = new PurposeRepo();

