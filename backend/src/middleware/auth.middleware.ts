import { FastifyRequest, FastifyReply } from 'fastify';
import { verifyFirebaseToken } from '../utils/firebase-admin';

export async function authMiddleware(request: FastifyRequest, reply: FastifyReply) {
  try {
    const authHeader = request.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.warn('⚠️  No Authorization header found');
      return; // Allow request to continue (controllers will check x-user-id fallback)
    }

    const token = authHeader.replace('Bearer ', '');
    const decodedToken = await verifyFirebaseToken(token);

    if (decodedToken) {
      // Attach user to request
      (request as any).user = {
        id: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
      };
      console.log(`✅ Authenticated via Firebase: ${decodedToken.uid}`);
    } else {
      console.warn('⚠️  Firebase token verification failed');
    }
  } catch (error) {
    console.error('❌ Auth middleware error:', error);
    // Don't block request - let it continue to controller
  }
}

