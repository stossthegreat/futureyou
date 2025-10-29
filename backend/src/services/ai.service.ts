import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 450);
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 10000);

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY missing — AI disabled");
    return null;
  }
  // Trim whitespace/newlines from API key (Railway env var issue)
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: LLM_TIMEOUT_MS });
}

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach" | "letter";
  temperature?: number;
  maxChars?: number;
};

export class AIService {
  async generateFutureYouReply(userId: string, userMessage: string, opts: GenerateOptions = {}) {
    const openai = getOpenAIClient();
    if (!openai) return "Future You is silent right now — try again later.";

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
    if (opts.maxChars && text.length > opts.maxChars) text = text.slice(0, opts.maxChars - 1) + "…";

    await prisma.event.create({
      data: { userId, type: opts.purpose || "coach", payload: { text } },
    });

    return text;
  }

  async generateMorningBrief(userId: string) {
    const prompt = "Write a short, powerful morning brief. 2–3 clear actions and one imperative closing line.";
    return this.generateFutureYouReply(userId, prompt, { purpose: "brief", temperature: 0.4, maxChars: 400 });
  }

  async generateEveningDebrief(userId: string) {
    await memoryService.summarizeDay(userId);
    const prompt = "Write a concise evening reflection. Mention progress, lessons, and one focus for tomorrow.";
    return this.generateFutureYouReply(userId, prompt, { purpose: "debrief", temperature: 0.3, maxChars: 400 });
  }

  async generateNudge(userId: string, reason: string) {
    const prompt = `Generate a one-sentence motivational nudge because: ${reason}`;
    return this.generateFutureYouReply(userId, prompt, { purpose: "nudge", temperature: 0.5, maxChars: 200 });
  }

  /** Legacy alias so old modules still compile */
  async generateMentorReply(userId: string, _mentorId: string, userMessage: string, opts: GenerateOptions = {}) {
    return this.generateFutureYouReply(userId, userMessage, opts);
  }

  private buildGuidelines(purpose: string, profile: any) {
    const base = [
      `You are Future You — wise, calm, but uncompromising.`,
      `Match tone=${profile.tone}, intensity=${profile.intensity}.`,
      `Be concise, human, actionable.`,
    ];
    const byPurpose: Record<string, string[]> = {
      brief: ["Morning brief: 2-3 short orders, end with drive."],
      debrief: ["Evening debrief: 3 lines, reflection + next step."],
      nudge: ["Nudge: 1 sentence, directive, motivational."],
      coach: ["Coach: call out avoidance, give one clear move."],
      letter: ["Letter: reflective, clarifying, self-honest."],
    };
    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }
}

export const aiService = new AIService();
