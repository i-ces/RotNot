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
 * All routes require Firebase authentication
 */

// Get nearby food banks based on location
router.get('/nearby', verifyFirebaseToken, getNearbyFoodBanks);

// Get all food banks
router.get('/', verifyFirebaseToken, getAllFoodBanks);

// Create a new food bank
router.post('/', verifyFirebaseToken, createFoodBank);

export default router;
