import { Router } from 'express';
import { getHealth } from '../controllers/health.controller';
import protectedRoutes from './protected.routes';
import userRoutes from './user.routes';

const router = Router();

// Health check route
router.get('/health', getHealth);

// User profile routes (require Firebase authentication)
router.use('/users', userRoutes);

// Protected routes (require Firebase authentication)
router.use('/', protectedRoutes);

export default router;
