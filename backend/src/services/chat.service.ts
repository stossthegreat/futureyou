import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { aiService } from "./ai.service";
import { purposePrompts } from "../modules/purpose/prompt.templates";

type HabitSuggestion = {
  title: string;
  type: "habit" | "task";
  time: string;
  emoji?: string;
  importance: number;
  reasoning: string;
};

export class ChatService {
  async nextMessage(userId: string, userInput: string) {
    const key = `chatstate:${userId}`;
    const raw = await redis.get(key);
    const state = raw ? JSON.parse(raw) : { phase: "intro", context: { answers: {} } };

    // store user answer
    state.context.answers[state.phase] = userInput;

    // decide next phase
    const order = ["intro", "funeral", "values", "vision", "commitment"];
    const nextIdx = Math.min(order.indexOf(state.phase) + 1, order.length - 1);
    const nextPhase = order[nextIdx];

    const prompt = purposePrompts[nextPhase];
    const message = await aiService.generateFutureYouReply(userId, prompt, {
      purpose: "coach",
      maxChars: 800, // Increased for better responses
    });

    // 🚀 NEW: Extract habit suggestions from conversation
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
