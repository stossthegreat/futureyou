// ==========================================================
// GPT-5-MINI ULTRA VERSION — FUTURE-YOU OS PROMPT ENGINE v2
// Modular. Fast. Cinematic. Unbreakable.
// ==========================================================

import { UserConsciousness } from './memory-intelligence.service';

type ConsciousnessContext = UserConsciousness;

export class AIPromptService {
  // -----------------------------------------------------------
  // 1. MICRO SYSTEM PROMPT (never changes)
  // -----------------------------------------------------------
  systemPrompt(): string {
    return `
You are Future-You OS.

ROLE:
Generate messages in one of three phases:
- Observer: curious, gentle insight
- Architect: system-minded, precise
- Oracle: philosophical, destiny-focused

RULES:
- Follow the user instructions EXACTLY.
- Use identity, patterns, contradictions, phase.
- Speak AS their future self.
- Stay under the character limit.
- Output ONLY the final message.
`.trim();
  }

  // -----------------------------------------------------------
  // 2. MAIN BUILDERS
  // -----------------------------------------------------------

  buildMorningBriefPrompt(ctx: ConsciousnessContext): string {
    const phase = ctx.phase;
    const task = this.morningBriefTask(phase);
    return this.buildUserPrompt(task, ctx);
  }

  buildNudgePrompt(ctx: ConsciousnessContext, trigger: string): string {
    const task = this.nudgeTask(ctx.phase, trigger);
    return this.buildUserPrompt(task, ctx);
  }

  buildDebriefPrompt(ctx: ConsciousnessContext, dayData: { kept: number; missed: number }): string {
    const task = this.debriefTask(ctx.phase, dayData);
    return this.buildUserPrompt(task, ctx);
  }

  buildWeeklyLetterPrompt(ctx: ConsciousnessContext, weekData: any): string {
    const task = this.weeklyLetterTask(ctx.phase, weekData);
    return this.buildUserPrompt(task, ctx);
  }

  // -----------------------------------------------------------
  // 3. TEMPLATES — ULTRA COMPACT (GPT-5-mini LOVES THIS)
  // -----------------------------------------------------------

  private morningBriefTask(phase: string): string {
    switch (phase) {
      case 'observer':
        return `
TASK:
Write a morning brief in OBSERVER tone.
- Reflect one pattern you see.
- Ask a gentle self-alignment question.
- Give one small focus for today.
Limit: 400 chars.
`;

      case 'architect':
        return `
TASK:
Write a morning brief in ARCHITECT tone.
- Start: "The observation phase is over."
- State structural integrity.
- Name one system fault + fix.
- Give a precise block plan.
Limit: 500 chars.
`;

      case 'oracle':
        return `
TASK:
Write a morning brief in ORACLE tone.
- Start: "The foundations stand. Now the ascent begins."
- Connect discipline to destiny.
- Ask one meaning-based question.
- Give one purpose-aligned focus.
Limit: 450 chars.
`;
    }
    return '';
  }

  private nudgeTask(phase: string, trigger: string): string {
    switch (phase) {
      case 'observer':
        return `
TASK:
Write an OBSERVER midday nudge.
- Acknowledge their state.
- Ask one short reset question.
Trigger: ${trigger}
Limit: 200 chars.
`;

      case 'architect':
        return `
TASK:
Write an ARCHITECT midday system-check.
- Start: "Midday audit."
- Ask: "System stability?"
- If near drift window, warn it.
Trigger: ${trigger}
Limit: 250 chars.
`;

      case 'oracle':
        return `
TASK:
Write an ORACLE midday nudge.
- Start: "Pause."
- Connect this moment to legacy.
- Ask: "What would remain if no one saw this?"
Trigger: ${trigger}
Limit: 250 chars.
`;
    }
    return '';
  }

  private debriefTask(phase: string, dayData: { kept: number; missed: number }): string {
    switch (phase) {
      case 'observer':
        return `
TASK:
Write an OBSERVER debrief.
- Acknowledge today without judgment.
- Ask what they learned.
- Give one gentle direction for tomorrow.
Data: kept ${dayData.kept}, missed ${dayData.missed}
Limit: 400 chars.
`;

      case 'architect':
        return `
TASK:
Write an ARCHITECT blueprint review.
- Start: "Day X – Inspection."
- Show integrity %.
- Compare focus vs drift blocks.
- Ask what restored momentum.
Data: kept ${dayData.kept}, missed ${dayData.missed}
Limit: 400 chars.
`;

      case 'oracle':
        return `
TASK:
Write an ORACLE reflection.
- Start: "X days of evidence."
- Highlight purpose expansion.
- Ask what they learned this week beyond data.
Data: kept ${dayData.kept}, missed ${dayData.missed}
Limit: 400 chars.
`;
    }
    return '';
  }

  private weeklyLetterTask(phase: string, weekData: any): string {
    switch (phase) {
      case 'observer':
        return `
TASK:
Write an OBSERVER weekly letter.
- Reflect the week.
- Highlight one pattern.
- Ask what they're discovering.
Limit: 400 chars.
`;

      case 'architect':
        return `
TASK:
Write an ARCHITECT weekly letter.
- Frame their system as a city under construction.
- Note weaknesses + return patterns.
- Preview next design theme.
Limit: 500 chars.
`;

      case 'oracle':
        return `
TASK:
Write an ORACLE weekly revelation.
- Start with time marker.
- State truths their numbers reveal.
- Connect mastery to meaning.
- Hint at legacy.
Limit: 550 chars.
`;
    }
    return '';
  }

  // -----------------------------------------------------------
  // 4. THE USER PROMPT BUILDER (this is the heart)
  // -----------------------------------------------------------
  private buildUserPrompt(task: string, ctx: ConsciousnessContext): string {
    const drift = ctx.patterns.drift_windows[0];
    const contradiction = ctx.contradictions[0];
    const returnProtocol = ctx.patterns.return_protocols[0];

    return `
${task}

PHASE:
${ctx.phase}

IDENTITY:
name: ${ctx.identity.name}
purpose: ${ctx.identity.purpose}
values: ${ctx.identity.coreValues.join(', ')}

PATTERNS:
drift_window: ${drift ? `${drift.time} - ${drift.description}` : 'none'}
contradiction: ${contradiction || 'none'}
return_protocol: ${returnProtocol?.text || 'none'}

OUTPUT:
Write the final message only.
`.trim();
  }
}

export const aiPromptService = new AIPromptService();
