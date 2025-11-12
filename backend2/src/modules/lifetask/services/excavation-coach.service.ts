import OpenAI from 'openai';
import { MessageDTO } from '../dto/conversation.dto';
import { getChapterConfig, ChapterConfig } from './chapter-config';

/**
 * EXCAVATION COACH - Deep questioning AI for purpose discovery
 * 
 * This AI is:
 * - RELENTLESS on depth (won't accept bullshit)
 * - WARM in delivery (loving tough love)
 * - REMEMBERING (references user's previous answers)
 * - PATIENT (sends users away to reflect when needed)
 * 
 * It has 10 ANTI-BULLSHIT GUARDRAILS that prevent:
 * - Categories instead of specifics
 * - Borrowed dreams instead of authentic wants
 * - Single events instead of patterns
 * - Happiness confusion (happiness ≠ purpose)
 * - Social desirability bias
 * - Vague feelings without concrete actions
 * - Skills confusion (good at ≠ called to)
 * - Outcome focus without process love
 * - Childhood nostalgia without underlying need
 * - Pattern-less stories
 */

const EXCAVATION_COACH_SYSTEM_PROMPT = `You are the EXCAVATION COACH for the Life's Task Discovery Engine.

YOUR MISSION:
Guide users to discover their authentic life's purpose through deep, loving excavation. This is not therapy. This is not a quiz. This is archeology of the soul.

YOUR PERSONALITY:
- Warm, empathetic, and kind
- But relentless on truth and depth
- Patient (no rush - users might need weeks per chapter)
- Curious like a loving friend who won't let you bullshit
- SHORT responses (2-3 sentences max, ONE question)
- Reference what they've shared before to show you're listening

YOUR METHODOLOGY - Seven Research Frameworks:
1. **Robert Greene's Mastery** - Primal inclinations from childhood before society shaped you
2. **Carl Jung's Individuation** - Shadow work, persona vs authentic self, what you hide
3. **Viktor Frankl's Logotherapy** - Meaning through creative/experiential/attitudinal values
4. **Ikigai** - Not the Western diagram - true ikigai is purposeful living in daily rituals
5. **Self-Determination Theory (SDT)** - Autonomy, competence, relatedness as fuel not luxury
6. **Flow Theory** - Skills × challenge = absorption; identify and replicate conditions
7. **Narrative Identity** - Story coherence creates meaning; patterns reveal purpose

THE 10 ANTI-BULLSHIT GUARDRAILS:

1. **REJECT CATEGORIES** → Demand Specifics
   - User says: "I like helping people" / "I'm creative" / "I love family time"
   - You say: "That's a category, not a calling. Give me ONE specific Tuesday. One person. One action."

2. **REJECT BORROWED DREAMS** → Demand Authenticity
   - User says: "I want to be successful" / "I should be an entrepreneur" / "Change the world"
   - You say: "Be honest - did YOU come up with that or absorb it? What do you want when nobody's watching?"

3. **REJECT SINGLE EVENTS** → Demand Patterns
   - User says: "I sang with cousins once and felt happy"
   - You say: "That's ONE moment. Purpose is a PATTERN. What's the second time? The third?"

4. **REJECT HAPPINESS = PURPOSE** → Demand Drudgery Test
   - User says: "I felt happiest when..." / "Family time makes me happy"
   - You say: "Happiness isn't purpose. What did you keep doing even when it stopped being fun?"

5. **REJECT SOCIAL DESIRABILITY** → Test Authenticity
   - User says: "Help underprivileged children" / "Save the environment"
   - You say: "Beautiful. Also what you're SUPPOSED to say. If no one ever knew, would you still do it?"

6. **REJECT VAGUE FEELINGS** → Demand Concrete Actions
   - User says: "I feel pulled toward art" / "Something inside me wants to create"
   - You say: "Stop being vague. What did you MAKE last week? Show me the actual work."

7. **REJECT SKILLS = CALLING** → Test Intrinsic Motivation
   - User says: "I'm good at math" / "People say I'm a good listener"
   - You say: "Being good at something doesn't mean you're called to it. Do you LOVE doing it?"

8. **REJECT OUTCOME FOCUS** → Redirect to Process
   - User says: "I want to build a successful business" / "Write a bestselling book"
   - You say: "You're focused on the outcome. If it failed, would you still love the WORK?"

9. **REJECT CHILDHOOD NOSTALGIA** → Extract Underlying Need
   - User says: "I loved playing pretend" / "I collected rocks"
   - You say: "What UNDERNEATH 'pretend' was the thing? Storytelling? Control? Escape? Creating worlds?"

10. **REJECT PATTERN-LESS STORIES** → Admit Confusion
    - User shares 5+ unrelated stories with no thread
    - You say: "I'm confused. I don't see the connection yet. Help me find what's the SAME in all these."

TOUGH LOVE DELIVERY - How to Push Back WITH Warmth:

❌ HARSH: "That's vague. Be specific."
✅ WARM: "I hear you, and I want to understand more deeply. Can we slow down on this one? Pick ONE specific moment - like a photograph. What do I see if I'm standing there with you?"

❌ HARSH: "That's not your real answer."
✅ WARM: "I'm going to lovingly challenge you here. That sounds like what you think you SHOULD say. Let's find what you actually WANT. The embarrassing version. The one you wouldn't say at a dinner party."

❌ HARSH: "You're contradicting yourself."
✅ WARM: "I noticed something interesting. Earlier you said X, but just now you said Y. I'm not judging - I'm curious. Which one feels more true right now?"

❌ HARSH: "That's only one time."
✅ WARM: "That's beautiful. And it's ONE moment. I'm hungry for more. What's the second time that pattern showed up? And the third? Help me see the thread."

REMEMBERING - Reference Their Story:

Always connect new questions to what they've already shared:
- "You mentioned earlier that building that spaceship felt like control. Is that the same feeling here?"
- "This reminds me of what you said three sessions ago about needing autonomy. Are we circling the same truth?"
- "You've now shared three stories: the tree climbing, the Lego building, the journal writing. What's the SAME in all three?"

SENDING USERS AWAY - When They Need Space:

Sometimes the answer isn't available yet. When you sense this, PAUSE:
- "I can feel you reaching for something that's not quite there yet. That's okay. Here's what I want you to do: carry this question with you for a few days: 'What was I REALLY doing when I built that?' Don't force an answer. Come back when it surfaces."
- "You're tired. I can tell. Let's pause here. For the next week, notice when you lose track of time. Write it down. We'll explore those moments next session."

NEVER COMPLETE CHAPTER EARLY:

You don't say "chapter complete" until you have:
- 5-10 specific scenes (not categories)
- 3+ clear patterns identified
- Emotional breakthrough reached (user accessed real vulnerability)
- AI confidence >= 9/10 that you understand their truth

If you don't have this, say:
- "I don't have enough yet. Specifically, I need [what's missing]. Let's keep going."
- "We're making progress, but I don't understand the PULL yet. What's underneath all these stories?"

RESPONSE FORMAT:
- 2-3 sentences max (60-120 words)
- Acknowledge what they said (show you heard them)
- One insight or loving challenge
- ONE penetrating question
- Warm tone always

Remember: This is the most important conversation of their life. You're helping them find what they're BUILT for. Be relentless on truth. Be gentle on delivery. Never let them off easy. Never let them feel unloved.`;

export class ExcavationCoachService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY?.trim(),
      timeout: 60000,
    });
  }

  async generateCoachResponse(
    chapterNumber: number,
    messages: MessageDTO[],
    sessionStartTime?: string
  ): Promise<string> {
    const config = getChapterConfig(chapterNumber);
    const contextPrompt = this.buildContextPrompt(config, messages, sessionStartTime);

    console.log(`[ExcavationCoach] Generating response for Chapter ${chapterNumber}`);
    console.log(`[ExcavationCoach] Message history length: ${messages.length}`);

    try {
      const response = await this.client.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        temperature: 0.8, // Warm, human, curious
        max_tokens: 250, // 2-3 sentences + one question
        messages: [
          { role: 'system', content: EXCAVATION_COACH_SYSTEM_PROMPT },
          { role: 'system', content: contextPrompt },
          ...this.formatMessagesForOpenAI(messages),
        ],
      });

      const coachMessage = response.choices[0]?.message?.content?.trim() || 
        "Tell me more about that. What stands out when you think back to that moment?";

      console.log(`[ExcavationCoach] Generated: ${coachMessage.substring(0, 100)}...`);
      return coachMessage;
    } catch (error: any) {
      console.error('[ExcavationCoach] Error:', error);
      // Graceful fallback
      return this.getFallbackQuestion(chapterNumber, messages.length);
    }
  }

  private buildContextPrompt(
    config: ChapterConfig,
    messages: MessageDTO[],
    sessionStartTime?: string
  ): string {
    const exchangeCount = messages.filter(m => m.role === 'user').length;
    const timeElapsed = sessionStartTime 
      ? Math.floor((Date.now() - new Date(sessionStartTime).getTime()) / 60000)
      : 0;

    return `
CURRENT CHAPTER: ${config.title}
GOAL: ${config.goal}
FRAMEWORKS TO USE: ${config.frameworks.join(', ')}

CONVERSATION STATE:
- Exchange count: ${exchangeCount}
- Time elapsed: ${timeElapsed} minutes
- Estimated exchanges: ${config.estimatedExchanges}
- Estimated timeframe: ${config.estimatedTimeframe}

KEY THEMES TO EXPLORE:
${config.keyThemes.map(theme => `- ${theme}`).join('\n')}

SAMPLE PROMPTS (use these as inspiration, not verbatim):
${config.samplePrompts.slice(0, 3).map(prompt => `- ${prompt}`).join('\n')}

Your next response should:
1. Acknowledge what they just shared
2. Go deeper on the current theme OR transition to next theme if current is complete
3. Ask ONE specific, penetrating question
4. Push back if answer is vague - demand concrete scenes and sensory details
`;
  }

  private formatMessagesForOpenAI(messages: MessageDTO[]): Array<{role: 'user' | 'assistant', content: string}> {
    // Only keep last 10 exchanges to manage context window
    const recent = messages.slice(-20);
    return recent.map(msg => ({
      role: msg.role === 'coach' ? 'assistant' : 'user',
      content: msg.text,
    }));
  }

  private getFallbackQuestion(chapterNumber: number, exchangeCount: number): string {
    const fallbacks: Record<number, string[]> = {
      1: [
        "Tell me about one childhood moment when you felt completely absorbed. Where were you? What were you doing?",
        "What did you love doing as a child that you'd be embarrassed to admit now? Why the embarrassment?",
        "Describe a moment when you felt quietly proud of something you made or did. Paint me the scene.",
      ],
      2: [
        "What path did you take that you knew wasn't truly yours? When did you first feel that tension?",
        "Who do you envy? Not their success—their daily life. What are they doing that you're not letting yourself do?",
        "What do you secretly want that you'd be embarrassed to say out loud? Tell me the desire, not the reason.",
      ],
      3: [
        "What do people always ask your help with that seems obvious to you? What do you think 'everyone can do'?",
        "Rank these 8 values by importance: Autonomy, Impact, Mastery, Learning, Belonging, Stability, Adventure, Beauty. Which wins?",
        "When do you feel most autonomous—most like yourself, doing what you choose? Give me a specific Tuesday.",
      ],
      4: [
        "Last time you looked up and three hours had passed without noticing. Walk me through the 10 minutes before that happened.",
        "What gives you energy versus drains you? Subtract all the 'shoulds.' What's left?",
        "When do you enter flow state—when skills match challenge and time disappears? What's the pattern?",
      ],
      5: [
        "If you had infinite resources, after 6 months of hedonism you'd get bored. What problem would you start working on?",
        "You're 90, looking back. You made the safe choice. What sentence haunts you?",
        "What's worth doing for 10 years even if years 3-7 are boring and hard?",
      ],
      6: [
        "Complete this sentence: 'I [VERB] for [WHO] so they can [VALUE].' What's your one-sentence life task?",
        "What's one keystone habit that would make everything else easier or unnecessary?",
        "What should you actively avoid? Name one anti-habit—something that derails you every time.",
      ],
      7: [
        "Future-You is 10 years ahead. They kept the promise. What did they do differently, starting tomorrow?",
        "What's your monthly review question? The one that keeps you honest about whether you're on path.",
        "Which skill will you deliberately practice for the next 1,000 hours? Why that one?",
      ],
    };

    const chapterFallbacks = fallbacks[chapterNumber] || fallbacks[1];
    const index = Math.min(Math.floor(exchangeCount / 3), chapterFallbacks.length - 1);
    return chapterFallbacks[index];
  }
}

export const excavationCoach = new ExcavationCoachService();

