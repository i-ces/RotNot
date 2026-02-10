import { Request, Response, NextFunction } from 'express';
import UserProfile, { UserRole } from '../models/userProfile.model';
import { ApiResponse } from '../types';
import { AppError } from '../middlewares/errorHandler';

/**
 * Create or update user profile
 * POST /api/users/profile
 */
export const createOrUpdateProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get Firebase UID from authenticated user
    const firebaseUid = req.user?.uid;

    if (!firebaseUid) {
      throw new AppError('User not authenticated', 401);
    }

    const { role, name, phone, email, foodBankId } = req.body;

    // Validate required fields
    if (!role || !name) {
      throw new AppError('Role and name are required', 400);
    }

    // Validate foodBankId for foodbank users
    if (role === UserRole.FOODBANK && !foodBankId) {
      throw new AppError('Food bank ID is required for food bank users', 400);
    }

    // Validate role enum
    if (!Object.values(UserRole).includes(role)) {
      throw new AppError(
        `Invalid role. Must be one of: ${Object.values(UserRole).join(', ')}`,
        400
      );
    }

    // Check if profile exists
    let userProfile = await UserProfile.findOne({ firebaseUid });

    if (userProfile) {
      // Update existing profile
      userProfile.role = role;
      userProfile.name = name;
      if (phone !== undefined) userProfile.phone = phone;
      if (email !== undefined) userProfile.email = email;
      if (foodBankId !== undefined) userProfile.foodBankId = foodBankId;
      await userProfile.save();
    } else {
      // Create new profile
      userProfile = await UserProfile.create({
        firebaseUid,
        role,
        name,
        phone,
        email,
        ...(foodBankId && { foodBankId }), // Only include if provided
      });
    }

    const response: ApiResponse = {
      success: true,
      message: userProfile ? 'Profile updated successfully' : 'Profile created successfully',
      data: {
        profile: {
          id: userProfile._id,
          firebaseUid: userProfile.firebaseUid,
          role: userProfile.role,
          name: userProfile.name,
          email: userProfile.email,
          phone: userProfile.phone,
          foodBankId: userProfile.foodBankId,
          createdAt: userProfile.createdAt,
        },
      },
    };

    res.status(userProfile ? 200 : 201).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user's profile
 * GET /api/users/profile/me
 */
export const getMyProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get Firebase UID from authenticated user
    const firebaseUid = req.user?.uid;

    if (!firebaseUid) {
      throw new AppError('User not authenticated', 401);
    }

    // Find user profile
    const userProfile = await UserProfile.findOne({ firebaseUid });

    if (!userProfile) {
      throw new AppError('Profile not found. Please create a profile first.', 404);
    }

    const response: ApiResponse = {
      success: true,
      data: {
        profile: {
          id: userProfile._id,
          firebaseUid: userProfile.firebaseUid,
          role: userProfile.role,
          name: userProfile.name,
          email: userProfile.email,
          phone: userProfile.phone,
          foodBankId: userProfile.foodBankId,
          createdAt: userProfile.createdAt,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
