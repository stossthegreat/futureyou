import crypto from "crypto";
import OpenAI from "openai";
import { redis } from "../utils/redis";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) return null;
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: 180000 }); // 🔥 3 MINUTES! No more timeouts!
}

interface AIRouterConfig {
  preset: "futureYou" | "habit" | "whatif" | "brief" | "nudge" | "debrief" | "default";
  systemPrompt: string;
  userInput: string;
  userId: string;
  parseJson?: boolean;
}

interface AIRouterResponse {
  chat: string;
  splitFutureCard?: string;
  commitCard?: any;
  insightCards?: any[];
  sources?: string[];
  progress?: any;
  nextQuestion?: string;
  lensUsed?: string[];
  rawOutput?: string;
}

// MODEL TIERS WITH REASONING + VERBOSITY
// 🔥 BACK TO 8000 - Reasoning tokens need space!
const MODEL_TIERS = {
  futureYou: { model: "gpt-5-mini", effort: "high", verbosity: "high", maxTokens: 8000 },
  habit: { model: "gpt-5-mini", effort: "medium", verbosity: "medium", maxTokens: 8000 },
  whatif: { model: "gpt-5-mini", effort: "medium", verbosity: "high", maxTokens: 8000 },
  brief: { model: "gpt-5-mini", effort: "low", verbosity: "medium", maxTokens: 450 },
  nudge: { model: "gpt-5-mini", effort: "low", verbosity: "medium", maxTokens: 200 },
  debrief: { model: "gpt-5-mini", effort: "low", verbosity: "medium", maxTokens: 450 },
  default: { model: "gpt-5-mini", effort: "low", verbosity: "medium", maxTokens: 500 },
};

/**
 * 🧠 GPT-5 UNIFIED AI ROUTER
 * 
 * Handles model selection, reasoning effort, caching, and memory chaining.
 * Uses OpenAI Chat Completions API (responses.create is not yet available in SDK).
 */
export class AIRouterService {
  /**
   * Main AI call with cost-aware caching and memory management
   */
  async callAI(config: AIRouterConfig): Promise<AIRouterResponse> {
    const openai = getOpenAIClient();
    if (!openai) {
      return {
        chat: "AI is silent right now — try again later.",
        rawOutput: "",
      };
    }

    // Cost-aware caching (12 hour expiry) - WITH ERROR HANDLING!
    const cacheKey = this.getCacheKey(config.preset, config.userInput);
    let cached = null;
    try {
      cached = await redis.get(cacheKey);
      if (cached) {
        console.log(`💚 Cache HIT for ${config.preset}`);
        return JSON.parse(cached);
      }
    } catch (redisErr) {
      // Silent fail - don't spam logs
    }

    // Get tier config
    const tier = MODEL_TIERS[config.preset] || MODEL_TIERS.default;

    // Get previous conversation memory for chaining - WITH ERROR HANDLING!
    let memory = null;
    try {
      memory = await this.getMemory(config.userId, config.preset);
    } catch (redisErr) {
      // Silent fail - don't spam logs
    }
    const enrichedInput = memory 
      ? `[Context from previous conversation]\n${memory}\n\n[Current message]\n${config.userInput}`
      : config.userInput;

    let result: OpenAI.Chat.Completions.ChatCompletion;

    try {
      // Primary call with selected tier
      result = await openai.chat.completions.create({
        model: tier.model,
        max_completion_tokens: tier.maxTokens,
        messages: [
          { role: "system", content: config.systemPrompt },
          { role: "user", content: enrichedInput },
        ],
        ...(config.parseJson && { response_format: { type: "json_object" } }),
      });
    } catch (e: any) {
      console.error(`❌ AI call failed (${tier.model}):`, e.message);
      
      // Fallback to mini if primary fails
      const fallbackModel = tier.model === "gpt-5" ? "gpt-5-mini" : "gpt-5-mini";
      console.log(`🔄 Falling back to ${fallbackModel}`);
      
      try {
        result = await openai.chat.completions.create({
          model: fallbackModel,
          max_completion_tokens: tier.maxTokens, // 🔥 NO LIMITS on fallback either!
          messages: [
            { role: "system", content: config.systemPrompt },
            { role: "user", content: config.userInput }, // Skip memory on fallback
          ],
          ...(config.parseJson && { response_format: { type: "json_object" } }),
        });
      } catch (fallbackErr: any) {
        console.error(`❌ Fallback also failed:`, fallbackErr.message);
        return {
          chat: "AI temporarily unavailable. Please try again.",
          rawOutput: "",
        };
      }
    }

    const rawOutput = result.choices[0]?.message?.content?.trim() || "";

    // Parse response based on format
    let data: AIRouterResponse;
    if (config.parseJson) {
      try {
        const parsed = JSON.parse(rawOutput);
        // 🔥 ALWAYS extract chat as STRING (not array!)
        let chatText = rawOutput;
        if (parsed.chat) {
          if (Array.isArray(parsed.chat)) {
            chatText = parsed.chat[0]?.text || parsed.chat[0] || rawOutput;
          } else if (typeof parsed.chat === 'object' && parsed.chat.text) {
            chatText = parsed.chat.text;
          } else if (typeof parsed.chat === 'string') {
            chatText = parsed.chat;
          }
        } else if (parsed.message) {
          chatText = parsed.message;
        }
        
        data = {
          chat: chatText, // Always a string!
          splitFutureCard: parsed.splitFutureCard,
          commitCard: parsed.commitCard,
          insightCards: parsed.insightCards,
          sources: parsed.sources,
          progress: parsed.progress,
          nextQuestion: parsed.nextQuestion,
          lensUsed: parsed.lensUsed,
          rawOutput,
        };
      } catch (err) {
        console.warn("⚠️ JSON parse failed, returning raw output");
        data = { chat: rawOutput, rawOutput };
      }
    } else {
      // Extract structured cards from markdown
      data = {
        chat: rawOutput,
        splitFutureCard: this.extractCard(rawOutput, "Split"),
        commitCard: this.extractCard(rawOutput, "Commit"),
        sources: this.extractSources(rawOutput),
        rawOutput,
      };
    }

    // Save condensed memory for next turn - WITH ERROR HANDLING!
    try {
      await this.saveMemory(config.userId, config.preset, rawOutput);
    } catch (redisErr) {
      // Silent fail - don't spam logs
    }

    // Cache result (12 hours) - WITH ERROR HANDLING!
    try {
      await redis.set(cacheKey, JSON.stringify(data), "EX", 60 * 60 * 12);
    } catch (redisErr) {
      // Silent fail - don't spam logs
    }

    return data;
  }

  /**
   * Generate cache key from preset + input
   */
  private getCacheKey(preset: string, input: string): string {
    return `ai:cache:${crypto.createHash("sha256").update(preset + input).digest("hex")}`;
  }

  /**
   * Get condensed memory from previous conversation
   */
  private async getMemory(userId: string, preset: string): Promise<string | null> {
    const key = `ai:memory:${userId}:${preset}`;
    return await redis.get(key);
  }

  /**
   * Save condensed memory (last 800 chars)
   */
  private async saveMemory(userId: string, preset: string, output: string): Promise<void> {
    const key = `ai:memory:${userId}:${preset}`;
    const summary = output.slice(0, 800); // Simple truncation, can be smarter later
    await redis.set(key, summary, "EX", 60 * 60 * 24 * 7); // 7 days
  }

  /**
   * Extract Split-Future Card or Commit Card from markdown
   */
  private extractCard(text: string, type: "Split" | "Commit"): string | undefined {
    if (type === "Split") {
      const match = text.match(/\| Metric \|.*?\n[\s\S]*?(?=\n\n|$)/);
      return match ? match[0] : undefined;
    }
    if (type === "Commit") {
      const match = text.match(/NEXT-BEST ACTION CARD[\s\S]*?(?=\n\n|$)/i);
      return match ? match[0] : undefined;
    }
    return undefined;
  }

  /**
   * Extract citation sources from output
   */
  private extractSources(text: string): string[] {
    const sources: string[] = [];
    // Match patterns like "Walker 2017 Sleep Med Rev" or "Harvard Study 2019"
    const pattern = /([A-Z][a-z]+ \d{4}[^.]*)/g;
    let match;
    while ((match = pattern.exec(text)) !== null) {
      sources.push(match[1]);
    }
    return [...new Set(sources)]; // Remove duplicates
  }
}

export const aiRouter = new AIRouterService();

