import { bootstrapSchedulers, startWorker } from "./jobs/scheduler";

(async () => {
  console.log("🧠 Scheduler worker starting...");
  try {
    // 🔥 CRITICAL: Start the worker FIRST before scheduling jobs
    // This prevents duplicate workers when server.ts imports scheduler.ts
    startWorker();
    
    // Then schedule the repeating jobs
    await bootstrapSchedulers();
    console.log("⏰ All repeatable jobs registered!");
  } catch (err) {
    console.error("❌ Failed to bootstrap schedulers:", err);
    process.exit(1);
  }
})();
