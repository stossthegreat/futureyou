import { FastifyInstance } from 'fastify';
import { conversationController } from './controllers/conversation.controller';
import { chaptersController } from './controllers/chapters.controller';
import { artifactsController } from './controllers/artifacts.controller';
import { bookController } from './controllers/book.controller';

/**
 * LIFE'S TASK ROUTER
 * Main router for the Life's Task Discovery Engine
 * 
 * Routes:
 * - POST /api/lifetask/converse - Generate coach response
 * - POST /api/lifetask/save-chapter - Save completed chapter
 * - GET /api/lifetask/chapters - Get all chapters
 * - GET /api/lifetask/chapters/:chapterNumber - Get specific chapter
 * - GET /api/lifetask/progress - Get progress summary
 * - GET /api/lifetask/artifacts - Get all artifacts
 * - GET /api/lifetask/artifacts/:artifactType - Get specific artifact
 * - POST /api/lifetask/book/compile - Compile book
 * - GET /api/lifetask/book/latest - Get latest book
 * - GET /api/lifetask/book/:bookId - Get specific book
 */

export async function lifeTaskRouter(fastify: FastifyInstance) {
  fastify.register(async (instance) => {
    // Register all controllers under /api/lifetask
    await instance.register(conversationController, { prefix: '/api/lifetask' });
    await instance.register(chaptersController, { prefix: '/api/lifetask' });
    await instance.register(artifactsController, { prefix: '/api/lifetask' });
    await instance.register(bookController, { prefix: '/api/lifetask' });

    console.log('✅ Life\'s Task Discovery Engine routes registered');
  });
}

