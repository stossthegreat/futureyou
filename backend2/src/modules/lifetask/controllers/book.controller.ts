import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { CompileBookRequestDTO, CompileBookResponseDTO } from '../dto/chapter.dto';
import { chaptersRepo } from '../repo/chapters.repo';
import { booksRepo } from '../repo/books.repo';
import { getChapterConfig } from '../services/chapter-config';

/**
 * BOOK CONTROLLER
 * Handles book compilation from completed chapters
 */

export async function bookController(fastify: FastifyInstance) {
  
  /**
   * POST /api/lifetask/book/compile
   * Compile all completed chapters into a book
   */
  fastify.post<{ Body: CompileBookRequestDTO }>(
    '/book/compile',
    async (req: FastifyRequest<{ Body: CompileBookRequestDTO }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { title } = req.body;
      const bookTitle = title || 'Your Life\'s Task: A Journey of Discovery';

      console.log(`[BookController] Compiling book for user ${userId}`);

      try {
        // Get all completed chapters
        const chapters = await chaptersRepo.getCompletedChapters(userId);

        if (chapters.length === 0) {
          return reply.code(400).send({ error: 'No completed chapters found' });
        }

        console.log(`[BookController] Found ${chapters.length} completed chapters`);

        // Build markdown
        let compiledMarkdown = `# ${bookTitle}\n\n`;
        compiledMarkdown += `*A seven-chapter journey through purpose discovery*\n\n`;
        compiledMarkdown += `---\n\n`;
        compiledMarkdown += `## Table of Contents\n\n`;

        // Table of contents
        for (const chapter of chapters) {
          const config = getChapterConfig(chapter.chapterNumber);
          compiledMarkdown += `${chapter.chapterNumber}. ${config.title}\n`;
        }

        compiledMarkdown += `\n---\n\n`;

        // Chapters
        for (const chapter of chapters) {
          const config = getChapterConfig(chapter.chapterNumber);
          
          compiledMarkdown += `## ${config.title}\n\n`;
          compiledMarkdown += `${chapter.proseText}\n\n`;
          compiledMarkdown += `*Time spent: ${chapter.timeSpentMinutes} minutes*\n\n`;
          compiledMarkdown += `---\n\n`;
        }

        // Epilogue
        compiledMarkdown += `## Epilogue\n\n`;
        compiledMarkdown += `You've completed the seven-chapter journey. You've excavated your childhood call, confronted your shadows, mapped your strengths and flow states, prototyped futures, crystallized your life's task, defined your path, and made your promise.\n\n`;
        compiledMarkdown += `This book is not the end. It's the beginning. Your life's task is not something you find once and forget. It's something you live, refine, and deepen every day.\n\n`;
        compiledMarkdown += `The monthly reviews will keep you honest. The keystone habits will keep you moving. The anti-habits will protect your focus. And the community you build will sustain you when the path gets hard.\n\n`;
        compiledMarkdown += `Future-You is waiting. Not in some distant tomorrow, but in the small decisions you make today. In the courage to say no to what doesn't serve your task. In the discipline to show up even when motivation fades. In the humility to keep learning, keep growing, keep becoming.\n\n`;
        compiledMarkdown += `You have your sentence now. You have your path. The only question left is: will you walk it?\n\n`;
        compiledMarkdown += `*The answer is already forming in your next decision.*\n\n`;
        compiledMarkdown += `---\n\n`;
        compiledMarkdown += `*Book compiled: ${new Date().toISOString()}*\n`;
        compiledMarkdown += `*Total time invested: ${chapters.reduce((sum, ch) => sum + ch.timeSpentMinutes, 0)} minutes*\n`;

        // Save book
        const chapterIds = chapters.map(ch => ch.id);
        const book = await booksRepo.createBook(userId, bookTitle, compiledMarkdown, chapterIds);

        console.log(`[BookController] Book compiled: ${book.id}`);

        // Count words
        const wordCount = compiledMarkdown.split(/\s+/).length;

        const response: CompileBookResponseDTO = {
          bookId: book.id,
          title: bookTitle,
          compiledMarkdown,
          chapterCount: chapters.length,
          wordCount,
          version: book.version,
        };

        return response;
      } catch (error: any) {
        console.error('[BookController] Error compiling book:', error);
        return reply.code(500).send({ error: error.message || 'Book compilation failed' });
      }
    }
  );

  /**
   * GET /api/lifetask/book/latest
   * Get the latest compiled book
   */
  fastify.get(
    '/book/latest',
    async (req: FastifyRequest, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      try {
        const book = await booksRepo.getLatestBook(userId);
        
        if (!book) {
          return reply.code(404).send({ error: 'No book found' });
        }

        const wordCount = book.compiledMarkdown.split(/\s+/).length;

        return {
          book: {
            id: book.id,
            title: book.title,
            compiledMarkdown: book.compiledMarkdown,
            chapterCount: book.chapterIds.length,
            wordCount,
            version: book.version,
            createdAt: book.createdAt.toISOString(),
          },
        };
      } catch (error: any) {
        console.error('[BookController] Error fetching book:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch book' });
      }
    }
  );

  /**
   * GET /api/lifetask/book/:bookId
   * Get specific book by ID
   */
  fastify.get<{ Params: { bookId: string } }>(
    '/book/:bookId',
    async (req: FastifyRequest<{ Params: { bookId: string } }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { bookId } = req.params;

      try {
        const book = await booksRepo.getBookById(bookId);
        
        if (!book || book.userId !== userId) {
          return reply.code(404).send({ error: 'Book not found' });
        }

        const wordCount = book.compiledMarkdown.split(/\s+/).length;

        return {
          book: {
            id: book.id,
            title: book.title,
            compiledMarkdown: book.compiledMarkdown,
            chapterCount: book.chapterIds.length,
            wordCount,
            version: book.version,
            createdAt: book.createdAt.toISOString(),
          },
        };
      } catch (error: any) {
        console.error('[BookController] Error fetching book:', error);
        return reply.code(500).send({ error: error.message || 'Failed to fetch book' });
      }
    }
  );
}

