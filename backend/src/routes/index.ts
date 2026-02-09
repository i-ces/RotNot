import { Router } from 'express';
import { getHealth } from '../controllers/health.controller';
import protectedRoutes from './protected.routes';
import userRoutes from './user.routes';
import foodRoutes from './food.routes';
import donationRoutes from './donation.routes';
import foodBankRoutes from './foodBank.routes';

const router = Router();

// Health check route
router.get('/health', getHealth);

// User profile routes (require Firebase authentication)
router.use('/users', userRoutes);

// Food item routes (require Firebase authentication)
router.use('/foods', foodRoutes);

// Donation routes (require Firebase authentication)
router.use('/donations', donationRoutes);

// Food bank routes (require Firebase authentication)
router.use('/food-banks', foodBankRoutes);

// Protected routes (require Firebase authentication)
router.use('/', protectedRoutes);

export default router;
