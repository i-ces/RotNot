import admin from 'firebase-admin';
import logger from '../utils/logger';

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
  try {
    // Check if Firebase is already initialized
    if (admin.apps.length > 0) {
      logger.info('🔥 Firebase Admin already initialized');
      return admin;
    }

    // Get Firebase credentials from environment variables
    const {
      FIREBASE_PROJECT_ID,
      FIREBASE_PRIVATE_KEY,
      FIREBASE_CLIENT_EMAIL,
    } = process.env;

    // Validate required environment variables
    if (!FIREBASE_PROJECT_ID || !FIREBASE_PRIVATE_KEY || !FIREBASE_CLIENT_EMAIL) {
      logger.warn('⚠️ Firebase credentials not configured. Firebase Admin SDK not initialized.');
      logger.warn('Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL environment variables.');
      return null;
    }

    // Initialize Firebase Admin with service account credentials
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: FIREBASE_PROJECT_ID,
        privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'), // Handle escaped newlines
        clientEmail: FIREBASE_CLIENT_EMAIL,
      }),
    });

    logger.info('🔥 Firebase Admin SDK initialized successfully');
    logger.info(`📱 Project ID: ${FIREBASE_PROJECT_ID}`);

    return admin;
  } catch (error) {
    if (error instanceof Error) {
      logger.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    } else {
      logger.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
    return null;
  }
};

// Initialize Firebase
const firebaseAdmin = initializeFirebase();

// Export Firebase Admin instance and auth
export const auth = firebaseAdmin ? admin.auth() : null;
export const firestore = firebaseAdmin ? admin.firestore() : null;
export const storage = firebaseAdmin ? admin.storage() : null;

export default firebaseAdmin;
