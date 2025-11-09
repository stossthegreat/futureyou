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
 * 🎯 FUTURE-YOU FREEFORM CHAT
 * 
 * Multi-lens purpose discovery master with 7 different approaches:
 * 1. Death Perspective (funeral, legacy)
 * 2. Urgency Lens (last day, mortality)
 * 3. Hero's Journey (challenge, calling)
 * 4. Aliveness Compass (energy tracking, flow states)
 * 5. Childhood Archaeology (natural gifts, lost in play)
 * 6. Freedom Test (money/status irrelevant)
 * 7. Aversion Mapping (reverse engineering via what they hate)
 */

const FUTURE_YOU_SYSTEM_PROMPT = `
You are Future You — a master of purpose discovery using 7 proven methods.

YOUR TOOLKIT (choose the right lens for each person):

1. DEATH PERSPECTIVE (long-term legacy):
   - "What do you want said at your funeral?"
   - "What mark do you want to leave on the world?"
   - Reference: Bronnie Ware's "Top 5 Regrets of the Dying"

2. URGENCY LENS (immediate mortality):
   - "If today was your last, what would you regret?"
   - "If you had 6 months to live, what changes?"
   - Reference: Tim Urban's "Life Calendar" concept

3. HERO'S JOURNEY (challenge/calling):
   - "What challenge is calling you to become more?"
   - "What are you avoiding that scares AND excites you?"
   - Reference: Joseph Campbell's monomyth

4. ALIVENESS COMPASS (energy tracking):
   - "When do you feel MOST alive?"
   - "What makes you lose complete track of time?"
   - Reference: Mihály Csíkszentmihályi's Flow research

5. CHILDHOOD ARCHAEOLOGY (natural gifts):
   - "What did you get lost in as a child?"
   - "What came effortlessly to you that others struggled with?"
   - Reference: Ken Robinson's "The Element"

6. FREEDOM TEST (true desires):
   - "What would you do if money wasn't an issue?"
   - "What would you create if no one would ever know?"
   - Reference: Derek Sivers' "Hell Yeah or No"

7. AVERSION MAPPING (reverse engineering):
   - "What don't you like? What drains you?"
   - "What are you sick of pretending to care about?"
   - Reference: Charlie Munger's inversion principle

YOUR APPROACH:

1. Start with whatever lens they respond to first (test 2-3)
2. Notice resistance — if they deflect, switch lenses immediately
3. Build contradiction map: Compare their WORDS vs their HABITS
4. Look for patterns across timeframes (childhood → today → deathbed)
5. Push on energy spikes — when they light up, dig deeper THERE
6. Use Socratic method — NEVER give answers, only sharper questions
7. Maximum 3-4 sentences per response (brevity = power)

CONVERSATION MEMORY:
- Remember EVERY answer they give
- Notice contradictions between different lenses
- Track which lens they resist vs engage with
- Build their "purpose fingerprint" across all 7 dimensions

RULES:
- Ask ONE question at a time
- Reference their habits when they contradict themselves
- Cite the method you're using when switching lenses
- Speak as THEM looking back, not external coach
- Max 4 sentences, ultra-concise

NEVER:
- Give generic motivation
- Provide the answer for them
- Skip over contradictions
- Forget previous answers
- Use multiple lenses in one response
`;

export class FutureYouChatService {
  private async getConversationHistory(userId: string): Promise<any[]> {
    const key = `futureyou:chat:${userId}`;
    const raw = await redis.get(key);
    return raw ? JSON.parse(raw) : [];
  }

  private async saveConversationHistory(userId: string, messages: any[]) {
    const key = `futureyou:chat:${userId}`;
    await redis.set(key, JSON.stringify(messages), "EX", 3600 * 24 * 7); // 7 days
  }

  private async detectContradictions(userId: string, message: string): Promise<string> {
    const ctx = await memoryService.getUserContext(userId);
    const identity = await memoryService.getIdentityFacts(userId);
    
    const contradictions: string[] = [];
    
    // Check habit contradictions
    const activeHabits = ctx.habitSummaries.filter(h => h.streak > 5);
    const droppedHabits = ctx.habitSummaries.filter(h => h.streak === 0 && h.ticks30d > 5);
    
    if (droppedHabits.length > 0) {
      contradictions.push(`Dropped habits: ${droppedHabits.map(h => h.title).join(", ")}`);
    }
    
    // Check values vs behavior
    if (identity.coreValues && identity.coreValues.length > 0) {
      const hasHealthValue = identity.coreValues.some(v => /health|fitness|energy/i.test(v));
      const hasHealthHabit = activeHabits.some(h => /workout|exercise|gym|run|meditate/i.test(h.title));
      
      if (hasHealthValue && !hasHealthHabit) {
        contradictions.push("Says health is core value, but no active health habits");
      }
    }
    
    return contradictions.join("\n");
  }

  async chat(userId: string, userMessage: string): Promise<string> {
    const openai = getOpenAIClient();
    if (!openai) return "Future You is silent right now — try again later.";

    // Get user context
    const [identity, ctx, history] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
      this.getConversationHistory(userId),
    ]);

    const contradictions = await this.detectContradictions(userId, userMessage);

    // Build rich context
    const contextString = `
IDENTITY SNAPSHOT:
Name: ${identity.name}, Age: ${identity.age || "unknown"}
Burning Question: ${identity.burningQuestion || "not yet answered"}
Current Purpose: ${identity.purpose || "discovering"}
Core Values: ${identity.coreValues?.join(", ") || "not yet defined"}
Vision: ${identity.vision || "not yet clarified"}
Discovery Completed: ${identity.discoveryCompleted ? "YES" : "NO"}

BEHAVIOR TRUTH (what they DO, not say):
Active Habits (streak > 0): ${ctx.habitSummaries.filter(h => h.streak > 0).map(h => `${h.title} (${h.streak} days)`).join(", ") || "none"}
Dropped Habits (streak 0, tried recently): ${ctx.habitSummaries.filter(h => h.streak === 0 && h.ticks30d > 5).map(h => h.title).join(", ") || "none"}
Most Consistent: ${ctx.habitSummaries.sort((a,b) => b.streak - a.streak)[0]?.title || "none"}

CONTRADICTIONS DETECTED:
${contradictions || "None yet"}

CONVERSATION HISTORY (last 10 exchanges):
${history.slice(-20).map((m: any) => `${m.role}: ${m.content}`).join("\n")}

AVAILABLE LENSES (reference by name when switching):
Death Perspective, Urgency Lens, Hero's Journey, Aliveness Compass, Childhood Archaeology, Freedom Test, Aversion Mapping
`;

    // Add user message to history
    history.push({ role: "user", content: userMessage, timestamp: new Date().toISOString() });

    // Generate response
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: "system", content: FUTURE_YOU_SYSTEM_PROMPT },
      { role: "system", content: contextString },
      ...history.slice(-10).map((m: any) => ({
        role: m.role === "user" ? "user" as const : "assistant" as const,
        content: m.content,
      })),
    ];

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      // temperature: removed - GPT-5-mini only supports default (1)
      max_completion_tokens: 300,
      messages,
    });

    const aiResponse = completion.choices[0]?.message?.content?.trim() || "Keep going.";

    // Save to history
    history.push({ role: "assistant", content: aiResponse, timestamp: new Date().toISOString() });
    await this.saveConversationHistory(userId, history);

    // Log event
    await prisma.event.create({
      data: {
        userId,
        type: "futureyou_chat",
        payload: { userMessage, aiResponse, contradictions },
      },
    });

    return aiResponse;
  }

  async clearHistory(userId: string) {
    const key = `futureyou:chat:${userId}`;
    await redis.del(key);
    return { success: true };
  }
}

export const futureYouChatService = new FutureYouChatService();

