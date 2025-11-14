import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { memoryIntelligence, UserConsciousness } from "./memory-intelligence.service";
import { shortTermMemory } from "./short-term-memory.service";
import { aiPromptService } from "./ai-os-prompts.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5-mini";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 900); // allow heavier replies by default
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 10000);

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY missing — AI disabled");
    return null;
  }
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: LLM_TIMEOUT_MS });
}

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach" | "letter";
  maxChars?: number;
};

export class AIService {
  // ────────────────────────────────────────────────────────────
  // PUBLIC: main chat entry
  // ────────────────────────────────────────────────────────────
  // PUBLIC: main chat entry (NEW ENGINE)
async generateFutureYouReply(
  userId: string,
  userMessage: string,
  opts: GenerateOptions = {}
) {
  try {
    const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
    const prompt = aiPromptService.buildReflectionChatPrompt(consciousness, userMessage);

    return this.generateWithConsciousnessPrompt(userId, prompt, {
      purpose: opts.purpose || "coach",
      maxChars: opts.maxChars,
    });
  } catch (err) {
    console.log("⚠️ Consciousness chat failed — using legacy:", err);
    return this.generateLegacy(userId, userMessage, opts);
  }
}

  // ────────────────────────────────────────────────────────────
  // INTERNAL: consciousness-based prompt processor
  // Used by: briefs, debriefs, nudges, letters
  // ────────────────────────────────────────────────────────────
  private async generateWithConsciousnessPrompt(
    userId: string,
    promptTemplate: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    const purpose = opts.purpose || "coach";

    let text: string;
    let name = "Friend";

    try {
      if (!openai) throw new Error("No OpenAI client");

      // Build full consciousness + dialogue meta
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

      const lengthRule =
        purpose === "nudge"
          ? "- Keep it to 1–2 sharp, surgical sentences that can fit in a notification, no fluff.\n"
          : purpose === "brief"
          ? "- Write 2–3 tight paragraphs, each with weight. No list formatting. Every line must feel like an order from their future self.\n"
          : purpose === "debrief"
          ? "- Write 4–6 paragraphs following this reflection loop: (1) Call-Out, (2) Truth, (3) Mirror, (4) Pivot, (5) Directive, (6) Question. Each step should be a distinct paragraph.\n"
          : purpose === "letter"
          ? "- Write 5–8 paragraphs, cinematic and reflective, like a letter from their future self who has already lived the life they want.\n"
          : "- Write 2–4 paragraphs, direct and reflective, always ending with a deep question.";

      const reflectionLoopRule =
        purpose === "debrief" || purpose === "letter" || purpose === "coach"
          ? `
REFLECTION LOOP (when applicable):
1. The Call-Out – Expose the real pattern active today (avoidance, drift, or discipline).
2. The Truth – Name the deeper motive, fear, or identity conflict.
3. The Mirror – Contrast who they say they want to be with how they acted.
4. The Pivot – Reframe this moment as symbolic and identity-defining.
5. The Directive – ONE clear, non-negotiable action or pattern change.
6. The Question – End with a heavy question that forces self-honesty.
`.trim()
          : "";

      const systemPrompt = `
${MENTOR.systemPrompt}

WHO YOU ARE SPEAKING TO:
- Name: ${name}
- Phase: ${consciousness.phase} (day ${consciousness.os_phase.days_in_phase})
- Purpose: ${consciousness.identity.purpose || "discovering"}
- Core values: ${
        consciousness.identity.coreValues.length
          ? consciousness.identity.coreValues.join(", ")
          : "not yet defined"
      }
- Current emotional state: ${consciousness.currentEmotionalState || "balanced"}
- Next evolution focus: ${consciousness.nextEvolution || "building consistency"}

MEMORY CONTEXT:
${memoryContext || "No strong patterns yet — treat this as early observation."}

HOW TO SPEAK (PHASE VOICE):
${voiceGuidelines || "Be wise, calm, and direct."}

${reflectionLoopRule ? reflectionLoopRule + "\n" : ""}

CRITICAL RULES:
- Always address them by their name ("${name}") at least once in your reply.
- Use their name naturally, ideally in the first sentence or first question.
${lengthRule}- Never sound generic, fluffy, or like a motivational quote page.
- You are Future You: calm, heavy, uncompromising, but not cruel.
- Expose patterns with psychological precision; tie everything back to identity.
- Always end with a powerful question that invites a reply.
`.trim();

      const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: "system", content: systemPrompt },
        { role: "user", content: promptTemplate || "Generate a brief morning message." },
      ];

      const maxTokens =
        opts.maxChars != null
          ? Math.max(50, Math.ceil(opts.maxChars / 3)) // keep a floor so it can still speak
          : LLM_MAX_TOKENS;

      const completion = await openai.chat.completions.create({
  model: process.env.CONSCIOUSNESS_MODEL || "gpt-5-turbo",
  max_completion_tokens: opts.maxChars
    ? Math.ceil(opts.maxChars / 3)
    : LLM_MAX_TOKENS,
  messages,
});

      const raw = completion.choices[0]?.message?.content?.trim();
      if (!raw) throw new Error("Empty completion");
      text = raw;
    } catch (err) {
      console.log("⚠️ generateWithConsciousnessPrompt fallback:", err);
      text = this.buildFallbackText(purpose, name);
    }

    if (opts.maxChars && text.length > opts.maxChars) {
      text = text.slice(0, opts.maxChars - 1) + "…";
    }

    await prisma.event.create({
      data: { userId, type: purpose || "coach", payload: { text } },
    });

    return text;
  }

  // ────────────────────────────────────────────────────────────
  // INTERNAL: consciousness-based chat (not wired to main yet)
  // ────────────────────────────────────────────────────────────
  private async generateWithConsciousness(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    const purpose = opts.purpose || "coach";

    let text: string;
    let name = "Friend";

    try {
      if (!openai) throw new Error("No OpenAI client");

      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const shortTerm = await shortTermMemory.getRecentConversation(userId, 10);
      const dialogueMeta = await shortTermMemory.getDialogueMeta(userId);

      consciousness.recentConversation = shortTerm;
      consciousness.currentEmotionalState = dialogueMeta.currentEmotionalState;
      consciousness.contradictions = dialogueMeta.recentContradictions;

      const voiceGuidelines = this.buildVoiceForPhase(consciousness);
      const useFullContext = purpose === "brief" || purpose === "debrief" || purpose === "letter";

      name = consciousness.identity.name || "Friend";

      const lengthRule =
        purpose === "nudge"
          ? "- Keep it to 1–2 sharp, surgical sentences that can fit in a notification, no fluff.\n"
          : purpose === "brief"
          ? "- Write 2–3 tight paragraphs, each with weight. No lists.\n"
          : purpose === "debrief"
          ? "- Write 4–6 paragraphs following the reflection loop (Call-Out, Truth, Mirror, Pivot, Directive, Question).\n"
          : purpose === "letter"
          ? "- Write 5–8 paragraphs, cinematic and reflective, as a letter from their future self.\n"
          : "- Write 2–4 paragraphs, direct and reflective, always ending with a deep question.";

      const reflectionLoopRule =
        purpose === "debrief" || purpose === "letter" || purpose === "coach"
          ? `
REFLECTION LOOP (when applicable):
1. The Call-Out – Expose the real pattern active right now.
2. The Truth – Name the deeper fear, motive, or identity conflict behind it.
3. The Mirror – Show the gap between who they want to be and how they acted.
4. The Pivot – Reframe this moment as symbolic and identity-defining.
5. The Directive – ONE clear action or pattern change, no more.
6. The Question – End with a heavy question that demands an honest answer.
`.trim()
          : "";

      const systemPrompt = `
${MENTOR.systemPrompt}

WHO YOU'RE SPEAKING TO:
${name}, ${consciousness.phase} phase (day ${consciousness.os_phase.days_in_phase})
${consciousness.identity.purpose ? `Purpose: ${consciousness.identity.purpose}` : ""}
${
  consciousness.identity.coreValues.length > 0
    ? `Values: ${consciousness.identity.coreValues.join(", ")}`
    : ""
}

${
  useFullContext
    ? this.buildMemoryContext(consciousness)
    : this.buildMemoryContextSummary(consciousness)
}

HOW TO SPEAK:
${voiceGuidelines}

${reflectionLoopRule ? reflectionLoopRule + "\n" : ""}

CRITICAL RULES:
- Always address them by name at least once in your reply: "${name}".
- Use their name in a natural way, ideally in the first sentence or question.
${lengthRule}- Never sound generic, fluffy, or like a quote poster.
- Expose contradictions gently but clearly when relevant.
- Always end with a question that keeps the conversation alive.
`.trim();

      const conversationMessages = shortTerm
        .slice(0, useFullContext ? 10 : 3)
        .map((m) => ({
          role: m.role as "user" | "assistant" | "system",
          content: m.text,
        }));

      const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: "system", content: systemPrompt },
        ...conversationMessages,
        { role: "user", content: userMessage },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: LLM_MAX_TOKENS,
        messages,
      });

      const raw = completion.choices[0]?.message?.content?.trim();
      if (!raw) throw new Error("Empty completion");
      text = raw;
    } catch (err) {
      console.log("⚠️ generateWithConsciousness fallback:", err);
      text = this.buildFallbackText(purpose, name);
    }

    if (opts.maxChars && text.length > opts.maxChars) {
      text = text.slice(0, opts.maxChars - 1) + "…";
    }

    await shortTermMemory.appendConversation(userId, "user", userMessage, "neutral");
    await shortTermMemory.appendConversation(userId, "assistant", text, "balanced");

    try {
      const emotionalState = await shortTermMemory.detectEmotionalState(userId);
      const contradictions = await shortTermMemory.detectContradictions(userId);
      await shortTermMemory.updateDialogueMeta(userId, {
        currentEmotionalState: emotionalState,
        recentContradictions: contradictions,
      });
    } catch (err) {
      console.log("⚠️ dialogue meta update failed:", err);
    }

    await prisma.event.create({
      data: { userId, type: purpose || "coach", payload: { text } },
    });

    return text;
  }

  // ────────────────────────────────────────────────────────────
  // LEGACY: original implementation (kept for safety)
  // ────────────────────────────────────────────────────────────
  private async generateLegacy(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ): Promise<string> {
    const openai = getOpenAIClient();
    const purpose = opts.purpose || "coach";

    if (!openai) {
      console.warn("⚠️ generateLegacy: no OpenAI client");
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const text = this.buildFallbackText(purpose, name);
      await prisma.event.create({
        data: { userId, type: purpose, payload: { text } },
      });
      return text;
    }

    const [profile, ctx, identity] = await Promise.all([
      memoryService.getProfileForMentor(userId),
      memoryService.getUserContext(userId),
      memoryService.getIdentityFacts(userId),
    ]);

    const guidelines = this.buildGuidelines(purpose, profile, identity);

    const contextString = identity.discoveryCompleted
      ? `IDENTITY:
Name: ${identity.name || "Friend"}, Age: ${identity.age || "not specified"}
Purpose: ${identity.purpose || "discovering"}
Core Values: ${identity.coreValues?.length ? identity.coreValues.join(", ") : "exploring"}
Vision: ${identity.vision || "building"}
Burning Question: ${identity.burningQuestion || "What do I truly want?"}

CONTEXT:
${JSON.stringify({
        habits: ctx.habitSummaries || [],
        recent: ctx.recentEvents?.slice(0, 30) || [],
      })}`
      : `IDENTITY:
Name: ${identity.name || "Friend"}, Age: ${identity.age || "not specified"}
Burning Question: ${identity.burningQuestion || "not yet answered"}
Note: User hasn't completed purpose discovery yet.

CONTEXT:
${JSON.stringify({
        habits: ctx.habitSummaries || [],
        recent: ctx.recentEvents?.slice(0, 30) || [],
      })}`;

    let text: string;
    try {
      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: LLM_MAX_TOKENS,
        messages: [
          { role: "system", content: MENTOR.systemPrompt },
          { role: "system", content: guidelines },
          { role: "system", content: contextString },
          { role: "user", content: userMessage },
        ],
      });

      const raw = completion.choices[0]?.message?.content?.trim();
      if (!raw) throw new Error("Empty completion");
      text = raw;
    } catch (err) {
      console.log("⚠️ generateLegacy fallback:", err);
      const name = identity.name || "Friend";
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

  // ────────────────────────────────────────────────────────────
  // SPECIALISED PROCESSORS (Master Engine entry points)
  // ────────────────────────────────────────────────────────────

  async generateMorningBrief(userId: string) {
    // Use consciousness system for briefs
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildMorningBriefPrompt(consciousness);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "brief",
        maxChars: 1200, // allow 2–3 strong paragraphs
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy brief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt =
        "Write a powerful morning brief with 2–3 short paragraphs. Call out what matters most today, give 2–3 clear identity-aligned actions, and end with one uncompromising line. Use the user's name in the first sentence.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "brief",
        maxChars: 900,
      }).catch(() => this.buildFallbackText("brief", name));
      return text;
    }
  }

  async generateEveningDebrief(userId: string) {
    await memoryService.summarizeDay(userId);

    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const habitActions = await prisma.event.findMany({
        where: {
          userId,
          type: "habit_action",
          ts: { gte: today },
        },
      });

      const dayData = {
        kept: habitActions.filter(
          (e) => (e.payload as any)?.completed === true
        ).length,
        missed: habitActions.filter(
          (e) => (e.payload as any)?.completed === false
        ).length,
      };

      const promptTemplate = aiPromptService.buildDebriefPrompt(
        consciousness,
        dayData
      );
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "debrief",
        maxChars: 1800, // long-form reflection loop
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy debrief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt =
        "Write a long-form evening reflection with 4–6 paragraphs. Call out the real pattern of today, name the truth behind it, mirror who they want to be versus how they acted, pivot the meaning of today, give ONE clear directive for tomorrow, and end with a deep question. Use the user's name in the first sentence.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "debrief",
        maxChars: 1600,
      }).catch(() => this.buildFallbackText("debrief", name));
      return text;
    }
  }

  async generateNudge(userId: string, reason: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildNudgePrompt(
        consciousness,
        reason
      );
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "nudge",
        maxChars: 400,
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy nudge:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt = `Generate a short but heavy nudge because: ${reason}. Use 1–2 sentences that feel like a call-out from their future self, and use the user's name naturally.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "nudge",
        maxChars: 350,
      }).catch(() => this.buildFallbackText("nudge", name));
      return text;
    }
  }

  // ────────────────────────────────────────────────────────────
  // HABIT EXTRACTION
  // ────────────────────────────────────────────────────────────
  async extractHabitFromConversation(
    userId: string,
    userInput: string,
    aiResponse: string
  ) {
    const openai = getOpenAIClient();
    if (!openai) return null;

    const extractionPrompt = `
CONTEXT:
User said: "${userInput}"
AI replied: "${aiResponse}"

TASK:
Extract ONE concrete habit or task from this conversation.
Return ONLY valid JSON (no markdown):
{
  "title": "Clear action (e.g., 'Morning Meditation')",
  "type": "habit or task",
  "time": "HH:MM format (e.g., '06:30')",
  "emoji": "single emoji",
  "importance": 1-5 (1=low, 5=critical),
  "reasoning": "Why this habit matters (1 sentence)"
}

If no clear habit/task, return: {"none": true}
`;

    try {
      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: 200,
        messages: [
          {
            role: "system",
            content:
              "You extract actionable habits from conversations. Output only JSON.",
          },
          { role: "user", content: extractionPrompt },
        ],
      });

      const raw = completion.choices[0]?.message?.content?.trim() || "{}";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(cleaned);

      if (parsed.none) return null;
      if (!parsed.title || !parsed.time) return null;

      return parsed;
    } catch (err) {
      console.warn("Failed to parse habit extraction:", err);
      return null;
    }
  }

  /** Legacy alias so old modules still compile */
  async generateMentorReply(
    userId: string,
    _mentorId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ) {
    return this.generateFutureYouReply(userId, userMessage, opts);
  }

  // ────────────────────────────────────────────────────────────
  // GUIDELINES & VOICE  (used by legacy path)
  // ────────────────────────────────────────────────────────────
  private buildGuidelines(purpose: string, profile: any, identity: any) {
    const base = [
      `You are Future You — wise, calm, uncompromising.`,
      `Speaking to: ${identity.name || "Friend"}${
        identity.age ? `, age ${identity.age}` : ""
      }`,
      `Match tone=${profile.tone || "balanced"}, intensity=${profile.intensity || 2}.`,
      `Always address them by their name ("${identity.name || "Friend"}") in the first sentence of your reply. Use it naturally, not forced.`,
      `Never sound like a generic motivational coach. Speak with psychological precision and emotional gravity.`,
    ];

    if (identity.discoveryCompleted) {
      base.push(`THEIR PURPOSE: ${identity.purpose || "discovering"}`);
      base.push(
        `THEIR VALUES: ${
          identity.coreValues?.length ? identity.coreValues.join(", ") : "exploring"
        }`
      );
      base.push(`THEIR VISION: ${identity.vision || "building"}`);
    } else if (identity.burningQuestion) {
      base.push(`THEIR QUESTION: ${identity.burningQuestion}`);
      base.push(
        `Note: Encourage them to complete Future-You discovery for deeper insights.`
      );
    }

    const reflectionLoop = `
When reflecting on a day or on deeper patterns, use this loop:
1) Call-Out – Expose the real pattern.
2) Truth – Name the deeper fear or motive.
3) Mirror – Who they want to be vs how they acted.
4) Pivot – Reframe this moment as symbolic.
5) Directive – ONE clear, non-negotiable move.
6) Question – End with a deep question.
`.trim();

    const byPurpose: Record<string, string[]> = {
      brief: identity.discoveryCompleted
        ? [
            `Morning brief for ${identity.name || "Friend"}:`,
            `- Write 2–3 short paragraphs, not bullet points.`,
            `- Reference their PURPOSE (${identity.purpose || "discovering"}) and VISION.`,
            `- Give 2–3 clear, identity-aligned orders for today.`,
            `- End with one uncompromising closing line.`,
          ]
        : [
            "Morning brief:",
            "- 2–3 short paragraphs, direct and grounding.",
            "- Gently remind them to complete Future-You discovery.",
            "- Use their name in the first sentence.",
          ],
      debrief: identity.discoveryCompleted
        ? [
            `Evening debrief for ${identity.name || "Friend"}:`,
            `- Use 4–6 paragraphs with the reflection loop structure.`,
            `- Reflect on progress toward their PURPOSE and VALUES (${identity.coreValues?.length ? identity.coreValues.join(", ") : "their values"}).`,
            `- Always end with a deep question that invites them to reply.`,
            reflectionLoop,
          ]
        : [
            "Evening debrief:",
            "- 3–5 paragraphs.",
            "- Reflect briefly on what today revealed about their patterns.",
            "- Encourage discovery completion.",
            "- End with a question.",
            reflectionLoop,
          ],
      nudge: identity.discoveryCompleted
        ? [
            `Nudge:`,
            `- 1–2 sentences max.`,
            `- Remind ${identity.name || "them"} of their PURPOSE (${
              identity.purpose || "discovering their path"
            }).`,
            `- Make it feel like a sharp interruption from their future self.`,
          ]
        : [
            "Nudge:",
            "- 1–2 sentences.",
            "- Motivational but not generic.",
            "- Still use their name in the sentence.",
          ],
      coach: [
        "Coach:",
        "- 2–4 paragraphs.",
        "- Call out avoidance directly but without shaming.",
        "- Tie everything back to identity, not just tasks.",
        "- Often use the reflection loop, and always end with a deep question.",
        reflectionLoop,
      ],
      letter: [
        "Letter:",
        "- 5–8 paragraphs, like a letter from their future self.",
        "- Heavy, reflective, identity-based.",
        "- Speak as if you already lived the life they want and are writing back.",
        "- Always end with a single question that forces honesty.",
        reflectionLoop,
      ],
    };

    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }

  private buildVoiceForPhase(consciousness: UserConsciousness): string {
    const { phase, patterns, reflectionThemes, legacyCode } = consciousness;
    const intensity = memoryIntelligence.determineVoiceIntensity(consciousness);

    if (phase === "observer") {
      return `You are in OBSERVER phase. Be curious and gentle, but not soft or vague.
Curiosity level: ${intensity.curiosity?.toFixed(1)}, Directness: ${intensity.directness?.toFixed(1)}
${
  reflectionThemes.length > 0
    ? `They've been reflecting on: ${reflectionThemes.slice(0, 3).join(", ")}`
    : ""
}
Focus on understanding who they are, what hurts, and what they avoid. Ask real questions, not surface ones.`;
    } else if (phase === "architect") {
      return `You are THE ARCHITECT. Speak with precision and engineering authority.
Authority: ${intensity.authority?.toFixed(1)}, Precision: ${intensity.precision?.toFixed(
        1
      )}, Empathy: ${intensity.empathy?.toFixed(1)}
Structural integrity: ${patterns.consistency_score}%
${
  patterns.drift_windows.length > 0
    ? `Known drag points: ${patterns.drift_windows.map((w) => w.time).join(", ")}`
    : ""
}
${
  patterns.avoidance_triggers.length > 0
    ? `Avoidance patterns: ${patterns.avoidance_triggers.slice(0, 2).join(", ")}`
    : ""
}

SPEAK LIKE THIS:
"The observation phase is over. I see the terrain: ${
        patterns.drift_windows.length > 0
          ? `you drift at ${patterns.drift_windows[0].time}`
          : "your patterns are forming"
      }.
${
  intensity.authority! > 0.7
    ? "Now we build structure. No excuses, only systems."
    : "Today we design your first pillar."
}
${
  intensity.empathy! > 0.4
    ? "I understand the struggle — that's why we engineer around it."
    : "The weakness is clear. We fix it through architecture, not willpower."
}"`;
    } else if (phase === "oracle") {
      return `You are THE ORACLE. Speak with stillness, wisdom, and mystery.
Stillness: ${intensity.stillness?.toFixed(1)}, Wisdom: ${intensity.wisdom?.toFixed(
        1
      )}, Mystery: ${intensity.mystery?.toFixed(1)}
${
  legacyCode.length > 0
    ? `Their own words: "${legacyCode.slice(-2).join('", "')}"`
    : ""
}

SPEAK LIKE THIS:
${
  legacyCode.length > 0
    ? `You once said: "${legacyCode[0]}". Have you kept that promise?`
    : "What would remain if the applause stopped?"
}
The foundations stand. Now we ascend toward meaning. Ask questions that reveal destiny, not tactics.`;
    }

    return "Be wise, calm, direct.";
  }

  private buildMemoryContext(consciousness: UserConsciousness): string {
    const memories: string[] = ["WHAT YOU REMEMBER:"];

    if (consciousness.contradictions.length > 0) {
      memories.push(`- Recent contradiction: ${consciousness.contradictions[0]}`);
    }

    if (consciousness.patterns.drift_windows.length > 0) {
      const drifts = consciousness.patterns.drift_windows
        .slice(0, 2)
        .map((w) => `${w.time} (${w.description})`)
        .join(", ");
      memories.push(`- They struggle most at: ${drifts}`);
    }

    if (consciousness.patterns.return_protocols.length > 0) {
      memories.push(
        `- What works when they recover: "${consciousness.patterns.return_protocols[0].text.slice(
          0,
          60
        )}"`
      );
    }

    if (consciousness.reflectionThemes.length > 0) {
      memories.push(
        `- They often reflect on: ${consciousness.reflectionThemes.slice(0, 3).join(", ")}`
      );
    }

    if (consciousness.patterns.avoidance_triggers.length > 0) {
      memories.push(
        `- Avoids: ${consciousness.patterns.avoidance_triggers.length} specific triggers`
      );
    }

    if (consciousness.reflectionHistory.emotional_arc !== "flat") {
      memories.push(
        `- Emotional trend: ${consciousness.reflectionHistory.emotional_arc}`
      );
    }

    if (consciousness.legacyCode.length > 0) {
      memories.push(
        `- Their legacy code: "${consciousness.legacyCode.slice(-1)[0]}"`
      );
    }

    return memories.join("\n");
  }

  private buildMemoryContextSummary(
    consciousness: UserConsciousness
  ): string {
    const key: string[] = [];

    if (consciousness.patterns.drift_windows.length > 0) {
      key.push(`Drift at: ${consciousness.patterns.drift_windows[0].time}`);
    }

    if (consciousness.patterns.consistency_score > 0) {
      key.push(`Consistency: ${consciousness.patterns.consistency_score}%`);
    }

    if (consciousness.reflectionThemes.length > 0) {
      key.push(`Focus: ${consciousness.reflectionThemes[0]}`);
    }

    return key.length > 0 ? `KEY CONTEXT: ${key.join(" | ")}` : "";
  }

  // ────────────────────────────────────────────────────────────
  // FALLBACK TEXTS (no more "Keep going.")
  // ────────────────────────────────────────────────────────────
  private buildFallbackText(
    purpose: GenerateOptions["purpose"],
    name: string
  ): string {
    const safeName = name || "Friend";

    switch (purpose) {
      case "brief":
        return `Listen, ${safeName}. Today is not about fixing your whole life; it’s about proving to yourself that your word still means something. Pick one promise that actually matters, build the day around keeping it, and refuse to negotiate with your own excuses. Tonight, you either look back proud or you explain to yourself why you folded again — which version are you going to meet?`;
      case "debrief":
        return `${safeName}, today was evidence, not a verdict. The way you moved — or failed to move — revealed where your standards are really set, not where you say they are. Notice what genuinely pulled you forward, notice what quietly drained you, and be honest about the pattern you are rehearsing. Tomorrow is not a fresh start, it’s the next chapter of this same story — what’s the one thing you’re willing to do differently so the story shifts by even one degree?`;
      case "nudge":
        return `${safeName}, you already know the move you’re dodging. The longer you sit in hesitation, the heavier it becomes and the more it teaches your brain that avoiding discomfort is acceptable. Do the one uncomfortable action you’ve been circling around — not later, now — and let your nervous system learn that you choose alignment over delay.`;
      case "letter":
        return `${safeName}, there is a version of you on the other side of discipline who looks back at these exact days with disbelief — not at how hard they were, but at how close you were to walking away from your own potential. That version of you does not romanticise your current level of distraction, negotiation, and half-commitment. They are quieter, clearer, and far more ruthless about what stays in their life. Start borrowing their standards now, before life forces you to. If they could speak to you tonight, what would they beg you to stop pretending you don’t see?`;
      case "coach":
      default:
        return `${safeName}, stop waiting for a perfect surge of motivation. Your future self will never care how inspired you felt — only whether you moved or stalled. Pick the one action that would slightly embarrass your current comfort level, do it in the next ten minutes, and let that be the proof that you’re not repeating the same day again. When you look back on tonight, will it feel like another loop, or the first small breach in it?`;
    }
  }
}

export const aiService = new AIService();
