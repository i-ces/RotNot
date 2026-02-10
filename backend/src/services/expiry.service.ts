import cron from 'node-cron';
import FoodItem from '../models/foodItem.model';
import logger from '../utils/logger';

/**
 * Check and log food item expiry information
 * This service is kept for future expiry-related features
 */
export const checkFoodItemExpiry = async (): Promise<void> => {
  try {
    const now = new Date();

    logger.info('Running food expiry check...');

    // Get all food items
    const foodItems = await FoodItem.find({});
    let expiringCount = 0;
    let expiredCount = 0;

    // Count expiring and expired items
    for (const item of foodItems) {
      const timeDiff = item.expiryDate.getTime() - now.getTime();
      const daysDiff = timeDiff / (1000 * 60 * 60 * 24);

      if (daysDiff < 0) {
        expiredCount++;
      } else if (daysDiff <= 2) {
        expiringCount++;
      }
    }

    logger.info(
      `Food expiry check completed. Total items: ${foodItems.length}, Expiring soon: ${expiringCount}, Expired: ${expiredCount}`
    );
  } catch (error) {
    logger.error('Error checking food item expiry:', error);
  }
};

/**
 * Start the cron job to run daily at midnight
 */
export const startExpiryCheckCron = (): void => {
  // Run daily at midnight (00:00)
  cron.schedule('0 0 * * *', async () => {
    logger.info('Starting scheduled food expiry check...');
    await checkFoodItemExpiry();
  });

  logger.info('✅ Food expiry check cron job scheduled (runs daily at midnight)');
};

/**
 * Run the expiry check immediately (useful for testing or manual trigger)
 */
export const runExpiryCheckNow = async (): Promise<void> => {
  logger.info('Running food expiry check manually...');
  await checkFoodItemExpiry();
};
