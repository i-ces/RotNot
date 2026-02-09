import { Request, Response, NextFunction } from 'express';
import Donation, { DonorType, DonationStatus } from '../models/donation.model';
import { ApiResponse } from '../types';
import { AppError } from '../middlewares/errorHandler';

/**
 * Create a new donation
 * POST /api/donations
 */
export const createDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const donorId = req.user?.uid;

    if (!donorId) {
      throw new AppError('User not authenticated', 401);
    }

    const { foodName, quantity, preparedAt, expiryTime, donorType, location, donorName, donorPhone, pickupAddress } = req.body;

    // Validate required fields
    if (!foodName || !quantity || !preparedAt || !expiryTime || !donorType || !location || !donorName || !donorPhone || !pickupAddress) {
      throw new AppError(
        'Food name, quantity, prepared at, expiry time, donor type, location, donor name, donor phone, and pickup address are required',
        400
      );
    }

    // Validate donorType enum
    if (!Object.values(DonorType).includes(donorType)) {
      throw new AppError(
        `Invalid donor type. Must be one of: ${Object.values(DonorType).join(', ')}`,
        400
      );
    }

    // Create donation
    const donation = await Donation.create({
      foodName,
      quantity,
      preparedAt: new Date(preparedAt),
      expiryTime: new Date(expiryTime),
      donorType,
      location,
      donorName,
      donorPhone,
      pickupAddress,
      status: DonationStatus.AVAILABLE,
      donorId,
    });

    const response: ApiResponse = {
      success: true,
      message: 'Donation created successfully',
      data: {
        donation: {
          id: donation._id,
          foodName: donation.foodName,
          quantity: donation.quantity,
          preparedAt: donation.preparedAt,
          expiryTime: donation.expiryTime,
          donorType: donation.donorType,
          location: donation.location,
          donorName: donation.donorName,
          donorPhone: donation.donorPhone,
          pickupAddress: donation.pickupAddress,
          status: donation.status,
          donorId: donation.donorId,
          claimedBy: donation.claimedBy,
        },
      },
    };

    res.status(201).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all available donations
 * GET /api/donations/available
 */
export const getAvailableDonations = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    // Get all available donations (not expired)
    const now = new Date();
    const donations = await Donation.find({
      status: DonationStatus.AVAILABLE,
      expiryTime: { $gt: now },
    }).sort({ createdAt: -1 });

    const response: ApiResponse = {
      success: true,
      data: {
        count: donations.length,
        donations: donations.map((donation) => ({
          id: donation._id,
          foodName: donation.foodName,
          quantity: donation.quantity,
          preparedAt: donation.preparedAt,
          expiryTime: donation.expiryTime,
          donorType: donation.donorType,
          location: donation.location,
          donorName: donation.donorName,
          donorPhone: donation.donorPhone,
          pickupAddress: donation.pickupAddress,
          status: donation.status,
          donorId: donation.donorId,
          claimedBy: donation.claimedBy,
        })),
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Claim a donation (for NGOs)
 * PUT /api/donations/:id/claim
 */
export const claimDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ngoId = req.user?.uid;
    const { id } = req.params;

    if (!ngoId) {
      throw new AppError('User not authenticated', 401);
    }

    // Find the donation
    const donation = await Donation.findById(id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    // Check if donation is available
    if (donation.status !== DonationStatus.AVAILABLE) {
      throw new AppError('Donation is not available for claiming', 400);
    }

    // Check if donation is expired
    if (new Date() > donation.expiryTime) {
      throw new AppError('Donation has expired', 400);
    }

    // Claim the donation
    donation.status = DonationStatus.CLAIMED;
    donation.claimedBy = ngoId;
    await donation.save();

    const response: ApiResponse = {
      success: true,
      message: 'Donation claimed successfully',
      data: {
        donation: {
          id: donation._id,
          foodName: donation.foodName,
          quantity: donation.quantity,
          preparedAt: donation.preparedAt,
          expiryTime: donation.expiryTime,
          donorType: donation.donorType,
          location: donation.location,
          donorName: donation.donorName,
          donorPhone: donation.donorPhone,
          pickupAddress: donation.pickupAddress,
          status: donation.status,
          donorId: donation.donorId,
          claimedBy: donation.claimedBy,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Mark donation as completed
 * PUT /api/donations/:id/complete
 */
export const completeDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;
    const { id } = req.params;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    // Find the donation
    const donation = await Donation.findById(id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    // Check if user is either the donor or the one who claimed it
    if (donation.donorId !== userId && donation.claimedBy !== userId) {
      throw new AppError('You do not have permission to complete this donation', 403);
    }

    // Check if donation is claimed
    if (donation.status !== DonationStatus.CLAIMED) {
      throw new AppError('Donation must be claimed before it can be completed', 400);
    }

    // Mark as completed
    donation.status = DonationStatus.COMPLETED;
    await donation.save();

    const response: ApiResponse = {
      success: true,
      message: 'Donation marked as completed',
      data: {
        donation: {
          id: donation._id,
          foodName: donation.foodName,
          quantity: donation.quantity,
          preparedAt: donation.preparedAt,
          expiryTime: donation.expiryTime,
          donorType: donation.donorType,
          location: donation.location,
          donorName: donation.donorName,
          donorPhone: donation.donorPhone,
          pickupAddress: donation.pickupAddress,
          status: donation.status,
          donorId: donation.donorId,
          claimedBy: donation.claimedBy,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
