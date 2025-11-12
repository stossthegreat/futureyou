// Coach Message Service - Creates proper CoachMessage database entries
import { prisma } from "../utils/db";
import { CoachMessageKind } from "@prisma/client";

export class CoachMessageService {
  /**
   * Create a CoachMessage entry in the database
   */
  async createMessage(
    userId: string,
    kind: CoachMessageKind,
    body: string,
    meta?: any
  ): Promise<{ id: string }> {
    const message = await prisma.coachMessage.create({
      data: {
        userId,
        kind,
        title: this.getTitleForKind(kind),
        body,
        meta: meta || {},
        createdAt: new Date(),
      },
    });

    console.log(`✅ Created ${kind} message for user ${userId}: ${message.id}`);
    return { id: message.id };
  }

  /**
   * Get all messages for a user
   */
  async getMessages(userId: string, limit: number = 30) {
    return await prisma.coachMessage.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: limit,
    });
  }

  /**
   * Mark message as read
   */
  async markAsRead(messageId: string) {
    return await prisma.coachMessage.update({
      where: { id: messageId },
      data: { readAt: new Date() },
    });
  }

  /**
   * Get today's brief (if exists)
   */
  async getTodaysBrief(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return await prisma.coachMessage.findFirst({
      where: {
        userId,
        kind: "brief",
        createdAt: { gte: today },
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Get latest debrief
   */
  async getLatestDebrief(userId: string) {
    return await prisma.coachMessage.findFirst({
      where: {
        userId,
        kind: "mirror", // debrief is stored as "mirror" kind
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Get active nudges (created today, unread)
   */
  async getActiveNudges(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return await prisma.coachMessage.findMany({
      where: {
        userId,
        kind: "nudge",
        createdAt: { gte: today },
        readAt: null,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Get unread letters
   */
  async getUnreadLetters(userId: string) {
    return await prisma.coachMessage.findMany({
      where: {
        userId,
        kind: "letter",
        readAt: null,
      },
      orderBy: { createdAt: "desc" },
      take: 5,
    });
  }

  /**
   * Helper: Get title for message kind
   */
  private getTitleForKind(kind: CoachMessageKind): string {
    switch (kind) {
      case "brief":
        return "Morning Brief";
      case "nudge":
        return "Nudge";
      case "mirror":
        return "Evening Debrief";
      case "letter":
        return "Letter from Future You";
      default:
        return "Message";
    }
  }
}

export const coachMessageService = new CoachMessageService();

