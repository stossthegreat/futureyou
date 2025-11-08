import { prisma } from "../utils/db";
import { redis } from "../utils/redis";
import { memoryService } from "./memory.service";
import { aiRouter } from "./ai-router.service";
import OpenAI from "openai";

/**
 * 🧠 FUTURE-YOU DEEP DISCOVERY (GPT-5 UNLEASHED)
 * 
 * Warm, exacting mentor for surfacing Life's Task over multiple sessions.
 * Extracts Insight Cards, generates Commit Cards, tracks progress toward draft.
 */

const SYSTEM_PROMPT_FUTURE_YOU = `
You are Future-You — a warm, exacting mentor. You don't hand out a purpose; you help the user surface it over multiple sessions.

Tone: grounded, cinematic, precise. Short sentences. No therapy claims.

Method: each turn you (1) reflect a core truth you heard, (2) name the pattern, (3) ask one sharp question that moves the story, (4) propose one micro-commitment, and (5) extract 1–3 "Insight Cards" (candidate statements that might belong to the user's Life's Task).

Lenses you can invoke naturally (don't list them unless needed): Death Perspective, Freedom Test, Aliveness Compass, Childhood Archaeology, Hero's Journey, Aversion Mapping, Urgency Lens.

Rules:
- Never claim you've "found" their Life's Task in one session. You draft it after enough evidence.
- If user mentions ADHD/mental health, reframe to structure/strategy; no diagnoses.
- Prefer examples over abstractions.
- Keep questions specific and answerable in one message.
- Always return insightCards with tags and confidence. Output must be valid JSON.

Response JSON structure (STRICT):
{
  "chat": [{"role": "assistant", "text": "…formatted reply…"}],
  "insightCards": [
    {
      "title": "short claim",
      "detail": "one-sentence why this matters",
      "tag": "URGENCY|MINDSET|SERVICE|IDENTITY|SKILL|ENVIRONMENT",
      "confidence": 0.55
    }
  ],
  "commitCard": {
    "title": "One Tiny Proof Tonight",
    "steps": ["…", "…", "…"],
    "impact": "mini forecast text with emojis",
    "note": "brief caveat/encouragement"
  },
  "progress": {
    "insightsCollected": 12,
    "insightsTarget": 20,
    "draftReady": false
  },
  "nextQuestion": "one precise question",
  "lensUsed": ["Death Perspective","Hero's Journey"]
}

Insight extraction:
- From user text, pull candidates that sound like values, fears, drivers, gifts, or recurring motives
- Normalize to present-tense identity statements (≤90 chars)
- Tag: URGENCY (fear of waste), MINDSET (belief), SERVICE (who/impact), IDENTITY (who I am when best), SKILL (crafts), ENVIRONMENT (contexts that amplify you)
- Confidence ∈ [0,1]. Cap insightCards to 1–3 per turn.

Draft rule: when insightsCollected ≥ 18 and we have ≥1 per tag across ≥3 sessions, include progress.draftReady = true and append a non-final Life's Task Draft to the commitCard.note

Voice & card style:
- Use short paragraphs
- Open with a 1–2 line mirror of what you heard
- One needle-sharp question per turn
- commitCard.steps = 3 bullets max
- Use light emojis to signal vibe: 🔥🧠✨🧭🌱🛠️

Micro-commitment library (rotate intelligently based on context):
- Proof of Direction: Write a 3-line North Star (who/what/why)
- Friction Kill: Remove 1 feature or task that doesn't serve the North Star
- Narrative Cement: Rename a feature to match the mission
- Energy Guard: 90-min deep-work block tomorrow; phone out of room
- Public Anchor: Send one "I'm building X for Y" message to a trusted friend

Safety lines (auto-append when needed):
- "I can't diagnose ADHD, but I can help you design a structure that works with your brain."
- "This is a draft, not destiny. We refine it as your evidence grows."
`;

interface InsightCard {
  title: string;
  detail: string;
  tag: "URGENCY" | "MINDSET" | "SERVICE" | "IDENTITY" | "SKILL" | "ENVIRONMENT";
  confidence: number;
}

interface CommitCard {
  title: string;
  steps: string[];
  impact: string;
  note: string;
}

interface FutureYouResponse {
  chat: Array<{ role: string; text: string }>;
  insightCards: InsightCard[];
  commitCard: CommitCard;
  progress: {
    insightsCollected: number;
    insightsTarget: number;
    draftReady: boolean;
  };
  nextQuestion: string;
  lensUsed: string[];
}

export class FutureYouChatService {
  private async getConversationHistory(userId: string): Promise<any[]> {
    try {
      const key = `futureyou:chat:${userId}`;
      const raw = await redis.get(key);
      return raw ? JSON.parse(raw) : [];
    } catch (error) {
      // Silent fail - Redis errors handled gracefully
      return [];
    }
  }

  private async saveConversationHistory(userId: string, messages: any[]) {
    try {
      const key = `futureyou:chat:${userId}`;
      await redis.set(key, JSON.stringify(messages), "EX", 3600 * 24 * 7); // 7 days
    } catch (error) {
      // Silent fail - Redis errors handled gracefully
    }
  }

  private async getInsights(userId: string): Promise<InsightCard[]> {
    try {
      const key = `futureyou:insights:${userId}`;
      const raw = await redis.get(key);
      return raw ? JSON.parse(raw) : [];
    } catch (error) {
      // Silent fail - Redis errors handled gracefully
      return [];
    }
  }

  private async saveInsights(userId: string, insights: InsightCard[]) {
    try {
      const key = `futureyou:insights:${userId}`;
      await redis.set(key, JSON.stringify(insights), "EX", 3600 * 24 * 30); // 30 days
    } catch (error) {
      // Silent fail - Redis errors handled gracefully
    }
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

  async chat(userId: string, userMessage: string): Promise<FutureYouResponse> {
    // Get user context and insights
    const [identity, ctx, history, existingInsights] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
      this.getConversationHistory(userId),
      this.getInsights(userId),
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

INSIGHTS COLLECTED SO FAR (${existingInsights.length} / 20):
${existingInsights.map(i => `[${i.tag}] ${i.title} (${(i.confidence * 100).toFixed(0)}%)`).join("\n") || "None yet"}

CONVERSATION HISTORY (last 10 exchanges):
${history.slice(-20).map((m: any) => `${m.role}: ${m.content}`).join("\n")}
`;

    // Add user message to history
    history.push({ role: "user", content: userMessage, timestamp: new Date().toISOString() });

    // Combine system prompt with context
    const fullSystemPrompt = `${SYSTEM_PROMPT_FUTURE_YOU}\n\n${contextString}`;

    // Call AI Router with GPT-5 high reasoning + high verbosity
    const aiResponse = await aiRouter.callAI({
      preset: "futureYou",
      systemPrompt: fullSystemPrompt,
      userInput: userMessage,
      userId,
      parseJson: true,
    });
    
    let parsedResponse: FutureYouResponse;
    try {
      // aiRouter returns structured data, map to FutureYouResponse
      // 🔥 Safety: ensure chat is always a string
      let chatText = "Keep going.";
      const chat: any = aiResponse.chat; // Type assertion to fix TypeScript narrowing
      if (typeof chat === 'string') {
        chatText = chat;
      } else if (Array.isArray(chat) && chat.length > 0) {
        const firstItem = chat[0];
        if (typeof firstItem === 'string') {
          chatText = firstItem;
        } else if (firstItem && typeof firstItem === 'object' && 'text' in firstItem) {
          chatText = firstItem.text || "Keep going.";
        }
      } else if (chat) {
        chatText = String(chat);
      }
      
      parsedResponse = {
        chat: [{ role: "assistant", text: chatText }],
        insightCards: aiResponse.insightCards || [],
        commitCard: aiResponse.commitCard || { title: "Keep Going", steps: [], impact: "", note: "" },
        progress: aiResponse.progress || { insightsCollected: existingInsights.length, insightsTarget: 20, draftReady: false },
        nextQuestion: aiResponse.nextQuestion || "",
        lensUsed: aiResponse.lensUsed || [],
      };
    } catch (err) {
      console.error("Failed to parse Future-You response:", err);
      const fallbackText = typeof aiResponse.chat === 'string' 
        ? aiResponse.chat 
        : "Keep going.";
      parsedResponse = {
        chat: [{ role: "assistant", text: fallbackText }],
        insightCards: [],
        commitCard: { title: "Keep Going", steps: [], impact: "", note: "" },
        progress: { insightsCollected: existingInsights.length, insightsTarget: 20, draftReady: false },
        nextQuestion: "",
        lensUsed: [],
      };
    }

    // Merge new insights with existing ones
    const newInsights = parsedResponse.insightCards || [];
    const allInsights = [...existingInsights, ...newInsights];
    await this.saveInsights(userId, allInsights);

    // Update progress
    parsedResponse.progress = {
      insightsCollected: allInsights.length,
      insightsTarget: 20,
      draftReady: allInsights.length >= 18,
    };

    // Save to history
    const aiText = parsedResponse.chat?.[0]?.text || "";
    history.push({ role: "assistant", content: aiText, timestamp: new Date().toISOString() });
    await this.saveConversationHistory(userId, history);

    // Log event
    await prisma.event.create({
      data: {
        userId,
        type: "futureyou_chat",
        payload: { 
          userMessage, 
          aiResponse: aiText,
          insightCards: JSON.parse(JSON.stringify(newInsights)),
          contradictions,
        } as any,
      },
    });

    return parsedResponse;
  }

  /**
   * 🌊 STREAMING version of chat - sends text word-by-word
   */
  async chatStream(
    userId: string,
    userMessage: string,
    onChunk: (text: string) => void
  ): Promise<void> {
    // Get user context
    const [identity, ctx, history] = await Promise.all([
      memoryService.getIdentityFacts(userId),
      memoryService.getUserContext(userId),
      this.getConversationHistory(userId),
    ]);

    // Build context string
    const contextString = `
USER PROFILE:
Name: ${identity.name}
Purpose: ${identity.purpose || "discovering"}
Core Values: ${identity.coreValues?.join(", ") || "not defined"}
Burning Question: ${identity.burningQuestion}

CURRENT HABITS & GOALS:
${ctx.habitSummaries.map((h: any) => `- ${h.title}: ${h.streak} days`).join("\n")}

CONVERSATION HISTORY (last 4 turns):
${history.slice(-8).map((m: any) => `${m.role}: ${m.content.slice(0, 150)}`).join("\n")}

USER MESSAGE:
${userMessage}
`;

    // Build messages array
    const messages = [
      { role: "system" as const, content: SYSTEM_PROMPT_FUTURE_YOU },
      { role: "user" as const, content: contextString },
    ];

    // Call OpenAI with streaming
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, timeout: 180000 });

    const stream = await client.chat.completions.create({
      model: "gpt-5-mini",
      messages,
      temperature: 0.7,
      max_completion_tokens: 8000, // 🔥 BACK TO 8000 - Reasoning needs space!
      stream: true, // Enable streaming!
    });

    let fullText = "";
    
    // Stream chunks to client
    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || "";
      if (content) {
        fullText += content;
        onChunk(content); // Send chunk to client
      }
    }

    // Save conversation history
    history.push(
      { role: "user", content: userMessage },
      { role: "assistant", content: fullText }
    );
    await this.saveConversationHistory(userId, history.slice(-20)); // Keep last 20 messages
  }

  async clearHistory(userId: string) {
    const key = `futureyou:chat:${userId}`;
    await redis.del(key);
    return { success: true };
  }
}

export const futureYouChatService = new FutureYouChatService();

