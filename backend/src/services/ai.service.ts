// backend/src/services/ai.service.ts

import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { memoryIntelligence, UserConsciousness } from "./memory-intelligence.service";
import { semanticMemory } from "./semanticMemory.service";
import { shortTermMemory } from "./short-term-memory.service";
import { aiPromptService } from "./ai-os-prompts.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 2000); // Much higher for GPT-4o complete responses
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 30000); // Increased for reflection generation

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
  // PUBLIC: main chat entry (kept on legacy for safety)
  // ────────────────────────────────────────────────────────────
  async generateFutureYouReply(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ) {
    return this.generateLegacy(userId, userMessage, opts);
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

      // ✅ IMPROVED: Better name extraction logic
      const rawName = consciousness.identity?.name;
      
      // Check if name exists and is NOT email-based
      if (rawName && typeof rawName === 'string') {
        const isEmailBased = rawName.startsWith("user_") || rawName.includes("@");
        name = isEmailBased ? "Friend" : rawName.trim();
      } else {
        name = "Friend";
      }
      
      console.log(`🎯 AI using name: "${name}" (raw: "${rawName}", userId: ${userId.substring(0, 8)}...)`);

      const styleRules = this.buildStyleRulesForPurpose(purpose, name);

      const systemPrompt = `
${MENTOR.systemPrompt}

${voiceGuidelines}

${memoryContext}

${styleRules}
`;

      const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content:
            (promptTemplate || "Generate a brief morning message.") +
            "\n\nRemember: obey STYLE & OUTPUT RULES exactly.",
        },
      ];

      // First attempt
      let completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: opts.maxChars
          ? Math.ceil(opts.maxChars / 3) // Tokens are roughly 3-4 chars, so /3 gives more room
          : LLM_MAX_TOKENS,
        messages,
      });

      let raw = completion.choices[0]?.message?.content?.trim();

      // Retry with simplified prompt if empty
      if (!raw) {
        console.warn(`⚠️ Empty completion for purpose: ${purpose} — retrying with simplified prompt`);
        const simpleMessages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
          {
            role: "system",
            content: this.buildSimplifiedSystemPrompt(purpose, name),
          },
          {
            role: "user",
            content: this.buildSimplifiedUserPrompt(purpose, name),
          },
        ];

        completion = await openai.chat.completions.create({
          model: OPENAI_MODEL,
          max_completion_tokens: opts.maxChars
            ? Math.ceil(opts.maxChars / 2) // Better ratio for GPT-4o (was /3)
            : LLM_MAX_TOKENS,
          messages: simpleMessages,
        });

        raw = completion.choices[0]?.message?.content?.trim();
        if (!raw) {
          throw new Error("Empty completion after retry");
        }
      }

      text = raw;
    } catch (err) {
      console.log("⚠️ generateWithConsciousnessPrompt fallback:", err);
      text = this.buildFallbackText(purpose, name);
    }

    // Post-process to enforce brevity & punch
    text = this.postProcessOutput(text, purpose, name, opts.maxChars);

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
      const useFullContext =
        purpose === "brief" || purpose === "debrief" || purpose === "letter";

      const rawName = consciousness.identity?.name;
      name =
        rawName && !String(rawName).startsWith("user_")
          ? rawName
          : "Friend";

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

CRITICAL RULES:
- Always address them by name at least once in your reply: "${name}".
- Use their name in a natural way, ideally in the first sentence or question.
- Do NOT use poetic, vague, or flowery language. No metaphors about tapestries, fabric, cosmic dances, etc.
- Speak like a battle-tested coach: concrete, direct, behavioural.
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

    text = this.postProcessOutput(text, purpose, name, opts.maxChars);

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
  // LEGACY: original implementation (kept for safety & main chat)
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
      const name =
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend";
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

    const safeIdentity = {
      ...identity,
      name:
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend",
    };

    const guidelines = this.buildGuidelines(purpose, profile, safeIdentity);

    const contextString = safeIdentity.discoveryCompleted
      ? `IDENTITY:
Name: ${safeIdentity.name || "Friend"}, Age: ${safeIdentity.age || "not specified"}
Purpose: ${safeIdentity.purpose || "discovering"}
Core Values: ${safeIdentity.coreValues?.length ? safeIdentity.coreValues.join(", ") : "exploring"}
Vision: ${safeIdentity.vision || "building"}
Burning Question: ${safeIdentity.burningQuestion || "What do I truly want?"}

CONTEXT:
${JSON.stringify({
  habits: ctx.habitSummaries || [],
  recent: ctx.recentEvents?.slice(0, 30) || [],
})}`
      : `IDENTITY:
Name: ${safeIdentity.name || "Friend"}, Age: ${safeIdentity.age || "not specified"}
Burning Question: ${safeIdentity.burningQuestion || "not yet answered"}
Note: User hasn't completed purpose discovery yet.

CONTEXT:
${JSON.stringify({
  habits: ctx.habitSummaries || [],
  recent: ctx.recentEvents?.slice(0, 30) || [],
})}`;

    let text: string;
    try {
      const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: "system", content: MENTOR.systemPrompt },
        {
          role: "system",
          content:
            guidelines +
            "\n\nSTYLE OVERRIDE: No poetic or flowery language. Be direct, behavioural, and cinematic but grounded.",
        },
        { role: "system", content: contextString },
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
      console.log("⚠️ generateLegacy fallback:", err);
      const safeName =
        safeIdentity.name && !String(safeIdentity.name).startsWith("user_")
          ? safeIdentity.name
          : "Friend";
      text = this.buildFallbackText(purpose, safeName);
    }

    text = this.postProcessOutput(
      text,
      purpose,
      safeIdentity.name || "Friend",
      opts.maxChars
    );

    await prisma.event.create({
      data: { userId, type: purpose, payload: { text } },
    });

    return text;
  }

  // ────────────────────────────────────────────────────────────
  // SPECIALISED PROCESSORS (Master Engine entry points)
  // ────────────────────────────────────────────────────────────

  async generateMorningBrief(userId: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);

      // Query relevant semantic memories
      const recentMemories = await semanticMemory.queryMemories({
        userId,
        query: "recent meaningful events, patterns, time wasting, wins, slips",
        limit: 5,
        minScore: 0.3,
      });

      // Enhance consciousness with semantic context
      const enhancedConsciousness = {
        ...consciousness,
        recentSemanticMemories: recentMemories.map((m) => ({
          text: m.text.substring(0, 150),
          importance: m.metadata?.importance || 3,
        })),
      };

      const promptTemplate = aiPromptService.buildMorningBriefPrompt(enhancedConsciousness);
      const text = await this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "brief",
        maxChars: 1200,
      });

      // Store in semantic memory
      await semanticMemory.storeMemory({
        userId,
        type: "brief",
        text,
        metadata: {
          phase: consciousness.phase,
          consistency_score: consciousness.patterns.consistency_score,
          drift_windows: consciousness.patterns.drift_windows.map((w) => w.time),
        },
        importance: 4,
      });

      return text;
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy brief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName =
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend";
      const prompt =
        `Write a powerful morning brief for ${safeName}.` +
        ` 2–3 short, concrete orders and one closing question that hits identity.` +
        ` No poetry. No metaphors. Speak like their future self who takes no bullshit.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "brief",
        maxChars: 1000,
      }).catch(() => this.buildFallbackText("brief", safeName));
      return text;
    }
  }

  async generateEveningDebrief(userId: string) {
    console.log("🔍 [REFLECTION DEBUG] Starting evening debrief for user:", userId);
    const summaryResult = await memoryService.summarizeDay(userId);
    console.log("🔍 [REFLECTION DEBUG] summarizeDay result:", { 
      reflectionLength: summaryResult.reflection?.length || 0,
      hasReflection: !!summaryResult.reflection
    });

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

      // Query relevant semantic memories for today's reflection
      const recentMemories = await semanticMemory.queryMemories({
        userId,
        query: "today's events, misses, wins, avoidance patterns, time wasting",
        limit: 5,
        minScore: 0.3,
      });

      // Enhance consciousness with semantic context
      const enhancedConsciousness = {
        ...consciousness,
        recentSemanticMemories: recentMemories.map((m) => ({
          text: m.text.substring(0, 150),
          importance: m.metadata?.importance || 3,
        })),
      };

      const promptTemplate = aiPromptService.buildDebriefPrompt(
        enhancedConsciousness,
        dayData
      );
      const text = await this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "debrief",
        maxChars: 1200,
      });

      // Store in semantic memory
      await semanticMemory.storeMemory({
        userId,
        type: "debrief",
        text,
        metadata: {
          phase: consciousness.phase,
          patterns: dayData,
          emotional_arc: consciousness.reflectionHistory.emotional_arc,
        },
        importance: 4,
      });

      return text;
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy debrief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName =
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend";
      const prompt =
        `Write a concise but hard-hitting evening debrief for ${safeName}.` +
        ` Reflect on progress, call out avoidance directly, and end with one brutal but honest question.` +
        ` No poetry. No metaphors.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "debrief",
        maxChars: 1000,
      }).catch(() => this.buildFallbackText("debrief", safeName));
      return text;
    }
  }

  async generateNudge(userId: string, reason: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);

      // Query relevant semantic memories about drifts and nudges
      const recentMemories = await semanticMemory.queryMemories({
        userId,
        query: `${reason} recent drifts misses repeated patterns`,
        limit: 3,
        minScore: 0.3,
      });

      // Enhance consciousness with semantic context
      const enhancedConsciousness = {
        ...consciousness,
        recentSemanticMemories: recentMemories.map((m) => ({
          text: m.text.substring(0, 100),
          importance: m.metadata?.importance || 3,
        })),
      };

      const promptTemplate = aiPromptService.buildNudgePrompt(
        enhancedConsciousness,
        reason
      );
      const text = await this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "nudge",
        maxChars: 260,
      });

      // Store in semantic memory
      await semanticMemory.storeMemory({
        userId,
        type: "nudge",
        text,
        metadata: {
          trigger: reason,
          phase: consciousness.phase,
        },
        importance: 3,
      });

      return text;
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy nudge:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName =
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend";
      const prompt = `Generate ONE short, viciously clear nudge for ${safeName} because: ${reason}. 
- One sentence only.
- No metaphors, no fluff.
- Call out the avoidance and tell them exactly what to do now.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "nudge",
        maxChars: 220,
      }).catch(() => this.buildFallbackText("nudge", safeName));
      return text;
    }
  }

  async generateWeeklyLetter(userId: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildWeeklyLetterPrompt(consciousness);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "letter",
        maxChars: 2000, // Weekly letters should be longer and more reflective
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy weekly letter:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName =
        identity.name && !String(identity.name).startsWith("user_")
          ? identity.name
          : "Friend";
      const prompt = `Write a reflective weekly letter from Future You to ${safeName}. 
- Reflect on the past week's patterns, growth, and drift.
- Be honest but encouraging.
- Connect their actions to their deeper purpose.
- End with a question that invites deeper reflection.
- 3-4 paragraphs, philosophical but grounded.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "letter",
        maxChars: 1500,
      }).catch(() => this.buildFallbackText("letter", safeName));
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
  // GUIDELINES & VOICE
  // ────────────────────────────────────────────────────────────
  private buildGuidelines(purpose: string, profile: any, identity: any) {
    const displayName =
      identity.name && !String(identity.name).startsWith("user_")
        ? identity.name
        : "Friend";

    const base = [
      `You are Future You — wise, calm, uncompromising.`,
      `Speaking to: ${displayName}${
        identity.age ? `, age ${identity.age}` : ""
      }`,
      `Match tone=${profile.tone || "balanced"}, intensity=${profile.intensity || 2}.`,
      `Always address them by their name ("${displayName}") in the first sentence of your reply. Use it naturally, not forced.`,
      `Never use poetic or vague metaphors. Speak in concrete, behavioural language.`,
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

    const byPurpose: Record<string, string[]> = {
      brief: identity.discoveryCompleted
        ? [
            `Morning brief for ${displayName}: Reference their PURPOSE (${identity.purpose || "discovering"}) and give 2–3 orders aligned with their VISION.`,
            `End with ONE powerful question that forces identity-level reflection.`,
            `No poetry. No fluff. Short, cinematic, and direct.`,
          ]
        : [
            `Morning brief: 2–3 short orders.`,
            `Gently remind to complete Future-You discovery.`,
            `End with ONE powerful question.`,
          ],
      debrief: identity.discoveryCompleted
        ? [
            `Evening debrief for ${displayName}: Reflect on progress toward their PURPOSE.`,
            `Call out any avoidance or drift.`,
            `End with ONE honest question that makes them confront the pattern.`,
          ]
        : [
            `Evening debrief: Reflect briefly.`,
            `Encourage discovery completion.`,
            `End with ONE question.`,
          ],
      nudge: identity.discoveryCompleted
        ? [
            `Nudge: ONE sentence.`,
            `Remind ${displayName} of their PURPOSE (${identity.purpose || "discovering their path"}).`,
            `Call out avoidance directly and tell them exactly what action to take now.`,
          ]
        : [
            `Nudge: ONE sentence.`,
            `Motivational but specific. Still use their name.`,
          ],
      coach: [
        `Coach: Call out avoidance, give one clear move.`,
        `No metaphors, no fluff. Speak like a hard but caring coach.`,
      ],
      letter: [
        `Letter: Reflective, clarifying, self-honest.`,
        `Open with their name in a direct, grounded way (e.g., 'Listen, [Name].').`,
      ],
    };

    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }

  private buildVoiceForPhase(consciousness: UserConsciousness): string {
    const { phase, patterns, reflectionThemes, legacyCode } = consciousness;
    const intensity = memoryIntelligence.determineVoiceIntensity(consciousness);

    if (phase === "observer") {
      return `You are in OBSERVER phase. Be curious and gentle, but not vague.
Curiosity level: ${intensity.curiosity?.toFixed(
        1
      )}, Directness: ${intensity.directness?.toFixed(1)}
${
  reflectionThemes.length > 0
    ? `They've been reflecting on: ${reflectionThemes.slice(0, 3).join(", ")}`
    : ""
}
${
  intensity.directness! > 0.3
    ? "You can start offering gentle but concrete guidance."
    : "Focus on understanding, not advising yet, but stay specific."
}`;
    } else if (phase === "architect") {
      return `You are THE ARCHITECT. Speak with precision and engineering authority.
Authority: ${intensity.authority?.toFixed(
        1
      )}, Precision: ${intensity.precision?.toFixed(
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
      return `You are THE ORACLE. Still, grounded, surgical.
Stillness: ${intensity.stillness?.toFixed(
        1
      )}, Wisdom: ${intensity.wisdom?.toFixed(
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
Ask questions that reveal destiny, not tactics.
Do not use mystical metaphors — be clear and unforgivingly honest.`;
    }

    return "Be wise, calm, direct, and concrete.";
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
        `- They often reflect on: ${consciousness.reflectionThemes
          .slice(0, 3)
          .join(", ")}`
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
  // STYLE HELPERS (no more "tapestry of life" nonsense)
  // ────────────────────────────────────────────────────────────
  private buildStyleRulesForPurpose(
    purpose: GenerateOptions["purpose"],
    name: string
  ): string {
    const base = [
      `- Never use poetic, mystical, or overly flowery language.`,
      `- No metaphors about tapestries, fabric of life, cosmic dances, etc.`,
      `- Speak like a ruthless but caring future self.`,
      `- Concrete, behavioural, identity-focused.`,
      `- Always use "${name}" naturally at least once.`,
    ];

    if (purpose === "brief") {
      base.push(
        `- 2–3 short, hard-hitting paragraphs max.`,
        `- You may use a short bullet list (max 3 bullets).`,
        `- Always end with ONE clear question that hits their identity and choices today.`
      );
    } else if (purpose === "debrief") {
      base.push(
        `- Call out today's pattern directly (avoidance, drift, or progress).`,
        `- 2–3 paragraphs max.`,
        `- One small, concrete directive for tomorrow.`,
        `- Always end with ONE question that makes them confront their trajectory.`
      );
    } else if (purpose === "nudge") {
      base.push(
        `- ONE sentence only.`,
        `- Must contain a direct instruction (e.g. "Do X now").`,
        `- No line breaks, no list, no intro.`
      );
    } else if (purpose === "letter") {
      base.push(
        `- Slightly longer is okay, but still concrete and grounded.`,
        `- Open with "Listen, ${name}." or similar direct address.`
      );
    } else if (purpose === "coach") {
      base.push(
        `- Short, sharp, and directive.`,
        `- Call out avoidance and give exactly one next move.`
      );
    }

    return base.join("\n");
  }

  private buildSimplifiedSystemPrompt(
    purpose: GenerateOptions["purpose"],
    name: string
  ): string {
    const base = [
      `You are Future ${name}'s best self.`,
      `Your job is to speak directly, concretely, and without poetry.`,
      `No metaphors. No fluff. Behavioural, not philosophical.`,
    ];

    if (purpose === "brief") {
      base.push(
        `Write a short morning brief:`,
        `- Call out today's main pattern or risk.`,
        `- Give 2–3 clear actions.`,
        `- End with ONE powerful question.`
      );
    } else if (purpose === "debrief") {
      base.push(
        `Write a short evening debrief:`,
        `- Reflect on today as data.`,
        `- Call out avoidance.`,
        `- End with ONE question.`
      );
    } else if (purpose === "nudge") {
      base.push(
        `Write a sharp, direct nudge (2-3 sentences):`,
        `- Call out the specific avoidance pattern.`,
        `- Tell them exactly what to do RIGHT NOW.`,
        `- End with ONE pointed question.`,
        `- Must be 2-3 sentences total (NOT just one sentence).`
      );
    } else {
      base.push(`Give one clear, direct coaching response.`);
    }

    return base.join("\n");
  }

  private buildSimplifiedUserPrompt(
    purpose: GenerateOptions["purpose"],
    name: string
  ): string {
    if (purpose === "brief") {
      return `Write a direct, non-poetic morning brief for ${name}.`;
    }
    if (purpose === "debrief") {
      return `Write a direct, non-poetic evening debrief for ${name}.`;
    }
    if (purpose === "nudge") {
      return `Write one clear nudge sentence for ${name} that tells them what to do now.`;
    }
    return `Give ${name} one clear, non-poetic coaching response.`;
  }

  private postProcessOutput(
    raw: string,
    purpose: GenerateOptions["purpose"],
    name: string,
    maxChars?: number
  ): string {
    let text = raw.trim();

    // Remove any accidental user_ ids if the model echoed them
    text = text.replace(/user_[0-9]+/g, name || "Friend");

    if (purpose === "nudge") {
      // Take first sentence only
      const idx = text.search(/[.!?]/);
      if (idx !== -1) {
        text = text.slice(0, idx + 1);
      }
      // Ensure single line
      text = text.replace(/\s+/g, " ").trim();
      if (maxChars && text.length > maxChars) {
        text = text.slice(0, maxChars - 1) + "…";
      }
      return text;
    }

    // For briefs/debriefs/letters/coach: trim length but keep structure
    if (maxChars && text.length > maxChars) {
      text = text.slice(0, maxChars - 1) + "…";
    }

    return text;
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
        return `Listen, ${safeName}. Today is simple: pick one promise that actually matters, keep it, and don't bargain with yourself. Build the day around that and you’ll sleep proud.`;
      case "debrief":
        return `${safeName}, today was data, not judgment. Notice what moved you forward, notice what dragged you back, and choose one thing you'll do differently tomorrow.`;
      case "nudge":
        return `${safeName}, you already know the move you’re avoiding. Do that one thing now before your brain talks you out of it.`;
      case "letter":
        return `${safeName}, there is a version of you on the other side of discipline who does not recognise this current level of hesitation. Start behaving like them now, before you feel ready.`;
      case "coach":
      default:
        return `${safeName}, stop waiting for a perfect plan. Take one clear action in the next 10 minutes that your future self would respect.`;
    }
  }
}

export const aiService = new AIService();
