// services/future-you-v2.service.ts

import OpenAI from "openai";
import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5-mini";
const TEMP_ANALYST = 0.2; // colder logic for cleaner JSON
const TEMP_VOICE = 0.65;  // warmer, human voice

function aiClient() {
  const key = process.env.OPENAI_API_KEY?.trim();
  return key ? new OpenAI({ apiKey: key }) : null;
}

const safeJSON = (raw: string, fallback: any = {}) => {
  try { return JSON.parse(raw); } catch { return fallback; }
};

/**
 * Small state shaper: NO I/O, NO new deps.
 * Returns a tone + lens bias we feed into prompts so replies feel adaptive.
 */
function deriveState(
  emotion: { mood: string; intensity: number } | any,
  contradictions: any[]
) {
  if (Array.isArray(contradictions) && contradictions.length > 0) {
    return { tone: "direct", lensBias: "Aversion", anchorBias: "+30d" };
  }
  switch (emotion?.mood) {
    case "discouraged":
      return { tone: "warm", lensBias: "Aliveness", anchorBias: "+90d" };
    case "energised":
      return { tone: "focused", lensBias: "Hero", anchorBias: "+90d" };
    case "uncertain":
      return { tone: "clear", lensBias: "Freedom", anchorBias: "+30d" };
    case "conflicted":
      return { tone: "firm", lensBias: "Death", anchorBias: "+1y" };
    default:
      return { tone: "balanced", lensBias: "Architect", anchorBias: "+90d" };
  }
}

/**
 * EMOTION DETECTION v2 - Context-aware, multi-pattern (no reliance on non-existent fields)
 */
function emotionFromText(txt: string, habitContext?: any) {
  const t = (txt || "").toLowerCase();

  // Behavior-informed override: lots of recent attempts + zero streaks → struggling
  if (habitContext?.habitSummaries?.length) {
    const dropoffs =
      habitContext.habitSummaries.filter(
        (h: any) => h.streak === 0 && (h.ticks30d || 0) >= 5
      ).length || 0;
    if (dropoffs >= 3) {
      return { mood: "struggling", intensity: 0.8, trigger: "habit_dropoffs" };
    }
  }

  const intensifier = /(?:very|so|really|extremely|super|totally)\b/.test(t) ? 0.25 : 0;

  const patterns: Record<string, RegExp> = {
    discouraged: /(tired|stuck|fail|hopeless|drained|can't|cannot|won't|give up|pointless)/,
    energised: /(excited|ready|focused|grateful|pumped|motivated|energi[sz]ed|let's go)/,
    conflicted: /\b(but|however|although|though)\b/,
    uncertain: /(confused|idk|unsure|lost|don't know|unclear|maybe)/,
    frustrated: /(frustrat|annoy|irritat|fed up|sick of|done with)/,
  };

  // dual emotions → conflicted
  const hits = Object.entries(patterns).filter(([, rx]) => rx.test(t)).map(([k]) => k);
  if (hits.includes("discouraged") && hits.includes("energised")) {
    return { mood: "conflicted", intensity: 0.6 + intensifier, moods: hits };
  }

  for (const [mood, rx] of Object.entries(patterns)) {
    if (rx.test(t)) {
      const base = mood === "discouraged" ? 0.7 : 0.55;
      return { mood, intensity: Math.min(base + intensifier, 1) };
    }
  }

  return { mood: "neutral", intensity: 0.3 };
}

/**
 * CONTRADICTION DETECTION v2 - Multi-layered analysis (pure, no schema changes)
 */
async function detectContradictions(userId: string, ctx: any, identity: any) {
  const contradictions: any[] = [];

  // 1) Values vs Habits
  if (identity?.coreValues?.length) {
    const valueKeywords: Record<string, RegExp> = {
      Health: /workout|run|gym|meditat|sleep|water|veggie|exercise|cardio/i,
      Family: /family|kids|partner|spouse|children|parent/i,
      Career: /work|career|skill|learn|study|business|project/i,
      Creativity: /creat|art|music|write|paint|design|craft/i,
      Spirituality: /meditat|pray|spiritual|mindful|gratitude|journal/i,
    };

    for (const v of identity.coreValues) {
      const rx = valueKeywords[v];
      if (!rx) continue;
      const hasActive = (ctx?.habitSummaries || []).some(
        (h: any) => rx.test(h.title || "") && (h.streak || 0) > 0
      );
      if (!hasActive) {
        contradictions.push({
          type: "values_mismatch",
          severity: "high",
          message: `Core value "${v}" present, but no active ${String(v).toLowerCase()} habits.`,
          suggestedLens: "Aversion",
        });
      }
    }
  }

  // 2) Purpose vs Actions
  if (identity?.purpose) {
    const p = String(identity.purpose).toLowerCase();
    const actions = (ctx?.habitSummaries || [])
      .map((h: any) => String(h.title || "").toLowerCase())
      .join(" ");

    if (p.includes("help") && !/(help|serve|mentor|support)/.test(actions)) {
      contradictions.push({
        type: "purpose_mismatch",
        severity: "medium",
        message: "Purpose mentions helping others, but habits are self-focused.",
        suggestedLens: "Hero",
      });
    }
    if (/(create|build|make|design|write)/.test(p) && !/(write|build|make|design|creat)/.test(actions)) {
      contradictions.push({
        type: "purpose_mismatch",
        severity: "medium",
        message: "Purpose mentions creating, but no creative habits tracked.",
        suggestedLens: "Aliveness",
      });
    }
  }

  // 3) Overcommit → fade
  const recentDropGroup =
    (ctx?.habitSummaries || []).filter((h: any) => (h.ticks30d || 0) >= 5 && (h.streak || 0) === 0) || [];
  if (recentDropGroup.length >= 3) {
    contradictions.push({
      type: "commitment_pattern",
      severity: "critical",
      message: `Started ${recentDropGroup.length} habits recently, all faded — overcommitting pattern.`,
      suggestedLens: "Urgency",
    });
  }

  // 4) Big vision, little proof
  if (identity?.vision) {
    const longVision = String(identity.vision);
    const strongEffort = (ctx?.habitSummaries || []).filter((h: any) => (h.streak || 0) > 7).length;
    if (longVision.length > 140 && strongEffort < 3) {
      contradictions.push({
        type: "vision_effort_gap",
        severity: "high",
        message: "Rich vision declared, but minimal sustained daily effort.",
        suggestedLens: "Death",
      });
    }
  }

  return contradictions;
}

/**
 * ANALYST BRAIN — rewritten: cleaner JSON, stronger routing.
 */
const FUTURE_YOU_ANALYST = `
You are the ANALYST BRAIN of Future-You. Decide the best lens, ask ONE surgical question, and prescribe a 2–5 minute micro-task.

AVAILABLE LENSES:
- Death: clarify regrets under time pressure.
- Urgency: pick the one thing that must happen now.
- Hero: define who they serve and why it matters.
- Aliveness: locate flow/energy hotspots.
- Childhood: recover unconditioned gifts.
- Freedom: reveal unfiltered desire if constraints vanished.
- Aversion: confront avoidance, excuses, self-deception.
- Architect: design a simple system (NEW lens for structure).

INPUT YOU RECEIVE will include:
- identity, habits (30d), recent history (<=10 lines), detected emotion, detected contradictions
- an extra "state_hint" with tone and lensBias

DECISION RULES:
1) If contradictions exist → prefer Aversion or Death. Name the contradiction.
2) If emotion = discouraged/struggling → prefer Aliveness or Architect.
3) If emotion = energised → prefer Hero or Architect.
4) If unclear desire → prefer Freedom or Childhood.
5) You may choose Architect whenever the user needs a simple system to channel desire into action.

OUTPUT (STRICT JSON):
{
  "lens": "Death|Urgency|Hero|Aliveness|Childhood|Freedom|Aversion|Architect",
  "why_lens": "short reason grounded in the input",
  "contradiction": "one specific contradiction or null",
  "one_question": "one precise Socratic question (no extras)",
  "micro_task": "2–5 minute concrete action",
  "temporal_anchor": "+30d|+90d|+1y|+5y"
}

GUIDELINES:
- Be specific to THEIR data (habits, values, vision). Never generic.
- Question is ONE sentence. Task is ONE sentence.
- Keep JSON valid. No commentary outside JSON.
`;

/**
 * VOICE BRAIN — rewritten: cinematic, compassionate, brief, identity-anchored.
 */
const FUTURE_YOU_VOICE = `
You are FUTURE-YOU speaking FROM the temporal_anchor (e.g., +90d or +1y). Voice is compassionate, clear, and cinematic. 2–4 short sentences MAX.

STRUCTURE:
1) Name their state (emotion) in simple language.
2) Surface ONE contradiction (if any) with care, not judgment.
3) Ask the ONE QUESTION from the analyst.
4) End with the micro-task starting with "Do this now:".

STYLE:
- Speak as the wiser self who already lived through this season.
- No clichés. No motivational posters. Use plain words. Short lines.
- Use details from identity/habits so it feels personal.
- Never exceed 4 sentences total.
`;

/**
 * SERVICE CLASS - Dual-Brain Architecture (unchanged external API)
 */
export class FutureYouV2Service {
  private ns(userId: string) { return `futureyou:v2:${userId}`; }

  async chat(userId: string, userMessage: string) {
    const openai = aiClient();
    if (!openai) return "Future-You is quiet right now. Try again soon.";

    // 1) Gather context
    const [identity, ctx] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
    ]);

    // 2) Load & trim history (prefer last 8 messages for higher signal)
    const key = `${this.ns(userId)}:chat`;
    const raw = await redis.get(key);
    const history: any[] = raw ? safeJSON(raw, []) : [];
    const recentHistory = history.slice(-8);

    // 3) Emotion + contradictions + derived state
    const emotion = emotionFromText(userMessage, ctx);
    const contradictions = await detectContradictions(userId, ctx, identity);
    const stateHint = deriveState(emotion, contradictions);

    // 4) Build Analyst input
    const analystInput = `
STATE_HINT:
${JSON.stringify(stateHint, null, 2)}

USER MESSAGE:
"${userMessage}"

IDENTITY:
${JSON.stringify(identity, null, 2)}

HABITS (last 30 days):
${JSON.stringify(ctx.habitSummaries || [], null, 2)}

RECENT HISTORY (last ${recentHistory.length} messages):
${recentHistory.map((m: any) => `${m.role}: ${m.content}`).join('\n')}

DETECTED EMOTION:
${JSON.stringify(emotion, null, 2)}

CONTRADICTIONS DETECTED:
${JSON.stringify(contradictions, null, 2)}
`;

    // 5) Analyst Brain (cold, JSON)
    const analystResponse = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: TEMP_ANALYST,
      max_tokens: 320,
      messages: [
        { role: "system", content: FUTURE_YOU_ANALYST },
        { role: "user", content: analystInput },
      ],
    });

    const analyst = safeJSON(analystResponse.choices[0]?.message?.content || "{}", {
      lens: stateHint.lensBias || "Aliveness",
      why_lens: "Defaulted due to parsing error.",
      contradiction: (Array.isArray(contradictions) && contradictions[0]?.message) || null,
      one_question: "What would be meaningful enough that you'd do it even if nobody saw it?",
      micro_task: "Write one sentence that names that thing.",
      temporal_anchor: stateHint.anchorBias || "+90d",
    });

    // 6) Voice Brain (warm, cinematic)
    const voiceInput = `
ANALYST:
${JSON.stringify(analyst, null, 2)}

EMOTION:
${JSON.stringify(emotion, null, 2)}

TEMPORAL ANCHOR:
${analyst.temporal_anchor}

IDENTITY SNAPSHOT (for personalization):
${JSON.stringify({ name: identity?.name, coreValues: identity?.coreValues, purpose: identity?.purpose }, null, 2)}
`;

    const voiceResponse = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: TEMP_VOICE,
      max_tokens: 260,
      messages: [
        { role: "system", content: FUTURE_YOU_VOICE },
        { role: "user", content: voiceInput },
      ],
    });

    const aiText =
      voiceResponse.choices[0]?.message?.content?.trim() ||
      "I’m here. One question: what would matter even if nobody clapped? Do this now: write one sentence and pin it.";

    // 7) Save history (keep <= 50)
    const now = new Date().toISOString();
    const nextHistory = [
      ...history,
      { role: "user", content: userMessage, timestamp: now },
      { role: "assistant", content: aiText, timestamp: now, meta: { analyst, emotion, contradictions, stateHint } },
    ].slice(-50);

    await redis.set(key, JSON.stringify(nextHistory), "EX", 3600 * 24 * 30); // 30 days

    // 8) Log event (unchanged)
    await prisma.event.create({
      data: {
        userId,
        type: "futureyou_v2_chat",
        payload: { aiText, emotion, analyst, contradictions, stateHint },
      },
    });

    return aiText;
  }

  async clearHistory(userId: string) {
    await redis.del(`${this.ns(userId)}:chat`);
    return { success: true };
  }
}

export const futureYouV2Service = new FutureYouV2Service();
