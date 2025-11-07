import { prisma } from "../../utils/db";
import { redis } from "../../utils/redis";
import OpenAI from "openai";
import { PHASES, PhaseConfig } from "./phases.config";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) return null;
  const apiKey = process.env.OPENAI_API_KEY.trim();
  return new OpenAI({ apiKey, timeout: 60000 });
}

const openai = getOpenAIClient();

/**
 * 🧠 7-PHASE DISCOVERY FLOW SERVICE
 * 
 * Guides users through research-backed purpose discovery
 * Generates cinematic insight cards after each phase
 */

export async function runPhaseFlow(userId: string, userInput: string) {
  if (!openai) {
    return {
      chat: "AI is currently unavailable. Please try again later.",
      card: null,
      phase: 0,
      phaseComplete: false,
      totalPhases: 7
    };
  }

  // Get or create profile
  let profile = await prisma.purposeProfile.findUnique({
    where: { userId }
  });

  if (!profile) {
    profile = await prisma.purposeProfile.create({
      data: { userId, phaseCompleted: 0, data: {} }
    });
  }

  const currentPhase = Math.min(profile.phaseCompleted, 6); // 0-6 (7 phases total)
  const phaseConfig = PHASES[currentPhase];

  // Load conversation history from Redis
  const historyKey = `purpose:${userId}:phase:${currentPhase}`;
  const history = await redis.get(historyKey);
  const messages = history ? JSON.parse(history) : [];

  // Add user message
  messages.push({ role: "user", content: userInput });

  // Call gpt-5-mini for phase coaching (fast, conversational)
  const coachResponse = await openai.chat.completions.create({
    model: "gpt-5-mini",
    messages: [
      { role: "system", content: buildPhasePrompt(phaseConfig) },
      ...messages
    ],
    temperature: 0.7,
    max_tokens: 900
  });

  const coachText = coachResponse.choices[0].message.content || "I'm here to guide you. Tell me more.";
  messages.push({ role: "assistant", content: coachText });

  // Save updated history
  await redis.set(historyKey, JSON.stringify(messages), "EX", 60 * 60 * 24 * 7); // 7 days

  // Check if phase is complete (heuristic: 3+ user messages)
  const userMessages = messages.filter((m: any) => m.role === "user").length;
  let card = null;
  let phaseComplete = false;

  // Auto-complete after 3 exchanges OR if AI signals readiness
  const signalReadiness = coachText.toLowerCase().includes("ready to") || 
                           coachText.toLowerCase().includes("want to see") ||
                           coachText.toLowerCase().includes("let's commit");

  if (userMessages >= 3 || (userMessages >= 2 && signalReadiness)) {
    // Generate insight card with gpt-5 (powerful synthesis)
    card = await generateInsightCard(userId, currentPhase, messages, phaseConfig);
    
    // Advance to next phase
    const phaseData = profile.data as any || {};
    phaseData[`phase${currentPhase}`] = messages;
    
    await prisma.purposeProfile.update({
      where: { userId },
      data: { 
        phaseCompleted: currentPhase + 1,
        data: phaseData
      }
    });

    // Clear phase history
    await redis.del(historyKey);
    phaseComplete = true;
  }

  return {
    chat: coachText,
    card,
    phase: currentPhase,
    phaseComplete,
    totalPhases: 7,
    phaseName: phaseConfig.name
  };
}

async function generateInsightCard(
  userId: string, 
  phaseId: number, 
  messages: any[], 
  config: PhaseConfig
) {
  if (!openai) return null;

  const conversationText = messages
    .map(m => `${m.role === "user" ? "User" : "Future-You"}: ${m.content}`)
    .join("\n\n");

  const cardPrompt = `You are synthesizing Phase ${phaseId}: ${config.name} into a powerful insight card.

This phase explored: ${config.description}

Conversation:
${conversationText}

Generate a JSON insight card that captures their breakthrough. Use THEIR words. Be cinematic but grounded.

Structure:
{
  "cardType": "phase_insight",
  "phase": ${phaseId},
  "phaseName": "${config.name}",
  "title": "3-5 word insight title (use their language)",
  "summary": "2-3 cinematic sentences capturing their core realization. Make it feel like a mirror—reflecting back what they discovered. Use specific details from their responses.",
  "bullets": [
    "Key insight 1 (specific to their story)",
    "Key insight 2 (specific to their story)", 
    "Key insight 3 (specific to their story)"
  ],
  "sources": ${JSON.stringify(config.references)},
  "nextStep": "One sentence: What they should reflect on before next phase"
}

Tone: Warm, precise, cinematic. Like a coach who's been paying attention.
Use their exact phrases when possible. Make it personal, not generic.`;

  try {
    const cardResponse = await openai.chat.completions.create({
      model: "gpt-5",
      messages: [{ role: "user", content: cardPrompt }],
      response_format: { type: "json_object" },
      temperature: 0.8,
      max_tokens: 700
    });

    const cardContent = cardResponse.choices[0].message.content || "{}";
    const cardData = JSON.parse(cardContent);

    // Save to vault
    const profile = await prisma.purposeProfile.findUnique({ where: { userId } });
    
    await prisma.vaultItem.create({
      data: {
        userId,
        profileId: profile?.id || null,
        cardType: "phase_insight",
        card: cardData as any
      }
    });

    return cardData;
  } catch (error) {
    console.error("Error generating insight card:", error);
    return null;
  }
}

function buildPhasePrompt(config: PhaseConfig): string {
  return config.promptTemplate;
}

export async function getPhaseStatus(userId: string) {
  const profile = await prisma.purposeProfile.findUnique({
    where: { userId }
  });

  const currentPhase = profile?.phaseCompleted || 0;
  const phase = Math.min(currentPhase, 6);

  return {
    currentPhase: phase,
    totalPhases: 7,
    phaseName: PHASES[phase]?.name || "On-Ramp",
    completed: currentPhase >= 7,
    progress: Math.round((currentPhase / 7) * 100)
  };
}

export async function getUserVaultItems(userId: string, limit: number = 20) {
  const items = await prisma.vaultItem.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: limit
  });

  return items.map(item => ({
    id: item.id,
    cardType: item.cardType,
    card: item.card,
    createdAt: item.createdAt
  }));
}

