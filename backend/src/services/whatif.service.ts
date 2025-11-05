import OpenAI from "openai";
import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

function getOpenAIClient() {
  if (!process.env.OPENAI_API_KEY) return null;
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY.trim() });
}

export class WhatIfService {
  async generatePurposeAlignedGoals(userId: string) {
    const openai = getOpenAIClient();
    if (!openai) return [];

    const identity = await memoryService.getIdentityFacts(userId);
    if (!identity.discoveryCompleted) return [];

    const prompt = `
USER PROFILE:
Purpose: ${identity.purpose}
Core Values: ${identity.coreValues.join(", ")}
Vision: ${identity.vision}
Burning Question: ${identity.burningQuestion}

TASK: Generate 3 personalized "What-If" goals aligned with their purpose.
Each goal should have:
- title: Clear, actionable (e.g., "Digital Sunset")
- subtitle: Benefit statement
- icon: Single emoji
- plan: Array of 5-7 specific micro-steps with { action, why, study }

Return ONLY valid JSON array of goals.
Example format:
[{
  "title": "Morning Ritual",
  "subtitle": "Align with your purpose daily",
  "icon": "🌅",
  "plan": [
    { "action": "Wake at 6am daily", "why": "Consistency builds discipline", "study": "Stanford 2021" },
    ...
  ]
}]
`;

    const completion = await openai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.7,
      max_tokens: 1500,
      messages: [
        { role: "system", content: "Generate personalized What-If goals. Output only JSON array." },
        { role: "user", content: prompt },
      ],
    });

    try {
      const raw = completion.choices[0]?.message?.content?.trim() || "[]";
      const cleaned = raw.replace(/```json|```/g, "").trim();
      const goals = JSON.parse(cleaned);
      
      // Cache for 24h
      await prisma.event.create({
        data: { userId, type: "whatif_goals_generated", payload: { goals } },
      });
      
      return goals;
    } catch (err) {
      console.warn("Failed to generate purpose-aligned goals:", err);
      return [];
    }
  }
}

export const whatIfService = new WhatIfService();

