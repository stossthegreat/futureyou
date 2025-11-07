import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import { redis } from "../utils/redis";
import { MENTOR } from "../config/mentors.config";
import { aiRouter } from "./ai-router.service";

const LLM_MAX_TOKENS = Number(process.env.LLM_MAX_TOKENS || 450);

type GenerateOptions = {
  purpose?: "brief" | "nudge" | "debrief" | "coach" | "letter";
  temperature?: number;
  maxChars?: number;
};

export class AIService {
  async generateFutureYouReply(userId: string, userMessage: string, opts: GenerateOptions = {}) {
    const [profile, ctx, identity] = await Promise.all([
      memoryService.getProfileForMentor(userId),
      memoryService.getUserContext(userId),
      memoryService.getIdentityFacts(userId),
    ]);

    const guidelines = this.buildGuidelines(opts.purpose || "coach", profile, identity);

    const contextString = identity.discoveryCompleted
      ? `IDENTITY:\nName: ${identity.name}, Age: ${identity.age}
Purpose: ${identity.purpose}
Core Values: ${identity.coreValues.join(", ")}
Vision: ${identity.vision}
Burning Question: ${identity.burningQuestion}

CONTEXT:
${JSON.stringify({ habits: ctx.habitSummaries, recent: ctx.recentEvents.slice(0, 30) })}`
      : `IDENTITY:\nName: ${identity.name}, Age: ${identity.age || "unknown"}
Burning Question: ${identity.burningQuestion || "not yet answered"}
Note: User hasn't completed purpose discovery yet.

CONTEXT:
${JSON.stringify({ habits: ctx.habitSummaries, recent: ctx.recentEvents.slice(0, 30) })}`;

    // Build full system prompt
    const fullSystemPrompt = `${MENTOR.systemPrompt}\n\n${guidelines}\n\n${contextString}`;

    // Map purpose to AI Router preset (brief/nudge/debrief use mini, coach/letter use default)
    const presetMap: Record<string, "brief" | "nudge" | "debrief" | "default"> = {
      brief: "brief",
      nudge: "nudge",
      debrief: "debrief",
      coach: "default",
      letter: "default",
    };
    const preset = presetMap[opts.purpose || "coach"] || "default";

    // Call AI Router
    const aiResponse = await aiRouter.callAI({
      preset,
      systemPrompt: fullSystemPrompt,
      userInput: userMessage,
      userId,
      parseJson: false,
    });

    let text = aiResponse.chat || "Keep going.";
    if (opts.maxChars && text.length > opts.maxChars) text = text.slice(0, opts.maxChars - 1) + "…";

    await prisma.event.create({
      data: { userId, type: opts.purpose || "coach", payload: { text } as any },
    });

    return text;
  }

  async generateMorningBrief(userId: string) {
    const prompt = "Write a short, powerful morning brief. 2–3 clear actions and one imperative closing line.";
    return this.generateFutureYouReply(userId, prompt, { purpose: "brief", temperature: 0.4, maxChars: 400 });
  }

  async generateEveningDebrief(userId: string) {
    await memoryService.summarizeDay(userId);
    const prompt = "Write a concise evening reflection. Mention progress, lessons, and one focus for tomorrow.";
    return this.generateFutureYouReply(userId, prompt, { purpose: "debrief", temperature: 0.3, maxChars: 400 });
  }

  async generateNudge(userId: string, reason: string) {
    const prompt = `Generate a one-sentence motivational nudge because: ${reason}`;
    return this.generateFutureYouReply(userId, prompt, { purpose: "nudge", temperature: 0.5, maxChars: 200 });
  }

  /**
   * 🧠 Extract habit suggestion from conversation
   */
  async extractHabitFromConversation(userId: string, userInput: string, aiResponse: string) {
    const extractionPrompt = `
CONTEXT:
User said: "${userInput}"
AI replied: "${aiResponse}"

TASK:
Extract ONE concrete habit or task from this conversation.
Return ONLY valid JSON (no markdown):
{
  "title": "Clear action (e.g., 'Morning Meditation')",
  "type": "habit or task",
  "time": "HH:MM format (e.g., '06:30')",
  "emoji": "single emoji",
  "importance": 1-5 (1=low, 5=critical),
  "reasoning": "Why this habit matters (1 sentence)"
}

If no clear habit/task, return: {"none": true}
`;

    const routerResponse = await aiRouter.callAI({
      preset: "default",
      systemPrompt: "You extract actionable habits from conversations. Output only JSON.",
      userInput: extractionPrompt,
      userId,
      parseJson: true,
    });

    try {
      const raw = routerResponse.rawOutput || "{}";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(cleaned);
      
      if (parsed.none) return null;
      if (!parsed.title || !parsed.time) return null;
      
      return parsed;
    } catch (err) {
      console.warn("Failed to parse habit extraction:", err);
      return null;
    }
  }

  /** Legacy alias so old modules still compile */
  async generateMentorReply(userId: string, _mentorId: string, userMessage: string, opts: GenerateOptions = {}) {
    return this.generateFutureYouReply(userId, userMessage, opts);
  }

  private buildGuidelines(purpose: string, profile: any, identity: any) {
    const base = [
      `You are Future You — wise, calm, uncompromising.`,
      `Speaking to: ${identity.name}${identity.age ? `, age ${identity.age}` : ''}`,
      `Match tone=${profile.tone}, intensity=${profile.intensity}.`,
    ];

    if (identity.discoveryCompleted) {
      base.push(`THEIR PURPOSE: ${identity.purpose}`);
      base.push(`THEIR VALUES: ${identity.coreValues.join(", ")}`);
      base.push(`THEIR VISION: ${identity.vision}`);
    } else if (identity.burningQuestion) {
      base.push(`THEIR QUESTION: ${identity.burningQuestion}`);
      base.push(`Note: Encourage them to complete Future-You discovery for deeper insights.`);
    }

    const byPurpose: Record<string, string[]> = {
      brief: identity.discoveryCompleted 
        ? [`Morning brief for ${identity.name}: Reference their PURPOSE (${identity.purpose}) and give 2-3 orders aligned with their VISION.`]
        : ["Morning brief: 2-3 short orders. Gently remind to complete Future-You discovery."],
      debrief: identity.discoveryCompleted
        ? [`Evening debrief for ${identity.name}: Reflect on progress toward their PURPOSE. Did today align with their VALUES (${identity.coreValues.join(", ")})?`]
        : ["Evening debrief: Reflect briefly. Encourage discovery completion."],
      nudge: identity.discoveryCompleted
        ? [`Nudge: One sentence. Remind ${identity.name} of their PURPOSE (${identity.purpose}) and what they want said at their funeral.`]
        : ["Nudge: Motivational, but generic until they complete discovery."],
      coach: ["Coach: Call out avoidance, give one clear move."],
      letter: ["Letter: Reflective, clarifying, self-honest."],
    };
    
    return [...base, ...(byPurpose[purpose] || [])].join("\n");
  }
}

export const aiService = new AIService();
