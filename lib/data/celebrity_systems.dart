// 🌟 Celebrity Habit Systems Data
// 25 viral celebrity routines with full details

class CelebritySystem {
  final String name;
  final String title;
  final String subtitle;
  final String tier;
  final List<String> habits;
  final String whyViral;
  final String emoji;
  final List<int> gradientColors; // RGB values for gradient

  const CelebritySystem({
    required this.name,
    required this.title,
    required this.subtitle,
    required this.tier,
    required this.habits,
    required this.whyViral,
    required this.emoji,
    required this.gradientColors,
  });
}

// 🔥 ALL 25 CELEBRITY SYSTEMS
final List<CelebritySystem> celebritySystems = [
  // TIER 1: MEGA-VIRAL
  CelebritySystem(
    name: 'Andrew Huberman',
    title: 'Science-Based Protocol',
    subtitle: 'MOST VIRAL SCIENCE ROUTINE',
    tier: '🔥 MEGA-VIRAL (100M+ Views)',
    habits: [
      'Wake 5:30-6:30am (no alarm if rested)',
      'Do yoga nidra if not rested (10-30 min NSDR)',
      'Drink 16-32oz water + electrolytes immediately',
      'Get 10-30min sunlight exposure (eyes, no sunglasses)',
      'DELAY caffeine 90-120 min after waking',
      'Yerba Mate over coffee (preferred)',
      'Exercise early (cardio/weights alternating)',
      'Intermittent fasting (no food until noon)',
      'Cold plunge/ice bath for resilience',
      'Deep work tasks BEFORE eating',
      'Afternoon yoga nidra session (4:30pm)',
    ],
    whyViral: 'People worldwide claim it\'s been "transformative"',
    emoji: '🧠',
    gradientColors: [99, 102, 241, 139, 92, 246], // Purple to violet
  ),
  CelebritySystem(
    name: 'The Rock',
    title: '4AM Discipline',
    subtitle: 'MOST CONSISTENT CELEBRITY',
    tier: '🔥 MEGA-VIRAL (100M+ Views)',
    habits: [
      'Wake at 4am daily (non-negotiable)',
      'Immediate cardio 30-60 minutes',
      'Post workout photo to social media',
      'First meal by 5:30am',
      'Second "Iron Paradise" training session',
      '6 days per week consistency',
    ],
    whyViral: 'Millions of daily followers track his routine',
    emoji: '💪',
    gradientColors: [239, 68, 68, 220, 38, 38], // Red gradient
  ),
  CelebritySystem(
    name: 'Cristiano Ronaldo',
    title: 'Peak Performance',
    subtitle: 'ATHLETE GOLD STANDARD',
    tier: '🔥 MEGA-VIRAL (100M+ Views)',
    habits: [
      'Wake at 5:30am for football-specific workout',
      '90-minute nap after workout (recovery)',
      'Avocado toast breakfast for healthy fats',
      'Ice bath or cryotherapy immediately post-workout',
      'Multiple naps throughout day for recovery',
      'Science-backed every step',
    ],
    whyViral: 'Peak athletic performance maintained into 40s',
    emoji: '⚽',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),

  // TIER 2: SUPER VIRAL
  CelebritySystem(
    name: 'Oprah Winfrey',
    title: 'Spiritual Foundation',
    subtitle: 'MINDFULNESS QUEEN',
    tier: '🌟 SUPER VIRAL (50M+ Views)',
    habits: [
      '20-minute meditation (non-negotiable)',
      'Gratitude practice first thing',
      'Workout (yoga or brisk walk)',
      'No phone for first hour awake',
      'Spiritual reading time',
      'Healthy breakfast ritual',
    ],
    whyViral: 'Most studied morning routine by wellness seekers',
    emoji: '🙏',
    gradientColors: [168, 85, 247, 147, 51, 234], // Purple gradient
  ),
  CelebritySystem(
    name: 'Jennifer Aniston',
    title: 'Hollywood Standard',
    subtitle: 'CONSISTENCY FOR 20+ YEARS',
    tier: '🌟 SUPER VIRAL (50M+ Views)',
    habits: [
      'Wake 4:30am on work days, 8-9am off days',
      'Warm lemon water immediately',
      '20-minute meditation',
      'Protein shake with berries, frozen cherries',
      '30min spinning + yoga with instructor',
      'Intermittent fasting approach',
      'Same routine for 20+ years',
    ],
    whyViral: 'Ageless beauty routine that actually works',
    emoji: '✨',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),
  CelebritySystem(
    name: 'Elon Musk',
    title: 'Time-Blocking Empire',
    subtitle: 'PRODUCTIVITY MAXIMIZER',
    tier: '🌟 SUPER VIRAL (50M+ Views)',
    habits: [
      'Wake 7am, prioritize critical emails (30 min)',
      '5-minute time blocks entire day',
      '6-6.5 hours sleep minimum',
      'Batch similar tasks together',
      '30-minute meeting maximum',
      'Strategic multitasking',
    ],
    whyViral: 'Manages multiple billion-dollar companies',
    emoji: '🚀',
    gradientColors: [59, 130, 246, 37, 99, 235], // Blue gradient
  ),
  CelebritySystem(
    name: 'Mark Wahlberg',
    title: 'Extreme Schedule',
    subtitle: 'MOST INTENSE',
    tier: '🌟 SUPER VIRAL (50M+ Views)',
    habits: [
      'Wake at 3:30am',
      'Prayer time immediately',
      '4am workout (95 minutes)',
      'Breakfast #1 at 5:15am',
      'Cryotherapy chamber',
      'Golf/meetings/family blocked',
    ],
    whyViral: 'Routinely makes headlines for intensity',
    emoji: '⏰',
    gradientColors: [239, 68, 68, 185, 28, 28], // Dark red
  ),

  // TIER 3: HIGHLY INFLUENTIAL
  CelebritySystem(
    name: 'Ashton Hall',
    title: 'Viral Morning',
    subtitle: '2025 INTERNET SENSATION',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      '3:50am-9:30am routine (5.5 hours!)',
      'Banana peel facial treatment',
      'Two facial ice baths',
      'Multiple Saratoga Spring Waters',
    ],
    whyViral: 'Video viewed over 700 MILLION times',
    emoji: '🍌',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Taylor Swift',
    title: 'Creative Discipline',
    subtitle: 'RECORD-BREAKING SUCCESS',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      'Songwriting first thing (morning deep work)',
      'Daily walks for inspiration',
      'Treats songwriting like regular job',
      'Dedicated time blocks for creativity',
    ],
    whyViral: 'Discipline enabled record-breaking 2024/2025 tour',
    emoji: '🎵',
    gradientColors: [147, 51, 234, 126, 34, 206], // Purple gradient
  ),
  CelebritySystem(
    name: 'Tim Ferriss',
    title: '5 Morning Rituals',
    subtitle: '4-HOUR WORKWEEK AUTHOR',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      'Make bed immediately',
      'Meditate 20 minutes',
      'Exercise 30+ minutes minimum',
      'Drink strong tea',
      'Journal 5-10 minutes',
    ],
    whyViral: 'Millions follow his 4-Hour Workweek methods',
    emoji: '📚',
    gradientColors: [14, 165, 233, 2, 132, 199], // Cyan gradient
  ),
  CelebritySystem(
    name: 'Beyoncé',
    title: '6AM Gratitude',
    subtitle: 'QUEEN OF CONSISTENCY',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      'Wake at 6am for gratitude practice',
      'Prayer and intention setting',
      'Plant-based vegan breakfast',
      'Workout session',
    ],
    whyViral: '"We all have as many hours as Beyoncé" meme',
    emoji: '👑',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),
  CelebritySystem(
    name: 'Paris Hilton',
    title: 'Branding Routine',
    subtitle: '\$300M+ EMPIRE',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      'Morning meditation and gratitude',
      'Significant content creation time',
      'Self-care prioritization',
      'Social media content development',
    ],
    whyViral: '\$300M+ brand built on consistency',
    emoji: '💎',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Barack Obama',
    title: 'Leadership Discipline',
    subtitle: 'PRESIDENTIAL ROUTINE',
    tier: '💫 HIGHLY INFLUENTIAL (20M+)',
    habits: [
      'Wake 5am for workout (cardio + strength)',
      'Evening reading time',
      'Multiple newspapers each morning',
      'Green tea instead of coffee',
      'Same color suits (decision minimization)',
    ],
    whyViral: 'Maintained routine through 8 years in office',
    emoji: '🎖️',
    gradientColors: [59, 130, 246, 29, 78, 216], // Blue gradient
  ),

  // TIER 4: NICHE VIRAL
  CelebritySystem(
    name: 'Serena Williams',
    title: 'Champion Mentality',
    subtitle: 'TENNIS LEGEND',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      'Wake before sunrise',
      'Gratitude mantra first thing',
      'Express appreciation for blessings',
      'Detailed beauty routine',
      'Simple breakfast',
    ],
    whyViral: 'Champion mindset in morning routine',
    emoji: '🎾',
    gradientColors: [34, 197, 94, 21, 128, 61], // Green gradient
  ),
  CelebritySystem(
    name: 'Lizzo',
    title: 'Hydration Focus',
    subtitle: 'SIMPLE SELF-CARE',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      'Water immediately upon waking',
      'More water! "Water is really important"',
      'Evian spray to face',
    ],
    whyViral: 'Simple but effective self-care',
    emoji: '💧',
    gradientColors: [14, 165, 233, 3, 105, 161], // Light blue
  ),
  CelebritySystem(
    name: 'Drake',
    title: '5AM Meditation',
    subtitle: 'RAP MOGUL MINDFULNESS',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      '5am meditation focusing on breathing and intentions',
      'Check news and phone',
      'Call son to touch base',
      'Gym session, then breakfast',
    ],
    whyViral: 'Unexpected mindfulness from rap star',
    emoji: '🧘',
    gradientColors: [168, 85, 247, 126, 34, 206], // Purple gradient
  ),
  CelebritySystem(
    name: 'Miley Cyrus',
    title: 'Yoga Non-Negotiable',
    subtitle: 'MENTAL HEALTH WARRIOR',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      '"Gotta do yoga, not for my body but for my mind!"',
      '"DO YOGA or GO CRAZY!"',
      'Multiple yoga sessions daily',
    ],
    whyViral: 'Public advocate for yoga\'s mental health benefits',
    emoji: '🧘‍♀️',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Denzel Washington',
    title: 'Silence Rule',
    subtitle: 'LEGENDARY DISCIPLINE',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      '"Spend a half hour every morning in quiet time first"',
      'Step away from phones',
      'Enjoy silence',
    ],
    whyViral: 'Decades of success through discipline',
    emoji: '🤫',
    gradientColors: [71, 85, 105, 51, 65, 85], // Gray gradient
  ),
  CelebritySystem(
    name: 'Zendaya',
    title: 'Family Morning',
    subtitle: 'RELATABLE STAR',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      'Wake around 8am but stays in bed',
      'Mornings filled with family time',
      'Bothering family members (relatable!)',
    ],
    whyViral: 'Most relatable celebrity routine',
    emoji: '👨‍👩‍👧',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),
  CelebritySystem(
    name: 'Kamala Harris',
    title: 'Two Non-Negotiables',
    subtitle: 'POLITICAL POWER',
    tier: '🎯 NICHE VIRAL (10M+)',
    habits: [
      'Must eat breakfast every morning',
      'Must get workout in',
      'Spinach omelet, chicken apple sausage, toast',
    ],
    whyViral: 'Simple routine enables demanding schedule',
    emoji: '🇺🇸',
    gradientColors: [59, 130, 246, 37, 99, 235], // Blue gradient
  ),

  // BONUS: UNIQUE VIRAL HABITS
  CelebritySystem(
    name: 'Orlando Bloom',
    title: 'Earn Your Breakfast',
    subtitle: 'UNCONVENTIONAL COMBO',
    tier: '🎨 BONUS: UNIQUE VIRAL',
    habits: [
      'Track sleep quality immediately',
      'Green powders, brain octane oil, collagen powder pre-breakfast',
      'Hike listening to Nirvana OR read Buddhist texts',
    ],
    whyViral: 'Unusual combinations sparked debate',
    emoji: '🏔️',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),
  CelebritySystem(
    name: 'Jim Carrey',
    title: 'Creative Call',
    subtitle: 'GENIUS CREATIVITY HACK',
    tier: '🎨 BONUS: UNIQUE VIRAL',
    habits: [
      'Calls himself at 11am daily',
      'Pretends someone from past is calling with news',
      'Gets creative ideas flowing and new perspective',
    ],
    whyViral: 'Most creative morning routine ever',
    emoji: '📞',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),
  CelebritySystem(
    name: 'Kate Hudson',
    title: 'Ice Bath Face',
    subtitle: 'BEAUTY BIOHACK',
    tier: '🎨 BONUS: UNIQUE VIRAL',
    habits: [
      'Ice bath on face using water and lots of ice',
      'Holds face in as long as possible',
      'Refreshes tired/dull skin',
    ],
    whyViral: 'Simple biohack for ageless beauty',
    emoji: '🧊',
    gradientColors: [14, 165, 233, 3, 105, 161], // Cyan gradient
  ),
  CelebritySystem(
    name: 'Gwyneth Paltrow',
    title: 'Oil Pulling',
    subtitle: 'GOOP FOUNDER ROUTINE',
    tier: '🎨 BONUS: UNIQUE VIRAL',
    habits: [
      '6:30am rise',
      'Swish minty coconut oil for 10 minutes',
      'Coffee and meditation with husband',
      'Workout then smoothie',
    ],
    whyViral: 'Wellness empire built on morning rituals',
    emoji: '🥥',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Jeff Bezos',
    title: 'Puttering Morning',
    subtitle: 'BILLIONAIRE LEISURE',
    tier: '🎨 BONUS: UNIQUE VIRAL',
    habits: [
      'No meetings before 10am',
      'Leisurely breakfast with family',
      'Read newspaper',
      '"Puttering around" time',
      'High-IQ meetings before lunch only',
    ],
    whyViral: 'Even billionaires need downtime',
    emoji: '☕',
    gradientColors: [120, 113, 108, 87, 83, 78], // Brown/coffee gradient
  ),
];

