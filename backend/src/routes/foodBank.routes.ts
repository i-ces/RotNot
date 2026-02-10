import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  getNearbyFoodBanks,
  getAllFoodBanks,
  createFoodBank,
} from '../controllers/foodBank.controller';

const router = Router();

/**
 * Food Bank Routes
 * Public routes for viewing food banks
 * Authentication required only for creating food banks
 */

// Get nearby food banks based on location (public)
router.get('/nearby', getNearbyFoodBanks);

// Get all food banks (public - needed for signup)
router.get('/', getAllFoodBanks);

// Create a new food bank (protected)
router.post('/', verifyFirebaseToken, createFoodBank);

export default router;
