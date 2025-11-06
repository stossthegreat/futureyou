import { FastifyInstance } from 'fastify';
import { prisma } from '../utils/db';
import { memoryService } from '../services/memory.service';

function getUserIdOr401(req: any) {
  const uid = req?.user?.id || req.headers["x-user-id"];
  if (!uid) throw Object.assign(new Error("Unauthorized"), { statusCode: 401 });
  return uid;
}

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

  /**
   * 🆔 Store user identity (name, age, burning question)
   */
  fastify.post("/api/v1/user/identity", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      const { name, age, burningQuestion } = req.body;
      
      await memoryService.upsertFacts(userId, {
        name,
        age,
        burningQuestion,
      });
      
      return { success: true };
    } catch (err: any) {
      return reply.code(err.statusCode || 500).send({ error: err.message });
    }
  });

  /**
   * 🗑️ Delete user account and all associated data
   * WARNING: This is a destructive operation and cannot be undone
   */
  fastify.delete("/api/v1/user/account", async (req: any, reply) => {
    try {
      const userId = getUserIdOr401(req);
      
      console.log(`🗑️ Deleting account for user: ${userId}`);

      // Delete all user-related data in order (respecting foreign key constraints)
      
      // 1. Delete events
      const deletedEvents = await prisma.event.deleteMany({
        where: { userId }
      });
      console.log(`  ✅ Deleted ${deletedEvents.count} events`);

      // 2. Delete user facts
      const deletedFacts = await prisma.userFacts.deleteMany({
        where: { userId }
      });
      console.log(`  ✅ Deleted ${deletedFacts.count} user facts`);

      // 3. Delete habits
      const deletedHabits = await prisma.habit.deleteMany({
        where: { userId }
      });
      console.log(`  ✅ Deleted ${deletedHabits.count} habits`);

      // 4. Delete tasks
      const deletedTasks = await prisma.task.deleteMany({
        where: { userId }
      });
      console.log(`  ✅ Deleted ${deletedTasks.count} tasks`);

      // 5. Delete coach messages (if they have userId)
      try {
        const deletedMessages = await prisma.coachMessage.deleteMany({
          where: { userId }
        });
        console.log(`  ✅ Deleted ${deletedMessages.count} coach messages`);
      } catch (e) {
        console.log(`  ⚠️ No coach messages to delete or table doesn't have userId`);
      }

      // 6. Finally, delete the user
      await prisma.user.delete({
        where: { id: userId }
      });
      console.log(`  ✅ Deleted user record`);

      console.log(`✅ Successfully deleted account for user: ${userId}`);
      
      return { 
        success: true,
        message: 'Account and all associated data successfully deleted',
        deletedItems: {
          events: deletedEvents.count,
          facts: deletedFacts.count,
          habits: deletedHabits.count,
          tasks: deletedTasks.count,
        }
      };
    } catch (err: any) {
      console.error(`❌ Account deletion error for user:`, err);
      return reply.code(err.statusCode || 500).send({ 
        error: 'Account deletion failed',
        message: err.message 
      });
    }
  });
}

