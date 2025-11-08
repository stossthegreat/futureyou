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
FUTUREYOU_CACHE_TTL_SEC=86400
```

## Phase 1 vs Phase 2
Phase 1 (current): Coaching API + DB + sync chapter generation
Phase 2 (future): Book compilation workers, summarization, exports

## Toggle
Set FUTUREYOU_ENABLED=true to activate.

