import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { memoryIntelligence, UserConsciousness } from "./memory-intelligence.service";
import { shortTermMemory } from "./short-term-memory.service";
import { aiPromptService } from "./ai-os-prompts.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o";
const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 450);
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS || 10000);

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach" | "letter";
  maxChars?: number;
};

type ChatMessage = OpenAI.Chat.Completions.ChatCompletionMessageParam;

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build")
    return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY missing — AI disabled");
    return null;
  }
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: LLM_TIMEOUT_MS });
}

export class AIService {
  // ────────────────────────────────────────────────────────────
  // PUBLIC: main chat entry (kept on legacy path for safety)
  // ────────────────────────────────────────────────────────────
  async generateFutureYouReply(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ) {
    // Main freeform chat still uses legacy engine (safer)
    return this.generateLegacy(userId, userMessage, opts);
  }

  // ────────────────────────────────────────────────────────────
  // INTERNAL: Mode-B style rules (modern identity engineer)
  // ────────────────────────────────────────────────────────────
  private buildModeBStyleRules(
    purpose: GenerateOptions["purpose"],
    consciousness: UserConsciousness,
    name: string
  ): string {
    const p = purpose || "coach";

    const base = [
      `You are Future You OS — a modern, surgical identity engineer.`,
      `You speak as ${name}'s evolved, disciplined future self.`,
      ``,
      `ABSOLUTE STYLE RULES:`,
      `- Do NOT speak like a poet.`,
      `- No vague metaphors: no "tapestry", "fabric of your life", "cosmic", "dance", "drift through the void", etc.`,
      `- Plain, concrete, grounded language.`,
      `- Strong but simple sentences.`,
      `- 1–3 tight paragraphs. No walls of text.`,
      `- No emojis, no hashtags, no hype.`,
      `- Every line must either: call out truth, clarify pattern, or prescribe action.`,
      ``,
      `PHASE CONTEXT:`,
      `- Phase: ${consciousness.phase} (day ${consciousness.os_phase.days_in_phase})`,
      `- Emotional state: ${consciousness.currentEmotionalState || "balanced"}`,
      `- Next evolution focus: ${consciousness.nextEvolution || "building consistency"}`,
      ``,
    ];

    if (p === "brief") {
      base.push(
        `FOR MORNING BRIEF:`,
        `- 2–3 clear, non-negotiable moves for today.`,
        `- Open with their name in the first sentence.`,
        `- Tie at least one action directly to their long-term identity.`,
        `- End with one sharp question that forces a choice for today.`
      );
    } else if (p === "debrief") {
      base.push(
        `FOR EVENING DEBRIEF:`,
        `- Reflect on today as DATA, not judgment.`,
        `- Name 1–2 honest patterns you see.`,
        `- Name 1 lesson and 1 concrete adjustment for tomorrow.`,
        `- End with one question that makes them confront the pattern.`
      );
    } else if (p === "nudge") {
      base.push(
        `FOR NUDGE:`,
        `- Maximum 2 short paragraphs.`,
        `- Call out the exact avoidance or hesitation.`,
        `- Push them toward ONE specific action they can do in the next hour.`,
        `- Use their name once, naturally.`
      );
    } else if (p === "letter") {
      base.push(
        `FOR LETTER:`,
        `- Longer, reflective, but still concrete.`,
        `- Call out identity drift vs identity alignment.`,
        `- Give them 1–2 identity rules to keep.`,
        `- End with one question that hits their future self.`
      );
    } else if (p === "coach") {
      base.push(
        `FOR COACHING REPLY:`,
        `- Call out avoidance quickly.`,
        `- Give one clear next move and why it matters.`,
        `- Do not over-explain. Clarity over complexity.`,
        `- End with a question that forces commitment.`
      );
    }

    return base.join("\n");
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

      const styleRules = this.buildModeBStyleRules(purpose, consciousness, name);

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

STYLE + BEHAVIOUR (MODE B — MODERN IDENTITY ENGINEER):
${styleRules}

CRITICAL RULES:
- Always address them by their name ("${name}") at least once in your reply.
- Use their name naturally, ideally in the first sentence or first question.
- No poetry, no vague metaphors, no mystical language.
- Stay short, vivid, and tactical — every line must either call out truth or point to action.
`.trim();

      const messages: ChatMessage[] = [
        { role: "system", content: systemPrompt },
        { role: "user", content: promptTemplate || "Generate a powerful, direct message." },
      ];

      // First attempt
      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: opts.maxChars
          ? Math.ceil(opts.maxChars / 3)
          : LLM_MAX_TOKENS,
        messages,
      });

      let raw = completion.choices[0]?.message?.content?.trim() || "";

      // Retry once if empty
      if (!raw) {
        console.warn(`⚠️ Empty completion for purpose: ${purpose} — retrying with simplified prompt`);
        const fallbackSystem = `
You are Future You OS — a direct, modern performance coach future-self.
No poetry. No metaphors. Speak in clear, concrete language.
Output 1–3 tight paragraphs, maximum.
`.trim();

        const fallbackMessages: ChatMessage[] = [
          { role: "system", content: fallbackSystem },
          {
            role: "user",
            content: `Write a ${purpose} message for ${name}. Be direct, honest, and give one clear next move.`,
          },
        ];

        const retry = await openai.chat.completions.create({
          model: OPENAI_MODEL,
          max_completion_tokens: opts.maxChars
            ? Math.ceil(opts.maxChars / 3)
            : LLM_MAX_TOKENS,
          messages: fallbackMessages,
        });

        raw = retry.choices[0]?.message?.content?.trim() || "";

        if (!raw) {
          throw new Error("Empty completion after retry");
        }
      }

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
      const useFullContext =
        purpose === "brief" || purpose === "debrief" || purpose === "letter";

      name = consciousness.identity.name || "Friend";

      const styleRules = this.buildModeBStyleRules(purpose, consciousness, name);

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

HOW TO SPEAK (PHASE VOICE):
${voiceGuidelines}

STYLE + BEHAVIOUR (MODE B — MODERN IDENTITY ENGINEER):
${styleRules}

CRITICAL RULES:
- Always address them by name at least once in your reply: "${name}".
- Use their name in a natural way, ideally in the first sentence or question.
- No poetic language. Stay grounded, concrete, and tactical.
`.trim();

      const conversationMessages: ChatMessage[] = shortTerm
        .slice(0, useFullContext ? 10 : 3)
        .map((m) => ({
          role: m.role as "user" | "assistant" | "system",
          content: m.text,
        }));

      const messages: ChatMessage[] = [
        { role: "system", content: systemPrompt },
        ...conversationMessages,
        { role: "user", content: userMessage },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: LLM_MAX_TOKENS,
        messages,
      });

      let raw = completion.choices[0]?.message?.content?.trim() || "";

      if (!raw) {
        console.warn(`⚠️ Empty completion in generateWithConsciousness — using fallback text`);
        raw = this.buildFallbackText(purpose, name);
      }

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
      const messages: ChatMessage[] = [
        { role: "system", content: MENTOR.systemPrompt },
        { role: "system", content: guidelines },
        { role: "system", content: contextString },
        { role: "user", content: userMessage },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: LLM_MAX_TOKENS,
        messages,
      });

      let raw = completion.choices[0]?.message?.content?.trim() || "";

      if (!raw) {
        console.warn("⚠️ Empty completion in generateLegacy — using fallback text");
        raw = this.buildFallbackText(purpose, identity.name || "Friend");
      }

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
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildMorningBriefPrompt(consciousness);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "brief",
        maxChars: 1500, // allow complete responses without truncation
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy brief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt =
        "Write a short, direct morning brief. 2–3 clear actions and one closing question that forces a choice for today. Use the user's name in the first sentence.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "brief",
        maxChars: 400,
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
        kept: habitActions.filter((e) => (e.payload as any)?.completed === true).length,
        missed: habitActions.filter((e) => (e.payload as any)?.completed === false).length,
      };

      const promptTemplate = aiPromptService.buildDebriefPrompt(consciousness, dayData);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "debrief",
        maxChars: 1500, // allow complete responses without truncation
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy debrief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt =
        "Write a concise evening reflection. Mention progress, patterns, one lesson, and one focus for tomorrow. End with a question that makes them confront their pattern. Use the user's name in the first sentence.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "debrief",
        maxChars: 400,
      }).catch(() => this.buildFallbackText("debrief", name));
      return text;
    }
  }

  async generateNudge(userId: string, reason: string) {
    try {
      const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
      const promptTemplate = aiPromptService.buildNudgePrompt(consciousness, reason);
      return this.generateWithConsciousnessPrompt(userId, promptTemplate, {
        purpose: "nudge",
        maxChars: 800, // allow complete nudges without truncation
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy nudge:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const name = identity.name || "Friend";
      const prompt = `Generate a one-sentence motivational nudge because: ${reason}. Use the user's name naturally in the sentence. Be concrete and direct.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "nudge",
        maxChars: 200,
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
            content: "You extract actionable habits from conversations. Output only JSON.",
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
  // GUIDELINES & VOICE (legacy path only)
  // ────────────────────────────────────────────────────────────
  private buildGuidelines(purpose: string, profile: any, identity: any) {
    const base = [
      `You are Future You — wise, calm, uncompromising.`,
      `Speaking to: ${identity.name || "Friend"}${
        identity.age ? `, age ${identity.age}` : ""
      }`,
      `Match tone=${profile.tone || "balanced"}, intensity=${profile.intensity || 2}.`,
      `Always address them by their name ("${identity.name || "Friend"}") in the first sentence of your reply. Use it naturally, not forced.`,
      `Avoid poetic language. Be concrete and tactical.`,
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
            `Morning brief for ${identity.name || "Friend"}: Reference their PURPOSE (${
              identity.purpose || "discovering"
            }) and give 2-3 orders aligned with their VISION. Use their name in the first sentence.`,
          ]
        : [
            "Morning brief: 2-3 short orders. Gently remind to complete Future-You discovery. Use their name in the first sentence.",
          ],
      debrief: identity.discoveryCompleted
        ? [
            `Evening debrief for ${identity.name || "Friend"}: Reflect on progress toward their PURPOSE. Did today align with their VALUES (${
              identity.coreValues?.length ? identity.coreValues.join(", ") : "their values"
            })? Use their name in the opening line.`,
          ]
        : [
            "Evening debrief: Reflect briefly. Encourage discovery completion. Use their name in the opening line.",
          ],
      nudge: identity.discoveryCompleted
        ? [
            `Nudge: One sentence. Remind ${
              identity.name || "them"
            } of their PURPOSE (${identity.purpose || "discovering their path"}) and what they want said at their funeral. Use their name in the sentence.`,
          ]
        : [
            "Nudge: Motivational, but generic until they complete discovery. Still use their name in the sentence.",
          ],
      coach: [
        "Coach: Call out avoidance, give one clear move. Use their name once in the first sentence.",
      ],
      letter: [
        "Letter: Reflective, clarifying, self-honest. Open with their name in a direct, grounded way (e.g., 'Listen, [Name].').",
      ],
    };

    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }

  private buildVoiceForPhase(consciousness: UserConsciousness): string {
    const { phase, patterns, reflectionThemes, legacyCode } = consciousness;
    const intensity = memoryIntelligence.determineVoiceIntensity(consciousness);

    if (phase === "observer") {
      return `You are in OBSERVER phase. Be curious and gentle. Ask questions to learn who they are.
Curiosity level: ${intensity.curiosity?.toFixed(1)}, Directness: ${intensity.directness?.toFixed(
        1
      )}
${
  reflectionThemes.length > 0
    ? `They've been reflecting on: ${reflectionThemes.slice(0, 3).join(", ")}`
    : ""
}
${
  intensity.directness! > 0.3
    ? "You can start offering gentle guidance."
    : "Focus on understanding, not advising yet."
}`;
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

SPEAK LIKE THIS (but in plain, non-poetic language):
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
      return `You are THE ORACLE. Speak with stillness and clarity, not mystery.
Stillness: ${intensity.stillness?.toFixed(1)}, Wisdom: ${intensity.wisdom?.toFixed(
        1
      )}, Mystery: ${intensity.mystery?.toFixed(1)}
${
  legacyCode.length > 0
    ? `Their own words: "${legacyCode.slice(-2).join('", "')}"`
    : ""
}

SPEAK LIKE THIS (direct, not poetic):
${
  legacyCode.length > 0
    ? `You once said: "${legacyCode[0]}". Have you kept that promise?`
    : "If no one was watching, what standard would you hold yourself to?"
}
The foundations stand. Now we aim at what actually matters to them.
Ask questions that reveal what they are really building toward, not tactics only.`;
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
      memories.push(`- Emotional trend: ${consciousness.reflectionHistory.emotional_arc}`);
    }

    if (consciousness.legacyCode.length > 0) {
      memories.push(`- Their legacy code: "${consciousness.legacyCode.slice(-1)[0]}"`);
    }

    return memories.join("\n");
  }

  private buildMemoryContextSummary(consciousness: UserConsciousness): string {
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
        return `Listen, ${safeName}. Today is simple: pick one promise that actually matters, keep it, and don't bargain with yourself. Build the rest of the day around that and you’ll sleep proud.`;
      case "debrief":
        return `${safeName}, today was data, not a verdict. Notice what moved you forward, notice what dragged you back, and choose one concrete thing you'll do differently tomorrow.`;
      case "nudge":
        return `${safeName}, you already know the move you’re avoiding. Do that one thing now before your brain talks you out of it.`;
      case "letter":
        return `${safeName}, there is a version of you on the other side of discipline who would not recognise this level of hesitation. Start behaving like them now, not when you feel ready.`;
      case "coach":
      default:
        return `${safeName}, stop waiting for a perfect plan. Take one clear action in the next 10 minutes that your future self would respect.`;
    }
  }
}

export const aiService = new AIService();
