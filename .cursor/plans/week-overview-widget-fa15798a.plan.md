<!-- fa15798a-1cdc-4598-8bf0-ebb379050009 b456d323-df0d-4ff1-93eb-65debbd74b5a -->
# Future-You Unified Engine - Phase 1 Implementation

## Overview

Add-only implementation of Future-You purpose coaching engine with 7-phase orchestration, structured AI responses, and immediate chapter generation. All new code under `/backend/src/modules/futureyou/` namespace, protected by `FUTUREYOU_ENABLED` env flag.

## Phase 1 Scope

- ✅ Coaching API with phase orchestration
- ✅ DB models for purpose profiles, chapters, and jobs
- ✅ Per-phase chapter writing (immediate, not queued)
- ⏸️ Phase 2: Book compilation workers, summarization, cache warming, exports

---

## 1. Environment Variables

Add to `.env` and document in README:

```env
# Future-You Unified Engine
FUTUREYOU_ENABLED=false
FUTUREYOU_AI_MODEL=gpt-5-mini
FUTUREYOU_MAX_TOKENS=900
FUTUREYOU_TEMPERATURE=0.7
FUTUREYOU_CACHE_TTL_SEC=86400
```

---

## 2. Prisma Schema (backend/prisma/schema.prisma)

Add 4 new models at end of file:

```prisma
model FutureYouPurposeProfile {
  id            String   @id @default(cuid())
  userId        String   @unique @index
  lifeTask      String?
  strengths     String[] @default([])
  valuesRank    String[] @default([])
  sdtAutonomy   Int?
  sdtCompetence Int?
  sdtRelatedness Int?
  flowContexts  String[] @default([])
  redTags       String[] @default([])
  odysseyPlans  Json?
  keystones     String[] @default([])
  antiHabits    String[] @default([])
  lastReviewAt  DateTime?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model FutureYouChapter {
  id         String   @id @default(cuid())
  userId     String   @index
  phase      String
  title      String
  bodyMd     String
  words      Int
  draftHash  String   @index
  status     String   @default("final")
  createdAt  DateTime @default(now())
  @@index([userId, phase])
}

model FutureYouBookEdition {
  id         String   @id @default(cuid())
  userId     String   @index
  version    Int
  title      String
  bodyMd     String
  chapterIds String[]
  createdAt  DateTime @default(now())
}

model FutureYouJob {
  id         String   @id @default(cuid())
  userId     String   @index
  type       String
  payload    Json
  status     String   @default("queued")
  error      String?
  insertedAt DateTime @default(now())
  startedAt  DateTime?
  finishedAt DateTime?
  idemKey    String   @unique
}
```

Run: `npx prisma migrate dev --name add_futureyou_models`

---

## 3. Module Structure

Create `/backend/src/modules/futureyou/` with:

```
modules/futureyou/
├── controllers/
│   ├── engine.controller.ts
│   └── chapters.controller.ts
├── services/
│   ├── ai.service.ts
│   ├── phases.service.ts
│   ├── chapters.service.ts
│   └── purpose.service.ts
├── dto/
│   └── engine.dto.ts
├── router.ts
└── README.md
```

---

## 4. DTOs (dto/engine.dto.ts)

```typescript
export type PhaseId = 'call' | 'conflict' | 'mirror' | 'mentor' | 'task' | 'path' | 'promise' | 'review';

export interface EngineStartDTO {
  phase: PhaseId;
  scenes?: Array<{ role: 'user' | 'coach'; text: string }>;
  idemKey?: string;
}

export interface CoachResponse {
  coach: string;
  next_prompt: string;
  artifacts?: {
    snapshot?: string;
    red_tags?: string[];
    strengths?: string[];
    values_rank?: string[];
    sdt?: { autonomy?: number; competence?: number; relatedness?: number };
    flow_contexts?: string[];
  };
  shouldGenerateChapter?: boolean;
}

export interface ChapterDTO {
  phase: PhaseId;
  title?: string;
  body?: string;
}
```

---

## 5. AI Service (services/ai.service.ts)

Structured AI coaching with strict JSON validation:

````typescript
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
      temperature: Number(process.env.FUTUREYOU_TEMPERATURE || 0.7),
      max_tokens: Number(process.env.FUTUREYOU_MAX_TOKENS || 900),
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
````

---

## 6. Phase Orchestration (services/phases.service.ts)

Maps 7 phases to coaching goals and exit criteria:

```typescript
import { PhaseId } from '../dto/engine.dto';

interface PhaseConfig {
  title: string;
  goal: string;
  exitCriteria: (profile: any, scenes: any[]) => boolean;
  chapterPrompt: string;
}

export const PHASES: Record<PhaseId, PhaseConfig> = {
  call: {
    title: 'Chapter I — The Call',
    goal: 'Excavate childhood pull, first peak experience scene',
    exitCriteria: (p, s) => s.some(sc => sc.text.length > 200),
    chapterPrompt: 'Write Chapter I: The Call. TTS-friendly markdown, 350-600 words. Focus on the childhood moment when purpose first whispered.'
  },
  conflict: {
    title: 'Chapter II — The Conflict',
    goal: 'False paths, persona pressure, anti-regret lens',
    exitCriteria: (p) => p.redTags && p.redTags.length > 0,
    chapterPrompt: 'Write Chapter II: The Conflict. 350-600 words. Explore false paths taken, societal pressures, what they fear regretting.'
  },
  mirror: {
    title: 'Chapter III — The Mirror',
    goal: 'Shadow work, envy map, embarrassment test',
    exitCriteria: (p) => p.strengths && p.strengths.length >= 2,
    chapterPrompt: 'Write Chapter III: The Mirror. 350-600 words. Shadow work, envy as compass, embarrassment test reveals truth.'
  },
  mentor: {
    title: 'Chapter IV — The Mentor',
    goal: 'Internal mentor dialogue, wisdom distilled',
    exitCriteria: (p, s) => s.length >= 4,
    chapterPrompt: 'Write Chapter IV: The Mentor. 350-600 words. Internal mentor emerges, wisdom distilled from pain.'
  },
  task: {
    title: 'Chapter V — The Task',
    goal: 'One-sentence Life Task + keystones',
    exitCriteria: (p) => !!p.lifeTask && p.keystones && p.keystones.length > 0,
    chapterPrompt: 'Write Chapter V: The Task. 350-600 words. The one-sentence life task crystallizes. Keystones identified.'
  },
  path: {
    title: 'Chapter VI — The Path',
    goal: 'Odyssey micro-experiments, boring Tuesday schedule',
    exitCriteria: (p) => !!p.odysseyPlans,
    chapterPrompt: 'Write Chapter VI: The Path. 350-600 words. Odyssey plans sketched, boring Tuesday schedule, next 90 days.'
  },
  promise: {
    title: 'Chapter VII — The Promise',
    goal: 'Commitment scene, small verifiable stakes',
    exitCriteria: (p, s) => s.some(sc => sc.text.includes('commit') || sc.text.includes('promise')),
    chapterPrompt: 'Write Chapter VII: The Promise. 350-600 words. The commitment moment. Small, verifiable stakes. No turning back.'
  },
  review: {
    title: 'Chapter VIII — The Review',
    goal: 'Reflection on journey, what changed',
    exitCriteria: () => true,
    chapterPrompt: 'Write Chapter VIII: The Review. 350-600 words. Reflection on the journey, what shifted, ongoing commitment.'
  }
};

export class PhasesService {
  shouldGenerateChapter(phase: PhaseId, profile: any, scenes: any[]): boolean {
    return PHASES[phase].exitCriteria(profile, scenes);
  }

  getPhaseTitle(phase: PhaseId): string {
    return PHASES[phase].title;
  }

  getChapterPrompt(phase: PhaseId): string {
    return PHASES[phase].chapterPrompt;
  }
}
```

---

## 7. Chapters Service (services/chapters.service.ts)

Immediate chapter generation (not queued for Phase 1):

```typescript
import crypto from 'crypto';
import { prisma } from '../../../utils/db';
import { FutureYouAIService } from './ai.service';
import { PhasesService } from './phases.service';
import { PhaseId } from '../dto/engine.dto';

export class ChaptersService {
  private ai = new FutureYouAIService();
  private phases = new PhasesService();

  async generateChapter(userId: string, phase: PhaseId, seed?: string): Promise<any> {
    const prompt = this.phases.getChapterPrompt(phase);
    const userMsg = seed 
      ? `${prompt}\n\nSEED CONTENT:\n${seed}`
      : prompt;

    const response = await this.ai.coachTurn(userId, phase, userMsg, {});
    const draft = response.coach;
    const words = this.countWords(draft);
    const draftHash = crypto.createHash('sha1').update(draft).digest('hex');

    // Check for duplicate
    const existing = await prisma.futureYouChapter.findFirst({
      where: { userId, phase, draftHash }
    });
    
    if (existing) return existing;

    return await prisma.futureYouChapter.create({
      data: {
        userId,
        phase,
        title: this.phases.getPhaseTitle(phase),
        bodyMd: draft,
        words,
        draftHash,
        status: 'final'
      }
    });
  }

  async listChapters(userId: string): Promise<any[]> {
    return await prisma.futureYouChapter.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      select: { id: true, phase: true, title: true, words: true, createdAt: true }
    });
  }

  private countWords(text: string): number {
    return text.split(/\s+/).filter(w => w.length > 0).length;
  }
}
```

---

## 8. Purpose Service (services/purpose.service.ts)

Manages purpose profiles and artifact updates:

```typescript
import { prisma } from '../../../utils/db';

export class PurposeService {
  async getOrCreateProfile(userId: string): Promise<any> {
    let profile = await prisma.futureYouPurposeProfile.findUnique({
      where: { userId }
    });

    if (!profile) {
      profile = await prisma.futureYouPurposeProfile.create({
        data: { userId }
      });
    }

    return profile;
  }

  async updateArtifacts(userId: string, artifacts: any): Promise<void> {
    const updates: any = {};
    
    if (artifacts.snapshot) updates.lifeTask = artifacts.snapshot;
    if (artifacts.strengths) updates.strengths = artifacts.strengths;
    if (artifacts.values_rank) updates.valuesRank = artifacts.values_rank;
    if (artifacts.flow_contexts) updates.flowContexts = artifacts.flow_contexts;
    if (artifacts.red_tags) updates.redTags = artifacts.red_tags;
    if (artifacts.sdt) {
      if (artifacts.sdt.autonomy !== undefined) updates.sdtAutonomy = artifacts.sdt.autonomy;
      if (artifacts.sdt.competence !== undefined) updates.sdtCompetence = artifacts.sdt.competence;
      if (artifacts.sdt.relatedness !== undefined) updates.sdtRelatedness = artifacts.sdt.relatedness;
    }

    if (Object.keys(updates).length > 0) {
      await prisma.futureYouPurposeProfile.update({
        where: { userId },
        data: updates
      });
    }
  }
}
```

---

## 9. Engine Controller (controllers/engine.controller.ts)

Phase coaching endpoint:

```typescript
import { FastifyInstance } from 'fastify';
import { FutureYouAIService } from '../services/ai.service';
import { PhasesService } from '../services/phases.service';
import { ChaptersService } from '../services/chapters.service';
import { PurposeService } from '../services/purpose.service';
import { EngineStartDTO } from '../dto/engine.dto';

export async function engineController(fastify: FastifyInstance) {
  const ai = new FutureYouAIService();
  const phases = new PhasesService();
  const chapters = new ChaptersService();
  const purpose = new PurposeService();

  fastify.post<{ Body: EngineStartDTO }>('/engine/phase', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    const { phase, scenes = [] } = req.body;
    if (!phase) {
      return reply.code(400).send({ error: 'Missing phase' });
    }

    // Get profile
    const profile = await purpose.getOrCreateProfile(userId);

    // Build transcript
    const transcript = scenes.map(s => `${s.role}: ${s.text}`).join('\n\n');

    // Get coach response
    const response = await ai.coachTurn(userId, phase, transcript, profile);

    // Update artifacts if present
    if (response.artifacts) {
      await purpose.updateArtifacts(userId, response.artifacts);
    }

    // Check if should generate chapter
    const shouldGenerate = phases.shouldGenerateChapter(phase, profile, scenes);
    response.shouldGenerateChapter = shouldGenerate;

    // If chapter needed, generate immediately (Phase 1: sync)
    let chapterId: string | undefined;
    if (shouldGenerate) {
      const chapter = await chapters.generateChapter(userId, phase, transcript);
      chapterId = chapter.id;
    }

    return {
      ...response,
      chapterId
    };
  });
}
```

---

## 10. Chapters Controller (controllers/chapters.controller.ts)

Chapter CRUD endpoints:

```typescript
import { FastifyInstance } from 'fastify';
import { ChaptersService } from '../services/chapters.service';
import { ChapterDTO } from '../dto/engine.dto';

export async function chaptersController(fastify: FastifyInstance) {
  const chapters = new ChaptersService();

  fastify.post<{ Body: ChapterDTO }>('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const { phase, title, body } = req.body;
    if (!phase) return reply.code(400).send({ error: 'Missing phase' });

    const chapter = await chapters.generateChapter(userId, phase, body);
    return { chapter };
  });

  fastify.get('/chapters', async (req, reply) => {
    const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
    if (!userId) return reply.code(401).send({ error: 'Unauthorized' });

    const list = await chapters.listChapters(userId);
    return { chapters: list };
  });
}
```

---

## 11. Router (router.ts)

Module router with FUTUREYOU_ENABLED guard:

```typescript
import { FastifyInstance } from 'fastify';
import { engineController } from './controllers/engine.controller';
import { chaptersController } from './controllers/chapters.controller';

export async function futureYouRouter(fastify: FastifyInstance) {
  // Guard: only register if enabled
  if (process.env.FUTUREYOU_ENABLED !== 'true') {
    fastify.get('/status', async () => ({ enabled: false }));
    return;
  }

  fastify.get('/status', async () => ({ enabled: true }));
  
  await fastify.register(engineController, { prefix: '/api/futureyou' });
  await fastify.register(chaptersController, { prefix: '/api/futureyou' });
}
```

---

## 12. Server Integration (server.ts)

Add router mount inside protected routes:

```typescript
// ADD-ONLY: inside protectedRoutes.register() block after line 110
import { futureYouRouter } from './modules/futureyou/router';

// ... existing code ...
protectedRoutes.register(whatIfChatControllerV2);

// ADD HERE:
protectedRoutes.register(futureYouRouter);
```

---

## 13. README (modules/futureyou/README.md)

````markdown
# Future-You Unified Engine

Purpose coaching system with 7-phase orchestration.

## Phases
1. call - Childhood pull, first scene
2. conflict - False paths, persona pressure
3. mirror - Shadow work, envy map
4. mentor - Internal mentor dialogue
5. task - One-sentence Life Task
6. path - Odyssey plans, boring Tuesday
7. promise - Commitment scene

## Namespaces
- Routes: /api/futureyou/*
- DB: FutureYou* models
- Redis: fy:* keys

## Environment
```env
FUTUREYOU_ENABLED=false
FUTUREYOU_AI_MODEL=gpt-5-mini
FUTUREYOU_MAX_TOKENS=900
FUTUREYOU_TEMPERATURE=0.7
````

## Phase 1 vs Phase 2

Phase 1 (current): Coaching API + DB + sync chapter generation

Phase 2 (future): Book compilation workers, summarization, exports

## Toggle

Set FUTUREYOU_ENABLED=true to activate.

```

---

## Acceptance Criteria

1. With FUTUREYOU_ENABLED=false, `/api/futureyou/status` returns `{enabled: false}`
2. With FUTUREYOU_ENABLED=true:

   - POST `/api/futureyou/engine/phase` with valid phase returns coach response
   - Artifacts update purpose profile in DB
   - When exit criteria met, chapter generated immediately
   - GET `/api/futureyou/chapters` returns user's chapters

3. Duplicate chapters deduped by draftHash
4. No impact on existing Habit OS functionality
5. Migration runs cleanly with 4 new models

---

## Files to Create/Modify

CREATE:

- backend/src/modules/futureyou/controllers/engine.controller.ts
- backend/src/modules/futureyou/controllers/chapters.controller.ts
- backend/src/modules/futureyou/services/ai.service.ts
- backend/src/modules/futureyou/services/phases.service.ts
- backend/src/modules/futureyou/services/chapters.service.ts
- backend/src/modules/futureyou/services/purpose.service.ts
- backend/src/modules/futureyou/dto/engine.dto.ts
- backend/src/modules/futureyou/router.ts
- backend/src/modules/futureyou/README.md

MODIFY:

- backend/prisma/schema.prisma (add 4 models)
- backend/src/server.ts (register router)
- backend/.env (add FUTUREYOU_* vars)
- backend/README.md (document env vars)

### To-dos

- [ ] Add copy button + SelectableText to What-If chat messages
- [ ] Add copy button + SelectableText to Future-You chat messages
- [ ] Remove .take(3) limit and commit all micro-habits with proper formatting
- [ ] Test longest preset (8 steps) to ensure habit card displays properly