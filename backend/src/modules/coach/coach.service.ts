// src/modules/coach/coach.service.ts
import { prisma } from "../../utils/db";
import { aiService } from "../../services/ai.service";
import { notificationsService } from "../../services/notifications.service";

export class CoachService {
  /**
   * 🔁 Sync habit + completion data from the frontend (observer-mode)
   * Logs completions to events table. The scheduler & nudge engine later interpret these.
   */
  async sync(userId: string, habits: any[], completions: { habitId: string; date: string; done: boolean }[]) {
    if (!userId) throw new Error("Missing userId");

    if (Array.isArray(completions) && completions.length > 0) {
      const writes = completions.map((c) =>
        prisma.event.create({
          data: {
            userId,
            type: "habit_action",
            payload: {
              habitId: c.habitId,
              date: c.date,
              completed: c.done,
            },
          },
        })
      );
      await Promise.allSettled(writes);
    }

    return { ok: true, logged: completions?.length ?? 0 };
  }

  /**
   * 🧠 Retrieve the most recent OS brain messages.
   * This is what powers the “Daily Briefs”, “Letters”, and “Nudges” tabs on the Home screen.
   */
  async getMessages(userId: string) {
    if (!userId) throw new Error("Missing userId");

    const events = await prisma.event.findMany({
      where: {
        userId,
        type: { in: ["morning_brief", "evening_debrief", "nudge", "letter", "mirror"] },
      },
      orderBy: { ts: "desc" },
      take: 30,
    });

    return events.map((e) => ({
      id: e.id,
      userId,
      kind: this.mapEventTypeToKind(e.type),
      title: this.titleForKind(e.type),
      body: e.payload?.text ?? "",
      meta: e.payload,
      createdAt: e.ts,
      readAt: null,
    }));
  }

  /**
   * 🪞 Reflective “Letter from Future You”
   * Generates a one-off AI reflection using current user state.
   */
  async generateLetter(userId: string, topic: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error("User not found");

    const mentor = (user as any)?.mentorId || "marcus";
    const prompt = `Write a reflective, concise letter from Future You about "${topic}". Encourage growth and self-alignment.`;

    const text = await aiService.generateMentorReply(userId, mentor, prompt, {
      purpose: "letter",
      maxChars: 800,
    });

    const event = await prisma.event.create({
      data: {
        userId,
        type: "letter",
        payload: { text, topic },
      },
    });

    await notificationsService.send(userId, "Letter from Future You", this.truncate(text, 180));
    return { ok: true, message: text, id: event.id };
  }

  /**
   * 🩺 Analyze patterns (optional for analytics or dashboard)
   */
  async analyzePatterns(userId: string) {
    const recent = await prisma.event.findMany({
      where: { userId },
      orderBy: { ts: "desc" },
      take: 200,
    });

    const keeps = recent.filter((e) => e.type === "habit_action" && (e.payload as any)?.completed === true).length;
    const misses = recent.filter((e) => e.type === "habit_action" && (e.payload as any)?.completed === false).length;

    const ratio = keeps + misses > 0 ? keeps / (keeps + misses) : 0;

    return {
      fulfillmentRate: ratio,
      keeps,
      misses,
      total: keeps + misses,
      lastActivity: recent[0]?.ts ?? null,
    };
  }

  // Helpers
  private mapEventTypeToKind(type: string): string {
    switch (type) {
      case "morning_brief": return "brief";
      case "evening_debrief": return "brief";
      case "nudge": return "nudge";
      case "letter": return "letter";
      case "mirror": return "mirror";
      default: return "nudge";
    }
  }

  private titleForKind(type: string): string {
    switch (type) {
      case "morning_brief": return "Morning Brief";
      case "evening_debrief": return "Evening Debrief";
      case "nudge": return "Nudge";
      case "letter": return "Letter from Future You";
      case "mirror": return "Mirror Reflection";
      default: return "Message";
    }
  }

  private truncate(s: string, n: number) {
    return s.length > n ? s.slice(0, n - 1) + "…" : s;
  }
}

// Singleton export
export const coachService = new CoachService();
