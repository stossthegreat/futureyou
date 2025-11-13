// src/services/brief.service.ts
import { prisma } from "../utils/db";
import { VoiceService } from "./voice.service";
import { aiService } from "./ai.service";

const voiceService = new VoiceService();

export class BriefService {
  /**
   * ☀️ Generate or retrieve today's morning brief
   * Uses the OS brain (aiService → GPT-5-mini + consciousness)
   */
  async getTodaysBrief(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    // mentor used for TTS voice flavour (text is always Future-You brain)
    const mentor = (user as any)?.mentorId || "marcus";

    // 1️⃣ Get the brief text from the OS brain
    let text: string;
    try {
      text = await aiService.generateMorningBrief(userId);
    } catch (err) {
      console.error("⚠️ generateMorningBrief failed, fallback:", err);
      text = "Today is not random. Pick the one thing that actually matters and move on it.";
    }

    text = (text || "").trim();
    if (!text) {
      text = "Begin your mission today.";
    }

    // 2️⃣ Optional TTS
    let audio: string | null = null;
    try {
      const voice = await voiceService.speak(userId, text, mentor);
      audio = voice?.url ?? null;
    } catch (err) {
      console.warn("⚠️ Morning brief TTS failed:", err);
      audio = null;
    }

    // 3️⃣ We do NOT re-log the event here because aiService
    // already logs a 'brief' event. This method is mainly for API consumers.
    return {
      mentor,
      message: text,
      audio,
      habits: [], // kept for backwards compatibility with existing clients
      tasks: [],
    };
  }

  /**
   * 🌙 Generate evening reflection / debrief
   * Uses the OS brain (aiService → GPT-5-mini + consciousness)
   */
  async getEveningDebrief(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const mentor = (user as any)?.mentorId || "drill";

    // 1️⃣ Get debrief text from OS brain
    let text: string;
    try {
      text = await aiService.generateEveningDebrief(userId);
    } catch (err) {
      console.error("⚠️ generateEveningDebrief failed, fallback:", err);
      text =
        "Today told you exactly where you are strong and where you keep slipping. Note it, forgive yourself, and sharpen one thing for tomorrow.";
    }

    text = (text || "").trim();
    if (!text) {
      text = "Reflect on today and set one clear move for tomorrow.";
    }

    // 2️⃣ Optional TTS
    let audio: string | null = null;
    try {
      const voice = await voiceService.speak(userId, text, mentor);
      audio = voice?.url ?? null;
    } catch (err) {
      console.warn("⚠️ Evening debrief TTS failed:", err);
      audio = null;
    }

    // Again, aiService already logs a 'debrief' style event internally
    return {
      mentor,
      message: text,
      audio,
    };
  }
}

export const briefService = new BriefService();
