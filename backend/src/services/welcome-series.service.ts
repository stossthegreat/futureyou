/**
 * WELCOME SERIES SERVICE
 * Delivers pre-written 7-day onboarding messages to new users
 */

import { prisma } from "../utils/db";
import { coachMessageService } from "./coach-message.service";
import { WELCOME_SERIES, getWelcomeDayMessage } from "../data/welcome-series";
import { CoachMessageKind } from "@prisma/client";

export class WelcomeSeriesService {
  
  /**
   * Initialize welcome series for a new user
   * Call this when user completes onboarding
   */
  async initializeForUser(userId: string): Promise<void> {
    console.log(`🎉 Initializing 7-day welcome series for user: ${userId}`);
    
    // Check if user already has welcome series initialized
    const existing = await prisma.event.findFirst({
      where: {
        userId,
        type: "welcome_series_initialized"
      }
    });
    
    if (existing) {
      console.log(`⚠️ Welcome series already initialized for user: ${userId}`);
      return;
    }
    
    // Mark as initialized
    await prisma.event.create({
      data: {
        userId,
        type: "welcome_series_initialized",
        payload: {
          startedAt: new Date().toISOString(),
          totalDays: WELCOME_SERIES.length
        }
      }
    });
    
    // Deliver Day 1 immediately
    await this.deliverDay(userId, 1);
    
    console.log(`✅ Welcome series initialized. Day 1 delivered immediately.`);
  }
  
  /**
   * Deliver a specific day's message
   */
  async deliverDay(userId: string, day: number): Promise<void> {
    const message = getWelcomeDayMessage(day);
    
    if (!message) {
      console.error(`❌ No welcome message found for day ${day}`);
      return;
    }
    
    // Check if this day was already delivered
    const alreadyDelivered = await prisma.event.findFirst({
      where: {
        userId,
        type: "welcome_day_delivered",
        payload: {
          path: ["day"],
          equals: day
        }
      }
    });
    
    if (alreadyDelivered) {
      console.log(`⚠️ Day ${day} already delivered to user ${userId}`);
      return;
    }
    
    // Map message kind to CoachMessageKind
    let kind: CoachMessageKind;
    switch (message.kind) {
      case 'letter':
        kind = 'letter';
        break;
      case 'brief':
        kind = 'brief';
        break;
      case 'mirror':
        kind = 'mirror';
        break;
      default:
        kind = 'letter'; // Default to letter
    }
    
    // Create the coach message
    await coachMessageService.createMessage(
      userId,
      kind,
      message.body,
      {
        welcomeSeries: true,
        day: day,
        title: message.title
      }
    );
    
    // Log delivery
    await prisma.event.create({
      data: {
        userId,
        type: "welcome_day_delivered",
        payload: {
          day,
          title: message.title,
          deliveredAt: new Date().toISOString()
        }
      }
    });
    
    console.log(`✅ Delivered welcome day ${day} to user ${userId}: "${message.title}"`);
  }
  
  /**
   * Get user's current welcome series progress
   */
  async getProgress(userId: string): Promise<{
    initialized: boolean;
    currentDay: number;
    totalDays: number;
    completedDays: number[];
  }> {
    const initialized = await prisma.event.findFirst({
      where: {
        userId,
        type: "welcome_series_initialized"
      }
    });
    
    if (!initialized) {
      return {
        initialized: false,
        currentDay: 0,
        totalDays: WELCOME_SERIES.length,
        completedDays: []
      };
    }
    
    const delivered = await prisma.event.findMany({
      where: {
        userId,
        type: "welcome_day_delivered"
      },
      orderBy: {
        ts: "asc"
      }
    });
    
    const completedDays = delivered.map(e => (e.payload as any).day as number);
    const currentDay = Math.max(...completedDays, 0) + 1;
    
    return {
      initialized: true,
      currentDay: currentDay <= WELCOME_SERIES.length ? currentDay : WELCOME_SERIES.length,
      totalDays: WELCOME_SERIES.length,
      completedDays
    };
  }
  
  /**
   * Check if user should receive next welcome message
   * Call this from daily scheduler
   */
  async checkAndDeliverNextDay(userId: string): Promise<boolean> {
    const progress = await this.getProgress(userId);
    
    if (!progress.initialized) {
      return false;
    }
    
    if (progress.currentDay > progress.totalDays) {
      // Series complete
      return false;
    }
    
    const initialized = await prisma.event.findFirst({
      where: {
        userId,
        type: "welcome_series_initialized"
      }
    });
    
    if (!initialized) return false;
    
    const startDate = new Date((initialized.payload as any).startedAt);
    const today = new Date();
    const daysSinceStart = Math.floor((today.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    
    // Deliver message if it's time (day 1 = immediately, day 2 = 1 day later, etc.)
    const targetDay = daysSinceStart + 1;
    
    if (targetDay <= progress.totalDays && !progress.completedDays.includes(targetDay)) {
      await this.deliverDay(userId, targetDay);
      return true;
    }
    
    return false;
  }
  
  /**
   * Process welcome series for all active users
   * Call this from daily scheduler (once per day)
   */
  async processAllUsers(): Promise<{ processed: number; delivered: number }> {
    const users = await prisma.user.findMany({
      select: { id: true }
    });
    
    let processed = 0;
    let delivered = 0;
    
    for (const user of users) {
      processed++;
      const didDeliver = await this.checkAndDeliverNextDay(user.id);
      if (didDeliver) {
        delivered++;
      }
    }
    
    console.log(`✅ Welcome series check complete. Processed ${processed} users, delivered ${delivered} messages.`);
    
    return { processed, delivered };
  }
}

export const welcomeSeriesService = new WelcomeSeriesService();

