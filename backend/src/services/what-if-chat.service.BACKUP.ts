import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";
import OpenAI from "openai";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) return null;
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey });
}

/**
 * 🔬 WHAT-IF IMPLEMENTATION COACH
 * 
 * Scientific authority on habit implementation:
 * - Context detection (new habit vs existing vs multi-step goal)
 * - ONLY cites real studies and books
 * - Variable plan length (1-8 steps based on complexity)
 * - Habit stacking with user's existing habits
 * - Troubleshooting based on actual failure patterns
 */

const APPROVED_SOURCES = {
  books: [
    "Atomic Habits (James Clear)",
    "Tiny Habits (BJ Fogg)",
    "Deep Work (Cal Newport)",
    "Power of Habit (Charles Duhigg)",
    "Willpower Instinct (Kelly McGonigal)",
    "Good Habits Bad Habits (Wendy Wood)",
    "Indistractable (Nir Eyal)",
    "The ONE Thing (Gary Keller)",
  ],
  studies: [
    "Stanford Behavior Lab",
    "Harvard Medical School",
    "NIH (National Institutes of Health)",
    "Mayo Clinic",
    "Sleep Foundation",
    "Exercise Science Journal",
    "Behavioral Economics Research",
    "Cognitive Psychology Studies",
    "Neuroscience Journal",
    "Journal of Applied Psychology",
  ],
  researchers: [
    "BJ Fogg (Stanford)",
    "James Clear",
    "Charles Duhigg",
    "Cal Newport",
    "Kelly McGonigral",
    "Wendy Wood (USC)",
    "Roy Baumeister",
    "Peter Gollwitzer",
    "Mihály Csíkszentmihályi",
  ],
};

const WHAT_IF_SYSTEM_PROMPT = `
You are the What-If Architect — a master of behavior change and goal implementation.

Your expertise:
- Habit formation science (Atomic Habits, BJ Fogg's Tiny Habits)
- Goal setting research (Locke & Latham, SMART framework)
- Willpower studies (Roy Baumeister, Kelly McGonigal)
- Implementation intentions (Peter Gollwitzer)

Your tone: Confident, authoritative, scientific. You speak ONLY from evidence.

APPROVED SOURCES ONLY:
Books: ${APPROVED_SOURCES.books.join(", ")}
Studies: ${APPROVED_SOURCES.studies.join(", ")}
Researchers: ${APPROVED_SOURCES.researchers.join(", ")}

CONVERSATION FLOW (CRITICAL):
1. **UNDERSTAND FIRST** - Ask 2-3 deep questions:
   - What's their real "why"? (connect to purpose if available)
   - What's stopped them before?
   - What's their realistic timeline/context?
2. **BUILD CONFIDENCE** - Show you understand their situation
3. **OFFER PLAN** - Only after understanding, ask: "Based on your purpose/situation, would you like me to create a concrete plan with science-backed steps you can commit to right now?"
4. **GENERATE** - ONLY after they say YES, create plan

RULES:
1. NEVER jump straight to plans - ask questions first
2. ALWAYS cite real studies or books from approved list
3. Detect habit type and respond accordingly:
   - NEW HABIT: Ask about triggers, past attempts, realistic time
   - EXISTING HABIT STRUGGLING: Analyze their data, ask what broke
   - MULTI-STEP GOAL: Break down complexity, ask about constraints
4. Reference their EXISTING habits to create stacks
5. Max 5 sentences of explanation (unless answering questions)
6. Be specific and actionable

PLAN GENERATION FORMAT:
When user confirms they want a plan, respond with:
"I'll create a plan for you. Give me one moment..."

Then call the generatePlan function. DO NOT output JSON directly in the chat.

NEVER:
- Output raw JSON in conversation
- Jump to plans without understanding first
- Make up studies or citations
- Give vague advice
- Reference sources not in approved list
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

  async chat(userId: string, userMessage: string): Promise<{ message: string; suggestedPlan?: any }> {
    const openai = getOpenAIClient();
    if (!openai) return { message: "What-If Architect is unavailable — try again later." };

    // Get user context
    const [identity, ctx, history] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
      this.getConversationHistory(userId),
    ]);

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

TASK: Respond with scientific authority. Use only approved sources listed in system prompt.
`;

    // Add user message to history
    history.push({ role: "user", content: userMessage, timestamp: new Date().toISOString() });

    // Generate response
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: "system", content: WHAT_IF_SYSTEM_PROMPT },
      { role: "system", content: contextString },
      ...history.slice(-8).map((m: any) => ({
        role: m.role === "user" ? "user" as const : "assistant" as const,
        content: m.content,
      })),
    ];

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.5,
      max_tokens: 400,
      messages,
    });

    const aiResponse = completion.choices[0]?.message?.content?.trim() || "Let's break this down systematically.";

    // Save to history
    history.push({ role: "assistant", content: aiResponse, timestamp: new Date().toISOString() });
    await this.saveConversationHistory(userId, history);

    // Log event
    await prisma.event.create({
      data: {
        userId,
        type: "whatif_chat",
        payload: { userMessage, aiResponse, conversationType: conversationType.type },
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
      suggestedPlan = await this.generatePlan(userId, goalContext, history);
    }

    return { message: aiResponse, suggestedPlan };
  }

  private async generatePlan(userId: string, goalDescription: string, history: any[]): Promise<any> {
    const openai = getOpenAIClient();
    if (!openai) return null;

    const identity = await memoryService.getIdentityFacts(userId);
    const ctx = await memoryService.getUserContext(userId);

    const prompt = `
USER: ${identity.name}
GOAL: ${goalDescription}
PURPOSE: ${identity.purpose}
EXISTING HABITS: ${ctx.habitSummaries.map(h => h.title).join(", ")}
CONVERSATION CONTEXT: ${history.slice(-4).map((m: any) => m.content).join("\n")}

Create a science-backed implementation plan in JSON format.

RULES:
1. Title: Clear, 2-3 words (e.g., "Digital Detox", "Morning Pages")
2. Subtitle: ONE benefit (e.g., "Reduce stress by 40%")
3. Icon: ONE emoji
4. Plan: Variable length 1-8 steps based on complexity:
   - Simple goals (meditate daily): 2-3 steps
   - Medium goals (write a book): 4-6 steps
   - Complex goals (career change): 7-8 steps

Each step MUST have:
- action: Specific, measurable, time-bound
- why: Science-backed reason
- study: Real citation from approved list

APPROVED SOURCES ONLY:
Books: Atomic Habits, Deep Work, Tiny Habits, Power of Habit, Willpower Instinct
Studies: Stanford Behavior Lab, Harvard Medical, NIH, Mayo Clinic, Sleep Foundation, Exercise Science Journal
Researchers: James Clear, BJ Fogg, Charles Duhigg, Cal Newport, Kelly McGonigal

Return ONLY valid JSON:
{
  "title": "...",
  "subtitle": "...",
  "icon": "...",
  "plan": [
    { "action": "...", "why": "...", "study": "..." }
  ]
}
`;

    try {
      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        temperature: 0.7,
        max_tokens: 1000,
        messages: [
          { role: "system", content: "Generate implementation plans with ONLY approved citations. Output valid JSON only." },
          { role: "user", content: prompt },
        ],
      });

      const raw = completion.choices[0]?.message?.content?.trim() || "{}";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      const plan = JSON.parse(cleaned);

      // Validate citations
      const validPlan = this.validateCitations(plan);

      await prisma.event.create({
        data: {
          userId,
          type: "whatif_plan_generated",
          payload: validPlan,
        },
      });

      return validPlan;
    } catch (err) {
      console.warn("Failed to generate plan:", err);
      return null;
    }
  }

  private validateCitations(plan: any): any {
    // Ensure all citations reference approved sources
    if (!plan.plan || !Array.isArray(plan.plan)) return plan;

    plan.plan = plan.plan.map((step: any) => {
      const study = step.study || "";
      const isValidSource = 
        APPROVED_SOURCES.books.some(b => study.toLowerCase().includes(b.toLowerCase().split("(")[0].trim().toLowerCase())) ||
        APPROVED_SOURCES.studies.some(s => study.toLowerCase().includes(s.toLowerCase())) ||
        APPROVED_SOURCES.researchers.some(r => study.toLowerCase().includes(r.toLowerCase().split("(")[0].trim().toLowerCase()));

      if (!isValidSource) {
        console.warn(`Invalid citation detected: ${study}`);
        step.study = "Research-backed"; // Fallback to generic if invalid
      }

      return step;
    });

    return plan;
  }

  async clearHistory(userId: string) {
    const key = `whatif:chat:${userId}`;
    await redis.del(key);
    return { success: true };
  }
}

export const whatIfChatService = new WhatIfChatService();

