# 7-Day Welcome Series Setup

## Overview

The 7-Day Welcome Series delivers pre-written messages to all new users over their first week. These messages are NOT AI-generated - they're the same for everyone.

## ⚠️ IMPORTANT: Independent System

**The welcome series is SEPARATE from the AI OS scheduler.** The scheduler handles only AI-generated briefs, debriefs, and nudges. The welcome series runs independently.

## How It Works

1. **User completes onboarding** → Saves name/age via `/api/v1/user/identity`
2. **Welcome series initializes** → Day 1 message delivered immediately
3. **Manual trigger required** → You call the service to deliver Days 2-7

## Architecture

### Files Created

```
backend/
├── src/
│   ├── data/
│   │   └── welcome-series.ts          # Pre-written 7-day content
│   ├── services/
│   │   └── welcome-series.service.ts   # Logic for delivery
│   └── workers/
│       └── scheduler.worker.ts         # Daily job integration
```

### Database Tracking

**Events tracked:**
- `welcome_series_initialized` - When series starts for a user
- `welcome_day_delivered` - Each time a day's message is sent

**Coach Messages:**
- Each welcome message creates a proper `CoachMessage` entry
- Shows up in user's reflections tab automatically
- Works with existing message sync system

## Setup & Deployment

### Option A: Manual Delivery (Recommended)

You control exactly when messages go out. Good for testing and precise timing.

**Deliver next day's message manually:**

```typescript
import { welcomeSeriesService } from './services/welcome-series.service';

// Deliver specific day to specific user
await welcomeSeriesService.deliverDay('user-id', 2); // Day 2
await welcomeSeriesService.deliverDay('user-id', 3); // Day 3
// etc...
```

**Or process all users at once:**

```typescript
// Check all users and deliver next message if it's time
const result = await welcomeSeriesService.processAllUsers();
console.log(`Delivered ${result.delivered} messages to ${result.processed} users`);
```

### Option B: Automated via Separate Cron Job

If you want it automatic, set up a separate cron job (NOT in the AI OS scheduler):

**Using Railway/Render cron:**

```bash
# Add this to your deployment platform's cron jobs
# Runs daily at 8am
0 8 * * * curl -X POST https://your-backend.com/api/v1/welcome-series/process
```

**Create the endpoint in a new controller:**

```typescript
// backend/src/controllers/welcome-series.controller.ts
export async function welcomeSeriesController(fastify: FastifyInstance) {
  fastify.post('/api/v1/welcome-series/process', async (req, reply) => {
    const result = await welcomeSeriesService.processAllUsers();
    return result;
  });
}
```

### Testing

Initialize for a test user:

```bash
curl -X POST https://your-backend.com/api/v1/user/identity \
  -H "x-user-id: test-user-felix" \
  -H "Content-Type: application/json" \
  -d '{"name": "Felix", "age": 25}'

# Day 1 delivered immediately ✅
# For Days 2-7, call manually or wait for cron
```

## Customizing the Content

### Edit Welcome Messages

Edit `/backend/src/data/welcome-series.ts`:

```typescript
export const WELCOME_SERIES: WelcomeDayMessage[] = [
  {
    day: 1,
    title: 'Day 1: Welcome to Your Future',
    kind: 'letter',  // Can be 'letter', 'brief', or 'mirror'
    body: `YOUR ACTUAL DAY 1 CONTENT HERE...`
  },
  // ... Days 2-7
];
```

### Message Kinds

- `letter` - Shows up as weekly OS letter (scroll UI)
- `brief` - Shows up as morning brief
- `mirror` - Shows up as debrief/reflection

## How Users Experience It

1. **Complete onboarding** → Enter name & age
2. **Day 1 arrives immediately** in their reflections tab
3. **Days 2-7 arrive automatically** (one per day at 8am)
4. **Can read anytime** via Reflections tab
5. **Works offline** - synced to Hive locally

## Production Checklist

- [ ] Replace placeholder content in `welcome-series.ts` with actual messages
- [ ] Deploy backend with new files
- [ ] Add `welcome-series-daily` recurring job to scheduler
- [ ] Test with a new test user
- [ ] Verify messages appear in app Reflections tab
- [ ] Monitor logs for delivery confirmations

## Monitoring

Check logs for these messages:

```
🎉 Initializing 7-day welcome series for user: {userId}
✅ Delivered welcome day {X} to user {userId}: "{title}"
✅ Welcome series check complete: {N} messages delivered to {M} users
```

## Future Enhancements

- [ ] Admin dashboard to view series progress per user
- [ ] A/B test different welcome series versions
- [ ] Pause/resume series if user goes inactive
- [ ] Customize delivery times per user timezone
- [ ] Add welcome series completion event/badge

---

**Ready to launch! 🚀**

Just replace the placeholder content with your actual 7-day messages and deploy.

