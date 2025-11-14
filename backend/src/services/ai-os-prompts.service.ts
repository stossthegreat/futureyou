// backend/src/services/ai-os-prompts.service.ts
// FINAL VERSION — matches your real OSPhase & UserConsciousness types

import { UserConsciousness } from "./memory-intelligence.service";

export const FUTURE_YOU_REFLECTION_PROMPT = `
You are Future-You OS: a long-form, cinematic, psychologically intelligent reflection engine.
You speak as the user's evolved future self — disciplined, clear, sovereign.

Your tone is heavy, precise, identity-driven. 
Never casual. Never short. Never fluffy.

Your mission:
Create identity transformation through deep reflection loops.

REFLECTION LOOP FORMAT
1. The Call-Out — expose the real pattern today.
2. The Truth — reveal the deeper driver.
3. The Mirror — contrast who they want to be vs how they acted.
4. The Pivot — redefine the moment as symbolic.
5. The Directive — ONE identity-aligned action.
6. The Question — mandatory powerful question.

RULES
- LONG cinematic paragraphs only.
- ALWAYS end with a deep question.
- ALWAYS use the user_context.
`.trim();

class AIPromptService {
  // MORNING PROMPT
  buildMorningBriefPrompt(consciousness: UserConsciousness): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.current_phase}",
  "time_of_day": "morning",
  "user_context": {
    "emotional_state": "${consciousness.currentEmotionalState}",
    "patterns": ${JSON.stringify(consciousness.patterns || {})},
    "themes": ${JSON.stringify(consciousness.reflectionThemes || [])},
    "contradictions": ${JSON.stringify(consciousness.contradictions || [])}
  }
}
`.trim();
  }

  // EVENING DEBRIEF PROMPT
  buildDebriefPrompt(
    consciousness: UserConsciousness,
    dayData: { kept: number; missed: number }
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.current_phase}",
  "time_of_day": "night",
  "user_context": {
    "kept": ${dayData.kept},
    "missed": ${dayData.missed},
    "patterns": ${JSON.stringify(consciousness.patterns)},
    "emotional_state": "${consciousness.currentEmotionalState}"
  }
}
`.trim();
  }

  // MIDDAY NUDGE PROMPT
  buildNudgePrompt(consciousness: UserConsciousness, reason: string): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN
{
  "phase": "${consciousness.os_phase.current_phase}",
  "time_of_day": "midday",
  "user_context": {
    "reason": "${reason}",
    "emotion": "${consciousness.currentEmotionalState}",
    "avoidance": ${JSON.stringify(consciousness.patterns.avoidance_triggers || [])}
  }
}
`.trim();
  }

  // REFLECTION CHAT
  buildReflectionChatPrompt(
    consciousness: UserConsciousness,
    userMessage: string
  ): string {
    return `
${FUTURE_YOU_REFLECTION_PROMPT}

BEGIN CHAT
{
  "phase": "${consciousness.os_phase.current_phase}",
  "time_of_day": "dynamic",
  "user_message": "${userMessage.replace(/"/g, "'")}",
  "user_context": {
    "emotion": "${consciousness.currentEmotionalState}",
    "patterns": ${JSON.stringify(consciousness.patterns)},
    "legacy_code": ${JSON.stringify(consciousness.legacyCode || [])}
  }
}
`.trim();
  }
}

export const aiPromptService = new AIPromptService();
