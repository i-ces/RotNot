import { connectDB, disconnectDB } from '../config/db';
import FoodBank, { FoodBankType } from '../models/foodBank.model';
import logger from '../utils/logger';

/**
 * Seed script to populate the database with initial data
 * Run: npm run seed
 */

const sampleFoodBanks = [
  {
    name: 'Kathmandu Community Fridge',
    type: FoodBankType.COMMUNITY,
    address: 'Thamel, Kathmandu',
    location: {
      type: 'Point',
      coordinates: [85.3240, 27.7172], // [lng, lat]
    },
    phone: '+977-1-4123456',
    openUntil: '8:00 PM',
  },
  {
    name: 'Patan Food Bank',
    type: FoodBankType.CHARITY,
    address: 'Mangalbazar, Lalitpur',
    location: {
      type: 'Point',
      coordinates: [85.3286, 27.6727],
    },
    phone: '+977-1-5234567',
    openUntil: '6:00 PM',
  },
  {
    name: 'Bhaktapur Shelter Kitchen',
    type: FoodBankType.SHELTER,
    address: 'Durbar Square, Bhaktapur',
    location: {
      type: 'Point',
      coordinates: [85.4298, 27.6722],
    },
    phone: '+977-1-6345678',
    openUntil: '9:00 PM',
  },
  {
    name: 'Balaju Community Center',
    type: FoodBankType.COMMUNITY,
    address: 'Balaju, Kathmandu',
    location: {
      type: 'Point',
      coordinates: [85.3050, 27.7350],
    },
    phone: '+977-1-4456789',
    openUntil: '5:00 PM',
  },
];

const seedDatabase = async () => {
  try {
    logger.info('🌱 Starting database seeding...\n');

    // Connect to database
    await connectDB();

    // Clear existing data
    logger.info('🗑️  Clearing existing data...');
    await FoodBank.deleteMany({});
    logger.info('   ✓ Existing data cleared\n');

    // Seed food banks
    logger.info('🏦 Seeding food banks...');
    const foodBanks = await FoodBank.insertMany(sampleFoodBanks);
    logger.info(`   ✓ Created ${foodBanks.length} food banks\n`);

    logger.info('\n📊 Seeding Summary:');
    logger.info(`   Food Banks: ${foodBanks.length}`);
    logger.info(`   - Community: ${foodBanks.filter(fb => fb.type === FoodBankType.COMMUNITY).length}`);
    logger.info(`   - Charity: ${foodBanks.filter(fb => fb.type === FoodBankType.CHARITY).length}`);
    logger.info(`   - Shelter: ${foodBanks.filter(fb => fb.type === FoodBankType.SHELTER).length}`);

    logger.info('\n✅ Database seeding completed successfully!');
    logger.info('💡 Real users will be created automatically when they sign up through the app.\n');
  } catch (error) {
    logger.error('❌ Error seeding database:', error);
    process.exit(1);
  } finally {
    await disconnectDB();
    process.exit(0);
  }
};

// Run the seed function
seedDatabase();
