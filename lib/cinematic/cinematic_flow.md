# 🎬 CORRECT CINEMATIC FLOW

## THE ACTUAL USER EXPERIENCE:

### PHASE 1 - THE CALL

**Step 1: Cinematic Intro**
- Black screen → particles fade in → music starts
- Title appears: "Chapter I — The Call"
- Intro text types out word by word:
  "The world is still. Something inside you is awake..."
- TTS reads it aloud
- **Duration: 30-45 seconds**

**Step 2: AI Conversation Begins**
- Intro fades slightly (stays visible at top)
- Chat interface slides up from bottom
- AI's first message appears:
  "Tell me about a moment in your childhood when you felt most alive. 
   A specific scene. Where were you? What were you doing?"
- User types their answer
- AI responds with follow-up questions
- **5-8 message back-and-forth conversation**

**Step 3: Chapter Generation**
- AI says: "I have what I need. Generating your chapter..."
- Loading animation (2-3 seconds)
- POST /api/futureyou/chapters with phase + conversation transcript
- Backend AI writes a 350-600 word CUSTOM chapter about THE USER

**Step 4: Chapter Display**
- Chat interface fades out
- Custom chapter appears with typing animation
- TTS reads it aloud
- "Next →" button appears
- User taps → moves to Phase 2

### PHASES 2-7: REPEAT THE SAME FLOW

Each phase:
1. Cinematic intro (phase-specific)
2. AI conversation (phase-specific questions)
3. Chapter generation (custom to user)
4. Chapter display
5. Next button

### PHASE 8: BOOK COMPILATION

- "Your journey is complete"
- "Compile Your Book" button
- POST /api/futureyou/book/compile
- Display all 7 CUSTOM chapters in one beautiful book
- Share/export options

---

## THE UI COMPONENTS NEEDED:

### 1. CinematicScene (per phase)
```dart
- Background (particles + gradient)
- Music player
- Three states:
  1. INTRO (typing animation + TTS)
  2. CHAT (AI conversation interface)
  3. CHAPTER (generated chapter display)
```

### 2. CinematicChat
```dart
- Messages list (AI + user)
- Input field
- Send button
- Connects to: POST /api/futureyou/engine/phase
- Detects when AI says phase complete
```

### 3. ChapterGenerator
```dart
- Loading animation
- Calls: POST /api/futureyou/chapters
- Displays generated chapter with typing effect
- TTS reads aloud
```

### 4. BookCompiler
```dart
- Calls: POST /api/futureyou/book/compile
- Fetches: GET /api/futureyou/book/latest
- Displays all chapters
- Share/export
```

---

## API INTEGRATION:

### During Intro → Chat:
```dart
POST /api/futureyou/engine/phase
{
  "phase": "call",
  "scenes": [
    {"role": "user", "text": "I remember playing in the woods..."},
    {"role": "coach", "text": "Tell me more about that..."}
  ]
}

Response:
{
  "coach": "What did you feel in that moment?",
  "next_prompt": "...",
  "shouldGenerateChapter": false
}
```

### When AI Determines Phase Complete:
```dart
Response:
{
  "coach": "I have what I need.",
  "shouldGenerateChapter": true
}

→ Trigger chapter generation
```

### Generate Chapter:
```dart
POST /api/futureyou/chapters
{
  "phase": "call",
  "title": "Chapter I — The Call",
  "body": "<user's conversation transcript>"
}

Response:
{
  "chapter": {
    "id": "...",
    "phase": "call",
    "title": "Chapter I — The Call",
    "bodyMd": "Felix's earliest memory... <custom 500 word chapter>",
    "words": 523
  }
}
```

---

## THE TRUTH:

**This is NOT a story playback.**
**This is an AI-powered purpose discovery journey.**

Every chapter is CUSTOM.
Every conversation is UNIQUE.
The book is ABOUT THE USER.

That's the masterpiece.

