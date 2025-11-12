import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

// Initialize Firebase Admin SDK
let firebaseApp: admin.app.App | null = null;

export function initializeFirebaseAdmin(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  try {
    // Try to load service account from file
    const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
    
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(
        fs.readFileSync(serviceAccountPath, 'utf8')
      );

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });

      console.log('✅ Firebase Admin initialized with service account file');
    } else {
      // Fallback: try environment variable (for production)
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
      
      if (serviceAccountJson) {
        const serviceAccount = JSON.parse(serviceAccountJson);
        
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });

        console.log('✅ Firebase Admin initialized with environment variable');
      } else {
        console.warn('⚠️  Firebase Admin not initialized - no service account found');
        console.warn('⚠️  Place firebase-service-account.json in backend/ or set FIREBASE_SERVICE_ACCOUNT env var');
        
        // Return a dummy app for development without breaking
        // @ts-ignore
        return null;
      }
    }

    return firebaseApp!;
  } catch (error) {
    console.error('❌ Firebase Admin initialization failed:', error);
    throw error;
  }
}

// Get the Firebase Admin app instance
export function getFirebaseAdmin(): admin.app.App | null {
  if (!firebaseApp) {
    return initializeFirebaseAdmin();
  }
  return firebaseApp;
}

// Get Firebase Auth instance
export function getFirebaseAuth(): admin.auth.Auth | null {
  const app = getFirebaseAdmin();
  return app ? app.auth() : null;
}

// Verify Firebase ID token
export async function verifyFirebaseToken(token: string): Promise<admin.auth.DecodedIdToken | null> {
  try {
    const auth = getFirebaseAuth();
    if (!auth) {
      console.warn('⚠️  Firebase Auth not available');
      return null;
    }

    const decodedToken = await auth.verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    console.error('❌ Firebase token verification failed:', error);
    return null;
  }
}

// Export admin for direct use if needed
export { admin };

