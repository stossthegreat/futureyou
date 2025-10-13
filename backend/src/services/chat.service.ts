import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { aiService } from "./ai.service";
import { purposePrompts } from "../modules/purpose/prompt.templates";

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
      maxChars: 600,
    });

    // persist
    state.phase = nextPhase;
    await redis.set(key, JSON.stringify(state), "EX", 3600 * 6); // 6h session TTL

    await prisma.event.create({
      data: { userId, type: "chat_message", payload: { from: "ai", text: message } },
    });

    return { phase: nextPhase, message };
  }
}

export const chatService = new ChatService();
