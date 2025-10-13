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
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

export class NudgesService {
  private voiceService = new VoiceService();

  /**
   * 🧠 Generate nudges directly from Future You.
   * Uses event and memory context — no other sub-services.
   */
  async generateNudges(userId: string) {
    const openai = getOpenAIClient();
    if (!openai) return { success: false, nudges: [] };

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error("User not found");

    const memory = await memoryService.getUserContext(userId);
    const recent = (memory.recentEvents || []).slice(0, 10);

    const context = `
You are Future You — a wiser, sharper version of the user.
Facts: ${JSON.stringify(memory.facts || {})}
Recent patterns: ${recent.map(e => e.type).join(", ")}
Tone: disciplined, direct, but human.
`;

    const prompt = `
Write 2 short nudges (1–2 sentences each), separated by "---".
• Nudge 1 → Focus on action, movement, discipline.
• Nudge 2 → Warn or correct based on recent drift.
Sound like Future You — concise, no fluff.
`;

    const ai = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      max_tokens: 220,
      temperature: 0.5,
      messages: [
        { role: "system", content: MENTOR.systemPrompt },
        { role: "system", content: context },
        { role: "user", content: prompt },
      ],
    });

    const raw = ai.choices[0]?.message?.content ?? "";
    const parts = raw.split("---").map(p => p.trim()).filter(Boolean);

    const nudges = [];
    for (const text of parts) {
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
        priority: "high",
      };

      await prisma.event.create({
        data: { userId, type: "nudge_generated", payload },
      });

      nudges.push(payload);
    }

    return { success: true, nudges, mentor: "futureyou" };
  }
}

export const nudgesService = new NudgesService();
