import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  createFoodItem,
  getFoodItems,
  updateFoodItem,
  deleteFoodItem,
  getExpiringFoods,
} from '../controllers/food.controller';

const router = Router();

/**
 * Food Item Routes
 * All routes require Firebase authentication
 * Users can only access their own food items
 */

// Get expiring food items (must be before '/:id' route)
router.get('/expiring', verifyFirebaseToken, getExpiringFoods);

// Create a new food item
router.post('/', verifyFirebaseToken, createFoodItem);

// Get all food items for the authenticated user
router.get('/', verifyFirebaseToken, getFoodItems);

// Update a food item (only if owned by user)
router.put('/:id', verifyFirebaseToken, updateFoodItem);

// Delete a food item (only if owned by user)
router.delete('/:id', verifyFirebaseToken, deleteFoodItem);

export default router;
