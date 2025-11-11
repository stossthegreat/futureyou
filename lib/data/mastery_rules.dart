// 🔥 The Ultimate Viral Habit Formation Rules
// 25 research-backed mastery lessons

class MasteryRule {
  final int number;
  final String title;
  final String subtitle;
  final String emoji;
  final String rule;
  final List<String> keyPoints;
  final List<String> examples;
  final String whyItWorks;
  final List<int> gradientColors; // RGB values for card gradient

  const MasteryRule({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.rule,
    required this.keyPoints,
    required this.examples,
    required this.whyItWorks,
    required this.gradientColors,
  });
}

// 🏆 ALL 25 MASTERY RULES
final List<MasteryRule> masteryRules = [
  MasteryRule(
    number: 1,
    title: 'THE 2-MINUTE RULE',
    subtitle: 'MOST VIRAL - 500M+ VIEWS',
    emoji: '⚡',
    rule: 'When starting a new habit, it should take less than two minutes to do',
    keyPoints: [
      'Makes the habit so easy you can\'t say no',
      'Removes all friction and excuses',
      'Gateway to larger behaviors',
      'Starting is 80% of the battle',
    ],
    examples: [
      'Want to exercise? → Put on workout clothes',
      'Want to read more? → Read 1 page',
      'Want to meditate? → Take 3 deep breaths',
      'Want to journal? → Write 1 sentence',
    ],
    whyItWorks: 'Starting is 80% of the battle - once you start, momentum carries you',
    gradientColors: [99, 102, 241, 139, 92, 246], // Purple gradient
  ),
  
  MasteryRule(
    number: 2,
    title: 'HABIT STACKING',
    subtitle: '2ND MOST VIRAL',
    emoji: '🔗',
    rule: 'After [CURRENT HABIT], I will [NEW HABIT]',
    keyPoints: [
      'Ties new behavior to existing habit',
      'Already wired into your brain',
      'No willpower needed',
      'Automatic trigger system',
    ],
    examples: [
      'After I pour my morning coffee, I will meditate for 1 minute',
      'After I brush my teeth, I will do 10 pushups',
      'After I sit down for dinner, I will say one thing I\'m grateful for',
      'After I close my laptop, I will do 5 minutes of stretching',
    ],
    whyItWorks: 'Ties new behavior to an existing habit that\'s already wired into your brain',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),

  MasteryRule(
    number: 3,
    title: 'IDENTITY-BASED HABITS',
    subtitle: 'GAME CHANGER',
    emoji: '🎯',
    rule: 'Focus on who you wish to become, not what you want to achieve',
    keyPoints: [
      'Identity beats outcomes',
      'Every action is a vote for your identity',
      'Pride becomes your motivator',
      'Shift from "do" to "be"',
    ],
    examples: [
      '❌ "I want to run a marathon" → ✅ "I am a runner"',
      '❌ "I want to write a book" → ✅ "I am a writer"',
      'Ask: What would a healthy person do?',
      'Ask: What would a disciplined person do?',
    ],
    whyItWorks: 'Once your pride is involved, you\'ll fight tooth and nail to maintain your habits',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),

  MasteryRule(
    number: 4,
    title: 'IMPLEMENTATION INTENTIONS',
    subtitle: 'RESEARCH PROVEN',
    emoji: '📋',
    rule: 'I will [BEHAVIOR] at [TIME] in [LOCATION]',
    keyPoints: [
      'Specific plans double success rate',
      'Removes decision fatigue',
      'Pre-commits your future self',
      'Research-backed effectiveness',
    ],
    examples: [
      'I will meditate for 10 minutes at 6am in my bedroom',
      'I will workout for 30 minutes at 5pm at the gym',
      'I will journal for 5 minutes at 9pm at my desk',
      'I will read for 20 minutes at 10pm in bed',
    ],
    whyItWorks: 'Studies show this doubles or triples your chances of success',
    gradientColors: [59, 130, 246, 37, 99, 235], // Blue gradient
  ),

  MasteryRule(
    number: 5,
    title: 'MAKE IT OBVIOUS',
    subtitle: 'ENVIRONMENT DESIGN',
    emoji: '👀',
    rule: 'Design your environment so good behaviors are obvious and easy',
    keyPoints: [
      'Environment shapes behavior',
      'Make good habits visible',
      'Make bad habits invisible',
      'Design beats willpower',
    ],
    examples: [
      'Want to drink more water? → Place water bottles everywhere',
      'Want to eat healthy? → Put fruit on the counter',
      'Want to exercise? → Lay out workout clothes the night before',
      'Want to read? → Put books on your pillow',
    ],
    whyItWorks: 'Your environment is the invisible hand that shapes human behavior',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),

  MasteryRule(
    number: 6,
    title: 'TEMPTATION BUNDLING',
    subtitle: 'DOPAMINE HACK',
    emoji: '🎁',
    rule: 'Pair an action you WANT to do with an action you NEED to do',
    keyPoints: [
      'Links instant gratification to delayed gratification',
      'Makes hard habits enjoyable',
      'Hijacks your reward system',
      'Neuroscience-backed',
    ],
    examples: [
      'Only watch Netflix while on the treadmill',
      'Only get a pedicure while reviewing work emails',
      'Only listen to favorite podcast while doing meal prep',
      'Only drink favorite coffee after morning workout',
    ],
    whyItWorks: 'Links instant gratification to delayed gratification behaviors',
    gradientColors: [168, 85, 247, 147, 51, 234], // Purple gradient
  ),

  MasteryRule(
    number: 7,
    title: 'THE 1% BETTER RULE',
    subtitle: 'COMPOUND EFFECT',
    emoji: '📈',
    rule: 'If you get 1% better each day for one year, you\'ll end up 37 times better',
    keyPoints: [
      '1% better daily = 37x improvement yearly',
      '1% worse daily = 97% decline yearly',
      'Small changes compound exponentially',
      'Breakthrough comes after critical threshold',
    ],
    examples: [
      'Day 1: Run 5 minutes',
      'Week 1: Run 7 minutes',
      'Month 1: Run 15 minutes',
      'Year 1: Completed 3 marathons',
    ],
    whyItWorks: 'Small changes appear to make no difference until you cross a critical threshold',
    gradientColors: [14, 165, 233, 3, 105, 161], // Cyan gradient
  ),

  MasteryRule(
    number: 8,
    title: 'THE GOLDILOCKS RULE',
    subtitle: 'PEAK MOTIVATION',
    emoji: '🎯',
    rule: 'Work on tasks that are right on the edge of your current abilities',
    keyPoints: [
      'Too easy = Boredom',
      'Too hard = Anxiety',
      'Just right = Flow state',
      'Work 4% beyond current ability',
    ],
    examples: [
      'Can do 10 pushups? Try for 11',
      'Read 5 pages daily? Try 6',
      'Meditate 5 minutes? Try 6 minutes',
      'Run 1 mile? Try 1.1 miles',
    ],
    whyItWorks: 'Humans experience peak motivation when working on tasks right at the edge',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),

  MasteryRule(
    number: 9,
    title: 'NEVER MISS TWICE',
    subtitle: 'COMEBACK STRATEGY',
    emoji: '🔄',
    rule: 'Missing once is an accident. Missing twice is the start of a new habit',
    keyPoints: [
      'One missed day = No problem',
      'Two missed days = Pattern forming',
      'Accept you\'ll miss sometimes',
      'Immediately plan the next occurrence',
    ],
    examples: [
      'Miss workout Monday? Do it Tuesday no matter what',
      'Skip meditation? Do it before bed',
      'Never abandon on a bad day - show up for 1 minute',
      'Mantra: "Never break the chain twice"',
    ],
    whyItWorks: 'Missing once is human. Missing twice starts breaking the identity',
    gradientColors: [239, 68, 68, 220, 38, 38], // Red gradient
  ),

  MasteryRule(
    number: 10,
    title: 'IMMEDIATE REWARDS',
    subtitle: 'DOPAMINE OPTIMIZATION',
    emoji: '🎁',
    rule: 'What is immediately rewarded is repeated. What is immediately punished is avoided',
    keyPoints: [
      'Good habits have delayed rewards',
      'Create immediate positive feelings',
      'Habit tracking becomes the reward',
      'Visual wins matter',
    ],
    examples: [
      'After workout → Mark calendar with X',
      'After saving money → Transfer $1 to "Fun Fund"',
      'After healthy meal → Text accountability partner',
      'After meditation → Light favorite candle',
    ],
    whyItWorks: 'The brain needs immediate feedback to wire behaviors effectively',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),

  MasteryRule(
    number: 11,
    title: 'REDUCE FRICTION',
    subtitle: 'LAZINESS HACK',
    emoji: '🛤️',
    rule: 'Reduce friction for good behaviors. Increase friction for bad behaviors',
    keyPoints: [
      'Every action requires energy',
      'More energy = Less likely to occur',
      'Make good habits effortless',
      'Make bad habits difficult',
    ],
    examples: [
      'Meal prep on Sundays (5 healthy choices ready)',
      'Sleep in workout clothes',
      'Delete social media apps (must re-download)',
      'Unplug TV after each use',
    ],
    whyItWorks: 'The path of least resistance determines behavior',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),

  MasteryRule(
    number: 12,
    title: 'THE BJ FOGG BEHAVIOR MODEL',
    subtitle: 'STANFORD RESEARCH',
    emoji: '🧠',
    rule: 'Behavior = Motivation + Ability + Prompt',
    keyPoints: [
      'All 3 elements must be present',
      'If behavior doesn\'t happen, one is missing',
      'Low motivation? → Tie to bigger "why"',
      'Low ability? → Make it smaller',
    ],
    examples: [
      'M (Motivation): Your desire to do it',
      'A (Ability): How easy it is to do',
      'P (Prompt): The trigger that reminds you',
      'Missing one? Behavior won\'t happen',
    ],
    whyItWorks: 'Identifies exactly why habits fail and how to fix them',
    gradientColors: [59, 130, 246, 37, 99, 235], // Blue gradient
  ),

  MasteryRule(
    number: 13,
    title: 'PLATEAU OF LATENT POTENTIAL',
    subtitle: 'THE VALLEY OF DISAPPOINTMENT',
    emoji: '🏔️',
    rule: 'Habits need time to break through the Plateau of Latent Potential',
    keyPoints: [
      'Week 1-4: "This isn\'t working"',
      'Week 5-8: "Still not seeing results"',
      'Week 9-12: "Maybe small changes?"',
      'Week 13+: "BREAKTHROUGH!"',
    ],
    examples: [
      'Like heating ice from 25°F to 31°F - still ice',
      'At 32°F it suddenly transforms to water',
      'Your work was not wasted, just stored',
      'All action happens at the breakthrough point',
    ],
    whyItWorks: 'Success is delayed but not denied - persistence wins',
    gradientColors: [168, 85, 247, 147, 51, 234], // Purple gradient
  ),

  MasteryRule(
    number: 14,
    title: 'HABIT TRACKING MULTIPLIER',
    subtitle: 'ACCOUNTABILITY BOOST',
    emoji: '📊',
    rule: 'People who track their habits are significantly more likely to maintain them',
    keyPoints: [
      'Creates obvious visual cue',
      'Inherently motivating',
      'Provides evidence of progress',
      'Tracking becomes addictive',
    ],
    examples: [
      '✅ Physical calendar with X\'s',
      '📱 Habit tracking apps',
      '📓 Bullet journal spreads',
      '🏆 Streaks counter',
    ],
    whyItWorks: 'Tracking itself becomes addictive - "Don\'t break the chain!"',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),

  MasteryRule(
    number: 15,
    title: 'SOCIAL ACCOUNTABILITY',
    subtitle: '2X SUCCESS RATE',
    emoji: '👥',
    rule: 'Having an accountability partner doubles your chances of success',
    keyPoints: [
      'Tell someone = 50% boost',
      'Weekly check-ins = 100% boost',
      'Daily partner = 150% boost',
      'Public commitment = 200% boost',
    ],
    examples: [
      'Join habit groups online',
      'Find accountability buddy',
      'Post daily progress on Instagram',
      'Bet money with friend',
    ],
    whyItWorks: '95% success rate with specific accountability appointments',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),

  MasteryRule(
    number: 16,
    title: 'THE COMMITMENT DEVICE',
    subtitle: 'LOCK YOURSELF IN',
    emoji: '🔒',
    rule: 'Make bad habits difficult by creating a commitment that locks in good behavior',
    keyPoints: [
      'Removes future choices',
      'You\'ve already decided',
      'Makes default behavior good',
      'Psychological pre-commitment',
    ],
    examples: [
      'Victor Hugo gave clothes to assistant until he finished writing',
      'Apps like Forest: trees die if you use phone',
      'Gym membership paid upfront',
      'Give friend $100 until you complete 30 days',
    ],
    whyItWorks: 'Future you can\'t opt out - decision already made',
    gradientColors: [239, 68, 68, 220, 38, 38], // Red gradient
  ),

  MasteryRule(
    number: 17,
    title: 'THE FRESH START EFFECT',
    subtitle: 'TIMING HACK',
    emoji: '🌅',
    rule: 'People are more likely to pursue goals after temporal landmarks',
    keyPoints: [
      'Monday (fresh week)',
      '1st of month (fresh month)',
      'January 1st (fresh year)',
      'After vacation (fresh mindset)',
    ],
    examples: [
      'Create your own landmark: "Today is Day 1"',
      '"New me starts NOW"',
      '"This is Week 1 of my transformation"',
      'Don\'t wait - manufacture the fresh start',
    ],
    whyItWorks: 'Landmarks help mentally disconnect from past failures',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),

  MasteryRule(
    number: 18,
    title: 'CELEBRATION TECHNIQUE',
    subtitle: 'BJ FOGG\'S SECRET',
    emoji: '🎉',
    rule: 'Immediately after doing the tiny habit, celebrate',
    keyPoints: [
      'Celebration creates positive emotion',
      'Tells brain "This is good! Do it again!"',
      'Emotions create habits faster than repetition',
      'Make it feel good NOW',
    ],
    examples: [
      'Fist pump + "Yes!"',
      'Mental "I\'m awesome!"',
      'Smile and nod',
      'Victory dance',
    ],
    whyItWorks: 'Emotions create habits faster than repetition alone',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),

  MasteryRule(
    number: 19,
    title: 'HABIT REPLACEMENT',
    subtitle: 'SWAP DON\'T STOP',
    emoji: '🔄',
    rule: 'You can break a bad habit, but you\'re unlikely to forget it. So replace it',
    keyPoints: [
      'Don\'t eliminate, replace',
      'Find new routine that satisfies same need',
      'Identify the cue',
      'Identify the craving',
    ],
    examples: [
      'Stress eating → Stress walking',
      'Social media scrolling → Reading articles',
      'Smoking → Chewing gum + deep breathing',
      'Late night snacking → Herbal tea ritual',
    ],
    whyItWorks: 'Satisfies the underlying need with a better behavior',
    gradientColors: [14, 165, 233, 3, 105, 161], // Cyan gradient
  ),

  MasteryRule(
    number: 20,
    title: 'THE 66-DAY TRUTH',
    subtitle: 'RESEARCH REALITY',
    emoji: '⏰',
    rule: 'On average, it takes 66 days for a new behavior to become automatic',
    keyPoints: [
      'NOT 21 days (old myth)',
      '66 days average (University College London)',
      'Range: 18 to 254 days depending on complexity',
      'Consistency matters more than timeline',
    ],
    examples: [
      'Easy habits: 18-21 days (drinking water)',
      'Medium habits: 66 days (morning workout)',
      'Hard habits: 254 days (major lifestyle change)',
      'Missing a day doesn\'t restart the process',
    ],
    whyItWorks: 'Realistic timeline prevents premature giving up',
    gradientColors: [168, 85, 247, 147, 51, 234], // Purple gradient
  ),

  MasteryRule(
    number: 21,
    title: 'THE 5-SECOND RULE',
    subtitle: 'MEL ROBBINS\' VIRAL METHOD',
    emoji: '⚡',
    rule: 'The moment you have an instinct to act, count 5-4-3-2-1 and physically move',
    keyPoints: [
      'Interrupts overthinking',
      'Creates immediate action',
      'Bypasses fear and hesitation',
      'Uses countdown momentum',
    ],
    examples: [
      '5-4-3-2-1 GET OUT OF BED',
      '5-4-3-2-1 START THE WORKOUT',
      '5-4-3-2-1 MAKE THE CALL',
      '5-4-3-2-1 ASK THE QUESTION',
    ],
    whyItWorks: 'Brain has 5 seconds before it kills an idea with doubt',
    gradientColors: [239, 68, 68, 220, 38, 38], // Red gradient
  ),

  MasteryRule(
    number: 22,
    title: 'THE SEINFELD STRATEGY',
    subtitle: 'DON\'T BREAK THE CHAIN',
    emoji: '📅',
    rule: 'Get a calendar, mark X for each day you do the habit, don\'t break the chain',
    keyPoints: [
      'Visual progress is motivating',
      'Loss aversion kicks in',
      'Gamifies the process',
      'Simple but powerful',
    ],
    examples: [
      'Duolingo (language learning streaks)',
      'Snapchat (snap streaks)',
      'GitHub (contribution streaks)',
      'Jerry Seinfeld\'s joke-writing calendar',
    ],
    whyItWorks: 'Don\'t want to lose the streak you\'ve built',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),

  MasteryRule(
    number: 23,
    title: 'MINIMUM VIABLE EFFORT',
    subtitle: 'NEVER ZERO DAYS',
    emoji: '💪',
    rule: 'On bad days, do the absolute minimum version of your habit (but never zero)',
    keyPoints: [
      'Maintains identity',
      'Keeps streak alive',
      'Usually leads to doing more',
      'Prevents all-or-nothing thinking',
    ],
    examples: [
      'Can\'t do full workout? → Do 1 pushup',
      'Can\'t write 1000 words? → Write 1 sentence',
      'Can\'t meditate 20 min? → Take 3 deep breaths',
      'Can\'t run 3 miles? → Walk around the block',
    ],
    whyItWorks: 'Something is infinitely better than nothing',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),

  MasteryRule(
    number: 24,
    title: 'KEYSTONE HABITS',
    subtitle: 'ONE HABIT CHANGES EVERYTHING',
    emoji: '🗝️',
    rule: 'Some habits trigger chain reactions that shift multiple behaviors',
    keyPoints: [
      'Exercise → Eat better, sleep better',
      'Making bed → More productive day',
      'Meal planning → Save money, less stress',
      'Morning routine → Sets tone for day',
    ],
    examples: [
      'Start with ONE keystone habit',
      'Master it completely',
      'Watch other habits fall into place',
      'Exercise is the #1 keystone habit',
    ],
    whyItWorks: 'Change one thing, everything else follows naturally',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),

  MasteryRule(
    number: 25,
    title: 'THE POWER OF "YET"',
    subtitle: 'GROWTH MINDSET',
    emoji: '🌱',
    rule: 'Add "yet" to the end of limiting beliefs about habits',
    keyPoints: [
      'Transforms fixed mindset to growth mindset',
      'Opens possibility',
      'Reduces resistance',
      'Increases attempt rate',
    ],
    examples: [
      '❌ "I\'m not a morning person" → ✅ "...YET"',
      '❌ "I can\'t do pushups" → ✅ "...YET"',
      '❌ "I don\'t meditate" → ✅ "...YET"',
      '❌ "I\'m not disciplined" → ✅ "...YET"',
    ],
    whyItWorks: 'Belief in growth makes growth possible',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),
];

