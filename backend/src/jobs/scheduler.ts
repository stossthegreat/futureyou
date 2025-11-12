// src/jobs/scheduler.ts
// ✅ OS brain-only scheduler: briefs, debriefs, and nudges (no habit CRUD, no device alarms)
import { Queue, Worker, JobsOptions } from 'bullmq';
import { redis } from '../utils/redis';
import { prisma } from '../utils/db';
import { aiService } from '../services/ai.service';
import { notificationsService } from '../services/notifications.service';

export const schedulerQueue = new Queue('scheduler', { connection: redis });

export async function bootstrapSchedulers() {
  console.log('⏰ Schedulers active (OS brain only)');

  // Re-upsert daily brief/debrief/nudge per user each hour to respect timezone changes
  await schedulerQueue.add('ensure-daily-briefs', {}, repeatHourly());
  await schedulerQueue.add('ensure-evening-debriefs', {}, repeatHourly());
  await schedulerQueue.add('ensure-nudges', {}, repeatHourly()); // ✅ NEW: 3x daily nudges

  // Evaluate nudges hourly (decide to send or skip); strictly observer-driven (LEGACY)
  await schedulerQueue.add('auto-nudges-hourly', {}, repeatHourly());

  // 📅 Weekly memory consolidation (Sundays at midnight)
  await schedulerQueue.add('weekly-consolidation', {}, {
    repeat: { pattern: '0 0 * * 0' }, // Every Sunday at midnight
    removeOnComplete: true,
    removeOnFail: true,
  });
}

new Worker('scheduler', async (job) => {
  switch (job.name) {
    case 'ensure-daily-briefs':       return ensureDailyBriefJobs();
    case 'ensure-evening-debriefs':   return ensureEveningDebriefJobs();
    case 'auto-nudges-hourly':        return runAutoNudges();
    case 'weekly-consolidation':      return runWeeklyConsolidation();
    case 'daily-brief':               return runDailyBrief(job.data.userId);
    case 'evening-debrief':           return runEveningDebrief(job.data.userId);
    case 'nudge-user':                return nudgeUser(job.data.userId, job.data.trigger);
    default: return;
  }
}, { connection: redis });

function repeatHourly(): JobsOptions {
  return { repeat: { every: 60 * 60_000 }, removeOnComplete: true, removeOnFail: true };
}

async function ensureDailyBriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true, briefsEnabled: true } });
  for (const u of users) {
    if (u.briefsEnabled === false) continue;
    const tz = u.tz || 'Europe/London';
    await schedulerQueue.add('daily-brief', { userId: u.id }, {
      repeat: { pattern: '0 7 * * *', tz },
      jobId: `daily-brief:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
  }
  return { ok: true, users: users.length };
}

async function ensureEveningDebriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true, debriefsEnabled: true } });
  for (const u of users) {
    if (u.debriefsEnabled === false) continue;
    const tz = u.tz || 'Europe/London';
    await schedulerQueue.add('evening-debrief', { userId: u.id }, {
      repeat: { pattern: '0 21 * * *', tz },
      jobId: `evening-debrief:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
  }
  return { ok: true, users: users.length };
}

async function runDailyBrief(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  // Inputs: what exists already (habits + recent actions)
  const habits = await prisma.habit.findMany({ where: { userId } });
  const recent = await prisma.event.findMany({
    where: { userId },
    orderBy: { ts: 'desc' },
    take: 50,
  });

  const mentor = (user as any)?.mentorId || 'marcus';
  const prompt = `Morning brief. Facts only, no fluff. Use recent patterns (${recent
    .map(e => e.type).slice(0, 12).join(', ')}) to set 2–3 crisp orders.`;

  const text = await aiService.generateMentorReply(userId, mentor as any, prompt, { purpose: 'brief', maxChars: 500 });

  await prisma.event.create({
    data: { userId, type: 'morning_brief', payload: { text } },
  });

  await notificationsService.send(userId, 'Morning Brief', truncate(text, 180));
  return { ok: true };
}

async function runEveningDebrief(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  const recent = await prisma.event.findMany({
    where: { userId },
    orderBy: { ts: 'desc' },
    take: 100,
  });

  // cast payload as any for TS safety when reading .completed
  const kept = recent.filter(e => e.type === 'habit_action' && (e.payload as any)?.completed === true).length;
  const missed = recent.filter(e => e.type === 'habit_action' && (e.payload as any)?.completed === false).length;

  const mentor = (user as any)?.mentorId || 'marcus';
  const prompt = `Evening debrief. Kept=${kept}, Missed=${missed}. Reflect briefly and give 1 order for tomorrow.`;

  const text = await aiService.generateMentorReply(userId, mentor as any, prompt, { purpose: 'debrief', maxChars: 500 });

  await prisma.event.create({
    data: { userId, type: 'evening_debrief', payload: { text } },
  });

  await notificationsService.send(userId, 'Evening Debrief', truncate(text, 180));
  return { ok: true };
}

async function runAutoNudges() {
  const users = await prisma.user.findMany({ select: { id: true, nudgesEnabled: true } });

  for (const u of users) {
    if (u.nudgesEnabled === false) continue;

    // 🚀 Use new smart nudge detection
    const { nudgesService } = await import('../services/nudges.service');
    const trigger = await nudgesService.shouldNudge(u.id);
    
    if (trigger) {
      await schedulerQueue.add(
        'nudge-user',
        { userId: u.id, trigger },
        { removeOnComplete: true, removeOnFail: true }
      );
    }
  }

  return { ok: true };
}

async function nudgeUser(userId: string, trigger?: any) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  // 🚀 Use new smart nudge generation with context
  const { nudgesService } = await import('../services/nudges.service');
  const result = await nudgesService.generateNudges(userId, trigger);
  
  if (result.success && result.nudges.length > 0) {
    const text = result.nudges[0].message;
    await notificationsService.send(userId, '⚡ Nudge from Future You', truncate(text, 180));
  }
  
  return { ok: true };
}

async function runWeeklyConsolidation() {
  const users = await prisma.user.findMany({ select: { id: true } });
  console.log(`📅 Running weekly consolidation for ${users.length} users...`);
  
  for (const u of users) {
    try {
      const { insightsService } = await import('../services/insights.service');
      const result = await insightsService.weeklyConsolidation(u.id);
      if (result.ok && result.reflection) {
        await notificationsService.send(
          u.id,
          '📊 Weekly Insights',
          truncate(result.reflection, 180)
        );
      }
    } catch (err) {
      console.error(`Failed weekly consolidation for ${u.id}:`, err);
    }
  }
  
  return { ok: true, processed: users.length };
}

function truncate(s: string, n: number) {
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
}
