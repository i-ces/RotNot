import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  createOrUpdateProfile,
  getMyProfile,
} from '../controllers/userProfile.controller';

const router = Router();

/**
 * User Profile Routes
 * All routes require Firebase authentication
 */

// Get current user's profile
router.get('/profile', verifyFirebaseToken, getMyProfile);

// Create or update user profile
router.post('/profile', verifyFirebaseToken, createOrUpdateProfile);
router.put('/profile', verifyFirebaseToken, createOrUpdateProfile);

export default router;
