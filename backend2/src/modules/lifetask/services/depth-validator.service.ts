import { MessageDTO } from '../dto/conversation.dto';
import { getChapterConfig } from './chapter-config';

/**
 * DEPTH VALIDATOR - Mastery Version
 * 
 * NO ARTIFICIAL LIMITS. Only QUALITY gates.
 * 
 * Conversation continues until:
 * - 5-10 specific scenes collected (not categories)
 * - 3+ clear patterns identified
 * - Emotional breakthrough reached
 * - AI confidence >= 9/10
 * 
 * User might need:
 * - Multiple sessions (3-6 per chapter)
 * - Days/weeks between sessions
 * - 80-180 exchanges per chapter
 */

export interface DepthMetrics {
  // Quantity (informational only - NOT gates)
  exchangeCount: number;
  timeElapsedMinutes: number;
  sessionNumber: number;
  
  // QUALITY GATES (these determine if chapter can complete)
  specificScenesCollected: number;        // Need: 5-10
  clearPatternsIdentified: number;        // Need: 3+
  emotionalBreakthroughReached: boolean;  // Need: true
  aiConfidenceScore: number;              // Need: 9+/10
  
  // Supporting metrics
  emotionalMarkersDetected: number;
  vagueResponseRatio: number;
  contradictionCount: number;
  categoryResponseCount: number;
  borrowedDreamCount: number;
  
  // Detailed scoring
  specificityScore: number;        // 0-10
  authenticityScore: number;       // 0-10
  patternClarityScore: number;     // 0-10
  emotionalDepthScore: number;     // 0-10
  intrinsicMotivationScore: number; // 0-10
  processLoveScore: number;        // 0-10
  uniquenessScore: number;         // 0-10
}

export interface ValidationResult {
  canComplete: boolean;
  metrics: DepthMetrics;
  missingElements: string[];
  nextFocus: string;
  reflectionPrompt?: string;  // Send user away to reflect
}

export class DepthValidatorService {
  /**
   * MASTER VALIDATION - Can this chapter complete?
   * 
   * NO artificial minimums. Only quality gates.
   */
  validateDepth(
    chapterNumber: number,
    messages: MessageDTO[],
    sessionStartTime?: string,
    sessionNumber: number = 1
  ): ValidationResult {
    const config = getChapterConfig(chapterNumber);
    const userMessages = messages.filter(m => m.role === 'user');
    const exchangeCount = userMessages.length;

    const timeElapsed = sessionStartTime
      ? Math.floor((Date.now() - new Date(sessionStartTime).getTime()) / 60000)
      : 0;

    // QUALITY GATES
    const specificScenesCollected = this.countSpecificScenes(userMessages);
    const clearPatternsIdentified = this.identifyPatterns(userMessages);
    const emotionalBreakthroughReached = this.detectEmotionalBreakthrough(userMessages);
    const aiConfidenceScore = this.calculateAIConfidence(userMessages, chapterNumber);
    
    // Supporting metrics
    const emotionalMarkersDetected = this.countEmotionalMarkers(userMessages);
    const vagueResponseRatio = this.calculateVagueRatio(userMessages);
    const contradictionCount = this.detectContradictions(userMessages);
    const categoryResponseCount = this.countCategoryResponses(userMessages);
    const borrowedDreamCount = this.countBorrowedDreams(userMessages);
    
    // Detailed scoring
    const specificityScore = this.scoreSpecificity(userMessages);
    const authenticityScore = this.scoreAuthenticity(userMessages);
    const patternClarityScore = this.scorePatternClarity(userMessages);
    const emotionalDepthScore = this.scoreEmotionalDepth(userMessages);
    const intrinsicMotivationScore = this.scoreIntrinsicMotivation(userMessages);
    const processLoveScore = this.scoreProcessLove(userMessages);
    const uniquenessScore = this.scoreUniqueness(userMessages);

    const metrics: DepthMetrics = {
      exchangeCount,
      timeElapsedMinutes: timeElapsed,
      sessionNumber,
      specificScenesCollected,
      clearPatternsIdentified,
      emotionalBreakthroughReached,
      aiConfidenceScore,
      emotionalMarkersDetected,
      vagueResponseRatio,
      contradictionCount,
      categoryResponseCount,
      borrowedDreamCount,
      specificityScore,
      authenticityScore,
      patternClarityScore,
      emotionalDepthScore,
      intrinsicMotivationScore,
      processLoveScore,
      uniquenessScore,
    };

    // CAN COMPLETE? (All gates must pass)
    const canComplete = 
      specificScenesCollected >= 5 &&
      clearPatternsIdentified >= 3 &&
      emotionalBreakthroughReached &&
      aiConfidenceScore >= 9.0 &&
      specificityScore >= 7 &&
      authenticityScore >= 7 &&
      patternClarityScore >= 7 &&
      emotionalDepthScore >= 7;

    // What's missing?
    const missingElements: string[] = [];
    if (specificScenesCollected < 5) {
      missingElements.push(`Only ${specificScenesCollected} specific scenes collected (need 5-10)`);
    }
    if (clearPatternsIdentified < 3) {
      missingElements.push(`Only ${clearPatternsIdentified} patterns identified (need 3+)`);
    }
    if (!emotionalBreakthroughReached) {
      missingElements.push('No emotional breakthrough detected (need vulnerability/real emotion)');
    }
    if (aiConfidenceScore < 9.0) {
      missingElements.push(`AI confidence only ${aiConfidenceScore.toFixed(1)}/10 (need 9+)`);
    }
    if (specificityScore < 7) {
      missingElements.push(`Too many vague answers (specificity: ${specificityScore.toFixed(1)}/10)`);
    }
    if (authenticityScore < 7) {
      missingElements.push(`Answers feel performative (authenticity: ${authenticityScore.toFixed(1)}/10)`);
    }

    // What to focus on next
    const nextFocus = this.determineNextFocus(metrics, missingElements);

    // Should we send user away to reflect?
    const reflectionPrompt = this.shouldSendUserAway(metrics, sessionNumber)
      ? this.generateReflectionPrompt(chapterNumber, userMessages)
      : undefined;

    console.log(`[DepthValidator] Chapter ${chapterNumber} - canComplete: ${canComplete}`);
    console.log(`[DepthValidator] Missing: ${missingElements.join('; ')}`);
    console.log(`[DepthValidator] AI Confidence: ${aiConfidenceScore.toFixed(1)}/10`);

    return { canComplete, metrics, missingElements, nextFocus, reflectionPrompt };
  }

  /**
   * Count specific scenes (not categories or abstract statements)
   */
  private countSpecificScenes(userMessages: MessageDTO[]): number {
    let sceneCount = 0;

    const sceneIndicators = [
      /\b(I was|we were|they were)\b.*\b(in|at|on)\b/i,
      /\b(I remember|I recall|moment when|time when|day when)\b/i,
      /\b(felt|touched|saw|heard|smelled|tasted)\b/i,
      /\b(morning|afternoon|evening|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b/i,
      /\b(backyard|room|tree|street|school|office|home|kitchen|bedroom)\b/i,
      /\b(hands|eyes|face|voice|breath|heart)\b/i,
    ];

    for (const msg of userMessages) {
      if (msg.text.length > 100) { // Substantial response
        const matchCount = sceneIndicators.filter(pattern => pattern.test(msg.text)).length;
        if (matchCount >= 3) { // Multiple indicators = specific scene
          sceneCount++;
        }
      }
    }

    return sceneCount;
  }

  /**
   * Identify recurring patterns across messages
   */
  private identifyPatterns(userMessages: MessageDTO[]): number {
    const allText = userMessages.map(m => m.text.toLowerCase()).join(' ');
    
    // Look for recurring themes
    const themePatterns = [
      { pattern: /\b(build|building|built|create|creating|made)\b/g, theme: 'creating' },
      { pattern: /\b(control|organize|order|structure|system)\b/g, theme: 'control' },
      { pattern: /\b(help|helping|guide|teach|mentor|coach)\b/g, theme: 'helping' },
      { pattern: /\b(alone|solo|independent|myself|by myself)\b/g, theme: 'autonomy' },
      { pattern: /\b(together|team|collaborate|group|we)\b/g, theme: 'collaboration' },
      { pattern: /\b(fix|solve|problem|figure out|solution)\b/g, theme: 'problem-solving' },
      { pattern: /\b(beauty|beautiful|elegant|aesthetic|design)\b/g, theme: 'beauty' },
      { pattern: /\b(understand|learn|discover|explore|curious)\b/g, theme: 'learning' },
    ];

    let patternsFound = 0;
    for (const { pattern, theme } of themePatterns) {
      const matches = allText.match(pattern);
      if (matches && matches.length >= 3) { // Theme appears 3+ times
        patternsFound++;
      }
    }

    return patternsFound;
  }

  /**
   * Detect emotional breakthrough (vulnerability, real emotion shared)
   */
  private detectEmotionalBreakthrough(userMessages: MessageDTO[]): boolean {
    const breakthroughIndicators = [
      /\b(cried|cry|tears|wept)\b/i,
      /\b(scared|afraid|terrified|fear|frightened)\b/i,
      /\b(ashamed|embarrassed|humiliated|vulnerable)\b/i,
      /\b(lonely|alone|isolated|disconnected|lost)\b/i,
      /\b(angry|furious|rage|frustrated|hurt)\b/i,
      /\b(realized|understood|saw clearly|it hit me|I get it now)\b/i,
      /\b(truth is|honestly|if I'm being real|I've never told anyone)\b/i,
    ];

    // Need at least 2 breakthrough moments
    let breakthroughCount = 0;
    for (const msg of userMessages) {
      if (msg.text.length > 80) { // Substantial response
        const hasBreakthrough = breakthroughIndicators.some(pattern => pattern.test(msg.text));
        if (hasBreakthrough) {
          breakthroughCount++;
        }
      }
    }

    return breakthroughCount >= 2;
  }

  /**
   * Calculate AI confidence: How well do we understand the user?
   */
  private calculateAIConfidence(userMessages: MessageDTO[], chapterNumber: number): number {
    if (userMessages.length < 10) return 0; // Not enough data

    const scores = {
      specificity: this.scoreSpecificity(userMessages),
      authenticity: this.scoreAuthenticity(userMessages),
      patternClarity: this.scorePatternClarity(userMessages),
      emotionalDepth: this.scoreEmotionalDepth(userMessages),
      intrinsicMotivation: this.scoreIntrinsicMotivation(userMessages),
      processLove: this.scoreProcessLove(userMessages),
      uniqueness: this.scoreUniqueness(userMessages),
    };

    // Average of all scores
    const values = Object.values(scores);
    const average = values.reduce((sum, val) => sum + val, 0) / values.length;

    return parseFloat(average.toFixed(1));
  }

  /**
   * Score specificity (concrete vs abstract)
   */
  private scoreSpecificity(userMessages: MessageDTO[]): number {
    const concreteCount = userMessages.filter(m => {
      return /\b(I did|I made|I built|I saw|I felt|specific|exactly|precisely)\b/i.test(m.text) &&
             m.text.length > 50;
    }).length;

    const abstractCount = userMessages.filter(m => {
      return /\b(generally|usually|often|sometimes|kind of|sort of|I guess|maybe)\b/i.test(m.text);
    }).length;

    if (userMessages.length === 0) return 0;
    
    const ratio = concreteCount / (concreteCount + abstractCount + 1);
    return parseFloat((ratio * 10).toFixed(1));
  }

  /**
   * Score authenticity (real vs performed)
   */
  private scoreAuthenticity(userMessages: MessageDTO[]): number {
    const borrowedDreams = this.countBorrowedDreams(userMessages);
    const sociallyDesirable = this.countSocialDesirability(userMessages);
    
    if (userMessages.length === 0) return 10;
    
    const problematicRatio = (borrowedDreams + sociallyDesirable) / userMessages.length;
    return parseFloat((10 - (problematicRatio * 10)).toFixed(1));
  }

  /**
   * Score pattern clarity
   */
  private scorePatternClarity(userMessages: MessageDTO[]): number {
    const patternsFound = this.identifyPatterns(userMessages);
    return Math.min(10, patternsFound * 2.5); // 4 patterns = 10/10
  }

  /**
   * Score emotional depth
   */
  private scoreEmotionalDepth(userMessages: MessageDTO[]): number {
    const emotionalMarkers = this.countEmotionalMarkers(userMessages);
    return Math.min(10, emotionalMarkers * 1.5); // 7 markers = 10/10
  }

  /**
   * Score intrinsic motivation (do they love the work vs the outcome?)
   */
  private scoreIntrinsicMotivation(userMessages: MessageDTO[]): number {
    const allText = userMessages.map(m => m.text.toLowerCase()).join(' ');
    
    const processWords = ['love', 'enjoy', 'fun', 'engaging', 'absorbing', 'flow', 'lost track of time'];
    const outcomeWords = ['successful', 'famous', 'rich', 'bestselling', 'recognized', 'achieve', 'win'];
    
    const processCount = processWords.filter(w => allText.includes(w)).length;
    const outcomeCount = outcomeWords.filter(w => allText.includes(w)).length;
    
    if (processCount + outcomeCount === 0) return 5;
    
    const ratio = processCount / (processCount + outcomeCount);
    return parseFloat((ratio * 10).toFixed(1));
  }

  /**
   * Score process love (do they love the work itself?)
   */
  private scoreProcessLove(userMessages: MessageDTO[]): number {
    return this.scoreIntrinsicMotivation(userMessages); // Same metric
  }

  /**
   * Score uniqueness (generic vs genuinely theirs)
   */
  private scoreUniqueness(userMessages: MessageDTO[]): number {
    const genericPhrases = [
      'make a difference',
      'help people',
      'change the world',
      'be successful',
      'follow my passion',
      'find my purpose',
      'make an impact',
    ];

    const allText = userMessages.map(m => m.text.toLowerCase()).join(' ');
    const genericCount = genericPhrases.filter(phrase => allText.includes(phrase)).length;

    if (userMessages.length === 0) return 10;
    
    const genericRatio = genericCount / userMessages.length;
    return parseFloat((10 - (genericRatio * 20)).toFixed(1)); // Heavy penalty for generic
  }

  /**
   * Count emotional markers
   */
  private countEmotionalMarkers(userMessages: MessageDTO[]): number {
    const markers = [
      'cried', 'scared', 'afraid', 'alive', 'free', 'powerful', 'proud',
      'ashamed', 'embarrassed', 'loved', 'angry', 'frustrated', 'lonely', 'joy',
    ];

    let count = 0;
    for (const msg of userMessages) {
      const lowerText = msg.text.toLowerCase();
      count += markers.filter(marker => lowerText.includes(marker)).length;
    }

    return count;
  }

  /**
   * Calculate vague response ratio
   */
  private calculateVagueRatio(userMessages: MessageDTO[]): number {
    if (userMessages.length === 0) return 1.0;

    const vagueCount = userMessages.filter(msg => {
      const text = msg.text.toLowerCase();
      const vagueWords = ['stuff', 'things', 'something', 'kinda', 'sorta', 'I guess', 'maybe'];
      return vagueWords.some(word => text.includes(word)) || msg.text.length < 50;
    }).length;

    return vagueCount / userMessages.length;
  }

  /**
   * Detect contradictions
   */
  private detectContradictions(userMessages: MessageDTO[]): number {
    // Simplified - would need more sophisticated NLP
    return 0;
  }

  /**
   * Count category responses (vs specific)
   */
  private countCategoryResponses(userMessages: MessageDTO[]): number {
    const categoryPhrases = [
      'help people', 'be creative', 'make a difference', 'family time',
      'being social', 'having fun', 'spending time with',
    ];

    let count = 0;
    for (const msg of userMessages) {
      const lowerText = msg.text.toLowerCase();
      if (categoryPhrases.some(phrase => lowerText.includes(phrase))) {
        count++;
      }
    }

    return count;
  }

  /**
   * Count borrowed dreams
   */
  private countBorrowedDreams(userMessages: MessageDTO[]): number {
    const borrowedPhrases = [
      'successful', 'entrepreneur', 'change the world', 'make an impact',
      'be the best', 'achieve greatness', 'reach my potential',
    ];

    let count = 0;
    for (const msg of userMessages) {
      const lowerText = msg.text.toLowerCase();
      if (borrowedPhrases.some(phrase => lowerText.includes(phrase))) {
        count++;
      }
    }

    return count;
  }

  /**
   * Count social desirability bias
   */
  private countSocialDesirability(userMessages: MessageDTO[]): number {
    const socialPhrases = [
      'help children', 'save the environment', 'serve the community',
      'give back', 'make the world better', 'help those in need',
    ];

    let count = 0;
    for (const msg of userMessages) {
      const lowerText = msg.text.toLowerCase();
      if (socialPhrases.some(phrase => lowerText.includes(phrase))) {
        count++;
      }
    }

    return count;
  }

  /**
   * Determine what to focus on next
   */
  private determineNextFocus(metrics: DepthMetrics, missingElements: string[]): string {
    if (metrics.specificScenesCollected < 5) {
      return 'Need more specific scenes with sensory details. Push for: "What did your hands touch? What did you see?"';
    }

    if (metrics.clearPatternsIdentified < 3) {
      return 'Don\'t see clear patterns yet. Ask: "What\'s the SAME in all these stories?"';
    }

    if (!metrics.emotionalBreakthroughReached) {
      return 'Need emotional depth. Push for vulnerability. Ask about embarrassment, fear, or what they\'ve never said out loud.';
    }

    if (metrics.aiConfidenceScore < 9.0) {
      return 'Still unclear on the underlying PULL. Keep excavating: "What were you REALLY doing?"';
    }

    return 'Continue deepening. We\'re close but not there yet.';
  }

  /**
   * Should we send user away to reflect?
   */
  private shouldSendUserAway(metrics: DepthMetrics, sessionNumber: number): boolean {
    // Send away if:
    // - Session is long (50+ exchanges) and still low confidence
    // - User seems stuck/repeating
    // - High vague ratio after many exchanges
    
    if (metrics.exchangeCount > 50 && metrics.aiConfidenceScore < 6) {
      return true; // Stuck - need time to reflect
    }

    if (metrics.vagueResponseRatio > 0.5 && metrics.exchangeCount > 30) {
      return true; // Too vague - need space
    }

    return false;
  }

  /**
   * Generate reflection prompt for between sessions
   */
  private generateReflectionPrompt(chapterNumber: number, userMessages: MessageDTO[]): string {
    const prompts = [
      'Carry this question with you for a few days: "What was I REALLY doing in those moments?" Don\'t force an answer. Let it surface.',
      'For the next week, notice when you lose track of time. Write down what you were doing. We\'ll explore those moments next session.',
      'Think about this: If you could only do ONE thing for the next 10 years, and no one would ever know or care, what would it be?',
      'Journal on this: What did you love as a child that you stopped doing because someone said it wasn\'t practical?',
      'Reflect: Who makes you irrationally jealous? Not their success—their daily life. What are they doing that you\'re not letting yourself do?',
    ];

    return prompts[chapterNumber % prompts.length];
  }
}

export const depthValidator = new DepthValidatorService();
