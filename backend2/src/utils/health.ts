import { dbHealthCheck } from "./db";
import { redisHealthCheck } from "./redis";

export async function checkDependencies() {
  const dbOk = await dbHealthCheck();
  const redisOk = await redisHealthCheck();

  return {
    ok: dbOk && redisOk,
    db: dbOk ? "ok" : "fail",
    redis: redisOk ? "ok" : "fail",
    timestamp: new Date().toISOString(),
  };
}
