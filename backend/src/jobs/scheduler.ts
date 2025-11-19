// src/jobs/scheduler.ts
// 🧠 OS brain-only scheduler: briefs, debriefs, nudges, and weekly insights

import { Queue, Worker, JobsOptions } from "bullmq";
import { redis } from "../utils/redis";
import { prisma } from "../utils/db";
import { aiService } from "../services/ai.service";
import { coachMessageService } from "../services/coach-message.service";
import { notificationsService } from "../services/notifications.service";
import { voiceService } from "../services/voice.service";
import { nudgesService } from "../services/nudges.service";

const QUEUE = "scheduler";
export const schedulerQueue = new Queue(QUEUE, { connection: redis });

const PRO_FEATURES_ENABLED =
  (process.env.PRO_FEATURES_ENABLED || "true").toLowerCase() === "true";
const FREE_NOTIFICATIONS_ENABLED =
  (process.env.FREE_NOTIFICATIONS_ENABLED || "false").toLowerCase() === "true";

// Re-usable hourly repeat options (for ensure-* + auto-nudges-hourly)
function repeatHourly(): JobsOptions {
  return {
    repeat: { every: 60 * 60_000 },
    removeOnComplete: true,
    removeOnFail: true,
  };
}

// 🔌 Called from app bootstrap
export async function bootstrapSchedulers() {
  console.log("⏰ Schedulers active (OS brain only)");

  // Re-upsert daily brief / debrief / nudge schedules per user (respect tz)
  // Run every 6 hours instead of hourly to prevent duplicate job creation
  await schedulerQueue.add("ensure-daily-briefs", {}, {
    repeat: { every: 6 * 60 * 60_000 },
    removeOnComplete: true,
    removeOnFail: true,
  });
  await schedulerQueue.add("ensure-evening-debriefs", {}, {
    repeat: { every: 6 * 60 * 60_000 },
    removeOnComplete: true,
    removeOnFail: true,
  });
  await schedulerQueue.add("ensure-nudges", {}, {
    repeat: { every: 6 * 60 * 60_000 },
    removeOnComplete: true,
    removeOnFail: true,
  });

  // REMOVED: auto-nudges-hourly - this was causing duplicate nudges
  // We already have scheduled nudges at 10am, 2pm, and 6pm via ensure-nudges

  // Weekly memory consolidation (Sundays at midnight)
  await schedulerQueue.add("weekly-consolidation", {}, {
    repeat: { pattern: "0 0 * * 0" }, // Sunday 00:00
    removeOnComplete: true,
    removeOnFail: true,
  });
}

// ─────────────────────────────────────────────
// JOB DEFINITIONS
// ─────────────────────────────────────────────

async function ensureDailyBriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true } });
  for (const u of users) {
    const tz = u.tz || "Europe/London";
    await schedulerQueue.add(
      "daily-brief",
      { userId: u.id },
      {
        repeat: { pattern: "0 7 * * *", tz },
        jobId: `daily-brief:${u.id}`,
        removeOnComplete: true,
        removeOnFail: true,
      }
    );
  }
  return { ok: true, users: users.length };
}

async function ensureEveningDebriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true } });
  for (const u of users) {
    const tz = u.tz || "Europe/London";
    await schedulerQueue.add(
      "evening-debrief",
      { userId: u.id },
      {
        repeat: { pattern: "0 21 * * *", tz },
        jobId: `evening-debrief:${u.id}`,
        removeOnComplete: true,
        removeOnFail: true,
      }
    );
  }
  return { ok: true, users: users.length };
}

async function ensureNudgeJobs() {
  const users = await prisma.user.findMany({
    select: { id: true, tz: true, nudgesEnabled: true },
  });

  for (const u of users) {
    if (!u.nudgesEnabled) continue;
    const tz = u.tz || "Europe/London";

    // Remove existing nudge jobs for this user to prevent duplicates
    const jobIds = [
      `nudge-morning:${u.id}`,
      `nudge-afternoon:${u.id}`,
      `nudge-evening:${u.id}`,
    ];
    
    for (const jobId of jobIds) {
      try {
        const job = await schedulerQueue.getJob(jobId);
        if (job) {
          await job.remove();
        }
      } catch (err) {
        // Job doesn't exist, that's fine
      }
    }

    // Morning nudge (10am)
    await schedulerQueue.add(
      "nudge",
      { userId: u.id, trigger: "morning_momentum" },
      {
        repeat: { pattern: "0 10 * * *", tz },
        jobId: `nudge-morning:${u.id}`,
        removeOnComplete: true,
        removeOnFail: true,
      }
    );

    // Afternoon nudge (2pm)
    await schedulerQueue.add(
      "nudge",
      { userId: u.id, trigger: "afternoon_drift" },
      {
        repeat: { pattern: "0 14 * * *", tz },
        jobId: `nudge-afternoon:${u.id}`,
        removeOnComplete: true,
        removeOnFail: true,
      }
    );

    // Evening nudge (6pm)
    await schedulerQueue.add(
      "nudge",
      { userId: u.id, trigger: "evening_closeout" },
      {
        repeat: { pattern: "0 18 * * *", tz },
        jobId: `nudge-evening:${u.id}`,
        removeOnComplete: true,
        removeOnFail: true,
      }
    );
  }
  return { ok: true, users: users.length };
}

async function runDailyBrief(userId: string) {
  const text =
    (await aiService.generateMorningBrief(userId).catch(() => null)) ||
    "Good morning.";

  let audioUrl: string | null = null;
  try {
    audioUrl = await voiceService.ttsToUrl(userId, text, "future-you");
  } catch {
    audioUrl = null;
  }

  // Store as CoachMessage (kind = brief)
  await coachMessageService.createMessage(userId, "brief", text, { audioUrl });

  // Backwards compat event
  await prisma.event.create({
    data: { userId, type: "morning_brief", payload: { text, audioUrl } },
  });

  await notificationsService.send(userId, "Morning Brief", text.slice(0, 180));
  return { ok: true };
}

async function runEveningDebrief(userId: string) {
  const text =
    (await aiService.generateEveningDebrief(userId).catch(() => null)) ||
    "Evening debrief.";

  let audioUrl: string | null = null;
  try {
    audioUrl = await voiceService.ttsToUrl(userId, text, "future-you");
  } catch {
    audioUrl = null;
  }

  // Store as CoachMessage (kind = mirror)
  await coachMessageService.createMessage(userId, "mirror", text, { audioUrl });

  // Backwards compat event
  await prisma.event.create({
    data: { userId, type: "evening_debrief", payload: { text, audioUrl } },
  });

  await notificationsService.send(userId, "Evening Debrief", text.slice(0, 180));
  return { ok: true };
}

async function runNudge(userId: string, trigger: string) {
  const text =
    (await aiService.generateNudge(userId, trigger).catch(() => null)) ||
    "Check in with yourself.";

  // Store as CoachMessage (kind = nudge)
  await coachMessageService.createMessage(userId, "nudge", text, { trigger });

  // Backwards compat event
  await prisma.event.create({
    data: { userId, type: "nudge", payload: { text, trigger } },
  });

  await notificationsService.send(userId, "Nudge", text.slice(0, 180));
  return { ok: true };
}

async function autoNudgesHourly() {
  const users = await prisma.user.findMany({
    select: { id: true, plan: true },
  });

  for (const u of users) {
    if (u.plan !== "PRO" && !FREE_NOTIFICATIONS_ENABLED) continue;

    const res = await nudgesService.generateNudges(u.id);
    const n = Array.isArray(res)
      ? res[0]
      : (res as any).nudges?.[0];

    if (!n?.message) continue;

    await notificationsService.send(
      u.id,
      "Nudge",
      n.message.slice(0, 180)
    );
  }
  return { ok: true };
}

async function runWeeklyConsolidation() {
  const users = await prisma.user.findMany({ select: { id: true } });
  console.log(`📅 Running weekly consolidation for ${users.length} users...`);

  for (const u of users) {
    try {
      const { insightsService } = await import("../services/insights.service");
      const result = await insightsService.weeklyConsolidation(u.id);
      if (result.ok && result.reflection) {
        await notificationsService.send(
          u.id,
          "📊 Weekly Insights",
          result.reflection.slice(0, 180)
        );
      }
    } catch (err) {
      console.error(`Failed weekly consolidation for ${u.id}:`, err);
    }
  }

  return { ok: true, processed: users.length };
}

// ─────────────────────────────────────────────
// WORKER
// ─────────────────────────────────────────────

new Worker(
  QUEUE,
  async (job) => {
    switch (job.name) {
      case "ensure-daily-briefs":
        return ensureDailyBriefJobs();
      case "ensure-evening-debriefs":
        return ensureEveningDebriefJobs();
      case "ensure-nudges":
        return ensureNudgeJobs();
      case "daily-brief":
        return runDailyBrief(job.data.userId);
      case "evening-debrief":
        return runEveningDebrief(job.data.userId);
      case "nudge":
        return runNudge(job.data.userId, job.data.trigger);
      // REMOVED: auto-nudges-hourly case - no longer used
      case "weekly-consolidation":
        return runWeeklyConsolidation();
      default:
        return;
    }
  },
  { 
    connection: redis
  }
);

console.log("🧠 Scheduler Worker Started (OS Brain Only)");
