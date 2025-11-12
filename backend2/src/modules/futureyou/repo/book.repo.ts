import { prisma } from '../../../utils/db';
import crypto from 'crypto';

export class BookRepo {
  async getLatest(userId: string): Promise<any | null> {
    return await prisma.futureYouBookEdition.findFirst({
      where: { userId },
      orderBy: { version: 'desc' }
    });
  }

  async create(userId: string, title: string, bodyMd: string, chapterIds: string[]): Promise<any> {
    const latest = await this.getLatest(userId);
    const version = latest ? latest.version + 1 : 1;

    return await prisma.futureYouBookEdition.create({
      data: {
        userId,
        version,
        title,
        bodyMd,
        chapterIds
      }
    });
  }

  async isIdentical(userId: string, chapterIds: string[], bodyMd: string): Promise<boolean> {
    const latest = await this.getLatest(userId);
    if (!latest) return false;

    const latestHash = crypto.createHash('sha1')
      .update(JSON.stringify(latest.chapterIds) + latest.bodyMd)
      .digest('hex');

    const newHash = crypto.createHash('sha1')
      .update(JSON.stringify(chapterIds) + bodyMd)
      .digest('hex');

    return latestHash === newHash;
  }

  // Soft cleanup: keep last 5 book editions
  async cleanup(userId: string) {
    try {
      const books = await prisma.futureYouBookEdition.findMany({
        where: { userId },
        orderBy: { version: 'desc' },
        select: { id: true }
      });

      if (books.length > 5) {
        const toDelete = books.slice(5).map(b => b.id);
        await prisma.futureYouBookEdition.deleteMany({
          where: { id: { in: toDelete } }
        });
        console.log(`🧹 Cleaned up ${toDelete.length} old book editions`);
      }
    } catch (error) {
      console.error('Book cleanup error:', error);
    }
  }
}

export const bookRepo = new BookRepo();

