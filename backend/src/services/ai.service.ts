// src/services/ai.service.ts
import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 450);
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 10000);

/** Lazy client creation */
function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️  OPENAI_API_KEY missing — AI features disabled");
    return null;
  }
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY, timeout: LLM_TIMEOUT_MS });
}

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach";
  temperature?: number;
  maxChars?: number;
};

export class AIService {
  /** 🧠 General Future-You generation pipeline */
  async generateFutureYouReply(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    if (!openai) return "Future You is silent for now.";

    // --- quota check ---
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error("User not found");
    const today = new Date().toISOString().split("T")[0];
    const quotaKey = `quota:ai:${userId}:${today}`;
    const used = parseInt((await redis.get(quotaKey)) || "0", 10);
    const cap = Number(process.env.LLM_DAILY_MSG_CAP_PRO || 150);
    if (used >= cap) throw new Error("AI daily quota exceeded");
    await redis.incr(quotaKey);
    await redis.expire(quotaKey, 60 * 60 * 24);

    // --- context ---
    const [profile, ctx] = await Promise.all([
      memoryService.getProfileForMentor(userId),
      memoryService.getUserContext(userId),
    ]);

    const guidelines = this.buildGuidelines(opts.purpose || "coach", profile);

    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: "system", content: MENTOR.systemPrompt },
      { role: "system", content: guidelines },
      {
        role: "system",
        content: `CONTEXT:\n${JSON.stringify({
          profile,
          habits: ctx.habitSummaries,
          recent: ctx.recentEvents.slice(0, 30),
        })}`,
      },
      { role: "user", content: userMessage },
    ];

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: opts.temperature ?? 0.4,
      max_tokens: LLM_MAX_TOKENS,
      messages,
    });

    let text = completion.choices[0]?.message?.content?.trim() || "Keep going.";
    if (opts.maxChars && text.length > opts.maxChars) {
      text = text.slice(0, opts.maxChars - 1) + "…";
    }

    await prisma.event.create({
      data: {
        userId,
        type: "coach",
        payload: { purpose: opts.purpose || "coach", text },
      },
    });

    return text;
  }

  /** 🌅 Morning brief */
  async generateMorningBrief(userId: string) {
    const prompt =
      "Write a short, powerful morning brief from Future You. Give 2-3 clear actions and one motivating closing line.";
    return this.generateFutureYouReply(userId, prompt, {
      purpose: "brief",
      temperature: 0.4,
      maxChars: 400,
    });
  }

  /** 🌇 Evening reflection */
  async generateEveningDebrief(userId: string) {
    await memoryService.summarizeDay(userId);
    const prompt =
      "Write a concise evening reflection from Future You. Mention progress, lessons, and one focus for tomorrow.";
    return this.generateFutureYouReply(userId, prompt, {
      purpose: "debrief",
      temperature: 0.3,
      maxChars: 400,
    });
  }

  /** ⚡ Quick motivational nudge */
  async generateNudge(userId: string, reason: string) {
    const prompt = `Generate a one-sentence motivational nudge from Future You because: ${reason}`;
    return this.generateFutureYouReply(userId, prompt, {
      purpose: "nudge",
      temperature: 0.5,
      maxChars: 200,
    });
  }

  /** 📏 Internal style rules */
  private buildGuidelines(purpose: string, profile: any) {
    const base = [
      `You are Future You — wise, calm, but uncompromising.`,
      `Match user tone=${profile.tone}, intensity=${profile.intensity}.`,
      `Be brief, human, and actionable.`,
    ];

    const byPurpose: Record<string, string[]> = {
      brief: ["Morning brief: 2-3 short orders, end with drive."],
      debrief: ["Evening debrief: 3 lines, reflection + next step."],
      nudge: ["Nudge: 1 sentence, directive, motivational."],
      coach: ["Coach: call out avoidance, give one clear next move."],
    };

    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }
}

export const aiService = new AIService();
