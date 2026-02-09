import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  createDonation,
  getAvailableDonations,
  claimDonation,
  completeDonation,
} from '../controllers/donation.controller';

const router = Router();

/**
 * Donation Routes
 * All routes require Firebase authentication
 */

// Get available donations (must be before '/:id' routes)
router.get('/available', verifyFirebaseToken, getAvailableDonations);

// Create a new donation
router.post('/', verifyFirebaseToken, createDonation);

// Claim a donation (for NGOs)
router.put('/:id/claim', verifyFirebaseToken, claimDonation);

// Complete a donation (for donor or NGO)
router.put('/:id/complete', verifyFirebaseToken, completeDonation);

export default router;
