import mongoose from 'mongoose';
import config from './index';
import logger from '../utils/logger';

export const connectDB = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(config.mongoUri);

    logger.info(`✅ MongoDB Connected: ${conn.connection.host}`);
    logger.info(`📊 Database: ${conn.connection.name}`);

    // Connection event listeners
    mongoose.connection.on('disconnected', () => {
      logger.warn('⚠️ MongoDB disconnected');
    });

    mongoose.connection.on('error', (err) => {
      logger.error('❌ MongoDB connection error:', err);
    });
  } catch (error) {
    if (error instanceof Error) {
      logger.error('❌ MongoDB connection failed:', error.message);
    } else {
      logger.error('❌ MongoDB connection failed:', error);
    }
    process.exit(1);
  }
};

export const disconnectDB = async (): Promise<void> => {
  try {
    await mongoose.connection.close();
    logger.info('MongoDB connection closed');
  } catch (error) {
    if (error instanceof Error) {
      logger.error('Error closing MongoDB connection:', error.message);
    } else {
      logger.error('Error closing MongoDB connection:', error);
    }
  }
};
