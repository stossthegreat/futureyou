import { FastifyInstance } from 'fastify';
import { prisma } from '../utils/db';

export async function userController(fastify: FastifyInstance) {
  /**
   * 🆕 Create or get user (auto-creation for mobile app)
   */
  fastify.post('/api/v1/users', async (req: any, reply) => {
    try {
      const userId = req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(400).send({ error: 'x-user-id header required' });
      }

      // Check if user exists
      let user = await prisma.user.findUnique({ 
        where: { id: userId } 
      });

      if (user) {
        return { user, created: false };
      }

      // Create new user with defaults
      user = await prisma.user.create({
        data: {
          id: userId,
          email: `${userId}@futureyou.app`,
          tz: 'Europe/London',
          tone: 'balanced',
          intensity: 2,
          mentorId: 'marcus',
          nudgesEnabled: true,
          briefsEnabled: true,
          debriefsEnabled: true,
        },
      });

      console.log(`✅ Created new user: ${userId}`);
      return { user, created: true };
    } catch (err: any) {
      const code = err.statusCode || 500;
      console.error(`❌ User creation error:`, err);
      return reply.code(code).send({ error: err.message });
    }
  });

  /**
   * 👤 Get user profile
   */
  fastify.get('/api/v1/users/:userId', async (req: any, reply) => {
    try {
      const { userId } = req.params;
      
      const user = await prisma.user.findUnique({ 
        where: { id: userId } 
      });

      if (!user) {
        return reply.code(404).send({ error: 'User not found' });
      }

      return { user };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });

  /**
   * 📝 Update user profile
   */
  fastify.put('/api/v1/users/:userId', async (req: any, reply) => {
    try {
      const { userId } = req.params;
      const updates = req.body as Partial<{
        email: string;
        tz: string;
        tone: 'strict' | 'balanced' | 'light';
        intensity: number;
        mentorId: string;
        nudgesEnabled: boolean;
        briefsEnabled: boolean;
        debriefsEnabled: boolean;
      }>;

      const user = await prisma.user.update({
        where: { id: userId },
        data: updates,
      });

      return { user };
    } catch (err: any) {
      const code = err.statusCode || 500;
      return reply.code(code).send({ error: err.message });
    }
  });
}

