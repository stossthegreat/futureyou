# Memory Intelligence OS - Migration Guide

## Database Migration Required

After deploying this code, run the following migration on your production database:

```sql
-- Add osMemoryEnabled flag to User table
ALTER TABLE "User" ADD COLUMN "osMemoryEnabled" BOOLEAN NOT NULL DEFAULT false;
```

Or use Prisma migrate:

```bash
npx prisma migrate deploy
```

## Enabling the Memory System for Users

### For New Users (Recommended)
The system will automatically be disabled by default (`osMemoryEnabled = false`). To enable for new signups, update user creation logic:

```typescript
await prisma.user.create({
  data: {
    // ... other fields ...
    osMemoryEnabled: true  // Enable for new users
  }
});
```

### For Existing Users (Manual Enable)
To enable the memory system for specific test users:

```sql
UPDATE "User" SET "osMemoryEnabled" = true WHERE id = 'user_id_here';
```

## Testing the System

### 1. Analyze Patterns
```bash
curl -X POST http://localhost:3000/admin/analyze-patterns/USER_ID
```

### 2. Check Phase Transition
```bash
curl -X POST http://localhost:3000/admin/check-phase-transition/USER_ID
```

### 3. View User Consciousness
```bash
curl http://localhost:3000/admin/consciousness/USER_ID
```

## What Gets Created

The system stores data in `UserFacts.json` with the following structure:

```json
{
  "os_phase": {
    "current_phase": "observer",
    "started_at": "2025-01-01",
    "days_in_phase": 15,
    "phase_transitions": []
  },
  "behaviorPatterns": {
    "drift_windows": [],
    "consistency_score": 0,
    "avoidance_triggers": [],
    "return_protocols": [],
    "last_analyzed": "2025-01-15"
  },
  "reflectionHistory": {
    "themes": [],
    "emotional_arc": "flat",
    "depth_score": 0
  },
  "architect": {
    "structural_integrity_score": 0,
    "system_faults": [],
    "return_protocols": [],
    "focus_pillars": [],
    "drag_map": {}
  },
  "oracle": {
    "legacy_code": [],
    "self_knowledge_journal": [],
    "meaning_graph": {}
  }
}
```

## Redis Keys

Short-term memory uses Redis with these keys:
- `conversation:{userId}` - Last 100 messages, 30-day TTL
- `dialogue_meta:{userId}` - Emotional state, contradictions, preferences

## Verification

After enabling for a test user:

1. Complete discovery (sets `identity.discoveryCompleted = true`)
2. Add 10+ chat_message events (reflections)
3. Call `/admin/analyze-patterns/:userId`
4. Check consciousness: `/admin/consciousness/:userId`
5. Verify phase is "observer"
6. Call `/admin/check-phase-transition/:userId` to see transition criteria
7. Generate brief/nudge and verify voice adapts to phase

## Rollback

If issues occur, disable the system:

```sql
UPDATE "User" SET "osMemoryEnabled" = false WHERE "osMemoryEnabled" = true;
```

Users will automatically fall back to the legacy AI system.

