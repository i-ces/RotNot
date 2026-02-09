import { Request, Response, NextFunction } from 'express';
import Donation, { DonationStatus } from '../models/donation.model';
import FoodItem, { FoodStatus } from '../models/foodItem.model';
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

/**
 * Cancel a donation
 * DELETE /api/donations/:id
 */
export const cancelDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const donorId = req.user?.uid;

    if (!donorId) {
      throw new AppError('User not authenticated', 401);
    }

    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    if (donation.donorId !== donorId) {
      throw new AppError('Access denied', 403);
    }

    if (
      donation.status === DonationStatus.COMPLETED ||
      donation.status === DonationStatus.PICKED_UP
    ) {
      throw new AppError(
        'Cannot cancel a completed or picked up donation',
        400
      );
    }

    donation.status = DonationStatus.CANCELLED;
    await donation.save();

    // Restore food items to available status
    const itemIds = donation.foodItems.map((item) => item.foodItemId);
    await FoodItem.updateMany(
      { _id: { $in: itemIds } },
      { status: FoodStatus.FRESH }
    );

    const response: ApiResponse = {
      success: true,
      message: 'Donation cancelled successfully',
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
