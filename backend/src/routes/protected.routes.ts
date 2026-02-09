import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import { getProtectedResource, getUserProfile } from '../controllers/protected.controller';

const router = Router();

/**
 * Protected routes - require Firebase authentication
 * Token must be sent in Authorization header: Bearer <firebase-id-token>
 */

// Example protected resource
router.get('/protected', verifyFirebaseToken, getProtectedResource);

// Get authenticated user's profile
router.get('/profile', verifyFirebaseToken, getUserProfile);

export default router;
