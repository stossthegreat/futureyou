import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { aiService } from "./ai.service";
import { memoryService } from "./memory.service";
import { purposePrompts } from "../modules/purpose/prompt.templates";
import OpenAI from "openai";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) return null;
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey });
}

type HabitSuggestion = {
  title: string;
  type: "habit" | "task";
  time: string;
  emoji?: string;
  importance: number;
  reasoning: string;
};

export class ChatService {
  private async extractPurposeFromDiscovery(userId: string, allAnswers: Record<string, string>) {
    const openai = getOpenAIClient();
    if (!openai) return null;

    const prompt = `
CONTEXT: User completed life purpose discovery. Their answers:
${JSON.stringify(allAnswers, null, 2)}

TASK: Extract their core identity and purpose.
Return ONLY valid JSON:
{
  "purpose": "One sentence: their distilled life purpose",
  "coreValues": ["value1", "value2", "value3"],
  "vision": "What their ideal day looks like (2 sentences)",
  "funeralWish": "What they want said at their funeral",
  "biggestFear": "What they're most afraid of",
  "whyNow": "Why they're starting this journey now"
}
`;

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.2,
      max_tokens: 500,
      messages: [
        { role: "system", content: "Extract identity insights from discovery conversations. Output only JSON." },
        { role: "user", content: prompt },
      ],
    });

    try {
      const raw = completion.choices[0]?.message?.content?.trim() || "{}";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      return JSON.parse(cleaned);
    } catch (err) {
      console.warn("Failed to extract purpose:", err);
      return null;
    }
  }

  async nextMessage(userId: string, userInput: string) {
    const key = `chatstate:${userId}`;
    const raw = await redis.get(key);
    const state = raw ? JSON.parse(raw) : { phase: "intro", context: { answers: {} } };

    // store user answer
    state.context.answers[state.phase] = userInput;

    // decide next phase
    const order = ["intro", "funeral", "values", "vision", "commitment"];
    const currentIdx = order.indexOf(state.phase);
    const nextIdx = Math.min(currentIdx + 1, order.length - 1);
    const nextPhase = order[nextIdx];

    // NEW: If completing discovery, extract and store purpose
    if (state.phase === "commitment" && currentIdx === order.length - 1) {
      const insights = await this.extractPurposeFromDiscovery(userId, state.context.answers);
      if (insights) {
        await memoryService.upsertFacts(userId, {
          identity: {
            ...insights,
            discoveryCompletedAt: new Date().toISOString(),
          },
        });
        
        await prisma.event.create({
          data: { userId, type: "discovery_completed", payload: insights },
        });
      }
    }

    const prompt = purposePrompts[nextPhase];
    const message = await aiService.generateFutureYouReply(userId, prompt, {
      purpose: "coach",
      maxChars: 800, // Increased for better responses
    });

    // 🚀 Extract habit suggestions from conversation
    const suggestions = await this.extractHabitSuggestions(userId, userInput, message);

    // persist
    state.phase = nextPhase;
    await redis.set(key, JSON.stringify(state), "EX", 3600 * 6); // 6h session TTL

    await prisma.event.create({
      data: { userId, type: "chat_message", payload: { from: "ai", text: message, suggestions } },
    });

    return { phase: nextPhase, message, suggestions };
  }

  /**
   * 🧠 Extract actionable habit suggestions from conversation using AI
   */
  private async extractHabitSuggestions(
    userId: string,
    userInput: string,
    aiResponse: string
  ): Promise<HabitSuggestion[]> {
    // Check if conversation mentions habits, goals, or commitments
    const keywords = /(want to|need to|should|goal|habit|daily|every day|morning|evening|workout|meditate|read|write|wake up)/i;
    if (!keywords.test(userInput)) {
      return [];
    }

    try {
      const suggestion = await aiService.extractHabitFromConversation(userId, userInput, aiResponse);
      return suggestion ? [suggestion] : [];
    } catch (err) {
      console.warn("Failed to extract habits:", err);
      return [];
    }
  }

  /**
   * 🎯 Create a habit from AI suggestion
   */
  async createHabitFromSuggestion(userId: string, suggestion: HabitSuggestion) {
    const habit = await prisma.habit.create({
      data: {
        userId,
        title: suggestion.title,
        schedule: {
          type: suggestion.type,
          time: suggestion.time,
          repeatDays: [0, 1, 2, 3, 4, 5, 6], // Daily by default
        },
        context: {
          emoji: suggestion.emoji || "⭐",
          importance: suggestion.importance,
          reasoning: suggestion.reasoning,
          source: "ai_chat",
        },
        streak: 0,
      },
    });

    await prisma.event.create({
      data: {
        userId,
        type: "habit_created",
        payload: { habitId: habit.id, source: "ai_chat", suggestion },
      },
    });

    return habit;
  }
}

export const chatService = new ChatService();
