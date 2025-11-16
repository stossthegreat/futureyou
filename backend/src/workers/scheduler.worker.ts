import { Queue, Worker } from "bullmq";
import { redis } from "../utils/redis";
import { prisma } from "../utils/db";
import { aiService } from "../services/ai.service";
import { coachMessageService } from "../services/coach-message.service";
import { notificationsService } from "../services/notifications.service";
import { voiceService } from "../services/voice.service";
import { nudgesService } from "../services/nudges.service";

const QUEUE = "scheduler";
export const schedulerQueue = new Queue(QUEUE, { connection: redis });

const PRO_FEATURES_ENABLED = (process.env.PRO_FEATURES_ENABLED || "true").toLowerCase() === "true";
const FREE_NOTIFICATIONS_ENABLED = (process.env.FREE_NOTIFICATIONS_ENABLED || "false").toLowerCase() === "true";

async function ensureDailyBriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true } });
  for (const u of users) {
    const tz = u.tz || "Europe/London";
    await schedulerQueue.add("daily-brief", { userId: u.id }, {
      repeat: { pattern: "0 7 * * *", tz },
      jobId: `daily-brief:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
  }
  return { ok: true, users: users.length };
}

async function ensureEveningDebriefJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true } });
  for (const u of users) {
    const tz = u.tz || "Europe/London";
    await schedulerQueue.add("evening-debrief", { userId: u.id }, {
      repeat: { pattern: "0 21 * * *", tz },
      jobId: `evening-debrief:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
  }
  return { ok: true, users: users.length };
}

async function ensureNudgeJobs() {
  const users = await prisma.user.findMany({ select: { id: true, tz: true, nudgesEnabled: true } });
  for (const u of users) {
    if (!u.nudgesEnabled) continue;
    const tz = u.tz || "Europe/London";
    
    // ✅ Morning nudge (10am)
    await schedulerQueue.add("nudge", { userId: u.id, trigger: "morning_momentum" }, {
      repeat: { pattern: "0 10 * * *", tz },
      jobId: `nudge-morning:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
    
    // ✅ Afternoon nudge (2pm)
    await schedulerQueue.add("nudge", { userId: u.id, trigger: "afternoon_drift" }, {
      repeat: { pattern: "0 14 * * *", tz },
      jobId: `nudge-afternoon:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
    
    // ✅ Evening nudge (6pm)
    await schedulerQueue.add("nudge", { userId: u.id, trigger: "evening_closeout" }, {
      repeat: { pattern: "0 18 * * *", tz },
      jobId: `nudge-evening:${u.id}`,
      removeOnComplete: true,
      removeOnFail: true,
    });
  }
  return { ok: true, users: users.length };
}

async function runDailyBrief(userId: string) {
  const text = await aiService.generateMorningBrief(userId).catch(() => "Good morning.");
  let audioUrl: string | null = null;
  try { audioUrl = await voiceService.ttsToUrl(userId, text, "future-you"); } catch { audioUrl = null; }

  // ✅ Create proper CoachMessage entry
  await coachMessageService.createMessage(userId, "brief", text, { audioUrl });
  
  // Also create event for backward compatibility
  await prisma.event.create({ data: { userId, type: "morning_brief", payload: { text, audioUrl } } });
  await notificationsService.send(userId, "Morning Brief", text.slice(0, 180));
  return { ok: true };
}

async function runEveningDebrief(userId: string) {
  const text = await aiService.generateEveningDebrief(userId).catch(() => "Evening debrief.");
  let audioUrl: string | null = null;
  try { audioUrl = await voiceService.ttsToUrl(userId, text, "future-you"); } catch { audioUrl = null; }

  // ✅ Create proper CoachMessage entry (debrief = "mirror" kind)
  await coachMessageService.createMessage(userId, "mirror", text, { audioUrl });
  
  // Also create event for backward compatibility
  await prisma.event.create({ data: { userId, type: "evening_debrief", payload: { text, audioUrl } } });
  await notificationsService.send(userId, "Evening Debrief", text.slice(0, 180));
  return { ok: true };
}

async function runNudge(userId: string, trigger: string) {
  const text = await aiService.generateNudge(userId, trigger).catch(() => "Check in with yourself.");
  
  // ✅ Create proper CoachMessage entry
  await coachMessageService.createMessage(userId, "nudge", text, { trigger });
  
  // Also create event for backward compatibility
  await prisma.event.create({ data: { userId, type: "nudge", payload: { text, trigger } } });
  await notificationsService.send(userId, "Nudge", text.slice(0, 180));
  return { ok: true };
}

async function autoNudgesHourly() {
  const users = await prisma.user.findMany({ select: { id: true, plan: true } });
  for (const u of users) {
    if (u.plan !== "PRO" && !FREE_NOTIFICATIONS_ENABLED) continue;
    const nudges = await nudgesService.generateNudges(u.id);
    const n = Array.isArray(nudges) ? nudges[0] : (nudges as any).nudges?.[0];
    if (!n?.message) continue;
    await notificationsService.send(u.id, "Nudge", n.message.slice(0, 180));
  }
  return { ok: true };
}

new Worker(QUEUE, async (job) => {
  switch (job.name) {
    case "ensure-daily-briefs": return ensureDailyBriefJobs();
    case "ensure-evening-debriefs": return ensureEveningDebriefJobs();
    case "ensure-nudges": return ensureNudgeJobs(); // ✅ NEW
    case "daily-brief": return runDailyBrief(job.data.userId);
    case "evening-debrief": return runEveningDebrief(job.data.userId);
    case "nudge": return runNudge(job.data.userId, job.data.trigger); // ✅ NEW
    case "auto-nudges-hourly": return autoNudgesHourly();
    case "welcome-series-daily": return processWelcomeSeries(); // ✅ NEW: 7-day welcome series
    default: return;
  }
}, { 
  connection: redis
});

console.log("🧠 Scheduler Worker Started (OS Brain Only)");
