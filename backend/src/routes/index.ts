import { Router } from 'express';
import { getHealth } from '../controllers/health.controller';
import protectedRoutes from './protected.routes';

const router = Router();

// Health check route
router.get('/health', getHealth);

// Protected routes (require Firebase authentication)
router.use('/', protectedRoutes);

export default router;
