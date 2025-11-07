// src/services/brief.service.ts
import { prisma } from "../utils/db";
import OpenAI from "openai";
import { VoiceService } from "./voice.service";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") {
    return null;
  }
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ Missing OpenAI API key — AI features disabled");
    return null;
  }
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey });
}

const voiceService = new VoiceService();

export class BriefService {
  /**
   * ☀️ Generate or retrieve today's morning brief
   */
  async getTodaysBrief(userId: string) {
    const openai = getOpenAIClient();
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const mentor = user?.mentorId ?? "marcus";

    // fallback path if OpenAI is not available
    if (!openai) {
      return {
        mentor,
        message: "Begin your mission today.",
        audio: null,
        habits: [],
        tasks: [],
      };
    }

    const context = `
User: ${userId}
Mentor: ${mentor}
Tone: ${user?.tone ?? "balanced"}
Goal: Write a short, motivating morning brief.
`;

    const ai = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "gpt-5-mini",
      max_tokens: 180,
      messages: [
        { role: "system", content: context },
        { role: "user", content: "Compose a concise, empowering morning briefing." },
      ],
    });

    const text = ai.choices?.[0]?.message?.content ?? "Begin your mission today.";
    const voice = await voiceService.speak(userId, text, mentor);
    const audio = voice?.url ?? null;

    // log event
    await prisma.event.create({
      data: {
        userId,
        type: "morning_brief",
        payload: { text, audio },
      },
    });

    return { mentor, message: text, audio };
  }

  /**
   * 🌙 Generate evening reflection / debrief
   */
  async getEveningDebrief(userId: string) {
    const openai = getOpenAIClient();
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const mentor = user?.mentorId ?? "drill";

    if (!openai) {
      return {
        mentor,
        message: "Reflect and prepare for tomorrow.",
        audio: null,
      };
    }

    const prompt = `
You are ${mentor}. Write an honest but encouraging evening debrief for the user.
Acknowledge effort, mention consistency, and inspire readiness for tomorrow.
`;

    const ai = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "gpt-5-mini",
      max_tokens: 180,
      messages: [{ role: "user", content: prompt }],
    });

    const text = ai.choices?.[0]?.message?.content ?? "Reflect and prepare for tomorrow.";
    const voice = await voiceService.speak(userId, text, mentor);
    const audio = voice?.url ?? null;

    await prisma.event.create({
      data: {
        userId,
        type: "evening_debrief",
        payload: { text, audio },
      },
    });

    return { mentor, message: text, audio };
  }
}

export const briefService = new BriefService();
