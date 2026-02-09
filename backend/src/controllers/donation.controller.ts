import { Request, Response, NextFunction } from 'express';
import Donation, { DonationStatus } from '../models/donation.model';
import FoodItem, { FoodStatus } from '../models/foodItem.model';
import { ApiResponse } from '../types';
import { AppError } from '../middlewares/errorHandler';
import logger from '../utils/logger';

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

    const { foodBankId, foodItems, notes } = req.body;

    if (!foodBankId || !foodItems || !Array.isArray(foodItems) || foodItems.length === 0) {
      throw new AppError('Food bank ID and food items are required', 400);
    }

    // Verify all food items exist and belong to the donor
    const itemIds = foodItems.map((item: any) => item.foodItemId);
    const existingItems = await FoodItem.find({
      _id: { $in: itemIds },
      ownerId: donorId,
    });

    if (existingItems.length !== foodItems.length) {
      throw new AppError('Some food items not found or do not belong to you', 400);
    }

    // Prepare food items data with names
    const foodItemsData = foodItems.map((item: any) => {
      const existingItem = existingItems.find(
        (ei) => ei._id.toString() === item.foodItemId
      );
      return {
        foodItemId: item.foodItemId,
        name: existingItem?.name || 'Unknown',
        quantity: item.quantity || existingItem?.quantity || 1,
        unit: item.unit || existingItem?.unit || 'unit',
      };
    });

    // Create donation
    const donation = await Donation.create({
      donorId,
      foodBankId,
      foodItems: foodItemsData,
      status: DonationStatus.SCHEDULED,
      pickupScheduledAt: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
      notes,
    });

    // Update food items status to donated
    await FoodItem.updateMany(
      { _id: { $in: itemIds } },
      { status: FoodStatus.DONATED }
    );

    const populatedDonation = await Donation.findById(donation._id).populate(
      'foodBankId'
    );

    const response: ApiResponse = {
      success: true,
      message: 'Donation created successfully',
      data: {
        donation: populatedDonation,
      },
    };

    res.status(201).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all donations for the current user
 * GET /api/donations
 */
export const getUserDonations = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const donorId = req.user?.uid;

    if (!donorId) {
      throw new AppError('User not authenticated', 401);
    }

    const donations = await Donation.find({ donorId })
      .populate('foodBankId')
      .sort({ createdAt: -1 });

    const response: ApiResponse = {
      success: true,
      data: {
        donations,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get a specific donation by ID
 * GET /api/donations/:id
 */
export const getDonationById = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const donorId = req.user?.uid;

    if (!donorId) {
      throw new AppError('User not authenticated', 401);
    }

    const donation = await Donation.findById(req.params.id).populate(
      'foodBankId'
    );

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    if (donation.donorId !== donorId) {
      throw new AppError('Access denied', 403);
    }

    const response: ApiResponse = {
      success: true,
      data: {
        donation,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Update donation status
 * PATCH /api/donations/:id/status
 */
export const updateDonationStatus = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const donorId = req.user?.uid;

    if (!donorId) {
      throw new AppError('User not authenticated', 401);
    }

    const { status } = req.body;

    if (!status || !Object.values(DonationStatus).includes(status)) {
      throw new AppError('Valid status is required', 400);
    }

    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    if (donation.donorId !== donorId) {
      throw new AppError('Access denied', 403);
    }

    donation.status = status;

    if (status === DonationStatus.PICKED_UP || status === DonationStatus.COMPLETED) {
      donation.pickupCompletedAt = new Date();
    }

    await donation.save();

    const response: ApiResponse = {
      success: true,
      message: 'Donation status updated successfully',
      data: {
        donation,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
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
