// DTOs for chapter and artifact operations

export interface GenerateProseRequestDTO {
  chapterNumber: number;
  conversationTranscript: string; // Formatted transcript
  extractedPatterns: Record<string, any>;
}

export interface GenerateProseResponseDTO {
  proseText: string;
  wordCount: number;
}

export interface GetArtifactsResponseDTO {
  artifacts: Array<{
    artifactType: string;
    data: Record<string, any>;
    updatedAt: string;
  }>;
}

export interface CompileBookRequestDTO {
  title?: string;
}

export interface CompileBookResponseDTO {
  bookId: string;
  title: string;
  compiledMarkdown: string;
  chapterCount: number;
  wordCount: number;
  version: number;
}

export interface GetProgressResponseDTO {
  chaptersCompleted: number[];
  totalChapters: number;
  artifactsGenerated: string[];
  bookCompiled: boolean;
  totalTimeSpent: number; // minutes
}

