import { prisma } from './db';
import { redis } from './redis';
import OpenAI from 'openai';
import Stripe from 'stripe';
import admin from 'firebase-admin';

export async function checkDependencies() {
  const results: Record<string, any> = {};

  try {
    await prisma.$queryRaw`SELECT 1`;
    results.postgres = 'ok';
  } catch (e: any) {
    results.postgres = `error: ${e.message}`;
  }

  try {
    await redis.ping();
    results.redis = 'ok';
  } catch (e: any) {
    results.redis = `error: ${e.message}`;
  }

  try {
    if (!process.env.OPENAI_API_KEY) {
      results.openai = 'error: OpenAI API key not configured';
    } else {
      const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
      await client.models.list();
      results.openai = 'ok';
    }
  } catch (e: any) {
    results.openai = `error: ${e.message}`;
  }

  try {
    const res = await fetch('https://api.elevenlabs.io/v1/voices', {
      headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY! },
    });
    results.elevenlabs = res.ok ? 'ok' : `error: ${res.statusText}`;
  } catch (e: any) {
    results.elevenlabs = `error: ${e.message}`;
  }

  try {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        }),
      });
    }
    results.firebase = 'ok';
  } catch (e: any) {
    results.firebase = `error: ${e.message}`;
  }

  try {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2025-08-27.basil' });
    await stripe.accounts.retrieve();
    results.stripe = 'ok';
  } catch (e: any) {
    results.stripe = `error: ${e.message}`;
  }

  return results;
}

export async function assertHealthyOrLog(userId: string) {
  const checks = await checkDependencies();
  const failures = Object.entries(checks).filter(([_, v]) => v !== 'ok');

  if (failures.length > 0) {
    await prisma.event.create({
      data: {
        userId,
        type: 'system_alert',
        payload: { failures },
      },
    });
    return false;
  }
  return true;
}
