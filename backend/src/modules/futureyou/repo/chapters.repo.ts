import { prisma } from '../../../utils/db';

interface ChapterData {
  userId: string;
  phase: string;
  title: string;
  bodyMd: string;
  words: number;
  draftHash: string;
}

class ChaptersBatchWriter {
  private queue: ChapterData[] = [];
  private flushInterval: NodeJS.Timeout | null = null;
  private readonly BATCH_MS = Number(process.env.FUTUREYOU_WRITE_BATCH_MS || 2500);

  constructor() {
    this.startFlushing();
  }

  addChapter(data: ChapterData) {
    this.queue.push(data);
  }

  private startFlushing() {
    this.flushInterval = setInterval(() => {
      this.flush();
    }, this.BATCH_MS);
  }

  private async flush() {
    if (this.queue.length === 0) return;

    const batch = [...this.queue];
    this.queue = [];

    try {
      // Write all chapters in batch
      await Promise.all(
        batch.map(data =>
          prisma.futureYouChapter.create({ data })
        )
      );
      console.log(`✅ Flushed ${batch.length} chapters to DB`);
    } catch (error) {
      console.error('❌ Chapter batch write error:', error);
      // Re-queue on error
      this.queue.push(...batch);
    }
  }

  async forceFlush() {
    await this.flush();
  }

  stop() {
    if (this.flushInterval) {
      clearInterval(this.flushInterval);
    }
  }
}

export class ChaptersRepo {
  private batchWriter = new ChaptersBatchWriter();

  async existsByHash(userId: string, phase: string, draftHash: string): Promise<boolean> {
    const existing = await prisma.futureYouChapter.findFirst({
      where: { userId, phase, draftHash }
    });
    return !!existing;
  }

  async list(userId: string): Promise<any[]> {
    return await prisma.futureYouChapter.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      select: { id: true, phase: true, title: true, words: true, createdAt: true }
    });
  }

  async getByPhase(userId: string, phase: string): Promise<any | null> {
    return await prisma.futureYouChapter.findFirst({
      where: { userId, phase, status: 'final' },
      orderBy: { createdAt: 'desc' }
    });
  }

  queueWrite(data: ChapterData) {
    this.batchWriter.addChapter(data);
  }

  async forceFlush() {
    await this.batchWriter.forceFlush();
  }

  // Soft cleanup: keep last 9 chapters per phase
  async cleanup(userId: string, phase: string) {
    try {
      const chapters = await prisma.futureYouChapter.findMany({
        where: { userId, phase },
        orderBy: { createdAt: 'desc' },
        select: { id: true }
      });

      if (chapters.length > 9) {
        const toDelete = chapters.slice(9).map(c => c.id);
        await prisma.futureYouChapter.deleteMany({
          where: { id: { in: toDelete } }
        });
        console.log(`🧹 Cleaned up ${toDelete.length} old chapters for ${phase}`);
      }
    } catch (error) {
      console.error('Cleanup error:', error);
    }
  }
}

export const chaptersRepo = new ChaptersRepo();

