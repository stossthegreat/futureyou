-- Create all tables for Future You OS

CREATE TYPE "Plan" AS ENUM ('FREE', 'PRO');
CREATE TYPE "Tone" AS ENUM ('strict', 'balanced', 'light');
CREATE TYPE "CoachMessageKind" AS ENUM ('nudge', 'brief', 'mirror', 'letter');

CREATE TABLE "User" (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  tz TEXT DEFAULT 'Europe/London' NOT NULL,
  tone "Tone" DEFAULT 'balanced' NOT NULL,
  intensity INTEGER DEFAULT 2 NOT NULL,
  "consentRoast" BOOLEAN DEFAULT false NOT NULL,
  "safeWord" TEXT,
  plan "Plan" DEFAULT 'FREE' NOT NULL,
  "mentorId" TEXT,
  "fcmToken" TEXT,
  "nudgesEnabled" BOOLEAN DEFAULT true NOT NULL,
  "briefsEnabled" BOOLEAN DEFAULT true NOT NULL,
  "debriefsEnabled" BOOLEAN DEFAULT true NOT NULL,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE "Habit" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  schedule JSONB DEFAULT '{}' NOT NULL,
  streak INTEGER DEFAULT 0 NOT NULL,
  "lastTick" TIMESTAMP,
  color TEXT DEFAULT 'emerald' NOT NULL,
  context JSONB DEFAULT '{}' NOT NULL,
  "reminderEnabled" BOOLEAN DEFAULT false NOT NULL,
  "reminderTime" TEXT DEFAULT '08:00',
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "Habit_userId_idx" ON "Habit"("userId");

CREATE TABLE "AntiHabit" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  "targetMins" INTEGER DEFAULT 10 NOT NULL,
  "cleanStreak" INTEGER DEFAULT 0 NOT NULL,
  "lastSlip" TIMESTAMP,
  "dangerWin" JSONB DEFAULT '{}',
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "AntiHabit_userId_idx" ON "AntiHabit"("userId");

CREATE TABLE "Alarm" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  rrule TEXT NOT NULL,
  tone "Tone" DEFAULT 'balanced' NOT NULL,
  enabled BOOLEAN DEFAULT true NOT NULL,
  "nextRun" TIMESTAMP,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "Alarm_userId_idx" ON "Alarm"("userId");
CREATE INDEX "Alarm_nextRun_idx" ON "Alarm"("nextRun");

CREATE TABLE "Event" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  ts TIMESTAMP DEFAULT NOW() NOT NULL,
  type TEXT NOT NULL,
  payload JSONB DEFAULT '{}' NOT NULL,
  embedding BYTEA
);
CREATE INDEX "Event_userId_ts_idx" ON "Event"("userId", ts);
CREATE INDEX "Event_type_idx" ON "Event"(type);

CREATE TABLE "UserFacts" (
  "userId" TEXT PRIMARY KEY REFERENCES "User"(id) ON DELETE CASCADE,
  json JSONB DEFAULT '{}' NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE "Task" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  "dueDate" TIMESTAMP,
  schedule JSONB DEFAULT '{}' NOT NULL,
  priority INTEGER DEFAULT 1 NOT NULL,
  category TEXT,
  completed BOOLEAN DEFAULT false NOT NULL,
  "completedAt" TIMESTAMP,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "updatedAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "Task_userId_idx" ON "Task"("userId");

CREATE TABLE "TodaySelection" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  "habitId" TEXT REFERENCES "Habit"(id) ON DELETE CASCADE,
  "taskId" TEXT REFERENCES "Task"(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  "order" INTEGER DEFAULT 0 NOT NULL,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "TodaySelection_userId_date_idx" ON "TodaySelection"("userId", date);

CREATE TABLE "VoiceCache" (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL,
  voice TEXT NOT NULL,
  url TEXT NOT NULL,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL
);
CREATE INDEX "VoiceCache_createdAt_idx" ON "VoiceCache"("createdAt");

CREATE TABLE "HabitSnapshot" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  at TIMESTAMP DEFAULT NOW() NOT NULL,
  data JSONB NOT NULL
);
CREATE INDEX "HabitSnapshot_userId_idx" ON "HabitSnapshot"("userId");

CREATE TABLE "Completion" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "habitId" TEXT NOT NULL,
  date TIMESTAMP NOT NULL,
  done BOOLEAN DEFAULT false NOT NULL,
  "completedAt" TIMESTAMP,
  UNIQUE("userId", "habitId", date)
);
CREATE INDEX "Completion_userId_idx" ON "Completion"("userId");
CREATE INDEX "Completion_date_idx" ON "Completion"(date);

CREATE TABLE "CoachMessage" (
  id TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  kind "CoachMessageKind" NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  meta JSONB,
  "createdAt" TIMESTAMP DEFAULT NOW() NOT NULL,
  "readAt" TIMESTAMP
);
CREATE INDEX "CoachMessage_userId_idx" ON "CoachMessage"("userId");

-- Create Prisma migrations table
CREATE TABLE "_prisma_migrations" (
  id TEXT PRIMARY KEY,
  checksum TEXT NOT NULL,
  finished_at TIMESTAMP,
  migration_name TEXT NOT NULL,
  logs TEXT,
  rolled_back_at TIMESTAMP,
  started_at TIMESTAMP DEFAULT NOW() NOT NULL,
  applied_steps_count INTEGER DEFAULT 0 NOT NULL
);

