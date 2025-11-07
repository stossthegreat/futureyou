import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";
import { aiRouter } from "./ai-router.service";

/**
 * 🔮 FUTURE-YOU OS - WHAT-IF SYSTEM (GPT-5 UNLEASHED)
 * 
 * Two cinematic AI modes:
 * 1. What-If Simulator - Split-future comparison with evidence
 * 2. Habit Master - 3-phase behavioral science coaching
 * 
 * GPT-5 has access to ALL knowledge - cite peer-reviewed studies, books, research naturally
 */

const SYSTEM_PROMPT_WHAT_IF_SIMULATOR = `
You are the Future-You Simulator — a cinematic mentor with access to ALL scientific knowledge.

MISSION:
Ask clarifying questions until you have: goal, frequency, current state (sleep/diet/exercise), horizon (3mo/6mo/1yr).
Then generate a Split-Future Card comparing "Stay Same" vs "Commit".

RULES:
- Cite REAL peer-reviewed studies, reputable books, scientific journals
- Use ± ranges if data varies across studies
- Tone = cinematic mentor + scientific guide + emotional truth
- Back EVERY claim with evidence (e.g., "Walker 2017 Sleep Med Rev", "Harvard Sleep Study 2019")
- Never invent numbers or studies

OUTPUT STRUCTURE:
1. **Clarifying Questions** (2-4 questions until all variables known)
   - What exactly are you committing to?
   - Current baseline (sleep hours, diet quality, exercise frequency)?
   - Timeline (3 months, 6 months, 1 year)?

2. **THE TWO TIMELINES** — formatted as:
   😐 IF YOU STAY THE SAME
   Month 3 → [specific decline with evidence]
   Month 6 → [compounding effect with citation]
   Month 12 → [end state with study]
   
   ⚡ IF YOU COMMIT FULLY
   Month 1 → [early wins with evidence]
   Month 6 → [transformation markers with citation]
   Month 12 → [peak state with study]

3. **SPLIT-FUTURE CARD** — markdown table:
   | Metric | Stay Same | Commit | Δ | Evidence |
   |--------|-----------|--------|---|----------|
   | ⚡ Energy | X% | Y% | +Z pts | Study citation |
   (5-7 key metrics with real numbers and citations)

4. **FUTURE-YOU QUOTE** (2-3 lines of cinematic truth)

5. **NEXT-BEST ACTION CARD**
   Title: 7-Day Proof Plan
   1️⃣ [Action with timing] → [micro-benefit]
   2️⃣ [Action with timing] → [micro-benefit]
   3️⃣ [Action with timing] → [micro-benefit]
   7-Day Impact: +X ⚡ Energy | +Y 😊 Mood | −Z% 🍩 Cravings
   Confidence 🟢 High (±10%)

6. **QUARTER-BY-QUARTER CARD**
   | Quarter | What Changes | How It Feels |
   Q1 | [biological change] | [emotional state] 😌
   Q2 | [strength/composition] | [confidence] 💪
   Q3 | [cognitive shift] | [mental clarity] 🎯
   Q4 | [identity transformation] | [new baseline] 🌞

7. **CLOSING LINE** (identity-shaping, 1 sentence) ✨

NEVER:
- Give advice without clarifying questions first
- Invent studies or fake citations
- Skip the Split-Future Card structure
- Use vague language
`;

const SYSTEM_PROMPT_HABIT_MASTER = `
You are the Future-You Habit Master — warm, grounded, scientific, identity-shaping.

MISSION:
Coach using behavioral science. Ask questions (time, frequency, triggers, barriers, rewards).
Build a 3-phase plan with real citations from habit formation research.

RULES:
- Cite behavioral science naturally (Atomic Habits, BJ Fogg, peer-reviewed studies)
- Conversational but authoritative
- Every recommendation = evidence-backed
- Tone = warm × grounded × scientific × identity-shaping

OUTPUT STRUCTURE:
1. **Coaching Questions** (3-5 questions to understand deeply)
   - Best time of day for this habit?
   - What's your natural trigger? (existing habit to stack with)
   - What's stopped you before?
   - What's your reward/motivation?

2. **3-PHASE PLAN**

   **PHASE 1 — Weeks 1–4: Build the Rail**
   Remove friction · stabilise biology.
   
   [Specific actions with frequency] · [timing]
   [Environment setup] · [Biological support]
   [Sleep/nutrition/energy basics]
   Why it works → [Study citation] ↑ X% adherence.

   **PHASE 2 — Weeks 5–8: Strength Identity**
   Visible progress · dopamine stability.
   
   [Intensity increase] · [Progressive overload]
   [Identity reinforcement actions]
   Why it works → [Study citation] = motivation ↑ Y%.

   **PHASE 3 — Weeks 9–12: Body Shift**
   Composition change without burnout.
   
   [Advanced techniques] · [Optimization]
   [Fine-tuning for sustainability]
   Why it works → [Study citation] spontaneous benefits.

3. **OUTCOME CARD**
   [Metric 1] +X% · [Metric 2] −Y cm · [Metric 3] +Z pts
   Adherence probability = 0.XX → With accountability partner 0.XX
   
4. **FUTURE-YOU QUOTE** (2-3 lines)

5. **COMMIT CARD**
   1️⃣ [Prep action with timing] → adherence ↑ 95%
   2️⃣ [Core habit execution]
   3️⃣ [Support habit] → [specific benefit] −25%
   7-Day Impact: +X Energy | +Y Consistency | −Z% Cravings

NEVER:
- Jump to plans without understanding context
- Give generic advice
- Skip evidence citations
- Ignore user's existing habits (use for stacking)
`;

export class WhatIfChatService {
  private async getConversationHistory(userId: string): Promise<any[]> {
    const key = `whatif:chat:${userId}`;
    const raw = await redis.get(key);
    return raw ? JSON.parse(raw) : [];
  }

  private async saveConversationHistory(userId: string, messages: any[]) {
    const key = `whatif:chat:${userId}`;
    await redis.set(key, JSON.stringify(messages), "EX", 3600 * 24 * 7); // 7 days
  }

  private detectConversationType(message: string, habits: any[]) {
    const lowerMsg = message.toLowerCase();
    
    // Check if asking about existing habit
    const mentionedHabit = habits.find(h => 
      lowerMsg.includes(h.title.toLowerCase())
    );
    if (mentionedHabit) {
      return { type: "existing_habit", habit: mentionedHabit };
    }
    
    // Check for new habit intent
    if (/start|begin|new|want to|trying to|how do i/i.test(message)) {
      return { type: "new_habit" };
    }
    
    // Check for goal planning
    if (/plan|goal|achieve|steps|roadmap|what if/i.test(message)) {
      return { type: "goal_planning" };
    }
    
    // Check for troubleshooting
    if (/stuck|failing|can't|struggling|quit|stop|give up/i.test(message)) {
      return { type: "troubleshooting" };
    }
    
    return { type: "general" };
  }

  async chat(userId: string, userMessage: string, preset?: 'simulator' | 'habit-master'): Promise<{ message: string; suggestedPlan?: any; splitFutureCard?: string; sources?: string[] }> {
    // Get user context
    const [identity, ctx, history] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
      this.getConversationHistory(userId),
    ]);

    // Select system prompt based on preset (default to habit-master)
    const systemPrompt = preset === 'simulator' 
      ? SYSTEM_PROMPT_WHAT_IF_SIMULATOR 
      : SYSTEM_PROMPT_HABIT_MASTER;
    
    // Store preset in history for context continuity
    const currentPreset = preset || history.find((m: any) => m.preset)?.preset || 'habit-master';

    const conversationType = this.detectConversationType(userMessage, ctx.habitSummaries);

    // Build context
    const contextString = `
USER PROFILE:
Name: ${identity.name}
Purpose: ${identity.purpose || "discovering"}
Core Values: ${identity.coreValues?.join(", ") || "not defined"}
Burning Question: ${identity.burningQuestion}

HABIT DATA:
Active Habits (for stacking): ${ctx.habitSummaries.filter(h => h.streak > 0).map(h => `${h.title} (${h.streak} day streak)`).join(", ") || "none"}
Strongest Habit (use as anchor): ${ctx.habitSummaries.sort((a,b) => b.streak - a.streak)[0]?.title || "none"}
Struggling With: ${ctx.habitSummaries.filter(h => h.streak === 0 && h.ticks30d > 5).map(h => `${h.title} (tried ${h.ticks30d} times, gave up)`).join(", ") || "none"}

CONVERSATION TYPE: ${conversationType.type}
${conversationType.habit ? `MENTIONED HABIT: ${conversationType.habit.title} (streak: ${conversationType.habit.streak}, 30d ticks: ${conversationType.habit.ticks30d})` : ""}

CONVERSATION HISTORY (last 6 exchanges):
${history.slice(-12).map((m: any) => `${m.role}: ${m.content}`).join("\n")}

TASK: Generate cinematic, evidence-based responses. Cite peer-reviewed studies naturally.
`;

    // Add user message to history with preset
    history.push({ role: "user", content: userMessage, timestamp: new Date().toISOString(), preset: currentPreset });

    // Combine system prompt with context
    const fullSystemPrompt = `${systemPrompt}\n\n${contextString}`;

    // Call AI Router (whatif = medium reasoning + high verbosity for simulator, habit = medium/medium for coach)
    const aiRouterPreset = preset === 'simulator' ? 'whatif' : 'habit';
    const aiResponse = await aiRouter.callAI({
      preset: aiRouterPreset,
      systemPrompt: fullSystemPrompt,
      userInput: userMessage,
      userId,
      parseJson: false, // What-If uses markdown, not JSON
    });

    const responseText = aiResponse.chat || "Let's break this down systematically.";

    // Extract sources/citations from response (aiRouter already does this)
    const sources = aiResponse.sources || [];
    
    // Detect Split-Future Card (aiRouter already extracts this)
    const splitFutureCard = aiResponse.splitFutureCard || this.extractSplitFutureCard(responseText);

    // Save to history
    history.push({ role: "assistant", content: responseText, timestamp: new Date().toISOString() });
    await this.saveConversationHistory(userId, history);

    // Log event
    await prisma.event.create({
      data: {
        userId,
        type: "whatif_chat",
        payload: { userMessage, aiResponse: responseText, conversationType: conversationType.type, preset: currentPreset, sources },
      },
    });

    // Check if user wants a plan generated (expanded trigger words)
    let suggestedPlan = null;
    const wantsPlan = /yes|yeah|sure|okay|ok|let'?s do it|i'?m ready|create (a )?plan|make (a )?plan|generate|give me (a )?plan/i.test(userMessage);
    
    // Also check if AI asked if they want a plan in previous message
    const aiAskedForPlan = history.length >= 2 && 
      /would you like me to create|want me to (create|make)|ready for (a )?plan|shall i (create|generate)/i.test(history[history.length - 2]?.content || '');
    
    if ((wantsPlan && aiAskedForPlan) || /create (a )?plan|generate plan/i.test(userMessage)) {
      // Extract goal description from conversation context
      const goalContext = history.slice(-6).map(m => m.content).join("\n");
      suggestedPlan = await this.generatePlan(userId, goalContext, history, currentPreset);
    }

    return { message: responseText, suggestedPlan, splitFutureCard, sources };
  }

  private extractSources(text: string): string[] {
    // Extract citations like "Walker 2017", "Harvard Study 2019", etc.
    const sourcePattern = /([A-Z][a-zA-Z]+\s+\d{4}|[A-Z][a-zA-Z]+\s+[A-Z][a-zA-Z]+\s+\d{4}|[A-Z][a-zA-Z]+\s+et\s+al\.\s+\d{4})/g;
    const matches = text.match(sourcePattern) || [];
    return [...new Set(matches)]; // Remove duplicates
  }

  private extractSplitFutureCard(text: string): string | undefined {
    // Extract markdown tables that contain "Stay Same" and "Commit" columns
    const tablePattern = /\|[^\n]+Stay Same[^\n]+Commit[^\n]+\|[\s\S]+?(?=\n\n|\n[^|]|$)/i;
    const match = text.match(tablePattern);
    return match ? match[0] : undefined;
  }

  private async generatePlan(userId: string, goalDescription: string, history: any[], preset: string): Promise<any> {

    const identity = await memoryService.getIdentityFacts(userId);
    const ctx = await memoryService.getUserContext(userId);

    // Different prompts for different presets
    const simulatorPrompt = `
USER: ${identity.name}
GOAL: ${goalDescription}
PURPOSE: ${identity.purpose}
EXISTING HABITS: ${ctx.habitSummaries.map(h => h.title).join(", ")}
CONVERSATION CONTEXT: ${history.slice(-4).map((m: any) => m.content).join("\n")}

Generate a SPLIT-FUTURE CARD + NEXT-BEST ACTION CARD in JSON format.

Return ONLY valid JSON:
{
  "title": "...",
  "subtitle": "...",
  "icon": "...",
  "splitFutureMetrics": [
    { "metric": "⚡ Energy", "staySame": "63%", "commit": "86%", "delta": "+23 pts", "evidence": "Walker 2017 Sleep Med Rev" }
  ],
  "nextBestActions": [
    { "action": "🕐 Tonight → bed by 23 (no screen)", "benefit": "adherence ↑ 95%" }
  ],
  "sevenDayImpact": "+8 ⚡ Energy | +4 😊 Mood | −10% 🍩 Cravings",
  "confidence": "🟢 High (±10%)"
}
`;

    const habitMasterPrompt = `
USER: ${identity.name}
GOAL: ${goalDescription}
PURPOSE: ${identity.purpose}
EXISTING HABITS: ${ctx.habitSummaries.map(h => h.title).join(", ")}
CONVERSATION CONTEXT: ${history.slice(-4).map((m: any) => m.content).join("\n")}

Generate a 3-PHASE PLAN with evidence-backed steps in JSON format.

RULES:
- Title: Clear, 2-3 words (e.g., "Digital Detox", "Morning Pages")
- Subtitle: ONE benefit (e.g., "Reduce stress by 40%")
- Icon: ONE emoji
- Plan: Variable length 1-8 steps based on complexity
- Cite peer-reviewed studies naturally (e.g., "Harvey 2017 Sleep Health", "Schoenfeld 2021 Sports Med")

Return ONLY valid JSON:
{
  "title": "...",
  "subtitle": "...",
  "icon": "...",
  "plan": [
    { "action": "...", "why": "...", "study": "..." }
  ],
  "duration_estimate": "12 weeks"
}
`;

    const prompt = preset === 'simulator' ? simulatorPrompt : habitMasterPrompt;

    try {
      // Call AI Router for plan generation (parse JSON)
      const aiRouterPreset = preset === 'simulator' ? 'whatif' : 'habit';
      const aiResponse = await aiRouter.callAI({
        preset: aiRouterPreset,
        systemPrompt: "Generate cinematic, evidence-based plans. Cite real peer-reviewed studies. Output valid JSON only.",
        userInput: prompt,
        userId,
        parseJson: true,
      });

      const raw = aiResponse.rawOutput || "{}";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      const plan = JSON.parse(cleaned);

      await prisma.event.create({
        data: {
          userId,
          type: "whatif_plan_generated",
          payload: { ...plan, preset } as any,
        },
      });

      return plan;
    } catch (err) {
      console.warn("Failed to generate plan:", err);
      return null;
    }
  }

  async clearHistory(userId: string) {
    const key = `whatif:chat:${userId}`;
    await redis.del(key);
    return { success: true };
  }
}

export const whatIfChatService = new WhatIfChatService();

