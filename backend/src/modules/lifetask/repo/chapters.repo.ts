import { prisma } from '../../../utils/db';
import { MessageDTO } from '../dto/conversation.dto';

export class ChaptersRepository {
  async createOrUpdateChapter(
    userId: string,
    chapterNumber: number,
    messages: MessageDTO[],
    timeSpentMinutes: number,
    extractedPatterns?: Record<string, any>,
    proseText?: string
  ) {
    return await prisma.lifeTaskChapter.upsert({
      where: {
        userId_chapterNumber: {
          userId,
          chapterNumber,
        },
      },
      create: {
        userId,
        chapterNumber,
        conversationTranscript: messages,
        extractedPatterns: extractedPatterns || {},
        proseText,
        timeSpentMinutes,
        completedAt: proseText ? new Date() : null,
      },
      update: {
        conversationTranscript: messages,
        extractedPatterns: extractedPatterns || {},
        proseText,
        timeSpentMinutes,
        completedAt: proseText ? new Date() : null,
        updatedAt: new Date(),
      },
    });
  }

  async getChapter(userId: string, chapterNumber: number) {
    return await prisma.lifeTaskChapter.findUnique({
      where: {
        userId_chapterNumber: {
          userId,
          chapterNumber,
        },
      },
    });
  }

  async getAllChapters(userId: string) {
    return await prisma.lifeTaskChapter.findMany({
      where: { userId },
      orderBy: { chapterNumber: 'asc' },
    });
  }

  async getCompletedChapters(userId: string) {
    return await prisma.lifeTaskChapter.findMany({
      where: {
        userId,
        completedAt: { not: null },
      },
      orderBy: { chapterNumber: 'asc' },
    });
  }

  async deleteChapter(userId: string, chapterNumber: number) {
    return await prisma.lifeTaskChapter.delete({
      where: {
        userId_chapterNumber: {
          userId,
          chapterNumber,
        },
      },
    });
  }
}

export const chaptersRepo = new ChaptersRepository();

