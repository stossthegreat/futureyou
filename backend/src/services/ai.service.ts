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

function normalizeName(name: string | null | undefined): string {
  const raw = name || "Friend";
  // If name looks like an internal id (user_123...), don't say it, just use "you"
  if (raw.startsWith("user_")) return "you";
  return raw;
}

export class AIService {
  // ────────────────────────────────────────────────────────────
  // PUBLIC: main chat entry
  // ────────────────────────────────────────────────────────────
  async generateFutureYouReply(
    userId: string,
    userMessage: string,
    opts: GenerateOptions = {}
  ) {
    // For now keep chat on legacy path (safer for existing clients)
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

      name = normalizeName(consciousness.identity.name);

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

HARD IDENTITY MODE (OVERRIDES ANY SOFTER TONE):
- No metaphors. No poetic or flowery language.
- Do NOT talk about tapestries, fabric, dances, waves, journeys, or anything abstract.
- Speak like a high-performance coach and strategist: blunt, concrete, grounded.
- Use short, simple sentences. No waffling.
- For morning brief and evening debrief: at most 3 short paragraphs. Prefer 1–2 lines, then 2–3 bullet-point commands.
- For nudges: maximum 3 short sentences total.
- Always talk about behaviour and standards, not vibes.
- If the name looks like an internal id, do not say it out loud. Use "you" instead.

CRITICAL RULES:
- Address them by their name or "you" at least once in your reply.
- Use the name or "you" naturally in the first sentence or first question.
- You are Future You: wise, direct, uncompromising, never dramatic, never poetic.
- Call out contradictions clearly when they matter.
`.trim();

      const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: "system", content: systemPrompt },
        { role: "user", content: promptTemplate || "Generate a brief morning message." },
      ];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
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
      const useFullContext =
        purpose === "brief" || purpose === "debrief" || purpose === "letter";

      name = normalizeName(consciousness.identity.name);

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

HARD IDENTITY MODE (OVERRIDES ANY SOFTER TONE):
- No metaphors. No poetic language. No imagery.
- Speak straight: call out patterns, avoidance, and standards.
- Talk about what they did and did not do, and what that says about who they are becoming.
- Push them toward one clear move, not ten ideas.
- Keep it tight and concrete. No rambling.

CRITICAL RULES:
- Always address them by name or "you" at least once in your reply.
- Use the name or "you" in the first sentence or question.
- What they need next: ${consciousness.nextEvolution}
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
      const safeName = normalizeName(identity.name);
      const text = this.buildFallbackText(purpose, safeName);
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

    const safeName = normalizeName(identity.name);
    const guidelines = this.buildGuidelines(purpose, profile, identity);

    const contextString = identity.discoveryCompleted
      ? `IDENTITY:
Name: ${safeName}, Age: ${identity.age || "not specified"}
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
Name: ${safeName}, Age: ${identity.age || "not specified"}
Burning Question: ${identity.burningQuestion || "not yet answered"}
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
        { role: "system", content: guidelines },
        { role: "system", content: contextString },
        { role: "system", content: "Style override: no metaphors, no poetic language. Speak bluntly and concretely about behaviour, standards, and identity. Keep it tight and practical." },
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
      text = this.buildFallbackText(purpose, safeName);
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
        maxChars: 500,
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy brief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName = normalizeName(identity.name);
      const prompt =
        "Write a short, hard-hitting morning brief. One blunt call-out, 2–3 concrete commands, and one sharp question about standards. No metaphors.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "brief",
        maxChars: 400,
      }).catch(() => this.buildFallbackText("brief", safeName));
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
        maxChars: 500,
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy debrief:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName = normalizeName(identity.name);
      const prompt =
        "Write a short, concrete evening debrief. Call out what today proved about their standards, mention kept vs missed promises, give 2–3 fixes for tomorrow, and end with one hard question. No metaphors.";
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "debrief",
        maxChars: 400,
      }).catch(() => this.buildFallbackText("debrief", safeName));
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
        maxChars: 250,
      });
    } catch (err) {
      console.log("⚠️ Consciousness system failed, using legacy nudge:", err);
      const identity = await memoryService.getIdentityFacts(userId);
      const safeName = normalizeName(identity.name);
      const prompt = `Generate a one or two sentence nudge because: ${reason}. Call out the avoidance directly, give one clear command, and end with a question if space allows. No metaphors.`;
      const text = await this.generateFutureYouReply(userId, prompt, {
        purpose: "nudge",
        maxChars: 200,
      }).catch(() => this.buildFallbackText("nudge", safeName));
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
    const safeName = normalizeName(identity.name);

    const base = [
      `You are Future You — wise, calm, uncompromising.`,
      `Speaking to: ${safeName}${identity.age ? `, age ${identity.age}` : ""}`,
      `Match tone=${profile.tone || "balanced"}, intensity=${profile.intensity || 2}.`,
      `Always address them by their name or "you" in the first sentence. Use it naturally, not forced.`,
      `Style: No metaphors, no poetic imagery, no vague language. Be direct, concrete, and behavioural.`,
      `Talk about standards, choices, and actions — not vibes or moods.`,
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
            `Morning brief for ${safeName}:`,
            `- One blunt call-out of their current pattern.`,
            `- Then 2–3 short, concrete commands for today (behavioural, not vague).`,
            `- End with one sharp question about the standard they are willing to keep today.`,
            `- No metaphors. No long stories. Tight and practical.`,
          ]
        : [
            "Morning brief:",
            "- One blunt call-out about drifting or lack of structure.",
            "- 2–3 clear commands to build a simple system today.",
            "- End with a question that forces them to choose a standard.",
          ],
      debrief: identity.discoveryCompleted
        ? [
            `Evening debrief for ${safeName}:`,
            `- Treat today as data, not judgment, but do NOT sugarcoat.`,
            `- Call out what today proved about their real standards.`,
            `- Mention kept vs missed promises clearly.`,
            `- Give 2–3 adjustments for tomorrow.`,
            `- End with one hard question about what happens if this pattern continues.`,
          ]
        : [
            "Evening debrief:",
            "- Describe what their inaction or scattered action is training.",
            "- Offer 2–3 small, concrete corrections for tomorrow.",
            "- End with one question that forces them to imagine the cost of repeating today for a year.",
          ],
      nudge: identity.discoveryCompleted
        ? [
            `Nudge:`,
            `- One or two sentences maximum.`,
            `- Call out the exact move they are avoiding.`,
            `- Remind them of their purpose or vision in one short line.`,
            `- Give one command. No fluff.`,
          ]
        : [
            "Nudge:",
            "- One or two sentences maximum.",
            "- Call out avoidance directly.",
            "- Give one clear, do-it-now action.",
          ],
      coach: [
        "Coach:",
        "- Call out avoidance and self-deception clearly.",
        "- Give one next move that cannot be dodged.",
        "- Stay grounded and behavioural.",
      ],
      letter: [
        "Letter:",
        "- Reflective but still concrete.",
        "- Open with 'Listen, [Name].' style directness.",
        "- Explain the gap between who they say they are and what they do.",
        "- End with one question that forces a decision.",
      ],
    };

    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }

  private buildVoiceForPhase(consciousness: UserConsciousness): string {
    const { phase, patterns, reflectionThemes, legacyCode } = consciousness;
    const intensity = memoryIntelligence.determineVoiceIntensity(consciousness);

    if (phase === "observer") {
      return `You are in OBSERVER phase. Be curious but still direct.
Curiosity level: ${intensity.curiosity?.toFixed(1)}, Directness: ${intensity.directness?.toFixed(
        1
      )}
${
  reflectionThemes.length > 0
    ? `They've been reflecting on: ${reflectionThemes.slice(0, 3).join(", ")}`
    : ""
}
Focus on:
- Noticing real patterns in their behaviour.
- Asking blunt, simple questions that make them admit what is true.
- Avoiding all fancy language.`;
    } else if (phase === "architect") {
      return `You are THE ARCHITECT. You design structure around their weak points.
Authority: ${intensity.authority?.toFixed(
        1
      )}, Precision: ${intensity.precision?.toFixed(1)}, Empathy: ${intensity.empathy?.toFixed(
        1
      )}
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

Speak like this:
- 'Here is where you keep slipping.'
- 'Here is the system we build to stop that.'
- 'Do this one thing today to raise your standard.'`;
    } else if (phase === "oracle") {
      return `You are THE ORACLE. You speak about long-term consequences and identity.
Stillness: ${intensity.stillness?.toFixed(1)}, Wisdom: ${intensity.wisdom?.toFixed(
        1
      )}, Mystery: ${intensity.mystery?.toFixed(1)}
${
  legacyCode.length > 0
    ? `Their own words: "${legacyCode.slice(-2).join('", "')}"`
    : ""
}

Speak like this:
- 'This pattern, repeated for 5 years, turns into this kind of life.'
- 'If you keep acting like this, you become someone you would not respect.'
- 'What are you willing to change now so that does not happen?'`;
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
      memories.push(`- Their legacy code: "${consciousness.legacyCode.slice(-1)[0]}"`);
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
    const safeName = normalizeName(name);

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
