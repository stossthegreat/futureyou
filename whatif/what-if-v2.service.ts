import OpenAI from "openai";
import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5-mini";

const CITATIONS = {
  books: [
    "Atomic Habits — James Clear",
    "Tiny Habits — BJ Fogg",
    "Deep Work — Cal Newport",
    "The Power of Habit — Charles Duhigg",
    "Indistractable — Nir Eyal",
    "Switch — Chip & Dan Heath"
  ],
  labs: [
    "Stanford Behavior Design Lab (BJ Fogg)",
    "Harvard Medical School Sleep Research",
    "NIH Behavioral Science Program",
    "Stanford Willpower Lab (Kelly McGonigal)",
    "Yale Center for Emotional Intelligence"
  ],
  studies: [
    "Lally et al. (2009) - habit formation averages 66 days",
    "Wood & Neal (2007) - context-dependent automaticity",
    "Gollwitzer (1999) - implementation intentions effectiveness",
    "Baumeister & Tierney (2011) - willpower as muscle theory",
    "Thaler & Sunstein (2008) - choice architecture nudges"
  ]
};

function aiClient() {
  const key = process.env.OPENAI_API_KEY?.trim();
  return key ? new OpenAI({ apiKey: key }) : null;
}

const safeJSON = (raw: string, fb: any = {}) => { 
  try { return JSON.parse(raw); } catch { return fb; } 
};

/**
 * ANALYST BRAIN - Context Classification & Question Generation
 */
const WHAT_IF_ANALYST = `
You are the WHAT-IF ANALYST. Your job: understand user context, classify the situation, and generate strategic questions.

## CONVERSATION TYPES:

1. **new_habit** - User wants to start something new
   - Detection: "want to start", "thinking about", "how do I begin"
   - Questions focus on: triggers, barriers, minimum viable habit

2. **existing_habit** - User has a habit but struggling
   - Detection: "I keep failing", "can't maintain", "used to do"
   - Questions focus on: breakdown point, context changes, friction

3. **goal_planning** - User has a What-If goal, needs a plan
   - Detection: "ready to commit", "how do I achieve", mentions What-If goal
   - Questions focus on: readiness, resources, obstacles

4. **troubleshooting** - Habit failing, needs diagnosis
   - Detection: "stopped working", "hit a wall", "losing momentum"
   - Questions focus on: when failed, what changed, emotional triggers

5. **general** - Exploration, unclear intent
   - Questions focus on: clarifying desire, readiness assessment

## YOUR OUTPUT (JSON ONLY):
{
  "type": "new_habit|existing_habit|goal_planning|troubleshooting|general",
  "context_summary": "1-2 sentences about what you understand",
  "readiness_score": 1-10 (how ready they seem to act),
  "questions": ["Q1 (most important)", "Q2 (secondary)", "Q3 (optional)"],
  "approved_source": "relevant book/study from approved list",
  "note": "brief reasoning for these questions"
}

RULES:
- ALWAYS ask questions before giving solutions
- Questions must be SPECIFIC to their situation
- Cite ONLY approved sources (books/labs/studies provided)
- Readiness <5 → more exploration questions
- Readiness ≥7 → can offer plan after 2-3 exchanges
- NEVER make up studies or sources
`;

/**
 * VOICE BRAIN - Evidence-Based Architect
 */
const WHAT_IF_VOICE = `
You are the WHAT-IF ARCHITECT — an implementation scientist who speaks with calm authority.

YOUR TONE:
- Confident but not cocky
- Evidence-based, citing real research
- Empathetic to struggle
- Direct and actionable

YOUR STRUCTURE:
1. Show you understand their situation (1 sentence)
2. Reference ONE approved source naturally (weave it in, don't force it)
3. Ask the most important question from the analyst
4. Optional: mention secondary question if relevant

CITATION EXAMPLES:
✅ "BJ Fogg's research at Stanford shows the best entry point is after an existing routine..."
✅ "James Clear calls this 'habit stacking' in Atomic Habits..."
✅ "Lally's 2009 study found habit formation averages 66 days, but ranged from 18-254..."
✅ "The NIH Behavioral Science Program emphasizes starting with a 2-minute version..."

❌ DON'T: "Studies show..." (too vague)
❌ DON'T: "Research indicates..." (weasel words)
❌ DON'T: Make up studies or cite things not in approved list

RULES:
- 2-5 sentences TOTAL
- ONE citation per response
- NEVER give unsolicited advice
- Questions first, solutions after understanding
- If readiness ≥8 and context clear → you may offer to create a plan
`;

/**
 * PLAN GENERATION SYSTEM
 */
const PLAN_GENERATOR_PROMPT = `
You are a behavioral scientist creating an implementation plan. 

CONTEXT PROVIDED:
- User's goal
- Their habits, values, purpose
- Conversation history showing their situation

YOUR JOB: Create a variable-length plan (1-8 steps) that's:
1. **Minimally sufficient** - only steps truly needed
2. **Science-backed** - every recommendation citable
3. **Context-aware** - fits their life, not generic

## PLAN FORMAT (JSON):

{
  "title": "Action-oriented title (e.g., 'Build Your Morning Writing Habit')",
  "why_this_works": "2-3 sentences with ONE study citation",
  "plan_type": "new_habit|existing_habit_fix|goal_achievement",
  "duration_estimate": "e.g., '30 days to automaticity'",
  "steps": [
    {
      "action": "Specific, concrete action",
      "why": "Science-backed reason this works",
      "study": "Author/Source from approved list",
      "order": 1
    }
  ]
}

## STEP COUNT GUIDELINES:

**1-2 steps**: Simple trigger changes, tiny habit additions
- Example: "Drink water" → "Put glass by bed at night"

**3-4 steps**: Standard habit formation
- Example: "Morning workout" → Lay clothes, set alarm, 2min start ritual, reward

**5-6 steps**: Complex habits or goal with milestones
- Example: "Write a book" → Daily time block, word count minimum, accountability, rest days, progress tracking

**7-8 steps**: Multi-layered What-If goals with dependencies
- Example: "Launch side business" → Research phase, MVP, testing, feedback, iteration, launch, growth

APPROVED SOURCES FOR CITATIONS:
${JSON.stringify(CITATIONS, null, 2)}

RULES:
- ONLY use approved sources
- Variable length based on complexity
- Every step needs "action + why + study"
- Favor FEWER steps when possible
- Make it COMMITTA BLE (user can say yes to this plan)
`;

export class WhatIfV2Service {
  private ns(userId: string) { return `whatif:v2:${userId}`; }

  async chat(userId: string, message: string) {
    const openai = aiClient();
    if (!openai) return { message: "What-If Architect is offline. Try again soon." };

    // 1. GATHER CONTEXT
    const [identity, ctx] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId)
    ]);

    // 2. LOAD HISTORY
    const key = `${this.ns(userId)}:chat`;
    const history = safeJSON(await redis.get(key) || "[]", []);

    // 3. BUILD ANALYST INPUT
    const analystInput = `
USER MESSAGE: "${message}"

IDENTITY:
${JSON.stringify(identity, null, 2)}

HABITS (last 30 days):
${JSON.stringify(ctx.habitSummaries || [], null, 2)}

RECENT HISTORY (last 5 messages):
${history.slice(-10).map((h: any) => `${h.role}: ${h.content}`).join('\n')}

APPROVED SOURCES:
${JSON.stringify(CITATIONS, null, 2)}

Classify conversation type, assess readiness, generate questions.
`;

    // 4. ANALYST BRAIN
    const a = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.25,
      max_completion_tokens: 300,
      messages: [
        { role: "system", content: WHAT_IF_ANALYST },
        { role: "user", content: analystInput }
      ]
    });

    const analyst = safeJSON(a.choices[0]?.message?.content || "{}", {
      type: "general",
      questions: ["What brings you here today?"],
      approved_source: "Atomic Habits — James Clear"
    });

    // 5. CHECK IF USER IS READY FOR PLAN
    const userWantsPlan = /ready|commit|let's do|create.*plan|give me.*plan/i.test(message);
    const highReadiness = (analyst.readiness_score || 0) >= 8;
    const hasEnoughContext = history.length >= 4; // At least 2 exchanges

    if (userWantsPlan && highReadiness && hasEnoughContext) {
      // Generate structured plan instead of continuing conversation
      const plan = await this.generatePlan(userId, history, identity, ctx);
      
      // Save to history
      const now = new Date().toISOString();
      history.push({ role: "user", content: message, timestamp: now });
      history.push({ 
        role: "assistant", 
        content: "Here's your personalized plan:", 
        timestamp: now, 
        meta: { analyst, plan, type: "plan_generated" } 
      });
      
      await redis.set(key, JSON.stringify(history.slice(-50)), "EX", 3600 * 24 * 30);
      
      await prisma.event.create({
        data: {
          userId,
          type: "whatif_v2_plan_generated",
          payload: { plan, analyst }
        }
      });
      
      return { 
        message: "I've created a science-backed plan for you. Ready to commit?",
        suggestedPlan: plan 
      };
    }

    // 6. VOICE BRAIN (Continue conversation)
    const voiceInput = `
ANALYST STRUCTURE:
${JSON.stringify(analyst, null, 2)}

APPROVED SOURCES:
${JSON.stringify(CITATIONS, null, 2)}

Speak as the What-If Architect. Ask questions, show understanding, cite ONE source.
`;

    const v = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.6,
      max_completion_tokens: 250,
      messages: [
        { role: "system", content: WHAT_IF_VOICE },
        { role: "user", content: voiceInput }
      ]
    });

    const aiText = v.choices[0]?.message?.content?.trim() || 
      "Let's think this through step by step. What matters most to you here?";

    // 7. SAVE HISTORY
    const now = new Date().toISOString();
    history.push({ role: "user", content: message, timestamp: now });
    history.push({ 
      role: "assistant", 
      content: aiText, 
      timestamp: now, 
      meta: { analyst } 
    });
    
    await redis.set(key, JSON.stringify(history.slice(-50)), "EX", 3600 * 24 * 30);

    await prisma.event.create({
      data: {
        userId,
        type: "whatif_v2_chat",
        payload: { aiText, analyst }
      }
    });

    return { message: aiText };
  }

  /**
   * Generate structured plan after conversation establishes context
   */
  private async generatePlan(
    userId: string, 
    history: any[], 
    identity: any, 
    ctx: any
  ) {
    const openai = aiClient();
    if (!openai) throw new Error("OpenAI unavailable");

    const conversationSummary = history
      .slice(-10)
      .map((m: any) => `${m.role}: ${m.content}`)
      .join('\n');

    const planInput = `
CONVERSATION SUMMARY:
${conversationSummary}

USER IDENTITY:
${JSON.stringify(identity, null, 2)}

USER HABITS:
${JSON.stringify(ctx.habitSummaries || [], null, 2)}

Based on this conversation, create a variable-length plan (1-8 steps) that's:
- Minimally sufficient (only what's needed)
- Science-backed (cite approved sources)
- Context-aware (fits their life)

Return JSON ONLY.
`;

    const response = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.3,
      max_completion_tokens: 800,
      messages: [
        { role: "system", content: PLAN_GENERATOR_PROMPT },
        { role: "user", content: planInput }
      ]
    });

    const plan = safeJSON(response.choices[0]?.message?.content || "{}", {
      title: "Your Personalized Plan",
      steps: [
        {
          action: "Start small and build from there",
          why: "Consistency beats intensity",
          study: "Atomic Habits — James Clear",
          order: 1
        }
      ]
    });

    return plan;
  }

  async clearHistory(userId: string) {
    await redis.del(`${this.ns(userId)}:chat`);
    return { success: true };
  }
}

export const whatIfV2Service = new WhatIfV2Service();

