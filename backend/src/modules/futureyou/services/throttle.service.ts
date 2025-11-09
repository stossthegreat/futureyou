import { redis } from '../../../utils/redis';

const MAX_CONCURRENT_PER_USER = Number(process.env.FUTUREYOU_MAX_CONCURRENCY || 2);
const GLOBAL_TOKENS_PER_MIN = Number(process.env.FUTUREYOU_TOKENS_PER_MIN || 120000);

interface ThrottleResult {
  ok: boolean;
  reason?: 'concurrency' | 'rate';
  waitMs?: number;
}

export class ThrottleService {
  async canRun(userId: string): Promise<ThrottleResult> {
    try {
      // Check per-user concurrency
      const userKey = `fy:lim:user:${userId}`;
      const running = await redis.get(userKey);
      const runningCount = running ? parseInt(running, 10) : 0;

      if (runningCount >= MAX_CONCURRENT_PER_USER) {
        return { 
          ok: false, 
          reason: 'concurrency', 
          waitMs: 5000 // Estimate 5s wait
        };
      }

      // Check global rate limit (simplified leaky bucket)
      const globalKey = 'fy:lim:global';
      const globalTokens = await redis.get(globalKey);
      const tokensUsed = globalTokens ? parseInt(globalTokens, 10) : 0;

      if (tokensUsed >= GLOBAL_TOKENS_PER_MIN) {
        return { 
          ok: false, 
          reason: 'rate', 
          waitMs: 10000 // Estimate 10s wait
        };
      }

      return { ok: true };
    } catch (error) {
      console.error('Throttle check error:', error);
      // On error, allow (fail open)
      return { ok: true };
    }
  }

  async trackStart(userId: string, estimatedTokens: number = 1000): Promise<void> {
    try {
      const userKey = `fy:lim:user:${userId}`;
      await redis.incr(userKey);
      await redis.expire(userKey, 60); // 1 minute TTL

      const globalKey = 'fy:lim:global';
      await redis.incrby(globalKey, estimatedTokens);
      await redis.expire(globalKey, 60); // 1 minute TTL
    } catch (error) {
      console.error('Track start error:', error);
    }
  }

  async trackEnd(userId: string): Promise<void> {
    try {
      const userKey = `fy:lim:user:${userId}`;
      const current = await redis.get(userKey);
      if (current && parseInt(current, 10) > 0) {
        await redis.decr(userKey);
      }
    } catch (error) {
      console.error('Track end error:', error);
    }
  }
}

export const throttleService = new ThrottleService();

