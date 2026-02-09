import cron from 'node-cron';
import FoodItem, { FoodStatus } from '../models/foodItem.model';
import logger from '../utils/logger';

/**
 * Check and update food item statuses based on expiry dates
 * Runs daily to keep statuses up to date
 */
export const updateFoodItemStatuses = async (): Promise<void> => {
  try {
    const now = new Date();

    logger.info('Running food expiry status update job...');

    // Get all food items
    const foodItems = await FoodItem.find({});
    let updatedCount = 0;

    // Update each item based on expiry date
    for (const item of foodItems) {
      const timeDiff = item.expiryDate.getTime() - now.getTime();
      const daysDiff = timeDiff / (1000 * 60 * 60 * 24);

      let newStatus = item.status;

      // Determine new status based on days until expiry
      if (daysDiff < 0) {
        // Past expiry date
        newStatus = FoodStatus.EXPIRED;
      } else if (daysDiff <= 2) {
        // Expiring within 2 days
        newStatus = FoodStatus.EXPIRING;
      } else {
        // More than 2 days until expiry
        newStatus = FoodStatus.FRESH;
      }

      // Update if status has changed
      if (newStatus !== item.status) {
        item.status = newStatus;
        await item.save();
        updatedCount++;
      }
    }

    logger.info(
      `Food expiry status update completed. Updated ${updatedCount} out of ${foodItems.length} items.`
    );
  } catch (error) {
    logger.error('Error updating food item statuses:', error);
  }
};

/**
 * Start the cron job to run daily at midnight
 */
export const startExpiryCheckCron = (): void => {
  // Run daily at midnight (00:00)
  cron.schedule('0 0 * * *', async () => {
    logger.info('Starting scheduled food expiry check...');
    await updateFoodItemStatuses();
  });

  logger.info('✅ Food expiry check cron job scheduled (runs daily at midnight)');
};

/**
 * Run the expiry check immediately (useful for testing or manual trigger)
 */
export const runExpiryCheckNow = async (): Promise<void> => {
  logger.info('Running food expiry check manually...');
  await updateFoodItemStatuses();
};
