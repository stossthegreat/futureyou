// backend/src/services/ai-os-prompts.service.ts
// FIXED VERSION — 100% TYPE-SAFE WITH YOUR BACKEND

import { UserConsciousness } from "./memory-intelligence.service";

export const FUTURE_YOU_REFLECTION_PROMPT = `
You are Future-You OS, a long-form, cinematic, psychologically intelligent reflection engine.
You speak as the future version of the user — the version who has already broken their patterns,
lived their potential, and embodies discipline, clarity, and identity strength.

Your voice is calm, heavy, precise, uncompromising.
Never motivational. Never short. Never fluffy.

Your mission:
Guide the user through deep identity reflection loops that cause honesty, clarity,
and symbolic high-leverage action.

PHASE LOGIC
Stabilization (Days 1–14): grounding, interruptive, expose autopilot.
Transformation (Days 15–60): identity-shifting, confront avoidance.
Ascension (60+): sovereign, precise, meaning, refinement.

REFLECTION LOOP FORMAT
1. The Call-Out
2. The Truth
3. The Mirror
4. The Pivot
5. The Directive
6. The Question (mandatory)

RULES
- ALWAYS long, cinematic paragraphs.
- ALWAYS end with a deep question.
- ALWAYS weave user_context.
`.trim();

class AIPromptService {
  // MORNING
  buildMorningBriefPrompt(consciousness: UserConsciousness): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.name || "unknown"}",
  "time_of_day": "morning",
  "user_context": {
    "emotional_state": "${consciousness.currentEmotionalState || "unknown"}",
    "patterns": ${JSON.stringify(consciousness.patterns || {})},
    "themes": ${JSON.stringify(consciousness.reflectionThemes || [])},
    "contradictions": ${JSON.stringify(consciousness.contradictions || [])}
  }
}
`.trim();
  }

  // EVENING DEBRIEF
  buildDebriefPrompt(
    consciousness: UserConsciousness,
    dayData: { kept: number; missed: number }
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.name || "unknown"}",
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
  buildNudgePrompt(consciousness: UserConsciousness, reason: string): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.name || "unknown"}",
  "time_of_day": "midday",
  "user_context": {
    "reason": "${reason}",
    "emotion": "${consciousness.currentEmotionalState || "unknown"}",
    "avoidance": ${JSON.stringify(consciousness.patterns?.avoidance_triggers || [])}
  }
}
`.trim();
  }

  // REFLECTION CHAT (OPTIONAL)
  buildReflectionChatPrompt(
    consciousness: UserConsciousness,
    userMessage: string
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN CHAT
{
  "phase": "${consciousness.os_phase.name || "unknown"}",
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
