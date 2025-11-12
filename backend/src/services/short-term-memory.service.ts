import { redis } from "../utils/redis";

// ===========================
// TYPE DEFINITIONS
// ===========================

export interface ConversationMessage {
  role: "user" | "assistant" | "system";
  text: string;
  timestamp: Date;
  emotionalTone: "energized" | "frustrated" | "reflective" | "avoidant" | "neutral" | "balanced";
}

export interface DialogueMeta {
  currentEmotionalState: "energized" | "frustrated" | "reflective" | "avoidant";
  lastToneShift: Date | null;
  responsePreference: "direct" | "philosophical" | "practical";
  engagementPattern: "daily" | "sporadic" | "resistant";
  recentContradictions: string[];
}

// ===========================
// SHORT-TERM MEMORY SERVICE
// ===========================

export class ShortTermMemoryService {
  private readonly TTL_DAYS = 30;
  private readonly TTL_SECONDS = this.TTL_DAYS * 24 * 60 * 60;

  /**
   * 💬 Append message to conversation history
   */
  async appendConversation(
    userId: string,
    role: "user" | "assistant" | "system",
    text: string,
    emotionalTone: ConversationMessage["emotionalTone"] = "neutral"
  ): Promise<void> {
    const key = `conversation:${userId}`;
    const message: ConversationMessage = {
      role,
      text,
      timestamp: new Date(),
      emotionalTone,
    };

    await redis.lpush(key, JSON.stringify(message));
    await redis.ltrim(key, 0, 99); // Keep last 100 messages
    await redis.expire(key, this.TTL_SECONDS);
  }

  /**
   * 📜 Get recent conversation history
   */
  async getRecentConversation(userId: string, limit: number = 10): Promise<ConversationMessage[]> {
    const key = `conversation:${userId}`;
    const messages = await redis.lrange(key, 0, limit - 1);

    return messages.map((m) => {
      try {
        return JSON.parse(m);
      } catch {
        return null;
      }
    }).filter(Boolean) as ConversationMessage[];
  }

  /**
   * 🎭 Detect emotional state from recent messages
   */
  async detectEmotionalState(userId: string): Promise<DialogueMeta["currentEmotionalState"]> {
    const recent = await this.getRecentConversation(userId, 5);

    if (recent.length === 0) return "reflective";

    // Count emotional tones
    const tones = recent.map((m) => m.emotionalTone);
    const frustrated = tones.filter((t) => t === "frustrated").length;
    const energized = tones.filter((t) => t === "energized").length;
    const avoidant = tones.filter((t) => t === "avoidant").length;

    if (frustrated >= 2) return "frustrated";
    if (energized >= 2) return "energized";
    if (avoidant >= 2) return "avoidant";

    return "reflective";
  }

  /**
   * 🔍 Detect contradictions in recent messages
   */
  async detectContradictions(userId: string): Promise<string[]> {
    const recent = await this.getRecentConversation(userId, 20);
    const contradictions: string[] = [];

    // Simple heuristic: look for "but" statements or opposing commitments
    const userMessages = recent.filter((m) => m.role === "user").map((m) => m.text);

    for (let i = 0; i < userMessages.length - 1; i++) {
      const current = userMessages[i].toLowerCase();
      const previous = userMessages[i + 1].toLowerCase();

      // Check for commitment followed by excuse
      if (
        previous.includes("will") &&
        (current.includes("but") || current.includes("didn't") || current.includes("forgot"))
      ) {
        contradictions.push(
          `Said they would do something, then made excuse: "${userMessages[i].slice(0, 60)}..."`
        );
      }
    }

    return contradictions.slice(0, 3);
  }

  /**
   * 📊 Update dialogue metadata
   */
  async updateDialogueMeta(userId: string, updates: Partial<DialogueMeta>): Promise<void> {
    const key = `dialogue_meta:${userId}`;

    if (updates.currentEmotionalState) {
      await redis.hset(key, "currentEmotionalState", updates.currentEmotionalState);
    }
    if (updates.lastToneShift) {
      await redis.hset(key, "lastToneShift", updates.lastToneShift.toISOString());
    }
    if (updates.responsePreference) {
      await redis.hset(key, "responsePreference", updates.responsePreference);
    }
    if (updates.engagementPattern) {
      await redis.hset(key, "engagementPattern", updates.engagementPattern);
    }
    if (updates.recentContradictions) {
      await redis.hset(key, "recentContradictions", JSON.stringify(updates.recentContradictions));
    }

    await redis.expire(key, this.TTL_SECONDS);
  }

  /**
   * 📖 Get dialogue metadata
   */
  async getDialogueMeta(userId: string): Promise<DialogueMeta> {
    const key = `dialogue_meta:${userId}`;
    const data = await redis.hgetall(key);

    return {
      currentEmotionalState: (data.currentEmotionalState as any) || "reflective",
      lastToneShift: data.lastToneShift ? new Date(data.lastToneShift) : null,
      responsePreference: (data.responsePreference as any) || "balanced",
      engagementPattern: (data.engagementPattern as any) || "daily",
      recentContradictions: data.recentContradictions
        ? JSON.parse(data.recentContradictions)
        : [],
    };
  }

  /**
   * 🧹 Clear conversation history (for testing)
   */
  async clearConversation(userId: string): Promise<void> {
    await redis.del(`conversation:${userId}`);
    await redis.del(`dialogue_meta:${userId}`);
  }
}

export const shortTermMemory = new ShortTermMemoryService();

