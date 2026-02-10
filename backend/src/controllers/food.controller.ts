import { Request, Response, NextFunction } from 'express';
import FoodItem from '../models/foodItem.model';
import { ApiResponse } from '../types';
import { AppError } from '../middlewares/errorHandler';

/**
 * Create a new food item
 * POST /api/foods
 */
export const createFoodItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ownerId = req.user?.uid;

    if (!ownerId) {
      throw new AppError('User not authenticated', 401);
    }

    const { name, category, quantity, unit, expiryDate } = req.body;

    // Validate required fields
    if (!name || !category || quantity === undefined || !unit || !expiryDate) {
      throw new AppError('Name, category, quantity, unit, and expiry date are required', 400);
    }

    // Validate quantity
    if (quantity < 0) {
      throw new AppError('Quantity must be a positive number', 400);
    }

    // Create food item
    const foodItem = await FoodItem.create({
      name,
      category,
      quantity,
      unit,
      expiryDate: new Date(expiryDate),
      ownerId,
    });

    const response: ApiResponse = {
      success: true,
      message: 'Food item created successfully',
      data: {
        foodItem: {
          id: foodItem._id,
          name: foodItem.name,
          category: foodItem.category,
          quantity: foodItem.quantity,
          unit: foodItem.unit,
          addedAt: foodItem.addedAt,
          expiryDate: foodItem.expiryDate,
          ownerId: foodItem.ownerId,
        },
      },
    };

    res.status(201).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all food items for the authenticated user
 * GET /api/foods
 */
export const getFoodItems = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ownerId = req.user?.uid;

    if (!ownerId) {
      throw new AppError('User not authenticated', 401);
    }

    // Get all food items for this user
    const foodItems = await FoodItem.find({ ownerId }).sort({ createdAt: -1 });

    const response: ApiResponse = {
      success: true,
      data: {
        count: foodItems.length,
        foodItems: foodItems.map((item) => ({
          id: item._id,
          name: item.name,
          category: item.category,
          quantity: item.quantity,
          unit: item.unit,
          addedAt: item.addedAt,
          expiryDate: item.expiryDate,
          ownerId: item.ownerId,
        })),
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Update a food item
 * PUT /api/foods/:id
 */
export const updateFoodItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ownerId = req.user?.uid;
    const { id } = req.params;

    if (!ownerId) {
      throw new AppError('User not authenticated', 401);
    }

    // Find the food item
    const foodItem = await FoodItem.findById(id);

    if (!foodItem) {
      throw new AppError('Food item not found', 404);
    }

    // Check ownership
    if (foodItem.ownerId !== ownerId) {
      throw new AppError('You do not have permission to update this food item', 403);
    }

    const { name, category, quantity, unit, expiryDate } = req.body;

    // Validate quantity if provided
    if (quantity !== undefined && quantity < 0) {
      throw new AppError('Quantity must be a positive number', 400);
    }

    // Update fields
    if (name !== undefined) foodItem.name = name;
    if (category !== undefined) foodItem.category = category;
    if (quantity !== undefined) foodItem.quantity = quantity;
    if (unit !== undefined) foodItem.unit = unit;
    if (expiryDate !== undefined) foodItem.expiryDate = new Date(expiryDate);

    await foodItem.save();

    const response: ApiResponse = {
      success: true,
      message: 'Food item updated successfully',
      data: {
        foodItem: {
          id: foodItem._id,
          name: foodItem.name,
          category: foodItem.category,
          quantity: foodItem.quantity,
          unit: foodItem.unit,
          addedAt: foodItem.addedAt,
          expiryDate: foodItem.expiryDate,
          ownerId: foodItem.ownerId,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a food item
 * DELETE /api/foods/:id
 */
export const deleteFoodItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ownerId = req.user?.uid;
    const { id } = req.params;

    if (!ownerId) {
      throw new AppError('User not authenticated', 401);
    }

    // Find the food item
    const foodItem = await FoodItem.findById(id);

    if (!foodItem) {
      throw new AppError('Food item not found', 404);
    }

    // Check ownership
    if (foodItem.ownerId !== ownerId) {
      throw new AppError('You do not have permission to delete this food item', 403);
    }

    await FoodItem.findByIdAndDelete(id);

    const response: ApiResponse = {
      success: true,
      message: 'Food item deleted successfully',
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get expiring food items (within next 2 days)
 * GET /api/foods/expiring
 */
export const getExpiringFoods = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ownerId = req.user?.uid;

    if (!ownerId) {
      throw new AppError('User not authenticated', 401);
    }

    const now = new Date();
    const twoDaysFromNow = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);

    // Find food items expiring within next 2 days
    const foodItems = await FoodItem.find({
      ownerId,
      expiryDate: {
        $gte: now,
        $lte: twoDaysFromNow,
      },
    }).sort({ expiryDate: 1 });

    // Calculate days until expiry
    const updatedItems = foodItems.map((item) => {
      const timeDiff = item.expiryDate.getTime() - now.getTime();
      const daysDiff = timeDiff / (1000 * 60 * 60 * 24);

      return {
        id: item._id,
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        addedAt: item.addedAt,
        expiryDate: item.expiryDate,
        ownerId: item.ownerId,
        daysUntilExpiry: Math.ceil(daysDiff),
      };
    });

    const response: ApiResponse = {
      success: true,
      data: {
        count: updatedItems.length,
        foodItems: updatedItems,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};
