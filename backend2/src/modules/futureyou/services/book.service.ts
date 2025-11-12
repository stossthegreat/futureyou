import { chaptersRepo } from '../repo/chapters.repo';
import { bookRepo } from '../repo/book.repo';
import { PhaseId } from '../dto/engine.dto';

const PHASE_ORDER: PhaseId[] = ['call', 'conflict', 'mirror', 'mentor', 'task', 'path', 'promise'];

export class BookService {
  async compile(userId: string, includePhases?: PhaseId[], customTitle?: string): Promise<any> {
    const phases = includePhases || PHASE_ORDER;
    
    // Fetch chapters in order
    const chapters = await Promise.all(
      phases.map(phase => chaptersRepo.getByPhase(userId, phase))
    );

    // Filter out nulls
    const validChapters = chapters.filter(c => c !== null);
    
    if (validChapters.length === 0) {
      throw new Error('No chapters found to compile');
    }

    // Build markdown
    const title = customTitle || 'Your Future-You Story';
    const chapterIds = validChapters.map(c => c.id);
    
    let bodyMd = `# ${title}\n\n`;
    bodyMd += `*A journey through purpose discovery*\n\n`;
    bodyMd += `---\n\n`;

    for (const chapter of validChapters) {
      bodyMd += `${chapter.bodyMd}\n\n`;
      bodyMd += `---\n\n`;
    }

    bodyMd += `\n\n*The End*\n\n`;
    bodyMd += `Generated: ${new Date().toISOString()}\n`;

    // Check if identical to latest
    const isIdentical = await bookRepo.isIdentical(userId, chapterIds, bodyMd);
    if (isIdentical) {
      const latest = await bookRepo.getLatest(userId);
      return { ...latest, skipped: true, reason: 'identical' };
    }

    // Create new edition
    const edition = await bookRepo.create(userId, title, bodyMd, chapterIds);
    
    // Cleanup old editions
    await bookRepo.cleanup(userId);

    return edition;
  }

  async getLatest(userId: string): Promise<any | null> {
    return await bookRepo.getLatest(userId);
  }
}

export const bookService = new BookService();

