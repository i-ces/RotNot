import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import {
  createDonation,
  getUserDonations,
  getDonationById,
  updateDonationStatus,
  getPendingDonations,
  acceptDonation,
  declineDonation,
  dismissDonation,
  getLeaderboard,
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

// Get pending donations (for food banks)
router.get('/pending', verifyFirebaseToken, getPendingDonations);

// Get leaderboard (public)
router.get('/leaderboard', getLeaderboard);

// Accept a donation (food bank)
router.post('/:id/accept', verifyFirebaseToken, acceptDonation);

// Decline a donation (food bank)
router.post('/:id/decline', verifyFirebaseToken, declineDonation);

// Dismiss a donation (donor)
router.post('/:id/dismiss', verifyFirebaseToken, dismissDonation);

// Get a specific donation by ID
router.get('/:id', verifyFirebaseToken, getDonationById);

// Update donation status
router.patch('/:id/status', verifyFirebaseToken, updateDonationStatus);

export default router;
