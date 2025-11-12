import OpenAI from 'openai';
import crypto from 'crypto';
import { redis } from '../../../utils/redis';
import { PhaseId, CoachResponse } from '../dto/engine.dto';

const SYSTEM_PROMPT = `You are FUTURE-YOU, a rigorous purpose coach who guides people to discover their life's purpose through deep conversation.

CORE MISSION:
- Help users discover their authentic purpose through the 7-phase journey
- Each phase digs deeper: childhood call → conflicts → mirror work → mentor → life task → path → promise
- Be conversational, warm, and deeply curious - like a wise friend, not a therapist
- Ask ONE powerful question at a time, then LISTEN deeply to their response
- Build on what they share - reference their previous answers to show you're paying attention

CONVERSATION STYLE:
- Keep responses SHORT: 2-3 sentences maximum (60-100 words)
- Ask ONE specific, penetrating question per turn
- Use their NAME if you know it
- Be direct, real, and challenge surface-level answers
- Push for CONCRETE scenes: "Tell me about a specific Tuesday when..." not abstract ideals
- If they're vague, ask for more detail: "What did that look like? Give me a real example."

RESPONSE FORMAT (JSON):
{
  "coach": "Your 2-3 sentence response + ONE question (60-100 words max)",
  "next_prompt": "A brief hint of what you're exploring",
  "artifacts": {
    "snapshot": "One-line summary of what you learned this turn",
    "red_tags": ["themes", "emerging"],
    "strengths": ["observed", "strengths"]
  }
}

IMPORTANT:
- NEVER write long paragraphs - users want conversation, not essays
- ONE question at a time - make it count
- Build trust through listening, not advice
- Reality > romance: test every claim with "What would a boring Tuesday look like?"
- Tone: warm, curious, real - never preachy or clinical`;

export class FutureYouAIService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY?.trim(),
      timeout: 60000,
    });
  }

  async coachTurn(
    userId: string,
    phase: PhaseId,
    transcript: string,
    profile: any
  ): Promise<CoachResponse> {
    console.log(`[FutureYou AI] Starting coach turn for user ${userId}, phase: ${phase}`);
    
    const cacheKey = this.getCacheKey(phase, transcript, profile);
    const cached = await redis.get(cacheKey);
    if (cached) {
      console.log(`[FutureYou AI] Cache hit for ${phase}`);
      return JSON.parse(cached);
    }

    const userMsg = this.buildUserMessage(phase, transcript, profile);
    console.log(`[FutureYou AI] Sending to OpenAI, model: ${process.env.FUTUREYOU_AI_MODEL || 'gpt-4o-mini'}`);
    
    const response = await this.client.chat.completions.create({
      model: process.env.FUTUREYOU_AI_MODEL || 'gpt-4o-mini', // Fix: use gpt-4o-mini, not gpt-5-mini
      max_completion_tokens: Number(process.env.FUTUREYOU_MAX_TOKENS || 900),
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userMsg }
      ]
    });

    const content = response.choices[0]?.message?.content?.trim() || '{}';
    console.log(`[FutureYou AI] Received response, length: ${content.length}`);
    
    const parsed = this.safeParseJSON(content);
    
    const result: CoachResponse = {
      coach: parsed.coach || 'Keep going.',
      next_prompt: parsed.next_prompt || 'Tell me more.',
      artifacts: parsed.artifacts,
    };

    console.log(`[FutureYou AI] Parsed coach response: ${result.coach.substring(0, 100)}...`);

    await redis.setex(
      cacheKey,
      Number(process.env.FUTUREYOU_CACHE_TTL_SEC || 86400),
      JSON.stringify(result)
    );

    return result;
  }

  private buildUserMessage(phase: PhaseId, transcript: string, profile: any): string {
    return `PHASE: ${phase}
TRANSCRIPT (last 2000 chars):
${transcript.slice(-2000)}

PROFILE:
${JSON.stringify(profile, null, 2)}

Provide next coaching turn.`;
  }

  private getCacheKey(phase: PhaseId, transcript: string, profile: any): string {
    const hash = crypto
      .createHash('sha1')
      .update(JSON.stringify({ phase, transcript: transcript.slice(-2000), profile }))
      .digest('hex');
    return `fy:cache:ai:${hash}`;
  }

  private safeParseJSON(content: string): any {
    try {
      return JSON.parse(content);
    } catch {
      // Extract JSON from markdown code blocks
      const match = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
      if (match) {
        try {
          return JSON.parse(match[1]);
        } catch {
          return {};
        }
      }
      return {};
    }
  }
}

