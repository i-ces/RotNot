import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  createDonation,
  getUserDonations,
  getDonationById,
  updateDonationStatus,
} from '../controllers/donation.controller';

const router = Router();

/**
 * Donation Routes
 * All routes require Firebase authentication
 */

// Create a new donation
router.post('/', verifyFirebaseToken, createDonation);

// Get all donations for current user
router.get('/', verifyFirebaseToken, getUserDonations);

// Get a specific donation by ID
router.get('/:id', verifyFirebaseToken, getDonationById);

// Update donation status
router.patch('/:id/status', verifyFirebaseToken, updateDonationStatus);

export default router;
