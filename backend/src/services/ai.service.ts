import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { memoryIntelligence, UserConsciousness } from "./memory-intelligence.service";
import { shortTermMemory } from "./short-term-memory.service";
import { aiPromptService } from "./ai-os-prompts.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5-mini";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 450);
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 10000);

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY missing — AI disabled");
    return null;
  }
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY.trim(), timeout: LLM_TIMEOUT_MS });
}

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach" | "letter";
  maxChars?: number;
};

export class AIService {

  // =====================================================================
  // PUBLIC: MAIN CHAT ENTRY (NOW USING FULL CONSCIOUSNESS ENGINE)
  // =====================================================================
  async generateFutureYouReply(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ) {
    return this.generateWithConsciousness(userId, userMessage, opts);
  }

  // =====================================================================
  // FULL CONSCIOUSNESS PROMPT PROCESSOR (BRIEFS / DEBRIEFS / NUDGES)
  // =====================================================================
  private async generateWithConsciousnessPrompt(
    userId: string,
    promptTemplate: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    const purpose = opts.purpose || "coach";
    let text = "";
    let name = "Friend";

    try {
      if (!openai) throw new Error("No OpenAI client");

      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const dialogueMeta = await shortTermMemory.getDialogueMeta(userId);

      consciousness.currentEmotionalState = dialogueMeta.currentEmotionalState;
      consciousness.contradictions = dialogueMeta.recentContradictions || [];

      const voiceGuidelines = this.buildVoiceForPhase(consciousness);

      const useFullContext =
        purpose === "brief" || purpose === "debrief" || purpose === "letter";

      const memoryContext = useFullContext
        ? this.buildMemoryContext(consciousness)
        : this.buildMemoryContextSummary(consciousness);

      name = consciousness.identity.name || "Friend";

      const systemPrompt = `
${MENTOR.systemPrompt}

YOU ARE FUTURE YOU. Speak like the upgraded, disciplined, wiser version of them.

WHO YOU ARE SPEAKING TO:
- Name: ${name}
- Phase: ${consciousness.phase} (day ${consciousness.os_phase.days_in_phase})
- Purpose: ${consciousness.identity.purpose || "discovering"}
- Core values: ${consciousness.identity.coreValues.length ? consciousness.identity.coreValues.join(", ") : "not yet defined"}
- Emotional state: ${consciousness.currentEmotionalState}
- Next evolution: ${consciousness.nextEvolution}

MEMORY CONTEXT:
${memoryContext}

VOICE RULES:
${voiceGuidelines}

ABSOLUTE RULES:
- Use their name ("${name}") in the first sentence.
- Be vivid, cinematic, emotional, and direct.
- You are their future self — no clichés, no fluff.
- Call out contradictions softly but honestly.
- Push them toward clarity and self-respect.
      `.trim();

      const messages = [
        { role: "system", content: systemPrompt },
        { role: "user", content: promptTemplate },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: opts.maxChars ? Math.ceil(opts.maxChars / 3) : LLM_MAX_TOKENS,
        messages,
      });

      text = completion.choices[0]?.message?.content?.trim() || "";
      if (!text) throw new Error("Empty completion");
    } catch (err) {
      console.log("⚠️ Consciousness prompt fallback:", err);
      text = this.buildFallbackText(purpose, name);
    }

    if (opts.maxChars && text.length > opts.maxChars) {
      text = text.slice(0, opts.maxChars - 1) + "…";
    }

    await prisma.event.create({
      data: { userId, type: purpose, payload: { text } },
    });

    return text;
  }

  // =====================================================================
  // FULL CONSCIOUSNESS CHAT ENGINE (MAIN CHAT)
  // =====================================================================
  private async generateWithConsciousness(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    const purpose = opts.purpose || "coach";
    let text = "";
    let name = "Friend";

    try {
      if (!openai) throw new Error("No OpenAI client");

      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);

      const shortTerm = await shortTermMemory.getRecentConversation(userId, 10);
      const dialogueMeta = await shortTermMemory.getDialogueMeta(userId);

      consciousness.currentEmotionalState = dialogueMeta.currentEmotionalState;
      consciousness.contradictions = dialogueMeta.recentContradictions;

      const useFull =
        purpose === "brief" || purpose === "debrief" || purpose === "letter";

      const memoryContext = useFull
        ? this.buildMemoryContext(consciousness)
        : this.buildMemoryContextSummary(consciousness);

      const voiceGuidelines = this.buildVoiceForPhase(consciousness);
      name = consciousness.identity.name || "Friend";

      const systemPrompt = `
${MENTOR.systemPrompt}

YOU ARE FUTURE THEM:
- Direct.
- Cinematic.
- Deep.
- No clichés.
- No robotic lines.
- Challenge them with respect.

WHO YOU'RE SPEAKING TO:
Name: ${name}
Phase: ${consciousness.phase}
Purpose: ${consciousness.identity.purpose || "discovering"}
Values: ${consciousness.identity.coreValues.join(", ") || "unknown"}

CONTEXT:
${memoryContext}

VOICE:
${voiceGuidelines}

WHAT THEY NEED NEXT:
${consciousness.nextEvolution}

RULES:
- Use their name in the first sentence.
- Do NOT be short. Do NOT be generic.
- Every reply must feel like a letter from their future self.
      `.trim();

      const history = shortTerm.map(m => ({
        role: m.role,
        content: m.text
      }));

      const messages = [
        { role: "system", content: systemPrompt },
        ...history,
        { role: "user", content: userMessage },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: LLM_MAX_TOKENS,
        messages,
      });

      text = completion.choices[0]?.message?.content?.trim() || "";
      if (!text) throw new Error("Empty completion");
    } catch (err) {
      console.log("⚠️ Consciousness fallback:", err);
      text = this.buildFallbackText(purpose, name);
    }

    if (opts.maxChars && text.length > opts.maxChars) {
      text = text.slice(0, opts.maxChars - 1) + "…";
    }

    await shortTermMemory.appendConversation(userId, "user", userMessage, "neutral");
    await shortTermMemory.appendConversation(userId, "assistant", text, "balanced");

    await prisma.event.create({
      data: { userId, type: purpose, payload: { text } },
    });

    return text;
  }

  // =====================================================================
  // BRIEFS / DEBRIEFS / NUDGES
  // =====================================================================
  async generateMorningBrief(userId: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildMorningBriefPrompt(consciousness);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "brief",
        maxChars: 500,
      });
    } catch (err) {
      console.log("⚠️ Morning brief fallback:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      return `Listen, ${identity.name || "Friend"}. Today is simple: pick one promise and keep it.`;
    }
  }

  async generateEveningDebrief(userId: string) {
    await memoryService.summarizeDay(userId);

    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const actions = await prisma.event.findMany({
        where: { userId, type: "habit_action", ts: { gte: today } },
      });

      const dayData = {
        kept: actions.filter(a => (a.payload as any)?.completed).length,
        missed: actions.filter(a => !(a.payload as any)?.completed).length,
      };

      const promptTemplate = aiPromptService.buildDebriefPrompt(consciousness, dayData);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "debrief",
        maxChars: 500,
      });
    } catch (err) {
      console.log("⚠️ Debrief fallback:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      return `${identity.name || "Friend"}, today was data. Look at it clearly.`;
    }
  }

  async generateNudge(userId: string, reason: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const template = aiPromptService.buildNudgePrompt(consciousness, reason);
      return this.generateWithConsciousnessPrompt(userId, template, {
        purpose: "nudge",
        maxChars: 250,
      });
    } catch (err) {
      console.log("⚠️ Nudge fallback:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      return `${identity.name || "Friend"}, move now. You already know why.`;
    }
  }

  // =====================================================================
  // HABIT EXTRACTION (unchanged)
  // =====================================================================
  async extractHabitFromConversation(userId: string, userInput: string, aiResponse: string) {
    const openai = getOpenAIClient();
    if (!openai) return null;

    const extractionPrompt = `
User said: "${userInput}"
AI replied: "${aiResponse}"

Extract ONE habit in JSON only.
    `;

    try {
      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: 200,
        messages: [
          { role: "system", content: "Return ONLY JSON." },
          { role: "user", content: extractionPrompt },
        ],
      });

      const raw = completion.choices[0].message?.content?.trim() || "{}";
      return JSON.parse(raw.replace(/```json|```/g, "").trim());
    } catch {
      return null;
    }
  }

  // =====================================================================
  // VOICE SYSTEM
  // =====================================================================
  private buildVoiceForPhase(c: UserConsciousness) {
    if (c.phase === "observer") {
      return `Gentle but perceptive. Ask questions. Reflect. Build trust.`;
    }

    if (c.phase === "architect") {
      return `Sharp, structural, engineering their life. No fluff. No excuses. Build systems.`;
    }

    if (c.phase === "oracle") {
      return `Quiet, deep, almost spiritual. Strip illusions. Ask existential questions.`;
    }

    return "Direct, honest, grounded.";
  }

  // =====================================================================
  // MEMORY CONTEXT
  // =====================================================================
  private buildMemoryContext(c: UserConsciousness) {
    const out: string[] = [];

    if (c.contradictions.length) out.push(`Contradiction: ${c.contradictions[0]}`);
    if (c.patterns.drift_windows.length)
      out.push(`Drift windows: ${c.patterns.drift_windows.map(w => w.time).join(", ")}`);
    if (c.reflectionThemes.length)
      out.push(`Themes: ${c.reflectionThemes.slice(0, 3).join(", ")}`);
    if (c.patterns.avoidance_triggers.length)
      out.push(`Avoidance triggers: ${c.patterns.avoidance_triggers.length}`);

    return out.join("\n");
  }

  private buildMemoryContextSummary(c: UserConsciousness) {
    return `Consistency: ${c.patterns.consistency_score}% | Focus: ${c.reflectionThemes[0] || "none"}`;
  }

  // =====================================================================
  // FALLBACK RESPONSES
  // =====================================================================
  private buildFallbackText(purpose: string, name: string) {
    switch (purpose) {
      case "brief":
        return `Listen, ${name}. One promise. One day. Keep it clean.`;
      case "debrief":
        return `${name}, today was a lesson. Tomorrow is a test.`;
      case "nudge":
        return `${name}, stop thinking. Make the move.`;
      case "letter":
        return `${name}, your future self is waiting for you to act like them.`;
      default:
        return `${name}, take one strong step. Right now.`;
    }
  }
}

export const aiService = new AIService();
