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

    const { role, name, phone } = req.body;

    // Validate required fields
    if (!role || !name || !phone) {
      throw new AppError('Role, name, and phone are required', 400);
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
      userProfile.phone = phone;
      await userProfile.save();
    } else {
      // Create new profile
      userProfile = await UserProfile.create({
        firebaseUid,
        role,
        name,
        phone,
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
          phone: userProfile.phone,
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
          phone: userProfile.phone,
          createdAt: userProfile.createdAt,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
