import { PhaseId } from '../dto/engine.dto';

interface PhaseConfig {
  title: string;
  goal: string;
  exitCriteria: (profile: any, scenes: any[]) => boolean;
  chapterPrompt: string;
}

export const PHASES: Record<PhaseId, PhaseConfig> = {
  call: {
    title: 'Chapter I — The Call',
    goal: 'Excavate childhood pull, first peak experience scene',
    exitCriteria: (p, s) => s.some(sc => sc.text && sc.text.length > 200),
    chapterPrompt: 'Write Chapter I: The Call. TTS-friendly markdown, 350-600 words. Focus on the childhood moment when purpose first whispered.'
  },
  conflict: {
    title: 'Chapter II — The Conflict',
    goal: 'False paths, persona pressure, anti-regret lens',
    exitCriteria: (p) => p.redTags && p.redTags.length > 0,
    chapterPrompt: 'Write Chapter II: The Conflict. 350-600 words. Explore false paths taken, societal pressures, what they fear regretting.'
  },
  mirror: {
    title: 'Chapter III — The Mirror',
    goal: 'Shadow work, envy map, embarrassment test',
    exitCriteria: (p) => p.strengths && p.strengths.length >= 2,
    chapterPrompt: 'Write Chapter III: The Mirror. 350-600 words. Shadow work, envy as compass, embarrassment test reveals truth.'
  },
  mentor: {
    title: 'Chapter IV — The Mentor',
    goal: 'Internal mentor dialogue, wisdom distilled',
    exitCriteria: (p, s) => s.length >= 4,
    chapterPrompt: 'Write Chapter IV: The Mentor. 350-600 words. Internal mentor emerges, wisdom distilled from pain.'
  },
  task: {
    title: 'Chapter V — The Task',
    goal: 'One-sentence Life Task + keystones',
    exitCriteria: (p) => !!p.lifeTask && p.keystones && p.keystones.length > 0,
    chapterPrompt: 'Write Chapter V: The Task. 350-600 words. The one-sentence life task crystallizes. Keystones identified.'
  },
  path: {
    title: 'Chapter VI — The Path',
    goal: 'Odyssey micro-experiments, boring Tuesday schedule',
    exitCriteria: (p) => !!p.odysseyPlans,
    chapterPrompt: 'Write Chapter VI: The Path. 350-600 words. Odyssey plans sketched, boring Tuesday schedule, next 90 days.'
  },
  promise: {
    title: 'Chapter VII — The Promise',
    goal: 'Commitment scene, small verifiable stakes',
    exitCriteria: (p, s) => s.some(sc => sc.text && (sc.text.includes('commit') || sc.text.includes('promise'))),
    chapterPrompt: 'Write Chapter VII: The Promise. 350-600 words. The commitment moment. Small, verifiable stakes. No turning back.'
  },
  review: {
    title: 'Chapter VIII — The Review',
    goal: 'Reflection on journey, what changed',
    exitCriteria: () => true,
    chapterPrompt: 'Write Chapter VIII: The Review. 350-600 words. Reflection on the journey, what shifted, ongoing commitment.'
  }
};

export class PhasesService {
  shouldGenerateChapter(phase: PhaseId, profile: any, scenes: any[]): boolean {
    return PHASES[phase].exitCriteria(profile, scenes);
  }

  getPhaseTitle(phase: PhaseId): string {
    return PHASES[phase].title;
  }

  getChapterPrompt(phase: PhaseId): string {
    return PHASES[phase].chapterPrompt;
  }
}

