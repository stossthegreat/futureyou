/**
 * ⚠️ THIS FILE IS DEPRECATED - DO NOT USE
 * 
 * All scheduling logic has been moved to backend/src/jobs/scheduler.ts
 * This file is kept for reference only to prevent import errors.
 * The duplicate worker was causing nudges to be sent twice.
 * 
 * Use backend/src/jobs/scheduler.ts instead.
 */

import { Queue } from "bullmq";
import { redis } from "../utils/redis";

const QUEUE = "scheduler";
export const schedulerQueue = new Queue(QUEUE, { connection: redis });

// All functions and worker logic removed - use backend/src/jobs/scheduler.ts instead

console.log("⚠️ This scheduler worker is DEPRECATED - all logic moved to backend/src/jobs/scheduler.ts");
