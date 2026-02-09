import { connectDB, disconnectDB } from '../config/db';
import UserProfile from '../models/userProfile.model';
import FoodItem from '../models/foodItem.model';
import Donation from '../models/donation.model';
import logger from '../utils/logger';

const clearDatabase = async () => {
  try {
    logger.info('🗑️  Clearing all data...');
    await connectDB();
    
    await UserProfile.deleteMany({});
    await FoodItem.deleteMany({});
    await Donation.deleteMany({});
    
    logger.info('✅ All data cleared successfully!');
  } catch (error) {
    logger.error('❌ Error clearing database:', error);
  } finally {
    await disconnectDB();
    process.exit(0);
  }
};

clearDatabase();
