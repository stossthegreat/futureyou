import { FastifyRequest, FastifyReply } from 'fastify';
import { verifyFirebaseToken } from '../utils/firebase-admin';

// Extend Fastify request type to include user
declare module 'fastify' {
  interface FastifyRequest {
    user?: {
      id: string;
      email: string | null;
      name: string | null;
    };
  }
}

/**
 * Firebase Authentication Middleware
 * 
 * Verifies Firebase ID token from Authorization header
 * and attaches user info to request object.
 */
export async function authMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  try {
    // Extract token from Authorization header
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      reply.code(401).send({
        error: 'Unauthorized',
        message: 'Missing or invalid Authorization header. Expected: Bearer <token>',
      });
      return;
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token with Firebase
    const decodedToken = await verifyFirebaseToken(token);

    if (!decodedToken) {
      reply.code(401).send({
        error: 'Unauthorized',
        message: 'Invalid or expired Firebase token',
      });
      return;
    }

    // Attach user info to request
    request.user = {
      id: decodedToken.uid,
      email: decodedToken.email || null,
      name: decodedToken.name || null,
    };

    // Log authenticated request
    console.log(`✅ Authenticated request from user: ${request.user.id} (${request.user.email})`);
    
  } catch (error) {
    console.error('❌ Auth middleware error:', error);
    reply.code(500).send({
      error: 'Internal Server Error',
      message: 'Authentication failed',
    });
  }
}

/**
 * Optional Auth Middleware
 * 
 * Tries to verify token but doesn't fail if missing.
 * Useful for endpoints that work with or without auth.
 */
export async function optionalAuthMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  try {
    const authHeader = request.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decodedToken = await verifyFirebaseToken(token);

      if (decodedToken) {
        request.user = {
          id: decodedToken.uid,
          email: decodedToken.email || null,
          name: decodedToken.name || null,
        };
        console.log(`✅ Optional auth: user ${request.user.id} authenticated`);
      }
    }
    
    // Continue even if no token or invalid token
  } catch (error) {
    console.error('⚠️  Optional auth middleware error:', error);
    // Continue even on error
  }
}

/**
 * Helper to get user ID from request
 * Throws error if not authenticated
 */
export function getUserId(request: FastifyRequest): string {
  if (!request.user || !request.user.id) {
    throw new Error('User not authenticated');
  }
  return request.user.id;
}

/**
 * Helper to get user ID from request (returns null if not auth)
 */
export function getUserIdOrNull(request: FastifyRequest): string | null {
  return request.user?.id || null;
}

