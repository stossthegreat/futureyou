import { redis } from "../utils/redis";

// ===========================
// TYPE DEFINITIONS
// ===========================

export interface ConversationMessage {
  role: "user" | "assistant" | "system";
  text: string;
  timestamp: Date;
  emotionalTone:
    | "energized"
    | "frustrated"
    | "reflective"
    | "avoidant"
    | "neutral"
    | "balanced"
    | "focused"
    | "overwhelmed";
}

export interface DialogueMeta {
  currentEmotionalState:
    | "energized"
    | "frustrated"
    | "reflective"
    | "avoidant"
    | "balanced"
    | "overwhelmed";
  lastToneShift: Date | null;

  // How they prefer to be spoken to
  responsePreference: "direct" | "philosophical" | "practical" | "gentle";

  // Behaviour patterns seen in chat
  engagementPattern: "daily" | "sporadic" | "resistant";

  // Contradictions captured recently
  recentContradictions: string[];
}

// ===========================
// SHORT-TERM MEMORY SERVICE
// ===========================

export class ShortTermMemoryService {
  private readonly TTL_DAYS = 30;
  private readonly TTL_SECONDS = this.TTL_DAYS * 24 * 60 * 60;

  /**
   * 💬 Store last 100 messages + emotional tone
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

    // keep last 100 messages
    await redis.ltrim(key, 0, 99);
    await redis.expire(key, this.TTL_SECONDS);
  }

  /**
   * 📜 Get recent messages (default 10)
   */
  async getRecentConversation(
    userId: string,
    limit: number = 10
  ): Promise<ConversationMessage[]> {
    const key = `conversation:${userId}`;
    const raw = await redis.lrange(key, 0, limit - 1);

    return raw
      .map((m) => {
        try {
          return JSON.parse(m);
        } catch {
          return null;
        }
      })
      .filter(Boolean) as ConversationMessage[];
  }

  /**
   * 🎭 Emotional detection improved — phase aware
   */
  async detectEmotionalState(
    userId: string
  ): Promise<DialogueMeta["currentEmotionalState"]> {
    const recent = await this.getRecentConversation(userId, 6);

    if (recent.length === 0) return "reflective";

    const tones = recent.map((m) => m.emotionalTone);

    const counts = {
      frustrated: tones.filter((t) => t === "frustrated").length,
      energized: tones.filter((t) => t === "energized").length,
      avoidant: tones.filter((t) => t === "avoidant").length,
      overwhelmed: tones.filter((t) => t === "overwhelmed").length,
    };

    if (counts.frustrated >= 2) return "frustrated";
    if (counts.overwhelmed >= 2) return "overwhelmed";
    if (counts.avoidant >= 2) return "avoidant";
    if (counts.energized >= 2) return "energized";

    return "reflective";
  }

  /**
   * 🔍 Detect contradictions like:
   *  “I WANT THIS” → “but I didn’t…”
   */
  async detectContradictions(userId: string): Promise<string[]> {
    const recent = await this.getRecentConversation(userId, 25);
    const userMessages = recent
      .filter((m) => m.role === "user")
      .map((m) => m.text.toLowerCase());

    const contradictions: string[] = [];

    for (let i = 0; i < userMessages.length - 1; i++) {
      const now = userMessages[i];
      const before = userMessages[i + 1];

      const promised =
        before.includes("i will") ||
        before.includes("i’m going to") ||
        before.includes("i have to") ||
        before.includes("i need to");

      const excuse =
        now.includes("but") ||
        now.includes("didn't") ||
        now.includes("couldn't") ||
        now.includes("forgot") ||
        now.includes("got distracted");

      if (promised && excuse) {
        contradictions.push(
          `Contradiction detected: promise → excuse (“${before.slice(
            0,
            40
          )}” → “${now.slice(0, 40)}”)`
        );
      }
    }

    return contradictions.slice(0, 3);
  }

  /**
   * 📊 Save dialogue metadata
   */
  async updateDialogueMeta(
    userId: string,
    updates: Partial<DialogueMeta>
  ): Promise<void> {
    const key = `dialogue_meta:${userId}`;

    if (updates.currentEmotionalState)
      await redis.hset(key, "currentEmotionalState", updates.currentEmotionalState);

    if (updates.lastToneShift)
      await redis.hset(key, "lastToneShift", updates.lastToneShift.toISOString());

    if (updates.responsePreference)
      await redis.hset(key, "responsePreference", updates.responsePreference);

    if (updates.engagementPattern)
      await redis.hset(key, "engagementPattern", updates.engagementPattern);

    if (updates.recentContradictions)
      await redis.hset(
        key,
        "recentContradictions",
        JSON.stringify(updates.recentContradictions)
      );

    await redis.expire(key, this.TTL_SECONDS);
  }

  /**
   * 📖 Load dialogue metadata
   */
  async getDialogueMeta(userId: string): Promise<DialogueMeta> {
    const key = `dialogue_meta:${userId}`;
    const data = await redis.hgetall(key);

    return {
      currentEmotionalState:
        (data.currentEmotionalState as any) || "reflective",

      lastToneShift: data.lastToneShift ? new Date(data.lastToneShift) : null,

      responsePreference:
        (data.responsePreference as any) || "practical",

      engagementPattern:
        (data.engagementPattern as any) || "daily",

      recentContradictions: data.recentContradictions
        ? JSON.parse(data.recentContradictions)
        : [],
    };
  }

  /**
   * 🧹 Utility for debugging
   */
  async clearConversation(userId: string): Promise<void> {
    await redis.del(`conversation:${userId}`);
    await redis.del(`dialogue_meta:${userId}`);
  }
}

export const shortTermMemory = new ShortTermMemoryService();
