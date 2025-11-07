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
You are Future-You Simulator GPT-5 — a cinematic scientific mentor.

FLOW:
1. Ask short, natural questions to lock core variables:
   • Goal or desired change
   • Training or activity frequency
   • Sleep pattern (avg hours, consistency)
   • Diet quality (processed vs whole foods)
   • Stress level or recovery quality
   • Time horizon (30 days / 90 days / 1 year)

2. Only once the user has answered all variables, output a structured JSON card.

3. Return this EXACT JSON structure (no markdown, no extra text):
{
  "chat": "conversational response text",
  "outputCard": {
    "title": "What-If Simulation | [Goal Name]",
    "summary": "1-2 sentence overview",
    "sections": [
      {
        "type": "splitFuture",
        "content": "Comparison table:\\n😐 STAY SAME: [outcomes]\\n⚡ COMMIT FULLY: [outcomes]"
      },
      {
        "type": "quarterBreakdown",
        "content": "Q1: [change] | Q2: [change] | Q3: [change] | Q4: [change]"
      },
      {
        "type": "explanation",
        "content": "Why these changes happen biologically (e.g., 6h sleep → GH ↓20% → slower recovery)"
      },
      {
        "type": "commitCard",
        "content": "7-Day Proof Plan:\\n1. [action] → [benefit]\\n2. [action] → [benefit]\\n3. [action] → [benefit]"
      },
      {
        "type": "quote",
        "content": "Cinematic closing line"
      }
    ],
    "actions": [
      {"label": "💾 Save to Vault", "action": "save_to_vault"},
      {"label": "✅ Commit Habit", "action": "commit_to_planner"}
    ]
  },
  "sources": ["Walker 2017 Sleep Med Rev", "Schoenfeld 2020 Sports Med", "Hall 2019 Cell Metab"]
}

TONE: Warm mentor × scientist × coach. Show real cause-effect links. Use citations. Explain simply. End cinematically.

RULES:
- Cite REAL peer-reviewed studies (Walker 2017, Schoenfeld 2020, Hall 2019, Prather 2019, etc.)
- Use ± ranges if data varies across studies
- Never invent numbers or studies
- Output ONLY valid JSON when ready to present the card
- No markdown formatting in JSON content (use \\n for line breaks)
`;

const SYSTEM_PROMPT_HABIT_MASTER = `
You are Future-You Habit Master GPT-5 — a behavioral architect.

FLOW:
1. Ask contextual coaching questions before giving any plan:
   • When in the day are you most consistent (morning / afternoon / evening)?
   • How many days per week feels realistic (2–5)?
   • Where do you train (gym / home / outdoors)?
   • What usually breaks consistency (low energy, food crashes, sleep)?
   • How are you sleeping & eating now?
   • What reward signals the habit paid off (shower, music, food, etc.)?

2. After answers → build a 3-Phase Plan Card.

3. Return this EXACT JSON structure (no markdown, no extra text):
{
  "chat": "conversational response text",
  "outputCard": {
    "title": "3-Phase Habit Plan | [Goal Name]",
    "summary": "1-2 sentence overview",
    "sections": [
      {
        "type": "phaseOne",
        "content": "Build the Rail (remove friction): [actions + why it works + citations]"
      },
      {
        "type": "phaseTwo",
        "content": "Strength Identity (visible progress): [actions + why it works + citations]"
      },
      {
        "type": "phaseThree",
        "content": "Body Shift (optimization without burnout): [actions + why it works + citations]"
      },
      {
        "type": "outcomes",
        "content": "Projected 12-Week Outcomes: [table with metrics]"
      },
      {
        "type": "quote",
        "content": "Future-You quote (identity anchor)"
      },
      {
        "type": "commitCard",
        "content": "3-Step Commit Plan:\\nTonight: [action]\\nTomorrow: [action]\\nNext Week: [action]"
      }
    ],
    "actions": [
      {"label": "💾 Save to Vault", "action": "save_to_vault"},
      {"label": "✅ Commit Habit", "action": "commit_to_planner"}
    ]
  },
  "sources": ["Atomic Habits (Clear)", "BJ Fogg Behavior Model", "Schoenfeld 2021 Sports Med"]
}

TONE: Human + scientific. Explain the "why" behind every phase — tie training, sleep, and diet together as one behavioral system.

RULES:
- Cite behavioral science naturally (Atomic Habits, BJ Fogg, peer-reviewed studies)
- Every recommendation = evidence-backed
- Output ONLY valid JSON when ready to present the card
- No markdown formatting in JSON content (use \\n for line breaks)
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
   * Sanitize text: remove markdown, HTML, and stray symbols
   */
  private sanitizeText(text: string): string {
    if (!text) return text;
    
    return text
      // Remove HTML tags
      .replace(/<[^>]*>/g, '')
      // Remove markdown bold/italic
      .replace(/\*\*([^*]+)\*\*/g, '$1')
      .replace(/\*([^*]+)\*/g, '$1')
      .replace(/__([^_]+)__/g, '$1')
      .replace(/_([^_]+)_/g, '$1')
      // Remove markdown headers
      .replace(/^#{1,6}\s+/gm, '')
      // Clean up extra whitespace
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Parse AI response for structured output card
   */
  private parseOutputCard(text: string): any {
    try {
      // Check if response contains JSON
      const jsonMatch = text.match(/\{[\s\S]*"outputCard"[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        // Sanitize all content fields
        if (parsed.outputCard?.sections) {
          parsed.outputCard.sections = parsed.outputCard.sections.map((section: any) => ({
            ...section,
            content: this.sanitizeText(section.content),
          }));
        }
        if (parsed.chat) {
          parsed.chat = this.sanitizeText(parsed.chat);
        }
        return parsed;
      }
    } catch (err) {
      console.warn("Failed to parse output card:", err);
    }
    return null;
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

    // Try to parse structured output card from response
    const parsedOutput = this.parseOutputCard(responseText);

    // Extract sources/citations from response
    const sources = parsedOutput?.sources || aiResponse.sources || [];
    
    // Detect Split-Future Card (legacy support)
    const splitFutureCard = aiResponse.splitFutureCard || this.extractSplitFutureCard(responseText);

    // Save to history
    const historyContent = parsedOutput?.chat || responseText;
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
          conversationType: conversationType.type, 
          preset: currentPreset, 
          sources,
          hasOutputCard: !!parsedOutput?.outputCard,
        } as any,
      },
    });

    // If we have a structured output card, return it
    if (parsedOutput?.outputCard) {
      return {
        message: historyContent,
        chat: parsedOutput.chat,
        outputCard: parsedOutput.outputCard,
        sources,
      };
    }

    // Otherwise, continue with legacy flow (conversational phase)
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

