import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { Prisma } from "@prisma/client";
import OpenAI from "openai";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5-mini";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 2000); // Increased for complete reflection generation
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 30000); // Increased for reflection generation

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OpenAI API key not available, AI features will be disabled");
    return null;
  }
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: LLM_TIMEOUT_MS });
}

type FactsPatch = Record<string, any>;
type EventPayload = Record<string, any>;

export class MemoryService {
  async appendEvent(userId: string, type: string, payload: EventPayload) {
    return prisma.event.create({ data: { userId, type, payload } });
  }

  async upsertFacts(userId: string, patch: FactsPatch) {
    const existing = await prisma.userFacts.findUnique({ where: { userId } });
    if (!existing) {
      return prisma.userFacts.create({ data: { userId, json: patch as Prisma.InputJsonValue } });
    }
    const merged = this.deepMerge(existing.json as Record<string, any>, patch);
    return prisma.userFacts.update({
      where: { userId },
      data: { json: merged as Prisma.InputJsonValue },
    });
  }

  async getUserContext(userId: string) {
    const facts = await prisma.userFacts.findUnique({ where: { userId } });
    const recentEvents = await prisma.event.findMany({
      where: { userId },
      orderBy: { ts: "desc" },
      take: 100,
    });

    const since = new Date();
    since.setDate(since.getDate() - 30);

    const recentTicks = await prisma.event.findMany({
      where: { userId, type: "habit_tick", ts: { gte: since } },
      orderBy: { ts: "desc" },
      take: 1000,
    });

    const perHabit: Record<string, { ticks: number; lastDate: string | null }> = {};
    for (const ev of recentTicks) {
      const hid = (ev.payload as any)?.habitId;
      if (!hid) continue;
      perHabit[hid] = perHabit[hid] || { ticks: 0, lastDate: null };
      perHabit[hid].ticks += 1;
      perHabit[hid].lastDate = (ev.payload as any)?.date || perHabit[hid].lastDate;
    }

    const habits = await prisma.habit.findMany({ where: { userId } });
    const habitSummaries = habits.map((h) => ({
      id: h.id,
      title: h.title,
      streak: h.streak,
      lastTick: h.lastTick,
      ticks30d: perHabit[h.id]?.ticks || 0,
    }));

    return {
      facts: (facts?.json as Record<string, any>) || {},
      recentEvents,
      habitSummaries,
    };
  }

  async summarizeDay(userId: string) {
    const openai = getOpenAIClient();
    if (!openai) return { patch: {}, reflection: "" };

    const cacheKey = `mem:summary:${userId}:${new Date().toISOString().slice(0, 10)}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const context = await this.getUserContext(userId);

    const system = `
You are the memory engine for Future You OS.
Input: user facts, events, and habits.
Output JSON with:
  - "factsPatch": updates to persistent memory
  - "reflection": 1–2 sentence summary of the day.
Keep JSON valid and concise.
    `;

    const user = {
      facts: context.facts,
      habitSummaries: context.habitSummaries,
      recentEvents: context.recentEvents.slice(0, 60),
    };

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      max_completion_tokens: LLM_MAX_TOKENS,
      messages: [
        { role: "system", content: system },
        { role: "user", content: JSON.stringify(user) },
      ],
      response_format: { type: "json_object" as any },
    });

    const rawResponse = completion.choices[0]?.message?.content || "{}";
    console.log("🔍 [REFLECTION DEBUG] Raw AI response length:", rawResponse.length);
    console.log("🔍 [REFLECTION DEBUG] Raw AI response preview:", rawResponse.slice(0, 200) + "...");

    let parsed: any = {};
    try {
      parsed = JSON.parse(rawResponse);
    } catch (err) {
      console.log("❌ [REFLECTION DEBUG] JSON parse failed:", err);
      parsed = {};
    }

    const patch = parsed.factsPatch || {};
    if (Object.keys(patch).length) {
      await this.upsertFacts(userId, patch);
      await this.appendEvent(userId, "memory_updated", { patch });
    }
    if (parsed.reflection) {
      console.log("🔍 [REFLECTION DEBUG] Reflection text length:", parsed.reflection.length);
      console.log("🔍 [REFLECTION DEBUG] Reflection text:", parsed.reflection);
      await this.appendEvent(userId, "day_reflection", { text: parsed.reflection });
      console.log("✅ [REFLECTION DEBUG] Reflection saved to database successfully");
    } else {
      console.log("❌ [REFLECTION DEBUG] No reflection text in parsed response");
    }

    const out = { patch, reflection: parsed.reflection || "" };
    await redis.set(cacheKey, JSON.stringify(out), "EX", 60 * 60 * 6);
    return out;
  }

  /**
   * 🔐 Unified identity facts:
   * - Name: prefers identity.name / facts.name / (user as any).name / email prefix
   * - Purpose & values: merges UserFacts.identity with FutureYouPurposeProfile
   */
  async getIdentityFacts(userId: string) {
    const [factsRow, user, purposeProfile] = await Promise.all([
      prisma.userFacts.findUnique({ where: { userId } }),
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.futureYouPurposeProfile.findUnique({ where: { userId } }).catch(() => null),
    ]);

    const facts = (factsRow?.json as Record<string, any>) || {};
    const identityFacts = (facts.identity as Record<string, any>) || {};

    // NAME: try identity.name → facts.name → user.name (if ever added) → email prefix → "Friend"
    const emailName = user?.email ? user.email.split("@")[0] : null;
    
    // DEBUG: Log what we're actually finding
    console.log(`🔍 [Name Debug] userId: ${userId.substring(0, 8)}`);
    console.log(`🔍 [Name Debug] identityFacts.name: "${identityFacts.name}"`);
    console.log(`🔍 [Name Debug] identityFacts.displayName: "${identityFacts.displayName}"`);
    console.log(`🔍 [Name Debug] facts.name: "${facts.name}"`);
    console.log(`🔍 [Name Debug] emailName: "${emailName}"`);
    console.log(`🔍 [Name Debug] Full identityFacts:`, JSON.stringify(identityFacts));
    
    const name =
      identityFacts.displayName ||
      identityFacts.name ||
      facts.name ||
      (user as any)?.name || // safe even if column doesn't exist yet
      emailName ||
      "Friend";
    
    console.log(`🔍 [Name Debug] Final resolved name: "${name}"`);

    // AGE
    const age = facts.age || identityFacts.age || null;

    // PURPOSE: prefer explicit identity purpose, then LifeTask
    const purpose =
      identityFacts.purpose ||
      purposeProfile?.lifeTask ||
      null;

    // CORE VALUES: prefer identity.coreValues, then ranked values from purpose profile
    const coreValues: string[] =
      (Array.isArray(identityFacts.coreValues) && identityFacts.coreValues.length > 0
        ? identityFacts.coreValues
        : Array.isArray(purposeProfile?.valuesRank)
        ? purposeProfile!.valuesRank
        : []) || [];

    // VISION: keep from identity if present
    const vision = identityFacts.vision || null;

    // Discovery completion: either explicit flag OR having a lifeTask
    const discoveryCompleted =
      !!identityFacts.discoveryCompletedAt ||
      !!purposeProfile?.lifeTask ||
      false;

    return {
      // Basic profile
      name,
      age,
      burningQuestion: facts.burningQuestion || identityFacts.burningQuestion || null,

      // Discovery insights
      discoveryCompleted,
      purpose,
      coreValues,
      vision,
      funeralWish: identityFacts.funeralWish || facts.funeralWish || null,
      biggestFear: identityFacts.biggestFear || facts.biggestFear || null,
      whyNow: identityFacts.whyNow || facts.whyNow || null,
    };
  }

  async getProfileForMentor(userId: string) {
    const identity = await this.getIdentityFacts(userId);
    const factsRow = await prisma.userFacts.findUnique({ where: { userId } });
    const facts = (factsRow?.json as Record<string, any>) || {};
    const user = await prisma.user.findUnique({ where: { id: userId } });

    return {
      ...identity, // spread identity facts
      tz: user?.tz || "UTC",
      tone: user?.tone || "balanced",
      intensity: user?.intensity || 2,
      plan: user?.plan || "FREE",
      bestTimes: facts.bestTimes || null,
      weakDays: facts.weakDays || null,
      triggers: facts.triggers || null,
      preferredRituals: facts.preferredRituals || null,
    };
  }

  private deepMerge(a: Record<string, any>, b: Record<string, any>) {
    const out = { ...a };
    for (const k of Object.keys(b)) {
      const av = a[k];
      const bv = b[k];
      if (av && typeof av === "object" && !Array.isArray(av) && typeof bv === "object" && !Array.isArray(bv)) {
        out[k] = this.deepMerge(av, bv);
      } else {
        out[k] = bv;
      }
    }
    return out;
  }
}

export const memoryService = new MemoryService();
