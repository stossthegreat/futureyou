import crypto from 'crypto';
import { FutureYouAIService } from './ai.service';
import { PhasesService } from './phases.service';
import { PhaseId } from '../dto/engine.dto';
import { chaptersRepo } from '../repo/chapters.repo';

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
    const exists = await chaptersRepo.existsByHash(userId, phase, draftHash);
    if (exists) {
      const existing = await chaptersRepo.getByPhase(userId, phase);
      return existing;
    }

    // Queue write (batched)
    const chapterData = {
      userId,
      phase,
      title: this.phases.getPhaseTitle(phase),
      bodyMd: draft,
      words,
      draftHash
    };

    chaptersRepo.queueWrite(chapterData);

    // Return immediately (optimistic)
    return {
      id: 'pending-' + Date.now(),
      ...chapterData,
      status: 'final',
      createdAt: new Date()
    };
  }

  async listChapters(userId: string): Promise<any[]> {
    return await chaptersRepo.list(userId);
  }

  private countWords(text: string): number {
    return text.split(/\s+/).filter(w => w.length > 0).length;
  }
}

