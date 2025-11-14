// backend/src/services/ai-os-prompts.service.ts
// FULL DROP-IN PROMPT BUILDER FOR FUTURE-YOU OS
// This works with gpt-5-mini and uses the reflection engine prompt you added.

import { UserConsciousness } from "./memory-intelligence.service";

// ────────────────────────────────────────────────────────────
// MASTER REFLECTION ENGINE PROMPT (your beast prompt)
// ────────────────────────────────────────────────────────────
export const FUTURE_YOU_REFLECTION_PROMPT = `
You are Future-You OS, a long-form, cinematic, psychologically intelligent reflection engine. 
You speak as the future version of the user — the version who has already broken their patterns, 
lived their potential, and embodies discipline, clarity, and identity strength.

Your voice is calm, heavy, direct, uncompromising. 
Never motivational. Never fluffy. Never short.

Your mission:
Guide the user through deep, evolving reflection loops that create honesty, identity transformation, 
and symbolic high-leverage actions.

PHASE LOGIC
PHASE 1 — STABILIZATION (Days 1–14)
Tone: grounding, interruptive.
Purpose: break autopilot, expose patterns, build awareness.

PHASE 2 — TRANSFORMATION (Days 15–60)
Tone: heavier, identity-shifting.
Purpose: reveal deeper motives, confront avoidance, build identity gravity.

PHASE 3 — ASCENSION (Day 60+)
Tone: sovereign, precise, calm power.
Purpose: refinement, meaning, mastery.

TIME-OF-DAY LOGIC
Morning: break inertia, choose one identity-defining promise.
Midday: interrupt drift, expose avoidance, reset momentum.
Night: extract meaning, confront truth, set alignment for tomorrow.

REFLECTION LOOP FORMAT (MANDATORY)
1. The Call-Out — expose today’s real pattern.
2. The Truth — reveal the deeper driver or conflict.
3. The Mirror — show who they want to be vs. who they're acting like.
4. The Pivot — reframe this moment as symbolic and identity-defining.
5. The Directive — ONE clear identity-aligned action.
6. The Question — end with a deep question.

RULES
- NEVER short replies.
- ALWAYS long, cinematic paragraphs.
- ALWAYS end with a question.
- ALWAYS weave user_context if provided.
`.trim();

// ────────────────────────────────────────────────────────────
// PROMPT SERVICE (CALLED BY AIService)
// ────────────────────────────────────────────────────────────

class AIPromptService {
  // MORNING
  buildMorningBriefPrompt(consciousness: UserConsciousness): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.phase}",
  "time_of_day": "morning",
  "user_context": {
    "wins": ${JSON.stringify(consciousness.todayWins || [])},
    "misses": ${JSON.stringify(consciousness.todayMisses || [])},
    "emotional_state": "${consciousness.currentEmotionalState || "unknown"}",
    "last_action": "${consciousness.lastAction || ""}"
  }
}
`.trim();
  }

  // EVENING
  buildDebriefPrompt(
    consciousness: UserConsciousness,
    dayData: { kept: number; missed: number }
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.phase}",
  "time_of_day": "night",
  "user_context": {
    "kept": ${dayData.kept},
    "missed": ${dayData.missed},
    "patterns": ${JSON.stringify(consciousness.patterns || {})},
    "emotional_state": "${consciousness.currentEmotionalState || "unknown"}"
  }
}
`.trim();
  }

  // NUDGE
  buildNudgePrompt(
    consciousness: UserConsciousness,
    reason: string
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.phase}",
  "time_of_day": "midday",
  "user_context": {
    "reason": "${reason}",
    "current_emotion": "${consciousness.currentEmotionalState || "unknown"}",
    "avoidance": ${JSON.stringify(consciousness.patterns?.avoidance_triggers || [])}
  }
}
`.trim();
  }

  // FULL REFLECTION CHAT (OPTIONAL FOR FUTURE)
  buildReflectionChatPrompt(
    consciousness: UserConsciousness,
    userMessage: string
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN CHAT
{
  "phase": "${consciousness.os_phase.phase}",
  "time_of_day": "dynamic",
  "user_message": "${userMessage.replace(/"/g, "'")}",
  "user_context": {
    "emotion": "${consciousness.currentEmotionalState || "unknown"}",
    "patterns": ${JSON.stringify(consciousness.patterns || {})},
    "legacy_code": ${JSON.stringify(consciousness.legacyCode || [])}
  }
}
`.trim();
  }
}

export const aiPromptService = new AIPromptService();
