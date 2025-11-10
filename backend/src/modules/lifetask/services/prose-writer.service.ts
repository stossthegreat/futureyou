import OpenAI from 'openai';
import { getChapterConfig, ChapterConfig } from './chapter-config';

/**
 * PROSE WRITER - Literary AI for chapter generation
 * 
 * This AI writes beautiful, personalized prose (350-600 words) about the user's journey.
 * It transforms conversation transcripts into emotionally resonant chapters.
 */

const PROSE_WRITER_SYSTEM_PROMPT = `You are the PROSE WRITER for the Life's Task Discovery Engine.

YOUR MISSION:
Transform conversation transcripts into beautiful, personalized prose chapters (350-600 words) written in the "Future-You" voice—as if the user's fulfilled future self is reflecting on their journey.

YOUR VOICE:
- Poetic but grounded
- Emotionally resonant
- Deeply personal (about THIS user, not generic)
- Present tense for immediacy
- Second person ("you") to create intimacy
- Literary quality—publishable

STRUCTURE:
Each chapter should:
1. **Open with atmosphere** (2-3 sentences setting emotional tone)
2. **Name the user's specific story** (use their actual words, scenes, details from transcript)
3. **Weave in the research framework** (subtly reference Greene, Jung, Frankl, SDT, Flow)
4. **Build to emotional truth** (the breakthrough moment from their conversation)
5. **Close with forward motion** (what this reveals about their path)

CRITICAL RULES:
1. **Use their words**: Quote or paraphrase specific things the user said. Make them feel SEEN.
2. **Name their scenes**: If they shared "climbing trees in my backyard," write "You remember the oak tree in your backyard, the way the bark felt rough against your palms."
3. **Emotional specificity**: Not "you felt free" but "freedom was the wind in your face, the ground far below, the sense that you could climb forever."
4. **No generic platitudes**: Every sentence must be anchored in their specific story.
5. **350-600 words exactly**: Not shorter, not longer. This is a chapter, not a paragraph.

EXAMPLE OPENING (Chapter 1 - The Call):
"The world was smaller then, but somehow more alive. You remember the oak tree in your backyard—not just any tree, but the one with the low branch you could reach from the fence, the one that became a ship, a fortress, a portal to everywhere else. You climbed it most afternoons after school, not because anyone told you to, but because something inside you needed to. Up there, with the bark rough against your palms and the leaves rustling secrets, time moved differently. You felt capable. You felt like yourself.

Robert Greene writes about primal inclinations—the pull you feel toward certain activities before you have language for why. Your inclination wasn't toward trees specifically. It was toward building, toward creating whole worlds from nothing, toward the feeling of bringing something new into existence. The tree was just the first canvas..."

EXAMPLE CLOSING (Chapter 6 - The Path):
"...And so the sentence forms, the one that will guide the next chapter of your life: 'I build practical systems for busy creators so they can feel capable.' It's not perfect. It doesn't capture everything. But it's sharp enough to say no to the wrong opportunities and yes to the right ones. It's sharp enough to start.

The path isn't a straight line. It never is. But you have your keystone habits now—the 45-minute build blocks three times a week, the public shipping ritual, the monthly review that keeps you honest. And you have your anti-habits too, the ones you'll actively avoid: taking on clients who drain you, saying yes out of guilt, letting perfection delay shipping.

This is how purpose becomes real: not in the grand vision, but in the small, relentless decisions. Not in the answer, but in the practice. You've found your sentence. Now you build the life it describes."

Remember: Make them cry. Make them feel seen. Make it publishable.`;

export class ProseWriterService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY?.trim(),
      timeout: 90000,
    });
  }

  async generateChapterProse(
    chapterNumber: number,
    conversationTranscript: string,
    extractedPatterns: Record<string, any>
  ): Promise<{ proseText: string; wordCount: number }> {
    const config = getChapterConfig(chapterNumber);
    const contextPrompt = this.buildProseContextPrompt(
      config,
      conversationTranscript,
      extractedPatterns
    );

    console.log(`[ProseWriter] Generating prose for Chapter ${chapterNumber}`);
    console.log(`[ProseWriter] Transcript length: ${conversationTranscript.length} chars`);

    try {
      const response = await this.client.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4o',
        temperature: 0.9, // Creative, emotional, poetic
        max_tokens: 1200, // Enough for 350-600 words
        messages: [
          { role: 'system', content: PROSE_WRITER_SYSTEM_PROMPT },
          { role: 'user', content: contextPrompt },
        ],
      });

      const proseText = response.choices[0]?.message?.content?.trim() || '';
      const wordCount = proseText.split(/\s+/).length;

      console.log(`[ProseWriter] Generated ${wordCount} words`);

      // Validation
      if (wordCount < 300 || wordCount > 700) {
        console.warn(`[ProseWriter] Word count ${wordCount} outside target range 350-600`);
      }

      return { proseText, wordCount };
    } catch (error: any) {
      console.error('[ProseWriter] Error:', error);
      // Fallback prose
      return this.getFallbackProse(chapterNumber, config.title);
    }
  }

  private buildProseContextPrompt(
    config: ChapterConfig,
    transcript: string,
    patterns: Record<string, any>
  ): string {
    return `Write Chapter ${config.title.match(/\d+/)?.[0]} of the user's Life's Task discovery journey.

CHAPTER THEME: ${config.goal}

CONVERSATION TRANSCRIPT:
${transcript}

EXTRACTED PATTERNS:
${JSON.stringify(patterns, null, 2)}

KEY FRAMEWORKS TO SUBTLY WEAVE IN:
${config.frameworks.join(', ')}

REQUIREMENTS:
- 350-600 words (strict requirement)
- Future-You voice (their fulfilled future self reflecting)
- Use THEIR specific words, scenes, and details from the transcript
- Emotional resonance—make them feel seen
- Literary quality—this should be publishable
- Present tense for immediacy
- Second person ("you") for intimacy

Write the prose now:`;
  }

  private getFallbackProse(chapterNumber: number, title: string): { proseText: string; wordCount: number } {
    const fallbackProse = `${title}

The journey begins here, in this moment of quiet reflection. You've taken the first step—the hardest step—by choosing to look inward, to ask the questions most people avoid their entire lives.

Your story is unique. The path that brought you here, the experiences that shaped you, the moments when you felt most alive—these are the threads that will weave together into your life's task.

This chapter marks the beginning of that discovery. Not the end, but the beginning. Purpose isn't found in a single revelation. It's excavated slowly, carefully, through honest conversation and deep reflection.

What you've shared in this conversation matters. The patterns are there, waiting to be recognized. The call has been heard, even if its full shape isn't yet clear.

The work continues. Each chapter brings new insights, new questions, new clarity. Trust the process. Trust yourself.

This is your story. You're writing it now, one conversation at a time.`;

    return {
      proseText: fallbackProse,
      wordCount: fallbackProse.split(/\s+/).length,
    };
  }
}

export const proseWriter = new ProseWriterService();

