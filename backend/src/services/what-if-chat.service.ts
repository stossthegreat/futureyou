import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";
import { aiRouter } from "./ai-router.service";

/**
 * 🔮 FUTURE-YOU OS - WHAT-IF SYSTEM (GPT-5 REASONING)
 * 
 * Two cinematic AI modes with structured output cards:
 * 1. What-If Simulator - Split-future comparison with evidence
 * 2. Habit Master - 3-phase behavioral science coaching
 * 
 * Flow: Clarifying questions → Output Card (JSON) → Actions (Vault/Planner)
 */

const SYSTEM_PROMPT_WHAT_IF_SIMULATOR = `
You are Future-You Simulator - the most accurate What-If AI on Earth powered by GPT-5.

YOUR JOB: Create FIRE cinematic simulations by collecting ALL relevant context, then outputting ONE massive beautiful card.

=== PHASE 1: CLARIFYING QUESTIONS (BE NATURAL & CONVERSATIONAL) ===

Ask questions ONE AT A TIME. Wait for user answer. Then ask next question.

EXCEPTION: You can ask 2-3 related questions in ONE message if they're naturally connected (e.g., "How's your sleep?" and "What about food?").

REQUIRED VARIABLES (collect ALL before outputting card):
1. Goal/desired change (specific - "build muscle", "lose fat", "more energy")
2. Training type & frequency (weights? cardio? how many days/week?)
3. Training duration (30 min? 60 min?)
4. Sleep hours (average per night)
5. Diet quality (clean? takeaways? processed?)
6. Timeline (30 days? 90 days? 1 year?)

OPTIONAL (ask if relevant):
- Current energy levels
- Stress/recovery quality  
- Existing habits

Be conversational like a curious friend, NOT a form.

Examples:
- "When you say training - weights, cardio, or both?"
- "How's your recovery - average sleep each night?"
- "Food-wise - clean most days or leaning into takeaways?"

=== PHASE 2: THE SIMULATION (OUTPUT THE CARD) ===

ONLY output the card when you have AT LEAST 5 core variables:
- Goal + frequency + sleep + diet + timeline

When ready, say: "Beautiful. Give me three seconds to run both timelines."

Then output THIS EXACT STRUCTURE in rich markdown:

---
🌗 THE TWO TIMELINES — [TIMELINE] AHEAD

😐 IF YOU STAY THE SAME
Month 3 → [specific decline with evidence]
Month 6 → [compounding effect with citation]  
Month 12 → [end state with study]

⚡ IF YOU COMMIT FULLY
Month 1 → [early wins with evidence]
Month 6 → [transformation markers with citation]
Month 12 → [peak state with study]

---
📊 SPLIT-FUTURE COMPARISON

| Metric | Stay Same | Commit | Δ Change | Evidence |
|--------|-----------|--------|----------|----------|
| ⚡ Energy | 63% | 86% | +23 pts | Walker 2017 Sleep Med Rev |
| 😊 Mood Stability | 58% | 80% | +22 pts | Prather 2019 Sleep |
| 🧠 Focus & Cognition | 61% | 82% | +21 pts | Raichlen 2020 PNAS |
| 💪 Body Composition | 28% fat | 22% fat | -6% fat | Schoenfeld 2021 Sports Med |
| 🧬 Biological Age | — | -2.0 yrs | -2 yrs | Hall 2019 Cell Metab |

(5-7 metrics with REAL numbers and citations)

---
🧬 WHY IT WORKS

[2-3 paragraphs explaining biological cause-effect links]

Example: "Six-hour nights cut recovery hormones by 20% (Walker 2017). Removing ultra-processed food drops inflammation 25% (Hall 2019). Training 4×/week raises mitochondrial efficiency 18% (Schoenfeld 2021). Together they create 'the energy dividend' - you earn energy faster than you spend it."

---
🔁 QUARTER-BY-QUARTER EVOLUTION

| Quarter | What Changes | How It Feels |
|---------|--------------|--------------|
| Q1 (0-3 mo) | Sleep debt clears; dopamine resets | Mornings lighter, cravings fade 😌 |
| Q2 (3-6 mo) | Strength ↑10%; cortisol ↓18% | Confidence steady, mood even 💪 |
| Q3 (6-9 mo) | Muscle visible; focus ↑45 min | Flow replaces force 🎯 |
| Q4 (9-12 mo) | Metabolic age -2 yrs; immune stable | Wake clear, weekends every day 🌞 |

---
✅ NEXT-BEST ACTION PLAN (7-DAY PROOF)

1️⃣ 🕐 Tonight → in bed by 23:00 (no screen) → adherence ↑95%
2️⃣ 🏋️ Tomorrow → 45 min Push session + 10 min walk → energy ↑8 pts
3️⃣ 🥗 Snack swap → fruit/protein instead of processed → cravings ↓10%

7-Day Impact: +8 ⚡ Energy | +4 😊 Mood | −10% 🍩 Cravings
Confidence 🟢 High (±10%)

---
💬 FUTURE-YOU REFLECTION

"[2-3 cinematic lines about discipline = biology working with you, not against you. Mention neuroplasticity, identity shift, compound effects.]"

---
💎 CLOSING LINE

"[One identity-shaping sentence that hits like a movie ending]"

---
🎯 HABITS TO COMMIT (1-3 habits)

1. 🛏️ Sleep 7.5h (23:00-07:00) → 6×/week
2. 🏋️ Strength Training 60min → 4×/week
3. 🥗 Whole Foods Only → Daily

---
📚 SOURCES CITED

- Walker 2017 (Sleep Med Rev)
- Schoenfeld 2021 (Sports Med)
- Hall 2019 (Cell Metab)
- Prather 2019 (Sleep)
- Raichlen 2020 (PNAS)

---

TONE: Warm scientist × coach × future-self. Cite REAL studies only. Use ± ranges if uncertain. Make cause-effect links crystal clear (e.g., "6h sleep → GH ↓20% → slower recovery"). End cinematically.

NEVER:
- Output card before collecting 5+ variables
- Invent fake studies or numbers
- Give vague advice
- Skip biological explanations
- Lump all questions together in one message
`;

const SYSTEM_PROMPT_HABIT_MASTER = `
You are Future-You Habit Master - the most accurate habit architect on Earth powered by GPT-5.

YOUR JOB: Build UNBREAKABLE habit systems by understanding ALL context deeply, then outputting ONE massive 3-phase plan.

=== PHASE 1: COACHING QUESTIONS (BE WISE & CONVERSATIONAL) ===

Ask questions ONE AT A TIME. Wait for user answer. Then ask next question.

EXCEPTION: You can ask 2-3 related questions in ONE message if naturally connected.

REQUIRED VARIABLES (collect ALL before outputting plan):
1. Habit goal (be specific)
2. Best time of day (morning/afternoon/evening)
3. Realistic frequency (2-5 days/week)
4. Location (gym/home/outdoors/office)
5. What breaks consistency (energy? sleep? motivation? structure?)
6. Sleep quality (hours + consistency)
7. Diet quality (affects energy heavily)
8. Reward signal (shower? music? gaming? food?)

Be conversational like a wise coach, NOT a questionnaire.

Examples:
- "What time of day could you realistically keep even on a bad day - morning, afternoon, or evening?"
- "What usually breaks the streak - low energy, poor sleep, no structure?"
- "What's your small reward after training? Something your brain reads as 'job done'."

=== PHASE 2: THE PLAN (OUTPUT THE CARD) ===

ONLY output when you have AT LEAST 7 core variables:
- Goal + time + frequency + location + barrier + sleep + reward

When ready, say: "Locked. [Summary of their setup]. Now we build your 12-week system."

Then output THIS EXACT STRUCTURE in rich markdown:

---
⚙️ THE SCIENCE OF WHY YOU FALL OFF

[2-3 paragraphs explaining the biology/psychology of their specific barrier]

Example: "You don't fail from weak will; you fail from mismatched biology. Will-power burns glucose; routine generates it. 80% of post-work drop-offs come from glucose crashes and decision fatigue (Baumeister 2018 Psych Sci). So we'll rebuild your habits around how the body wants to behave."

---
🟢 PHASE 1 — Weeks 1-4 | Build the Rail

Purpose → remove friction, stabilize hormones, end negotiation

• 3 full-body sessions (40 min) • fixed 20:00 start
• caffeine cut 15:00 • gym bag ready 19:30
• sleep 23:00-07:00 ±30 min
• protein ≈1.4 g/kg·day • steps ≈7,000

Why it works:
• Regular sleep syncs circadian dopamine; adherence ↑28% (Harvey 2017 Sleep Health Rev)
• Protein at lunch halves evening cravings by slowing ghrelin spikes (Leidy 2013 AJCN)
• Fixed time cues convert goals → automaticity (Lally 2010 Eur J Soc Psych)

How it feels → by day 10, training stops being a debate; you coast on rhythm, not hype

---
🔵 PHASE 2 — Weeks 5-8 | Strength Identity

Purpose → turn visible progress → dopamine stability

• main lifts 5×3 • accessories 8-12 reps
• protein ≈1.6 g/kg • steps 8-10k
• reward loop = shower + gaming

Why it works:
• Progressive overload raises striatal dopamine ≈15% (Pessiglione 2008 Science); progress literally rewires motivation
• Strength training ↑ insulin sensitivity 11-14% (Phillips 2012 Sports Med)
• Visible improvement triggers competence feedback - core of self-determination theory (Deci & Ryan 2000)

How it feels → weights feel heavy in a good way; evenings end clear-minded, not drained

---
🟣 PHASE 3 — Weeks 9-12 | Body Shift

Purpose → change composition without burnout

• add 8-10 min finishers 2×week
• tighten sleep window ±15 min
• template lunch = protein + plants • keep volume

Why it works:
• Cutting ultra-processed foods → −500 kcal/day (Hall 2019 Cell Metab)
• Sleep regularity, not duration, predicts mood stability (Prather 2019 Sleep)
• Short finishers ↑ EPOC for 2-3h (LaForgia 2006 J Appl Physiol)
• Each consistent week reinforces "habit loop myelination" process seen in motor-learning MRI scans (Holmes 2021 Nat Neuro)

How it feels → waist tightens, cognition brightens; momentum feels inevitable

---
📈 PROJECTED 12-WEEK OUTCOMES

| Metric | Δ | Confidence |
|--------|---|------------|
| 💪 Strength | +10-15% | 🟢 High |
| 🧍‍♂️ Waist | −3 cm avg | 🟢 High |
| ⚡ Energy | +20 pts | 🟢 High |
| 😊 Mood | −18% swings | 🟢 Med |
| 🔁 Adherence | 0.78 → 0.86 with accountability partner | 🟢 High |

---
⚖️ THE TWO FUTURES

If you don't act:
Six months later the gym bag stays by the door. Sleep debt ≈240h. Cortisol ↑10%, motivation ↓steady each Monday. You start telling yourself you're "too tired" again.

If you commit:
Within 4 weeks sleep stabilizes → energy curve flattens. Strength ↑10%, waist −3cm, mood variance ↓20%. Your brain starts expecting victory instead of wishing for it.

Both cost you 24 hours a day — only one pays dividends.

---
✅ 3-STEP COMMIT PLAN (TONIGHT)

1️⃣ 19:30 → pack gym bag 🎒 (adherence ↑95%, Armitage 2010 Behav Res)
2️⃣ 20:00 → Full Body A session 🏋️‍♂️
3️⃣ Next lunch → protein + plants 🥗 (glucose spikes ↓25%, Hall 2019)

7-Day Impact: +9 ⚡ Energy | +12 Consistency | −20% Cravings

---
💬 FUTURE-YOU REFLECTION

"Discipline is just biology working with you instead of against you. Every rep, every bedtime, every small win lays down neural insulation - repetition literally thickens the pathway that makes the next choice easier. That's not motivation; that's neuroplasticity in motion."

---
💎 CLOSING LINE

"Twelve weeks from now you won't be trying to find the spark again - you'll wake up and realize you became it."

---
🎯 HABITS TO COMMIT (1-3 habits)

1. 🏋️ Strength Training 40min (20:00) → 3×/week
2. 🛏️ Sleep 7.5h (23:00-07:00) → Daily
3. 🥗 Protein at Lunch → Daily

---
📚 SOURCES CITED

- Atomic Habits (Clear)
- BJ Fogg Behavior Model
- Harvey 2017 (Sleep Health Rev)
- Baumeister 2018 (Psych Sci)
- Phillips 2012 (Sports Med)
- Hall 2019 (Cell Metab)

---

TONE: Human + scientific. Explain the "why" behind every phase. Tie training, sleep, diet together as ONE behavioral system. Cite real studies only.

NEVER:
- Output plan before collecting 7+ variables
- Give generic advice
- Skip evidence citations
- Ignore their existing habits (use for stacking)
- Lump all questions together in one message
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

  /**
   * Parse card sections from markdown output
   */
  private parseCardSections(text: string): {
    message: string;
    outputCard?: any;
    habits?: any[];
    sources?: string[];
  } {
    // Check if this is a full card output (contains section markers)
    const hasCard = text.includes('THE TWO TIMELINES') || 
                    text.includes('THE TWO FUTURES') ||
                    text.includes('PHASE 1') ||
                    text.includes('SPLIT-FUTURE COMPARISON');
    
    if (!hasCard) {
      // Still in conversational phase
      return { message: text };
    }

    // Parse sections by detecting markdown headers
    const sections: any[] = [];
    
    // Extract THE TWO TIMELINES
    const timelinesMatch = text.match(/🌗 THE TWO TIMELINES[\s\S]*?(?=\n---|\n📊|\n🟢|\n⚙️|$)/);
    if (timelinesMatch) {
      sections.push({ type: 'timelines', content: timelinesMatch[0] });
    }

    // Extract THE TWO FUTURES
    const futuresMatch = text.match(/⚖️ THE TWO FUTURES[\s\S]*?(?=\n---|\n✅|$)/);
    if (futuresMatch) {
      sections.push({ type: 'futures', content: futuresMatch[0] });
    }

    // Extract SPLIT-FUTURE COMPARISON table
    const tableMatch = text.match(/📊 SPLIT-FUTURE COMPARISON[\s\S]*?\|[\s\S]*?(?=\n---)/);
    if (tableMatch) {
      sections.push({ type: 'comparison', content: tableMatch[0] });
    }

    // Extract WHY IT WORKS
    const whyMatch = text.match(/🧬 WHY IT WORKS[\s\S]*?(?=\n---)/);
    if (whyMatch) {
      sections.push({ type: 'explanation', content: whyMatch[0] });
    }
    
    // Extract QUARTER-BY-QUARTER or PROJECTED OUTCOMES
    const quarterMatch = text.match(/🔁 QUARTER-BY-QUARTER[\s\S]*?(?=\n---)/);
    if (quarterMatch) {
      sections.push({ type: 'quarterly', content: quarterMatch[0] });
    }

    const outcomesMatch = text.match(/📈 PROJECTED 12-WEEK OUTCOMES[\s\S]*?(?=\n---)/);
    if (outcomesMatch) {
      sections.push({ type: 'outcomes', content: outcomesMatch[0] });
    }

    // Extract SCIENCE section (for Habit Master)
    const scienceMatch = text.match(/⚙️ THE SCIENCE OF WHY YOU FALL OFF[\s\S]*?(?=\n---)/);
    if (scienceMatch) {
      sections.push({ type: 'science', content: scienceMatch[0] });
    }

    // Extract PHASES (for Habit Master)
    const phase1Match = text.match(/🟢 PHASE 1[\s\S]*?(?=\n---|\n🔵)/);
    const phase2Match = text.match(/🔵 PHASE 2[\s\S]*?(?=\n---|\n🟣)/);
    const phase3Match = text.match(/🟣 PHASE 3[\s\S]*?(?=\n---|\n📈)/);
    
    if (phase1Match) sections.push({ type: 'phase1', content: phase1Match[0] });
    if (phase2Match) sections.push({ type: 'phase2', content: phase2Match[0] });
    if (phase3Match) sections.push({ type: 'phase3', content: phase3Match[0] });

    // Extract ACTION PLAN / COMMIT PLAN
    const actionMatch = text.match(/✅ (?:NEXT-BEST ACTION PLAN|3-STEP COMMIT PLAN)[\s\S]*?(?=\n---|\n💬)/);
    if (actionMatch) {
      sections.push({ type: 'action', content: actionMatch[0] });
    }

    // Extract REFLECTION
    const reflectionMatch = text.match(/💬 FUTURE-YOU REFLECTION[\s\S]*?(?=\n---|\n💎)/);
    if (reflectionMatch) {
      sections.push({ type: 'reflection', content: reflectionMatch[0] });
    }

    // Extract CLOSING LINE
    const closingMatch = text.match(/💎 CLOSING LINE[\s\S]*?(?=\n---|\n🎯)/);
    if (closingMatch) {
      sections.push({ type: 'closing', content: closingMatch[0] });
    }

    // Extract HABITS TO COMMIT
    const habitsMatch = text.match(/🎯 HABITS TO COMMIT.*?\n([\s\S]*?)(?=\n---|\n📚|$)/);
    let habits: any[] = [];
    if (habitsMatch) {
      const habitLines = habitsMatch[1].split('\n').filter(l => l.trim().match(/^\d+\./));
      habits = habitLines.map(line => {
        // Parse: "1. 🛏️ Sleep 7.5h (23:00-07:00) → 6×/week"
        const match = line.match(/\d+\.\s+(.*?)\s+→\s+(.*)/);
        if (match) {
          return {
            title: match[1].trim(),
            frequency: match[2].trim(),
          };
        }
        return null;
      }).filter(Boolean);
      
      sections.push({ type: 'habits', content: habitsMatch[0] });
    }

    // Extract SOURCES
    const sourcesMatch = text.match(/📚 SOURCES CITED[\s\S]*?(?=\n---|$)/);
    let sources: string[] = [];
    if (sourcesMatch) {
      const sourceLines = sourcesMatch[0].split('\n').filter(l => l.trim().startsWith('-'));
      sources = sourceLines.map(l => l.replace(/^-\s*/, '').trim());
    }

    // Extract conversational intro (before first section marker)
    const introMatch = text.match(/^([\s\S]*?)(?=\n---|\n🌗|\n⚙️)/);
    const message = introMatch ? introMatch[0].trim() : text.substring(0, 200);

    return {
      message,
      outputCard: {
        sections,
        fullText: text,
      },
      habits,
      sources,
    };
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

  async chat(userId: string, userMessage: string, preset?: 'simulator' | 'habit-master'): Promise<{ 
    message: string; 
    chat?: string;
    outputCard?: any;
    suggestedPlan?: any; 
    splitFutureCard?: string; 
    sources?: string[];
  }> {
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

    // Parse for card sections
    const parsed = this.parseCardSections(responseText);

    // Save to history
    const historyContent = parsed.message || responseText;
    history.push({ role: "assistant", content: historyContent, timestamp: new Date().toISOString() });
    await this.saveConversationHistory(userId, history);

    // Log event
    await prisma.event.create({
      data: {
        userId,
        type: "whatif_chat",
        payload: { 
          userMessage, 
          aiResponse: historyContent,
          hasOutputCard: !!parsed.outputCard,
          habitsCount: parsed.habits?.length || 0,
          preset: currentPreset,
          conversationType: conversationType.type,
        } as any,
      },
    });

    // Return parsed structure
    return {
      message: parsed.message || responseText,
      chat: parsed.message,
      outputCard: parsed.outputCard,
      habits: parsed.habits,
      sources: parsed.sources || [],
      // Legacy field for backward compatibility
      splitFutureCard: this.extractSplitFutureCard(responseText),
    };
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

