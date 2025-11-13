// src/services/nudges.service.ts
import { prisma } from "../utils/db";
import { VoiceService } from "./voice.service";
import { aiService } from "./ai.service";

export type NudgeTrigger = {
  type: "drift" | "streak_break" | "high_importance_missed" | "energy_dip" | "time_sensitive";
  reason: string;
  severity: number; // 1-5
  context: any;
};

export class NudgesService {
  private voiceService = new VoiceService();

  /**
   * 🧠 Smarter nudge detection - considers time, importance, patterns
   */
  async shouldNudge(userId: string): Promise<NudgeTrigger | null> {
    const now = new Date();
    const hour = now.getHours();

    // Don't nudge during sleep hours (11pm - 6am)
    if (hour >= 23 || hour < 6) return null;

    const [habits, recentEvents] = await Promise.all([
      prisma.habit.findMany({ where: { userId } }),
      prisma.event.findMany({
        where: { userId, ts: { gte: new Date(now.getTime() - 6 * 60 * 60 * 1000) } },
        orderBy: { ts: "desc" },
        take: 100,
      }),
    ]);

    // 1️⃣ Check for high-importance habit misses
    const highImpHabits = habits.filter((h: any) => {
      const ctx = h.context as any;
      return ctx?.importance >= 4;
    });

    if (highImpHabits.length > 0) {
      const habitsCheckedToday = new Set(
        recentEvents
          .filter((e) => e.type === "habit_action")
          .map((e: any) => e.payload.habitId)
      );

      const uncheckedCritical = highImpHabits.filter((h) => !habitsCheckedToday.has(h.id));
      if (uncheckedCritical.length > 0 && hour >= 12) {
        return {
          type: "high_importance_missed",
          reason: `${uncheckedCritical.length} critical habit(s) not completed: ${uncheckedCritical
            .map((h) => h.title)
            .join(", ")}`,
          severity: 5,
          context: { habits: uncheckedCritical },
        };
      }
    }

    // 2️⃣ Check for streak breaks
    const longStreaks = habits.filter((h) => h.streak >= 7);
    for (const habit of longStreaks) {
      const lastTick = habit.lastTick ? new Date(habit.lastTick) : null;
      if (lastTick) {
        const daysSinceLastTick = Math.floor(
          (now.getTime() - lastTick.getTime()) / (1000 * 60 * 60 * 24)
        );
        if (daysSinceLastTick >= 1) {
          return {
            type: "streak_break",
            reason: `${habit.title} — ${habit.streak} day streak at risk`,
            severity: 4,
            context: { habit },
          };
        }
      }
    }

    // 3️⃣ General drift (no completions in last 6h, multiple misses)
    const actions = recentEvents.filter((e) => e.type === "habit_action");
    const done = actions.filter((a: any) => a.payload?.completed === true).length;
    const notDone = actions.filter((a: any) => a.payload?.completed === false).length;

    if (notDone >= 3 && done === 0 && hour >= 10 && hour <= 20) {
      return {
        type: "drift",
        reason: "Multiple habits missed, no completions in 6 hours",
        severity: 3,
        context: { misses: notDone },
      };
    }

    // 4️⃣ Time-sensitive habits (scheduled for current hour)
    const currentHour = `${hour.toString().padStart(2, "0")}:`;
    const thisHourHabits = habits.filter((h) => {
      const schedule = h.schedule as any;
      return schedule?.time?.startsWith(currentHour);
    });

    if (thisHourHabits.length > 0) {
      const completedThisHour = recentEvents
        .filter(
          (e) =>
            e.type === "habit_action" &&
            (e.payload as any)?.completed === true
        )
        .map((e: any) => e.payload.habitId);

      const pendingNow = thisHourHabits.filter(
        (h) => !completedThisHour.includes(h.id)
      );

      if (pendingNow.length > 0) {
        return {
          type: "time_sensitive",
          reason: `${pendingNow.length} habit(s) scheduled for now: ${pendingNow
            .map((h) => h.title)
            .join(", ")}`,
          severity: 4,
          context: { habits: pendingNow },
        };
      }
    }

    return null;
  }

  /**
   * ⚡ Generate contextual nudge using the OS brain (GPT-5, consciousness, memory)
   */
  async generateNudges(userId: string, trigger?: NudgeTrigger) {
    // 1️⃣ If no trigger provided, decide whether we should nudge
    if (!trigger) {
      trigger = await this.shouldNudge(userId);
      if (!trigger) {
        return { success: false, nudges: [], reason: "No nudge trigger detected" };
      }
    }

    // 2️⃣ Build a rich reason string for the brain
    const reasonForBrain = `[${trigger.type.toUpperCase()} • severity ${trigger.severity}/5] ${trigger.reason}`;

    // 3️⃣ Ask the OS brain (aiService) to generate the text
    let text: string;
    try {
      text = await aiService.generateNudge(userId, reasonForBrain);
    } catch (err) {
      console.error("❌ generateNudges failed, falling back:", err);
      text = "You know exactly what needs doing next. Do the thing you keep postponing.";
    }

    text = (text || "").trim();
    if (!text) {
      return { success: false, nudges: [], reason: "Empty nudge text from AI" };
    }

    // 4️⃣ Optional: voice (Future You voice)
    let audioUrl: string | null = null;
    try {
      const voice = await this.voiceService.speak(userId, text, "futureyou");
      audioUrl = voice.url;
    } catch (err) {
      console.warn("⚠️ Nudge TTS failed:", err);
      audioUrl = null;
    }

    // 5️⃣ Persist event
    const payload = {
      type: "futureyou_nudge",
      message: text,
      audio: audioUrl,
      priority: trigger.severity >= 4 ? "high" : "medium",
      trigger: trigger.type,
    };

    await prisma.event.create({
      data: { userId, type: "nudge", payload },
    });

    return { success: true, nudges: [payload], mentor: "futureyou", trigger };
  }
}

export const nudgesService = new NudgesService();
