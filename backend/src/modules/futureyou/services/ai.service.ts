import OpenAI from 'openai';
import crypto from 'crypto';
import { redis } from '../../../utils/redis';
import { PhaseId, CoachResponse } from '../dto/engine.dto';

const SYSTEM_PROMPT = `You are FUTURE-YOU, a rigorous purpose coach.
Rules:
- Model: gpt-5-mini. Cite frameworks briefly (Greene, Jung, Frankl, SDT, Flow).
- No skipping phases: excavate → align → direction → commit → review.
- Push for scenes, not slogans. Demand concrete Tuesdays, real names, boring details.
- Reality > romance: run "boring Tuesday" and "anti-regret" tests on claims.
- Output JSON with { coach, next_prompt, artifacts? }.
- NEVER alter user memory; return artifacts for worker to persist.
- Tone: short, precise, curious; never preachy.

Format:
{
  "coach": "string (<= 220 words, 2-3 paragraphs)",
  "next_prompt": "string",
  "artifacts": {
    "snapshot?": "...",
    "red_tags?": ["build","clarify"],
    "strengths?": ["creativity","fairness"],
    "values_rank?": ["autonomy","impact"],
    "sdt?": {"autonomy":7,"competence":8,"relatedness":5},
    "flow_contexts?": ["..."]
  }
}`;

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
    const cacheKey = this.getCacheKey(phase, transcript, profile);
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const userMsg = this.buildUserMessage(phase, transcript, profile);
    
    const response = await this.client.chat.completions.create({
      model: process.env.FUTUREYOU_AI_MODEL || 'gpt-5-mini',
      // temperature: removed - GPT-5-mini only supports default (1)
      max_completion_tokens: Number(process.env.FUTUREYOU_MAX_TOKENS || 900),
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userMsg }
      ]
    });

    const content = response.choices[0]?.message?.content?.trim() || '{}';
    const parsed = this.safeParseJSON(content);
    
    const result: CoachResponse = {
      coach: parsed.coach || 'Keep going.',
      next_prompt: parsed.next_prompt || 'Tell me more.',
      artifacts: parsed.artifacts,
    };

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

