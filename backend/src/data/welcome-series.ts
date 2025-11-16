/**
 * 7-DAY WELCOME SERIES
 * Pre-written messages delivered to all new users over their first week
 * These are NOT AI-generated - same for everyone
 */

export interface WelcomeDayMessage {
  day: number;
  title: string;
  body: string;
  kind: 'letter' | 'brief' | 'mirror'; // Maps to CoachMessageKind
}

export const WELCOME_SERIES: WelcomeDayMessage[] = [
  {
    day: 1,
    title: 'Day 1: Welcome to Your Future',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 1 CONTENT]

Welcome to Future-You OS.

This is not just another productivity app. This is a system designed to help you remember who you said you'd become.

Over the next 7 days, I'll guide you through the fundamentals of how this OS works, and how to make it work for you.

Today's Focus: Understanding the Mirror

The person you'll become isn't some distant fantasy. They're already inside you, waiting to be remembered. Every decision you make today either brings you closer or pushes you further away.

Tomorrow, we'll talk about habits. For now, just be present.

— Future-You`,
  },
  
  {
    day: 2,
    title: 'Day 2: The Habit Truth',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 2 CONTENT]

You don't lack willpower. You lack systems.

Habits aren't about discipline. They're about design. When you design your environment, your calendar, your defaults — behavior follows naturally.

The Brief you receive each morning isn't a task list. It's a reality check. It reminds you of who you said you'd be today.

Today's Focus: Trust the System

Don't try to be perfect. Just show up. The OS tracks, you execute.

Tomorrow, we'll talk about nudges.

— Future-You`,
  },
  
  {
    day: 3,
    title: 'Day 3: Real-Time Guidance',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 3 CONTENT]

You'll get nudges when you need them.

Not constant nagging. Not motivational quotes. Real guidance based on what you're doing (or not doing).

The nudges aren't there to make you feel guilty. They're there to course-correct before you drift too far.

Today's Focus: Listen to the Nudges

When you get one, don't dismiss it. Read it. Consider it. Act on it.

Tomorrow, we'll talk about debriefs.

— Future-You`,
  },
  
  {
    day: 4,
    title: 'Day 4: The Evening Reflection',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 4 CONTENT]

Every evening, you'll receive a debrief.

This isn't a report card. It's a conversation. Did you show up today? What got in the way? What did you learn?

The debrief closes the loop. It celebrates wins, processes losses, and prepares you for tomorrow.

Today's Focus: Complete Your First Debrief

When it arrives tonight, take it seriously. Answer honestly. Growth lives in reflection.

Tomorrow, we'll talk about the What-If Engine.

— Future-You`,
  },
  
  {
    day: 5,
    title: 'Day 5: The What-If Engine',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 5 CONTENT]

You've discovered the What-If Engine by now.

This is where you turn vague goals into science-backed action plans. "What if I wanted to build muscle?" becomes a 12-week phased system with research citations.

Use it whenever you're stuck. Whenever you want to simulate two futures. Whenever you need clarity.

Today's Focus: Run One Simulation

Think of ONE goal you've been putting off. Ask the What-If Engine. Commit the habits.

Tomorrow, we'll talk about The Book of Purpose.

— Future-You`,
  },
  
  {
    day: 6,
    title: 'Day 6: Your Life\'s Task',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 6 CONTENT]

You haven't completed The Book of Purpose yet. That's okay.

This isn't something you rush. It's 7 profound chapters about who you are, what shaped you, and what you're meant to do.

When you complete each chapter, I'll write an epic narrative about you — weaving your answers into a story of purpose.

Today's Focus: Start Chapter 1

Carve out 30 minutes. Begin your Origin Story. Don't worry about perfection. Just be honest.

Tomorrow, we'll talk about what comes next.

— Future-You`,
  },
  
  {
    day: 7,
    title: 'Day 7: The System is Yours',
    kind: 'letter',
    body: `[REPLACE THIS WITH YOUR ACTUAL DAY 7 CONTENT]

You've made it through your first week.

By now, you understand how the OS works:
- Morning Briefs to align your day
- Real-Time Nudges to keep you on track
- Evening Debriefs to close the loop
- Weekly Letters to maintain perspective
- The What-If Engine to clarify goals
- The Book of Purpose to discover your calling

This is your system now.

I'm not going anywhere. I'll be here every morning, every evening, every time you need guidance.

The only question that matters: Who will you choose to become?

— Future-You

P.S. The work begins now.`,
  },
];

/**
 * Get message for a specific day
 */
export function getWelcomeDayMessage(day: number): WelcomeDayMessage | null {
  return WELCOME_SERIES.find(msg => msg.day === day) || null;
}

/**
 * Get all welcome messages
 */
export function getAllWelcomeMessages(): WelcomeDayMessage[] {
  return WELCOME_SERIES;
}

