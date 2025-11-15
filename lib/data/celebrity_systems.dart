// 🌟 Celebrity Habit Systems Data
// 25 serious celebrity routines with full details

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
  // TIER 1: EXTREME INTENSITY
  CelebritySystem(
    name: 'Andrew Huberman',
    title: 'Science-Based Protocol',
    subtitle: 'NEUROSCIENCE OPTIMIZED',
    tier: '🔥 EXTREME INTENSITY',
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
    whyViral: 'Science-backed protocol proven transformative',
    emoji: '🧠',
    gradientColors: [99, 102, 241, 139, 92, 246], // Purple to violet
  ),
  CelebritySystem(
    name: 'The Rock',
    title: '4AM Discipline',
    subtitle: 'MOST CONSISTENT CELEBRITY',
    tier: '🔥 EXTREME INTENSITY',
    habits: [
      'Wake at 3:30am daily (non-negotiable)',
      'Cardio 50 min (fasted)',
      'Workout 90 min (4 sets x 12 reps)',
      'First meal by 5:30am',
      'Second "Iron Paradise" training session',
      '6 meals daily (5,000+ calories precision)',
      'Answer fan DMs personally in car',
      '7 workouts per week',
      'Gratitude practice',
    ],
    whyViral: 'Legendary work ethic and consistency',
    emoji: '💪',
    gradientColors: [239, 68, 68, 220, 38, 38], // Red gradient
  ),
  CelebritySystem(
    name: 'David Goggins',
    title: 'Mental Warfare',
    subtitle: 'ULTRA-ENDURANCE LEGEND',
    tier: '🔥 EXTREME INTENSITY',
    habits: [
      'Wake 4am (no exceptions)',
      '3-hour morning workout',
      'Cold water immersion',
      'Fasted until noon',
      'Accountability mirror practice',
      'Evening 1-2 hour workout',
      'Visualization 30 min',
      'Cookie jar method (recall past wins)',
    ],
    whyViral: '300lbs to Navy SEAL - ultimate transformation',
    emoji: '⚔️',
    gradientColors: [239, 68, 68, 185, 28, 28], // Dark red
  ),
  CelebritySystem(
    name: 'Jocko Willink',
    title: 'Discipline Equals Freedom',
    subtitle: '4:30 AM FOR 10+ YEARS',
    tier: '🔥 EXTREME INTENSITY',
    habits: [
      'Wake 4:30am (posts watch photo daily)',
      'Immediate workout',
      'Jiu-jitsu training daily',
      'No sugar ever',
      'Cold exposure',
      'Same routine weekends',
      'Early bed (discipline)',
    ],
    whyViral: 'Decade+ of 4:30am consistency, zero days off',
    emoji: '⏰',
    gradientColors: [71, 85, 105, 51, 65, 85], // Dark gray
  ),

  // TIER 2: HIGH INTENSITY
  CelebritySystem(
    name: 'Cristiano Ronaldo',
    title: 'Peak Performance',
    subtitle: 'ATHLETE GOLD STANDARD',
    tier: '🌟 HIGH INTENSITY',
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
  CelebritySystem(
    name: 'Jennifer Lopez',
    title: 'NO Compromise',
    subtitle: 'NO SUGAR, ALCOHOL, CAFFEINE EVER',
    tier: '🌟 HIGH INTENSITY',
    habits: [
      'Wake 5am (no snooze)',
      '90-min workout (cardio, strength, abs)',
      'NO sugar, alcohol, caffeine EVER',
      'Salmon, quinoa, veggies (no carbs after 6pm)',
      'Sleep 8-10 hours',
      'Same routine 20+ years',
    ],
    whyViral: 'Looks 35 at 55 - elimination diet works',
    emoji: '✨',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),
  CelebritySystem(
    name: 'LeBron James',
    title: 'Recovery Investment',
    subtitle: '\$1.5M ANNUAL RECOVERY',
    tier: '🌟 HIGH INTENSITY',
    habits: [
      'Sleep 8-10 hours (non-negotiable)',
      'Ice bath daily',
      'Hyperbaric chamber sessions',
      'Cryotherapy',
      'Compression therapy',
      'Professional recovery team',
    ],
    whyViral: 'Playing at elite level at 40 years old',
    emoji: '🏀',
    gradientColors: [147, 51, 234, 126, 34, 206], // Purple gradient
  ),
  CelebritySystem(
    name: 'Oprah Winfrey',
    title: 'Spiritual Foundation',
    subtitle: 'MINDFULNESS QUEEN',
    tier: '🌟 HIGH INTENSITY',
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
    name: 'Mark Wahlberg',
    title: 'Extreme Schedule',
    subtitle: 'MOST INTENSE',
    tier: '🌟 HIGH INTENSITY',
    habits: [
      'Wake at 3:30am',
      'Prayer time immediately',
      '4am workout (95 minutes)',
      'Breakfast #1 at 5:15am',
      'Cryotherapy chamber',
      'Golf/meetings/family blocked',
    ],
    whyViral: 'Routinely makes headlines for intensity',
    emoji: '🌅',
    gradientColors: [239, 68, 68, 185, 28, 28], // Dark red
  ),
  CelebritySystem(
    name: 'Bryan Johnson',
    title: 'Blueprint Protocol',
    subtitle: 'AGE 47, BIOLOGICAL AGE 37',
    tier: '🌟 HIGH INTENSITY',
    habits: [
      'Wake 6am',
      '111 pills daily',
      'Vegan 1,977 calories',
      'Workout protocol',
      'Sleep optimization pod',
      'Plasma transfusions',
      '\$2M/year anti-aging investment',
    ],
    whyViral: 'Biological age reversal scientifically proven',
    emoji: '🧬',
    gradientColors: [14, 165, 233, 2, 132, 199], // Cyan gradient
  ),

  // TIER 3: MODERATE INTENSITY
  CelebritySystem(
    name: 'Tim Ferriss',
    title: '5 Morning Rituals',
    subtitle: '4-HOUR WORKWEEK AUTHOR',
    tier: '💫 MODERATE INTENSITY',
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
    title: 'Excellence Preparation',
    subtitle: 'DECADES OF DOMINANCE',
    tier: '💫 MODERATE INTENSITY',
    habits: [
      'Wake at 6am for gratitude practice',
      '30 days vegan before tours',
      'No alcohol for months before shows',
      '5-6 hour rehearsals',
      'Visualization practice',
      'Team of 20+ professionals',
      'Rest days sacred',
    ],
    whyViral: '"I woke up like this" = extreme preparation',
    emoji: '👑',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),
  CelebritySystem(
    name: 'Barack Obama',
    title: 'Leadership Discipline',
    subtitle: 'PRESIDENTIAL ROUTINE',
    tier: '💫 MODERATE INTENSITY',
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
  CelebritySystem(
    name: 'Jennifer Aniston',
    title: 'Hollywood Standard',
    subtitle: 'CONSISTENCY FOR 20+ YEARS',
    tier: '💫 MODERATE INTENSITY',
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
    emoji: '💎',
    gradientColors: [251, 191, 36, 245, 158, 11], // Gold gradient
  ),
  CelebritySystem(
    name: 'Rihanna',
    title: 'Billionaire Mom Balance',
    subtitle: '\$1.4B NET WORTH',
    tier: '💫 MODERATE INTENSITY',
    habits: [
      'Wake 7:30am',
      'Morning affirmations (mirror work)',
      'School drop-off personally',
      'Fenty meetings (product, marketing)',
      'Gym 45 min (strength)',
      'Family dinner (Caribbean meals)',
      'Present parenting (bath, bedtime)',
    ],
    whyViral: 'Built billion-dollar empire while being hands-on mom',
    emoji: '💄',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Simone Biles',
    title: 'Mental Health Champion',
    subtitle: 'GOAT GYMNAST',
    tier: '💫 MODERATE INTENSITY',
    habits: [
      'Wake 6am',
      'Gymnastics training 6 hours (vault, bars, beam, floor)',
      'Strength training 60 min',
      'Weekly therapy (mental health non-negotiable)',
      'Epsom salt bath nightly',
      'Sleep 10pm (8+ hours)',
      'Can say no (set boundaries)',
    ],
    whyViral: 'Mental health = physical health priority',
    emoji: '🤸‍♀️',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),
  CelebritySystem(
    name: 'Denzel Washington',
    title: 'Silence Rule',
    subtitle: 'LEGENDARY DISCIPLINE',
    tier: '💫 MODERATE INTENSITY',
    habits: [
      'Half hour every morning in quiet time first',
      'Step away from phones',
      'Enjoy silence',
      'Prayer and reflection',
    ],
    whyViral: 'Decades of success through discipline',
    emoji: '🤫',
    gradientColors: [71, 85, 105, 51, 65, 85], // Gray gradient
  ),

  // TIER 4: ACCESSIBLE INTENSITY
  CelebritySystem(
    name: 'Olivia Rodrigo',
    title: 'Creative Emotions',
    subtitle: 'AGE 21 - TEEN ICON',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Wake 6:45am naturally',
      'Journal 3 pages (emotions out)',
      'Skincare: cleanser, moisturizer, SPF 50',
      'Voice warmups 15 min',
      'Pilates/yoga 60 min',
      'Studio practice 90 min',
      'Evening walk (no phone)',
      'Sleep 10:30pm (8+ hours)',
    ],
    whyViral: 'Feelings = creativity fuel for Gen Z',
    emoji: '🎵',
    gradientColors: [147, 51, 234, 126, 34, 206], // Purple gradient
  ),
  CelebritySystem(
    name: 'Zendaya',
    title: 'Multi-Skill Mastery',
    subtitle: 'AGE 28 - TRIPLE THREAT',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Wake 6:30am',
      'Meditation 10-15 min',
      'Dance cardio/choreography 60 min',
      '12-step Korean skincare',
      'Family calls daily',
      'Gratitude journal',
      'Sleep 10:30pm',
    ],
    whyViral: 'Korean skincare + dance = career longevity',
    emoji: '✨',
    gradientColors: [236, 72, 153, 219, 39, 119], // Pink gradient
  ),
  CelebritySystem(
    name: 'Sabrina Carpenter',
    title: 'Voice as Instrument',
    subtitle: 'AGE 25 - VOCAL DISCIPLINE',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Wake 7am',
      '1L lemon water first',
      'Vocal steaming 10 min',
      'Vocal exercises 30 min',
      'Cardio 30 min (stamina)',
      'Rehearsal 2 hours',
      'Ice bath post-show',
      'Throat care: tea, steam',
    ],
    whyViral: 'Daily voice care = flawless performances',
    emoji: '🎤',
    gradientColors: [251, 146, 60, 249, 115, 22], // Orange gradient
  ),
  CelebritySystem(
    name: 'Taylor Swift',
    title: 'Creative Discipline',
    subtitle: 'RECORD-BREAKING SUCCESS',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Songwriting first thing (morning deep work)',
      'Daily walks for inspiration',
      'Treats songwriting like regular job',
      'Dedicated time blocks for creativity',
    ],
    whyViral: 'Discipline enabled record-breaking 2024/2025 tour',
    emoji: '🎸',
    gradientColors: [147, 51, 234, 126, 34, 206], // Purple gradient
  ),
  CelebritySystem(
    name: 'Serena Williams',
    title: 'Champion Mentality',
    subtitle: 'TENNIS LEGEND',
    tier: '🎯 ACCESSIBLE INTENSITY',
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
    name: 'Drake',
    title: '5AM Meditation',
    subtitle: 'RAP MOGUL MINDFULNESS',
    tier: '🎯 ACCESSIBLE INTENSITY',
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
    name: 'Viola Davis',
    title: 'Authentic Excellence',
    subtitle: 'AGE 59 - OSCAR WINNER',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Wake 6am',
      'Meditation 15 min',
      'Journal (gratitude, intentions)',
      'Script study 1 hour',
      'Workout 45 min',
      'Family board games',
      'Nighttime skincare (retinol)',
    ],
    whyViral: 'Deep character preparation + family connection',
    emoji: '🎭',
    gradientColors: [59, 130, 246, 37, 99, 235], // Blue gradient
  ),
  CelebritySystem(
    name: 'Orlando Bloom',
    title: 'Earn Your Breakfast',
    subtitle: 'UNCONVENTIONAL COMBO',
    tier: '🎯 ACCESSIBLE INTENSITY',
    habits: [
      'Track sleep quality immediately',
      'Green powders, brain octane oil, collagen powder pre-breakfast',
      'Hike listening to Nirvana OR read Buddhist texts',
    ],
    whyViral: 'Unusual combinations sparked debate',
    emoji: '🏔️',
    gradientColors: [34, 197, 94, 22, 163, 74], // Green gradient
  ),
];

