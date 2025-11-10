import { MessageDTO } from '../dto/conversation.dto';

/**
 * PATTERN EXTRACTOR
 * 
 * Extracts meaningful patterns from conversation transcripts:
 * - Red threads (recurring verbs, themes, contexts)
 * - Values signals
 * - Strengths indicators
 * - Flow contexts
 * - Emotional markers
 */

export interface ExtractedPatterns {
  redThreads: string[];
  values: string[];
  strengths: string[];
  flowContexts: string[];
  emotionalMarkers: string[];
  keyQuotes: string[];
  themes: string[];
}

export class PatternExtractorService {
  extractPatterns(messages: MessageDTO[], chapterNumber: number): ExtractedPatterns {
    const userMessages = messages.filter(m => m.role === 'user');
    const allText = userMessages.map(m => m.text).join(' ');

    return {
      redThreads: this.extractRedThreads(userMessages),
      values: this.extractValues(allText),
      strengths: this.extractStrengths(userMessages),
      flowContexts: this.extractFlowContexts(userMessages),
      emotionalMarkers: this.extractEmotionalMarkers(allText),
      keyQuotes: this.extractKeyQuotes(userMessages),
      themes: this.extractThemes(allText, chapterNumber),
    };
  }

  /**
   * Red threads: recurring verbs and action patterns
   */
  private extractRedThreads(userMessages: MessageDTO[]): string[] {
    const verbs = new Map<string, number>();
    
    const actionVerbs = [
      'build', 'create', 'make', 'design', 'write', 'teach', 'help', 'solve',
      'organize', 'connect', 'lead', 'explore', 'discover', 'analyze', 'simplify',
      'guide', 'mentor', 'coach', 'heal', 'protect', 'serve', 'inspire',
    ];

    for (const msg of userMessages) {
      const text = msg.text.toLowerCase();
      for (const verb of actionVerbs) {
        if (text.includes(verb)) {
          verbs.set(verb, (verbs.get(verb) || 0) + 1);
        }
      }
    }

    // Return verbs mentioned 2+ times
    return Array.from(verbs.entries())
      .filter(([_, count]) => count >= 2)
      .sort((a, b) => b[1] - a[1])
      .map(([verb]) => verb)
      .slice(0, 5);
  }

  /**
   * Values signals from language patterns
   */
  private extractValues(text: string): string[] {
    const lowerText = text.toLowerCase();
    const detectedValues: string[] = [];

    const valuePatterns: Record<string, string[]> = {
      autonomy: ['freedom', 'independent', 'own terms', 'my way', 'control'],
      impact: ['change', 'difference', 'better', 'improve', 'transform'],
      mastery: ['learn', 'practice', 'perfect', 'master', 'skill'],
      learning: ['curious', 'understand', 'discover', 'explore', 'know'],
      belonging: ['together', 'community', 'team', 'connect', 'relationship'],
      stability: ['secure', 'stable', 'reliable', 'consistent', 'predictable'],
      adventure: ['new', 'explore', 'adventure', 'risk', 'unknown'],
      beauty: ['beautiful', 'aesthetic', 'art', 'elegant', 'design'],
    };

    for (const [value, keywords] of Object.entries(valuePatterns)) {
      const matchCount = keywords.filter(kw => lowerText.includes(kw)).length;
      if (matchCount >= 2) {
        detectedValues.push(value);
      }
    }

    return detectedValues;
  }

  /**
   * Strengths indicators from VIA framework
   */
  private extractStrengths(userMessages: MessageDTO[]): string[] {
    const allText = userMessages.map(m => m.text.toLowerCase()).join(' ');
    const detectedStrengths: string[] = [];

    const strengthPatterns: Record<string, string[]> = {
      creativity: ['create', 'invent', 'imagine', 'original', 'new way'],
      curiosity: ['wonder', 'curious', 'explore', 'question', 'discover'],
      judgment: ['analyze', 'think through', 'consider', 'evaluate', 'reason'],
      love_of_learning: ['learn', 'study', 'research', 'understand', 'knowledge'],
      perspective: ['see', 'perspective', 'wisdom', 'big picture', 'context'],
      bravery: ['courage', 'brave', 'fear', 'risk', 'stand up'],
      perseverance: ['persist', 'keep going', 'finish', 'complete', 'through'],
      honesty: ['honest', 'truth', 'authentic', 'genuine', 'real'],
      zest: ['energy', 'enthusiasm', 'passion', 'excited', 'alive'],
      love: ['love', 'care', 'compassion', 'close', 'connection'],
      kindness: ['kind', 'help', 'generous', 'compassion', 'caring'],
      social_intelligence: ['understand people', 'empathy', 'read', 'sense'],
      teamwork: ['team', 'collaborate', 'together', 'cooperate', 'group'],
      fairness: ['fair', 'justice', 'equal', 'right', 'principle'],
      leadership: ['lead', 'guide', 'organize', 'direct', 'rally'],
      forgiveness: ['forgive', 'mercy', 'second chance', 'let go'],
      humility: ['humble', 'modest', 'not about me', 'serve'],
      prudence: ['careful', 'cautious', 'plan', 'think ahead', 'wise'],
      self_regulation: ['control', 'discipline', 'regulate', 'manage', 'restrain'],
      appreciation: ['beauty', 'excellence', 'appreciate', 'admire', 'awe'],
      gratitude: ['grateful', 'thankful', 'appreciate', 'blessing', 'fortunate'],
      hope: ['hope', 'optimistic', 'future', 'believe', 'possible'],
      humor: ['laugh', 'funny', 'joke', 'playful', 'lighthearted'],
      spirituality: ['meaning', 'purpose', 'higher', 'spiritual', 'transcendent'],
    };

    for (const [strength, keywords] of Object.entries(strengthPatterns)) {
      const matchCount = keywords.filter(kw => allText.includes(kw)).length;
      if (matchCount >= 2) {
        detectedStrengths.push(strength.replace('_', ' '));
      }
    }

    return detectedStrengths.slice(0, 7);
  }

  /**
   * Flow contexts: situations where time disappeared
   */
  private extractFlowContexts(userMessages: MessageDTO[]): string[] {
    const flowIndicators = [
      /time (disappeared|flew|passed quickly|vanished)/i,
      /lost track of time/i,
      /hours (felt like|passed like) minutes/i,
      /completely absorbed/i,
      /in the zone/i,
      /flow state/i,
    ];

    const contexts: string[] = [];

    for (const msg of userMessages) {
      const hasFlowIndicator = flowIndicators.some(pattern => pattern.test(msg.text));
      if (hasFlowIndicator && msg.text.length > 50) {
        // Extract the activity context (simplified - could be more sophisticated)
        const sentences = msg.text.split(/[.!?]/);
        for (const sentence of sentences) {
          if (flowIndicators.some(pattern => pattern.test(sentence))) {
            contexts.push(sentence.trim());
          }
        }
      }
    }

    return contexts.slice(0, 5);
  }

  /**
   * Emotional markers for depth assessment
   */
  private extractEmotionalMarkers(text: string): string[] {
    const markers: string[] = [];
    const lowerText = text.toLowerCase();

    const emotionalWords: Record<string, string[]> = {
      vulnerability: ['scared', 'afraid', 'vulnerable', 'embarrassed', 'ashamed'],
      aliveness: ['alive', 'free', 'powerful', 'capable', 'confident'],
      connection: ['loved', 'connected', 'belonging', 'seen', 'understood'],
      pain: ['hurt', 'painful', 'sad', 'grief', 'loss'],
      joy: ['joy', 'happy', 'ecstatic', 'thrilled', 'delighted'],
      pride: ['proud', 'accomplished', 'satisfied', 'fulfilled'],
    };

    for (const [category, words] of Object.entries(emotionalWords)) {
      const found = words.filter(w => lowerText.includes(w));
      if (found.length > 0) {
        markers.push(category);
      }
    }

    return markers;
  }

  /**
   * Extract most meaningful quotes from user
   */
  private extractKeyQuotes(userMessages: MessageDTO[]): string[] {
    const quotes: string[] = [];

    // Look for substantive messages (100+ chars) with emotional or scene content
    for (const msg of userMessages) {
      if (msg.text.length >= 100 && msg.text.length <= 300) {
        const hasEmotionalWord = /\b(felt|feel|remember|realized|understood|discovered)\b/i.test(msg.text);
        const hasSceneDetail = /\b(I was|I remember|moment when|time when)\b/i.test(msg.text);
        
        if (hasEmotionalWord || hasSceneDetail) {
          quotes.push(msg.text);
        }
      }
    }

    return quotes.slice(0, 5);
  }

  /**
   * Extract chapter-specific themes
   */
  private extractThemes(text: string, chapterNumber: number): string[] {
    const themes: string[] = [];
    const lowerText = text.toLowerCase();

    const chapterThemes: Record<number, Record<string, string[]>> = {
      1: {
        'childhood_absorption': ['childhood', 'kid', 'young', 'child', 'back then'],
        'primal_pull': ['attracted', 'drawn', 'pulled', 'fascinated', 'obsessed'],
        'early_mastery': ['good at', 'natural', 'easy', 'effortless', 'intuitive'],
      },
      2: {
        'shadow_work': ['hide', 'secret', 'afraid to admit', 'won\'t tell', 'embarrassed'],
        'false_paths': ['should', 'supposed to', 'expected', 'pressure', 'not mine'],
        'envy': ['envy', 'jealous', 'wish I had', 'they have', 'admire'],
      },
      3: {
        'autonomy': ['freedom', 'choice', 'my way', 'independent', 'control'],
        'competence': ['good at', 'capable', 'mastery', 'skill', 'excel'],
        'relatedness': ['connection', 'belong', 'team', 'together', 'relationship'],
      },
      4: {
        'flow_state': ['absorbed', 'zone', 'time disappeared', 'focused', 'immersed'],
        'energy_gain': ['energized', 'alive', 'motivated', 'excited', 'fueled'],
        'skill_challenge': ['challenge', 'stretch', 'growth', 'pushing', 'edge'],
      },
      5: {
        'meaning': ['purpose', 'why', 'matters', 'meaningful', 'significance'],
        'contribution': ['help', 'serve', 'impact', 'difference', 'change'],
        'future_vision': ['imagine', 'future', 'could be', 'possibility', 'potential'],
      },
      6: {
        'commitment': ['commit', 'promise', 'decide', 'choose', 'dedicate'],
        'habits': ['daily', 'regular', 'practice', 'routine', 'ritual'],
        'identity': ['I am', 'become', 'who I', 'my role', 'my path'],
      },
      7: {
        'mastery': ['master', 'practice', 'develop', 'improve', 'refine'],
        'legacy': ['future', 'impact', 'after', 'leave behind', 'continue'],
        'sustainability': ['sustain', 'maintain', 'keep going', 'long term', 'endure'],
      },
    };

    const themePatternsForChapter = chapterThemes[chapterNumber] || {};

    for (const [theme, keywords] of Object.entries(themePatternsForChapter)) {
      const matchCount = keywords.filter(kw => lowerText.includes(kw)).length;
      if (matchCount >= 1) {
        themes.push(theme.replace('_', ' '));
      }
    }

    return themes;
  }
}

export const patternExtractor = new PatternExtractorService();

