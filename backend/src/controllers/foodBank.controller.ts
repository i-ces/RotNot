import { Request, Response, NextFunction } from 'express';
import FoodBank from '../models/foodBank.model';
import { AppError } from '../middlewares/errorHandler';
import { ApiResponse } from '../types';

/**
 * Get nearby food banks based on user location
 * GET /api/food-banks/nearby?lat=27.7172&lng=85.3240&maxDistance=10000
 */
export const getNearbyFoodBanks = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { lat, lng, maxDistance = 10000 } = req.query; // maxDistance in meters (default 10km)

    if (!lat || !lng) {
      throw new AppError('Latitude and longitude are required', 400);
    }

    const latitude = parseFloat(lat as string);
    const longitude = parseFloat(lng as string);
    const maxDist = parseInt(maxDistance as string);

    const foodBanks = await FoodBank.find({
      isActive: true,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude],
          },
          $maxDistance: maxDist,
        },
      },
    });

    // Calculate distance for each food bank
    const foodBanksWithDistance = foodBanks.map((bank) => {
      const [bankLng, bankLat] = bank.location.coordinates;
      const distance = calculateDistance(latitude, longitude, bankLat, bankLng);

      return {
        id: bank._id,
        name: bank.name,
        type: bank.type,
        address: bank.address,
        lat: bankLat,
        lng: bankLng,
        phone: bank.phone,
        openUntil: bank.openUntil,
        distance: `${distance.toFixed(1)} km away`,
      };
    });

    const response: ApiResponse = {
      success: true,
      data: {
        foodBanks: foodBanksWithDistance,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all active food banks
 * GET /api/food-banks
 */
export const getAllFoodBanks = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const foodBanks = await FoodBank.find({ isActive: true });

    const response: ApiResponse = {
      success: true,
      data: {
        foodBanks,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Create a new food bank (admin only for now)
 * POST /api/food-banks
 */
export const createFoodBank = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { name, type, address, lat, lng, phone, openUntil } = req.body;

    if (!name || !type || !address || !lat || !lng) {
      throw new AppError('Name, type, address, lat, and lng are required', 400);
    }

    const foodBank = await FoodBank.create({
      name,
      type,
      address,
      location: {
        type: 'Point',
        coordinates: [lng, lat],
      },
      phone,
      openUntil,
    });

    const response: ApiResponse = {
      success: true,
      message: 'Food bank created successfully',
      data: {
        foodBank,
      },
    };

    res.status(201).json(response);
  } catch (error) {
    next(error);
  }
};

/**
 * Haversine formula to calculate distance between two points on Earth
 * Returns distance in kilometers
 */
function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(degrees: number): number {
  return degrees * (Math.PI / 180);
}
