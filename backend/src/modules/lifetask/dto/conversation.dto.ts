// DTOs for Life's Task conversation system

export interface MessageDTO {
  role: 'user' | 'coach';
  text: string;
  timestamp?: string;
}

export interface ConverseRequestDTO {
  chapterNumber: number; // 1-7
  messages: MessageDTO[]; // Full conversation history
  sessionStartTime?: string; // ISO timestamp
}

export interface ConverseResponseDTO {
  coachMessage: string;
  shouldContinue: boolean; // false = chapter complete
  depthMetrics?: {
    exchangeCount: number;
    timeElapsedMinutes: number;
    specificScenesCollected: number;
    emotionalMarkersDetected: number;
    vagueResponseRatio: number;
    minimumExchangesMet: boolean;
    minimumTimeMet: boolean;
    qualityChecksPassed: boolean;
  };
  extractedPatterns?: {
    redThreads?: string[];
    values?: string[];
    strengths?: string[];
    flowContexts?: string[];
    emotionalMarkers?: string[];
  };
  nextPromptHint?: string; // Internal guidance for next AI turn
}

export interface SaveChapterRequestDTO {
  chapterNumber: number;
  messages: MessageDTO[];
  timeSpentMinutes: number;
  sessionStartTime: string;
}

export interface SaveChapterResponseDTO {
  chapterId: string;
  proseGenerated: boolean;
  proseText?: string;
  artifactsUpdated: string[]; // List of artifact types updated
}

