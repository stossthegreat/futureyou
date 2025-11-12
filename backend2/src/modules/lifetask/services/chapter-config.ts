/**
 * CHAPTER CONFIGURATIONS
 * Research-based frameworks and prompts for each of the 7 chapters
 */

export interface ChapterConfig {
  title: string;
  goal: string;
  frameworks: string[];
  keyThemes: string[];
  samplePrompts: string[];
  estimatedExchanges: string;      // e.g., "80-150" (estimate only, NOT enforced)
  estimatedSessions: string;        // e.g., "3-5 sessions"
  estimatedTimeframe: string;       // e.g., "2-4 weeks"
  requiredScenes: number;           // Minimum specific scenes needed
  requiredPatterns: number;         // Minimum patterns to identify
  requiredBreakthrough: boolean;    // Must have emotional breakthrough
  artifactTypes: string[];
}

export const CHAPTER_CONFIGS: Record<number, ChapterConfig> = {
  1: {
    title: 'Chapter I — The Call',
    goal: 'Excavate childhood pull, primal inclinations, earliest peak experiences',
    frameworks: ['Greene - Mastery', 'Narrative Identity', 'Primal Inclinations'],
    keyThemes: [
      'Childhood moments of absorption',
      'Activities that sparked deep curiosity',
      'Feelings of heightened power or fascination',
      'Games invented, projects created',
      'Moments feeling most alive',
    ],
    samplePrompts: [
      "Tell me about one childhood moment when you felt completely absorbed. Not a memory—a scene. Where were you? What were you doing?",
      "What did you love doing as a child that you'd be embarrassed to admit now? Why the embarrassment?",
      "Describe a moment when you felt quietly proud of something you made or did. Paint me the scene.",
      "What game did you invent as a child? Not the name—the rules, the feeling, who played, why it mattered.",
      "When did you feel most yourself before you had vocabulary for it? Give me the sensory details.",
      "What attracted you before you could explain why? What object, activity, or topic pulled you in?",
      "Tell me about a time you lost track of time completely. What were your hands doing? What were you creating?",
    ],
    estimatedExchanges: '80-150',
    estimatedSessions: '3-5 sessions',
    estimatedTimeframe: '2-4 weeks',
    requiredScenes: 5,
    requiredPatterns: 3,
    requiredBreakthrough: true,
    artifactTypes: ['story_map'],
  },

  2: {
    title: 'Chapter II — The Conflict',
    goal: 'Shadow work, false paths, persona vs authentic self, envy as compass',
    frameworks: ['Jung - Shadow', 'Frankl - Anti-regret', 'Embarrassment Test'],
    keyThemes: [
      'False paths taken',
      'Expectations that weren\'t truly yours',
      'Shadow desires (what you want but won\'t admit)',
      'Envy map (who makes you jealous and why)',
      'Embarrassment test (secret wants)',
      'Deathbed regrets avoided',
    ],
    samplePrompts: [
      "What path did you take that you knew wasn't truly yours? When did you first feel that tension?",
      "Who do you envy? Not their success—their daily life. What are they doing that you're not letting yourself do?",
      "What do you secretly want that you'd be embarrassed to say out loud? Tell me the desire, not the reason.",
      "You're 90, looking back. You made the safe choice. What sentence haunts you?",
      "What did society tell you mattered that you pretended to care about? When did you realize it was a lie?",
      "What part of yourself did you hide to fit in? What does that part still want?",
      "Who were you trying to become that wasn't you? Whose approval were you chasing?",
      "What conflict keeps repeating in your life? What's the pattern underneath?",
    ],
    estimatedExchanges: '100-180',
    estimatedSessions: '4-6 sessions',
    estimatedTimeframe: '2-3 weeks',
    requiredScenes: 5,
    requiredPatterns: 3,
    requiredBreakthrough: true,
    artifactTypes: ['shadow_map'],
  },

  3: {
    title: 'Chapter III — The Mirror',
    goal: 'Strengths × Values mapping, SDT needs diagnostic, authentic self-reflection',
    frameworks: ['VIA Strengths', 'Self-Determination Theory', 'Values Hierarchy'],
    keyThemes: [
      'Signature strengths (what energizes you)',
      'Values ranked by importance',
      'Autonomy need level',
      'Competence need level',
      'Relatedness need level',
      'Natural talents that feel effortless',
    ],
    samplePrompts: [
      "What do people always ask your help with that seems obvious to you? What do you think 'everyone can do'?",
      "Rank these 8 values: Autonomy, Impact, Mastery, Learning, Belonging, Stability, Adventure, Beauty. Which wins and why?",
      "When do you feel most autonomous—most like yourself, doing what you choose? Give me a specific Tuesday.",
      "Tell me about a time you felt deeply competent. Not praised—competent. What were you mastering?",
      "Who makes you feel most like yourself? What do they see in you that others miss?",
      "What strength of yours is invisible to you but obvious to others? What do you do effortlessly?",
      "Which value, if violated, makes you furious? That's your core value—name it.",
      "When do you feel like you're pretending? That's where autonomy is missing. Tell me about that moment.",
    ],
    estimatedExchanges: '90-140',
    estimatedSessions: '3-5 sessions',
    estimatedTimeframe: '2-3 weeks',
    requiredScenes: 6,
    requiredPatterns: 4,
    requiredBreakthrough: true,
    artifactTypes: ['strengths_grid'],
  },

  4: {
    title: 'Chapter IV — The Mentor',
    goal: 'Flow mapping, energy patterns, contexts of absorption',
    frameworks: ['Flow Theory', 'Energy Audit', 'Skill × Challenge'],
    keyThemes: [
      'Flow state triggers',
      'Activities where time disappears',
      'Energy sources vs drains',
      'Contexts producing 9-10 focus',
      'Skills used during peak engagement',
      'People who amplify your energy',
    ],
    samplePrompts: [
      "Last time you looked up and three hours had passed without noticing. Walk me through the 10 minutes before that happened.",
      "What gives you energy versus drains you? Subtract all the 'shoulds.' What's left?",
      "When do you enter flow state—when skills match challenge and time disappears? What's the pattern?",
      "Describe your best working day in the last month. Not productive—best. What made it feel that way?",
      "What do you do where you forget to check your phone? What's so absorbing you lose track?",
      "Who do you work with when time moves differently? What's special about that collaboration?",
      "What skill are you practicing that doesn't feel like practice? What's the challenge you're chasing?",
      "Future-You speaks: 'This is what you're built for.' What are they pointing at? Be specific.",
    ],
    estimatedExchanges: '80-130',
    estimatedSessions: '2-3 weeks (includes 7-day flow diary)',
    estimatedTimeframe: '2-3 weeks',
    requiredScenes: 7,
    requiredPatterns: 3,
    requiredBreakthrough: false,
    artifactTypes: ['flow_map'],
  },

  5: {
    title: 'Chapter V — The Task',
    goal: 'Odyssey plans, meaning tests, prototyping futures, anti-regret lens',
    frameworks: ['Designing Your Life', 'Odyssey Planning', 'Job Crafting', 'Frankl - Meaning'],
    keyThemes: [
      'Three possible futures (double-down, adjacent, wild card)',
      'Meaning tests (contribution, courage, attitude)',
      'Boring Tuesday reality checks',
      'Anti-regret questions',
      'Micro-experiments to run',
      'What\'s worth 10 years of effort',
    ],
    samplePrompts: [
      "If you had infinite resources, after 6 months of hedonism you'd get bored. What problem would you start working on?",
      "You're 90, looking back. You made the safe choice. What sentence haunts you?",
      "What's worth doing for 10 years even if years 3-7 are boring and hard?",
      "Three futures: 1) Double-down on current path. 2) Adjacent possible. 3) Wild card. Sketch each—what does a Tuesday look like?",
      "What would make you feel deeply useful—not appreciated, but useful? Who would benefit? How?",
      "What scares you that, if you could do it, would fundamentally change how you see yourself?",
      "Who would be genuinely worse off if you'd never existed? Not sad—worse off. What did you give them?",
      "What cheap experiment could you run in 2 weeks to test if this path is real? What's the $100 version?",
    ],
    estimatedExchanges: '120-200',
    estimatedSessions: '5-7 sessions',
    estimatedTimeframe: '3-4 weeks',
    requiredScenes: 8,
    requiredPatterns: 3,
    requiredBreakthrough: true,
    artifactTypes: ['odyssey_plans', 'job_crafting'],
  },

  6: {
    title: 'Chapter VI — The Path',
    goal: 'One-sentence life task, keystone habits, anti-habits, commitment structure',
    frameworks: ['Life Crafting', 'Keystone Habits', 'Identity-Based Goals'],
    keyThemes: [
      'Life task sentence: [VERB] + [WHO] + [VALUE]',
      '6-month mission (single domain, audience, output)',
      'Keystone habits (2-3 max)',
      'Anti-habits (what to actively avoid)',
      'Accountability structure',
      'Success metrics (not vanity)',
    ],
    samplePrompts: [
      "Complete this sentence: 'I [VERB] for [WHO] so they can [VALUE].' What's your one-sentence life task?",
      "What's one keystone habit that would make everything else easier or unnecessary?",
      "What should you actively avoid? Name one anti-habit—something that derails you every time.",
      "6 months from now, what should exist that doesn't exist today? Who receives it? How do they change?",
      "Your life task needs to be sharp enough to say NO to opportunities. Test it—what would you reject?",
      "What's the smallest weekly commitment that keeps you on path? Not ambitious—sustainable. What's the Tuesday ritual?",
      "Who holds you accountable? Not who you want to impress—who sees through your bullshit lovingly?",
      "If nothing changes in 90 days, what's the first regret? Name it specifically.",
    ],
    estimatedExchanges: '100-160',
    estimatedSessions: '4-6 sessions',
    estimatedTimeframe: '2-3 weeks',
    requiredScenes: 6,
    requiredPatterns: 3,
    requiredBreakthrough: true,
    artifactTypes: ['purpose_card'],
  },

  7: {
    title: 'Chapter VII — The Promise',
    goal: 'Review structure, mastery path, legacy vision, long-term commitment',
    frameworks: ['Deliberate Practice', 'Monthly Reviews', 'Mastery Journey', 'Legacy'],
    keyThemes: [
      'Monthly review questions',
      'Skill to master over 1,000+ hours',
      'Deliberate practice structure',
      'Contribution beyond self',
      'Long-term commitment vision',
      'How you\'ll know you\'re on path',
    ],
    samplePrompts: [
      "Future-You is 10 years ahead. They kept the promise. What did they do differently, starting tomorrow?",
      "What's your monthly review question? The one that keeps you honest about whether you're on path.",
      "Which skill will you deliberately practice for the next 1,000 hours? Why that one?",
      "How will you know, in 1 year, that you stayed true to your task? What's the evidence you'll look for?",
      "What's the contribution that outlives you? Not legacy—impact. Who benefits after you're gone?",
      "You're at your funeral. Someone you mentored speaks. What do you desperately want them to say?",
      "What will try to pull you off path? Name the specific temptations. How will you say no?",
      "The promise isn't one grand moment. It's small decisions. What's the daily one that matters most?",
    ],
    estimatedExchanges: '80-140',
    estimatedSessions: '3-5 sessions',
    estimatedTimeframe: '2-3 weeks',
    requiredScenes: 5,
    requiredPatterns: 3,
    requiredBreakthrough: true,
    artifactTypes: ['mastery_path'],
  },
};

export function getChapterConfig(chapterNumber: number): ChapterConfig {
  return CHAPTER_CONFIGS[chapterNumber] || CHAPTER_CONFIGS[1];
}

