import { Request, Response, NextFunction } from 'express';
import Donation, { DonationStatus } from '../models/donation.model';
import FoodItem from '../models/foodItem.model';
import DonatedFood from '../models/donatedFood.model';
import UserProfile from '../models/userProfile.model';
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
      status: DonationStatus.PENDING,
      notes,
    });

    // Move food items to donated foods collection
    const donatedFoodsData = existingItems.map((item) => ({
      name: item.name,
      category: item.category,
      quantity: item.quantity,
      unit: item.unit,
      addedAt: item.addedAt,
      expiryDate: item.expiryDate,
      originalOwnerId: donorId,
      donationId: donation._id,
      foodBankId: foodBankId,
      donatedAt: new Date(),
    }));

    // Insert into donated foods collection
    await DonatedFood.insertMany(donatedFoodsData);

    // Remove food items from the original collection
    await FoodItem.deleteMany({ _id: { $in: itemIds } });

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

    const donations = await Donation.find({ 
      donorId,
      dismissedByDonor: { $ne: true }
    })
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

    // Restore food items from donated collection back to active inventory
    const donatedFoods = await DonatedFood.find({ donationId: donation._id });
    
    if (donatedFoods.length > 0) {
      // Recreate food items in the FoodItem collection
      const restoredItems = donatedFoods.map((item) => ({
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        addedAt: item.addedAt,
        expiryDate: item.expiryDate,
        ownerId: item.originalOwnerId,
      }));

      await FoodItem.insertMany(restoredItems);

      // Remove from donated foods collection
      await DonatedFood.deleteMany({ donationId: donation._id });
    }

    const response: ApiResponse = {
      success: true,
      message: 'Donation cancelled successfully',
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get pending donations for a food bank (for food bank users)
 * GET /api/donations/pending
 */
export const getPendingDonations = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    // Find the user's profile to get their food bank ID
    const userProfile = await UserProfile.findOne({ firebaseUid: userId });

    if (!userProfile) {
      throw new AppError('User profile not found', 404);
    }

    if (!userProfile.foodBankId) {
      throw new AppError('User is not associated with a food bank', 403);
    }

    // Get all pending donations for this specific food bank
    const donations = await Donation.find({
      foodBankId: userProfile.foodBankId,
      status: DonationStatus.PENDING,
    })
      .populate('foodBankId')
      .sort({ createdAt: -1 });

    const response: ApiResponse = {
      success: true,
      message: 'Pending donations retrieved successfully',
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
 * Accept a donation (food bank)
 * POST /api/donations/:id/accept
 */
export const acceptDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    if (donation.status !== DonationStatus.PENDING) {
      throw new AppError('Only pending donations can be accepted', 400);
    }

    // Update donation status
    donation.status = DonationStatus.ACCEPTED;
    donation.pickupScheduledAt = new Date(Date.now() + 2 * 60 * 60 * 1000); // 2 hours from now
    await donation.save();

    const response: ApiResponse = {
      success: true,
      message: 'Donation accepted successfully',
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
 * Decline a donation (food bank)
 * POST /api/donations/:id/decline
 */
export const declineDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    if (donation.status !== DonationStatus.PENDING) {
      throw new AppError('Only pending donations can be declined', 400);
    }

    // Update donation status
    donation.status = DonationStatus.DECLINED;
    await donation.save();

    // Restore food items from donated collection back to active inventory
    const donatedFoods = await DonatedFood.find({ donationId: donation._id });
    
    if (donatedFoods.length > 0) {
      // Recreate food items in the FoodItem collection
      const restoredItems = donatedFoods.map((item) => ({
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        addedAt: item.addedAt,
        expiryDate: item.expiryDate,
        ownerId: item.originalOwnerId,
      }));

      await FoodItem.insertMany(restoredItems);

      // Remove from donated foods collection
      await DonatedFood.deleteMany({ donationId: donation._id });
    }

    const response: ApiResponse = {
      success: true,
      message: 'Donation declined successfully',
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
 * Dismiss a donation (donor)
 * POST /api/donations/:id/dismiss
 */
export const dismissDonation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      throw new AppError('Donation not found', 404);
    }

    // Verify the donation belongs to this user
    if (donation.donorId !== userId) {
      throw new AppError('Not authorized to dismiss this donation', 403);
    }

    // Update dismissed status
    donation.dismissedByDonor = true;
    await donation.save();

    const response: ApiResponse = {
      success: true,
      message: 'Donation dismissed successfully',
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
 * Get leaderboard (aggregated donation statistics by user)
 * GET /api/donations/leaderboard
 */
export const getLeaderboard = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Aggregate accepted donations by donor
    const leaderboardData = await Donation.aggregate([
      {
        $match: { status: DonationStatus.ACCEPTED },
      },
      {
        $unwind: '$foodItems',
      },
      {
        $group: {
          _id: '$donorId',
          totalDonations: { $sum: 1 },
          totalItems: { $sum: '$foodItems.quantity' },
          donationIds: { $push: '$_id' },
        },
      },
      {
        $sort: { totalItems: -1 },
      },
      {
        $limit: 100,
      },
    ]);

    // Fetch user profiles for donors
    const donorIds = leaderboardData.map((item) => item._id);
    const profiles = await UserProfile.find({
      firebaseUid: { $in: donorIds },
    });

    // Map profiles to donor IDs
    const profileMap = new Map(
      profiles.map((p) => [p.firebaseUid, p])
    );

    // Build leaderboard response
    const leaderboard = leaderboardData.map((item, index) => {
      const profile = profileMap.get(item._id);
      return {
        rank: index + 1,
        donorId: item._id,
        name: profile?.name || 'Anonymous',
        role: profile?.role || 'user',
        totalDonations: item.totalDonations,
        totalItems: item.totalItems,
      };
    });

    const response: ApiResponse = {
      success: true,
      message: 'Leaderboard retrieved successfully',
      data: {
        leaderboard,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
