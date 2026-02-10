import { Router } from 'express';
import { detectFood, checkDetectionHealth } from '../controllers/foodDetection.controller';
import { verifyFirebaseToken } from '../middlewares/auth';

const router = Router();

// Health check for detection service (public)
router.get('/health', checkDetectionHealth);

// Detect food from base64 image (requires auth)
router.post('/detect', verifyFirebaseToken, detectFood);

export default router;
