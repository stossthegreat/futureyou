import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { VoiceService } from "./voice.service";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OpenAI API key not available — nudges disabled");
    return null;
  }
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey });
}

type NudgeTrigger = {
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
      const todayString = now.toISOString().split("T")[0];
      const habitsCheckedToday = new Set(
        recentEvents.filter((e) => e.type === "habit_action").map((e: any) => e.payload.habitId)
      );
      
      const uncheckedCritical = highImpHabits.filter((h) => !habitsCheckedToday.has(h.id));
      if (uncheckedCritical.length > 0 && hour >= 12) {
        return {
          type: "high_importance_missed",
          reason: `${uncheckedCritical.length} critical habit(s) not completed: ${uncheckedCritical.map((h) => h.title).join(", ")}`,
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
        const daysSinceLastTick = Math.floor((now.getTime() - lastTick.getTime()) / (1000 * 60 * 60 * 24));
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

    // 3️⃣ Check for general drift (no completions in last 6h, multiple misses)
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

    // 4️⃣ Check for time-sensitive habits (scheduled for current hour)
    const currentHour = `${hour.toString().padStart(2, "0")}:`;
    const thisHourHabits = habits.filter((h) => {
      const schedule = h.schedule as any;
      return schedule?.time?.startsWith(currentHour);
    });
    if (thisHourHabits.length > 0) {
      const completedThisHour = recentEvents
        .filter((e) => e.type === "habit_action" && (e.payload as any)?.completed === true)
        .map((e: any) => e.payload.habitId);
      
      const pendingNow = thisHourHabits.filter((h) => !completedThisHour.includes(h.id));
      if (pendingNow.length > 0) {
        return {
          type: "time_sensitive",
          reason: `${pendingNow.length} habit(s) scheduled for now: ${pendingNow.map((h) => h.title).join(", ")}`,
          severity: 4,
          context: { habits: pendingNow },
        };
      }
    }

    return null;
  }

  /**
   * 🧠 Generate contextual nudge based on trigger
   */
  async generateNudges(userId: string, trigger?: NudgeTrigger) {
    const openai = getOpenAIClient();
    if (!openai) return { success: false, nudges: [] };

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error("User not found");

    // If no trigger provided, check if we should nudge
    if (!trigger) {
      trigger = await this.shouldNudge(userId);
      if (!trigger) {
        return { success: false, nudges: [], reason: "No nudge trigger detected" };
      }
    }

    const memory = await memoryService.getUserContext(userId);
    const recent = (memory.recentEvents || []).slice(0, 10);

    const context = `
You are Future You — wise, direct, motivating.
Facts: ${JSON.stringify(memory.facts || {})}
Recent patterns: ${recent.map((e) => e.type).join(", ")}
Tone: ${user.tone || "balanced"}

TRIGGER: ${trigger.type}
REASON: ${trigger.reason}
SEVERITY: ${trigger.severity}/5
`;

    const prompt = `
Write 1 powerful nudge (2-3 sentences max).
Address the specific trigger: ${trigger.type}.
Be direct, actionable, and motivating. No fluff.
`;

    const ai = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      max_tokens: 150,
      temperature: 0.6,
      messages: [
        { role: "system", content: MENTOR.systemPrompt },
        { role: "system", content: context },
        { role: "user", content: prompt },
      ],
    });

    const text = ai.choices[0]?.message?.content?.trim() ?? "";
    if (!text) return { success: false, nudges: [] };

    let audioUrl: string | null = null;
    try {
      const voice = await this.voiceService.speak(userId, text, "futureyou");
      audioUrl = voice.url;
    } catch {
      audioUrl = null;
    }

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
