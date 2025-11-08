import crypto from 'crypto';
import { prisma } from '../../../utils/db';
import { FutureYouAIService } from './ai.service';
import { PhasesService } from './phases.service';
import { PhaseId } from '../dto/engine.dto';

export class ChaptersService {
  private ai = new FutureYouAIService();
  private phases = new PhasesService();

  async generateChapter(userId: string, phase: PhaseId, seed?: string): Promise<any> {
    const prompt = this.phases.getChapterPrompt(phase);
    const userMsg = seed 
      ? `${prompt}\n\nSEED CONTENT:\n${seed}`
      : prompt;

    const response = await this.ai.coachTurn(userId, phase, userMsg, {});
    const draft = response.coach;
    const words = this.countWords(draft);
    const draftHash = crypto.createHash('sha1').update(draft).digest('hex');

    // Check for duplicate
    const existing = await prisma.futureYouChapter.findFirst({
      where: { userId, phase, draftHash }
    });
    
    if (existing) return existing;

    return await prisma.futureYouChapter.create({
      data: {
        userId,
        phase,
        title: this.phases.getPhaseTitle(phase),
        bodyMd: draft,
        words,
        draftHash,
        status: 'final'
      }
    });
  }

  async listChapters(userId: string): Promise<any[]> {
    return await prisma.futureYouChapter.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      select: { id: true, phase: true, title: true, words: true, createdAt: true }
    });
  }

  private countWords(text: string): number {
    return text.split(/\s+/).filter(w => w.length > 0).length;
  }
}

