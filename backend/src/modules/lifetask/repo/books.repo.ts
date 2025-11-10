import { prisma } from '../../../utils/db';

export class BooksRepository {
  async createBook(
    userId: string,
    title: string,
    compiledMarkdown: string,
    chapterIds: string[]
  ) {
    // Get the next version number
    const latestBook = await prisma.lifeTaskBook.findFirst({
      where: { userId },
      orderBy: { version: 'desc' },
    });

    const version = latestBook ? latestBook.version + 1 : 1;

    return await prisma.lifeTaskBook.create({
      data: {
        userId,
        title,
        compiledMarkdown,
        chapterIds,
        version,
      },
    });
  }

  async getLatestBook(userId: string) {
    return await prisma.lifeTaskBook.findFirst({
      where: { userId },
      orderBy: { version: 'desc' },
    });
  }

  async getAllBooks(userId: string) {
    return await prisma.lifeTaskBook.findMany({
      where: { userId },
      orderBy: { version: 'desc' },
    });
  }

  async getBookById(bookId: string) {
    return await prisma.lifeTaskBook.findUnique({
      where: { id: bookId },
    });
  }

  async deleteBook(bookId: string) {
    return await prisma.lifeTaskBook.delete({
      where: { id: bookId },
    });
  }
}

export const booksRepo = new BooksRepository();

