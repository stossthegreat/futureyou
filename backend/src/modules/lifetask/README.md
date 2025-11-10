# Life's Task Discovery Engine - Backend

Complete backend implementation for the deep excavation purpose discovery system.

## Architecture

**Local-First Design:**
- During conversations: No database writes, all state in Flutter
- At chapter completion: One bulk write with transcript + patterns + prose
- Zero impact on existing Habit OS

**Two AI Modes:**
1. **ExcavationCoach** - Deep questioning (T=0.8, 200 tokens/response)
2. **ProseWriter** - Literary prose generation (T=0.9, 1000 tokens)

## API Endpoints

### Conversation Flow

#### `POST /api/lifetask/converse`
Generate next coach response during conversation.

**Request:**
```json
{
  "chapterNumber": 1,
  "messages": [
    { "role": "user", "text": "...", "timestamp": "..." },
    { "role": "coach", "text": "..." }
  ],
  "sessionStartTime": "2025-11-10T14:30:00Z"
}
```

**Response:**
```json
{
  "coachMessage": "Tell me about one childhood moment...",
  "shouldContinue": true,
  "depthMetrics": {
    "exchangeCount": 5,
    "timeElapsedMinutes": 12,
    "specificScenesCollected": 2,
    "emotionalMarkersDetected": 1,
    "vagueResponseRatio": 0.4,
    "minimumExchangesMet": false,
    "minimumTimeMet": false,
    "qualityChecksPassed": false
  },
  "extractedPatterns": {
    "redThreads": ["build", "create"],
    "values": ["autonomy", "impact"],
    "strengths": ["creativity", "curiosity"],
    "flowContexts": ["..."],
    "emotionalMarkers": ["vulnerability", "aliveness"]
  },
  "nextPromptHint": "Continue exploration. Need 10 more exchanges minimum."
}
```

#### `POST /api/lifetask/save-chapter`
Save completed chapter with prose generation.

**Request:**
```json
{
  "chapterNumber": 1,
  "messages": [...],
  "timeSpentMinutes": 45,
  "sessionStartTime": "2025-11-10T14:30:00Z"
}
```

**Response:**
```json
{
  "chapterId": "clx...",
  "proseGenerated": true,
  "proseText": "The world was smaller then...",
  "artifactsUpdated": ["story_map"]
}
```

### Chapters & Progress

#### `GET /api/lifetask/chapters`
Get all chapters for user.

#### `GET /api/lifetask/chapters/:chapterNumber`
Get specific chapter (1-7).

#### `GET /api/lifetask/progress`
Get progress summary.

**Response:**
```json
{
  "chaptersCompleted": [1, 2, 3],
  "totalChapters": 7,
  "artifactsGenerated": ["story_map", "shadow_map", "strengths_grid"],
  "bookCompiled": false,
  "totalTimeSpent": 135
}
```

#### `DELETE /api/lifetask/chapters/:chapterNumber`
Delete a chapter (for restart).

### Artifacts

#### `GET /api/lifetask/artifacts`
Get all vault artifacts.

#### `GET /api/lifetask/artifacts/:artifactType`
Get specific artifact (story_map, shadow_map, strengths_grid, flow_map, odyssey_plans, job_crafting, purpose_card, mastery_path).

### Book Compilation

#### `POST /api/lifetask/book/compile`
Compile all completed chapters into publishable book.

**Request:**
```json
{
  "title": "Your Life's Task: A Journey of Discovery"
}
```

**Response:**
```json
{
  "bookId": "clx...",
  "title": "Your Life's Task...",
  "compiledMarkdown": "# Your Life's Task...",
  "chapterCount": 7,
  "wordCount": 3542,
  "version": 1
}
```

#### `GET /api/lifetask/book/latest`
Get latest compiled book.

#### `GET /api/lifetask/book/:bookId`
Get specific book by ID.

## Database Schema

```prisma
model LifeTaskChapter {
  id                    String   @id @default(cuid())
  userId                String
  chapterNumber         Int      // 1-7
  conversationTranscript Json    // Full message history
  extractedPatterns     Json?    // Red threads, values, strengths
  proseText             String?  // 350-600 word generated chapter
  completedAt           DateTime?
  timeSpentMinutes      Int      @default(0)
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  
  @@unique([userId, chapterNumber])
}

model LifeTaskArtifact {
  id           String   @id @default(cuid())
  userId       String
  artifactType String   // 'story_map', 'shadow_map', etc.
  data         Json     // Artifact-specific structure
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@unique([userId, artifactType])
}

model LifeTaskBook {
  id               String   @id @default(cuid())
  userId           String
  title            String
  compiledMarkdown String   @db.Text
  chapterIds       String[]
  createdAt        DateTime @default(now())
  version          Int      @default(1)
}
```

## Chapter Configurations

### Chapter 1: The Call (40min, 15+ exchanges)
- **Frameworks**: Greene - Mastery, Narrative Identity
- **Goal**: Excavate childhood pull, primal inclinations
- **Artifact**: Story Map

### Chapter 2: The Conflict (50min, 18+ exchanges)
- **Frameworks**: Jung - Shadow, Frankl - Anti-regret
- **Goal**: Shadow work, false paths, envy map
- **Artifact**: Shadow Map

### Chapter 3: The Mirror (45min, 16+ exchanges)
- **Frameworks**: VIA Strengths, SDT, Values Hierarchy
- **Goal**: Strengths × Values mapping
- **Artifact**: Strengths Grid

### Chapter 4: The Mentor (40min, 15+ exchanges)
- **Frameworks**: Flow Theory, Energy Audit
- **Goal**: Flow mapping, energy patterns
- **Artifact**: Flow Map

### Chapter 5: The Task (60min, 20+ exchanges)
- **Frameworks**: Odyssey Planning, Job Crafting, Frankl - Meaning
- **Goal**: Future prototypes, meaning tests
- **Artifacts**: Odyssey Plans, Job Crafting Canvas

### Chapter 6: The Path (50min, 18+ exchanges)
- **Frameworks**: Life Crafting, Keystone Habits
- **Goal**: One-sentence task, habits, commitment
- **Artifact**: Purpose Card

### Chapter 7: The Promise (40min, 15+ exchanges)
- **Frameworks**: Deliberate Practice, Monthly Reviews, Legacy
- **Goal**: Review structure, mastery path
- **Artifact**: Mastery Path

## Services

### ExcavationCoachService
- Deep questioning AI with research-based prompts
- Pushes back on vague answers
- Never rushes to chapter completion
- Cites frameworks (Greene, Jung, Frankl, SDT, Flow)

### ProseWriterService
- Literary AI for 350-600 word chapters
- Future-You voice (fulfilled future self)
- Uses user's specific words and scenes
- Publishable quality prose

### DepthValidatorService
- Ensures conversations meet criteria before completion
- Tracks: exchanges, time, scenes, emotional markers, vagueness
- Provides hints for next AI prompts

### PatternExtractorService
- Extracts red threads, values, strengths, flow contexts
- Identifies emotional markers
- Generates key quotes
- Chapter-specific theme extraction

## Environment Variables

```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini  # or gpt-4o for prose generation
DATABASE_URL=postgresql://...
```

## Migration

When deploying to production, run:

```bash
npx prisma migrate deploy
```

This will create the three new tables without affecting existing ones.

## Testing

```bash
# Test conversation endpoint
curl -X POST http://localhost:8080/api/lifetask/converse \
  -H "Content-Type: application/json" \
  -H "x-user-id: test-user-123" \
  -d '{
    "chapterNumber": 1,
    "messages": [],
    "sessionStartTime": "2025-11-10T14:30:00Z"
  }'

# Test progress endpoint
curl http://localhost:8080/api/lifetask/progress \
  -H "x-user-id: test-user-123"
```

## Next Steps (Flutter Integration)

1. Create `/lib/lifetask/` module
2. Build `DeepChat` widget with local state management
3. Implement cinematic intros with beautiful prose
4. Create 8 artifact card UIs
5. Build book reader with export options
6. Add "Life's Task" card to Future-You tab

---

**Status**: Backend Phase 1 Complete ✅
**Next**: Flutter UI Implementation (Phase 2)

