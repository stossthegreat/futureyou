import { prisma } from "../../utils/db";
import { schedulerQueue } from "../../jobs/scheduler";

export const coachService = {
  async sync(userId: string, habits: any[], completions: any[]) {
    await prisma.habitSnapshot.create({ data: { userId, data: habits } });

    for (const c of completions ?? []) {
      await prisma.completion.upsert({
        where: { userId_habitId_date: { userId, habitId: c.habitId, date: new Date(c.date) } },
        update: { done: c.done, completedAt: c.completedAt ? new Date(c.completedAt) : null },
        create: { userId, habitId: c.habitId, date: new Date(c.date), done: c.done },
      });
    }

    await schedulerQueue.add("coach-analyze", { userId }, { removeOnComplete: true });
  },

  async getMessages(userId: string) {
    return prisma.coachMessage.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 30,
    });
  },
};
