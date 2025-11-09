export type PhaseId = 'call' | 'conflict' | 'mirror' | 'mentor' | 'task' | 'path' | 'promise' | 'review';

export interface EngineStartDTO {
  phase: PhaseId;
  scenes?: Array<{ role: 'user' | 'coach'; text: string }>;
  idemKey?: string;
}

export interface CoachResponse {
  coach: string;
  next_prompt: string;
  artifacts?: {
    snapshot?: string;
    red_tags?: string[];
    strengths?: string[];
    values_rank?: string[];
    sdt?: { autonomy?: number; competence?: number; relatedness?: number };
    flow_contexts?: string[];
  };
  shouldGenerateChapter?: boolean;
}

export interface ChapterDTO {
  phase: PhaseId;
  title?: string;
  body?: string;
}

export interface BookCompileDTO {
  includePhases?: PhaseId[];
  title?: string;
  idemKey?: string;
}

