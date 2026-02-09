import { connectDB, disconnectDB } from '../config/db';
import UserProfile, { UserRole } from '../models/userProfile.model';
import FoodItem, { FoodStatus } from '../models/foodItem.model';
import Donation, { DonorType, DonationStatus } from '../models/donation.model';
import logger from '../utils/logger';

/**
 * Seed script to populate the database with initial data
 * Run: npm run seed
 */

const sampleUsers = [
  {
    firebaseUid: 'user_001',
    role: UserRole.USER,
    name: 'John Doe',
    phone: '+1-555-0101',
  },
  {
    firebaseUid: 'hostel_001',
    role: UserRole.HOSTEL,
    name: 'Campus Hostel A',
    phone: '+1-555-0201',
  },
  {
    firebaseUid: 'restaurant_001',
    role: UserRole.RESTAURANT,
    name: 'Green Leaf Restaurant',
    phone: '+1-555-0301',
  },
  {
    firebaseUid: 'ngo_001',
    role: UserRole.NGO,
    name: 'Food Relief Foundation',
    phone: '+1-555-0401',
  },
  {
    firebaseUid: 'ngo_002',
    role: UserRole.NGO,
    name: 'Hunger Free Society',
    phone: '+1-555-0402',
  },
];

const sampleFoodItems = [
  {
    name: 'Fresh Apples',
    category: 'Fruits & Vegetables',
    quantity: 5,
    unit: 'kg',
    expiryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
    status: FoodStatus.FRESH,
    ownerId: 'user_001',
  },
  {
    name: 'Milk',
    category: 'Dairy',
    quantity: 2,
    unit: 'liters',
    expiryDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
    status: FoodStatus.EXPIRING,
    ownerId: 'user_001',
  },
  {
    name: 'Bread',
    category: 'Bakery',
    quantity: 3,
    unit: 'loaves',
    expiryDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
    status: FoodStatus.EXPIRED,
    ownerId: 'hostel_001',
  },
  {
    name: 'Rice',
    category: 'Raw Food',
    quantity: 10,
    unit: 'kg',
    expiryDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000), // 6 months
    status: FoodStatus.FRESH,
    ownerId: 'restaurant_001',
  },
  {
    name: 'Tomatoes',
    category: 'Fruits & Vegetables',
    quantity: 3,
    unit: 'kg',
    expiryDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // 1 day
    status: FoodStatus.EXPIRING,
    ownerId: 'restaurant_001',
  },
];

const sampleDonations = [
  {
    foodName: 'Cooked Rice and Curry',
    quantity: '50 servings',
    preparedAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
    expiryTime: new Date(Date.now() + 4 * 60 * 60 * 1000), // 4 hours from now
    donorType: DonorType.HOSTEL,
    location: 'Campus Hostel A Canteen',
    donorName: 'Campus Hostel A',
    donorPhone: '+1-555-0201',
    pickupAddress: '123 University Avenue, Building A',
    status: DonationStatus.AVAILABLE,
    donorId: 'hostel_001',
  },
  {
    foodName: 'Vegetable Biryani',
    quantity: '30 servings',
    preparedAt: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
    expiryTime: new Date(Date.now() + 3 * 60 * 60 * 1000), // 3 hours from now
    donorType: DonorType.RESTAURANT,
    location: 'Green Leaf Restaurant',
    donorName: 'Green Leaf Restaurant',
    donorPhone: '+1-555-0301',
    pickupAddress: '456 Main Street, Downtown',
    status: DonationStatus.AVAILABLE,
    donorId: 'restaurant_001',
  },
  {
    foodName: 'Sandwiches',
    quantity: '20 pieces',
    preparedAt: new Date(Date.now() - 3 * 60 * 60 * 1000), // 3 hours ago
    expiryTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
    donorType: DonorType.EVENT,
    location: 'Tech Conference Hall',
    donorName: 'TechCon 2026 Organizers',
    donorPhone: '+1-555-0501',
    pickupAddress: '789 Conference Center, Hall B',
    status: DonationStatus.CLAIMED,
    donorId: 'user_001',
    claimedBy: 'ngo_001',
  },
  {
    foodName: 'Pasta with Sauce',
    quantity: '40 servings',
    preparedAt: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 hours ago
    expiryTime: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago (expired)
    donorType: DonorType.RESTAURANT,
    location: 'Green Leaf Restaurant',
    donorName: 'Green Leaf Restaurant',
    donorPhone: '+1-555-0301',
    pickupAddress: '456 Main Street, Downtown',
    status: DonationStatus.COMPLETED,
    donorId: 'restaurant_001',
    claimedBy: 'ngo_002',
  },
  {
    foodName: 'Fresh Salad Bowls',
    quantity: '25 bowls',
    preparedAt: new Date(Date.now() - 30 * 60 * 1000), // 30 minutes ago
    expiryTime: new Date(Date.now() + 5 * 60 * 60 * 1000), // 5 hours from now
    donorType: DonorType.RESTAURANT,
    location: 'Green Leaf Restaurant',
    donorName: 'Green Leaf Restaurant',
    donorPhone: '+1-555-0301',
    pickupAddress: '456 Main Street, Downtown',
    status: DonationStatus.AVAILABLE,
    donorId: 'restaurant_001',
  },
];

const seedDatabase = async () => {
  try {
    logger.info('🌱 Starting database seeding...');

    // Connect to database
    await connectDB();

    // Clear existing data
    logger.info('🗑️  Clearing existing data...');
    await UserProfile.deleteMany({});
    await FoodItem.deleteMany({});
    await Donation.deleteMany({});
    logger.info('✅ Existing data cleared');

    // Seed users
    logger.info('👥 Seeding user profiles...');
    const users = await UserProfile.insertMany(sampleUsers);
    logger.info(`✅ Created ${users.length} user profiles`);

    // Seed food items
    logger.info('🍎 Seeding food items...');
    const foodItems = await FoodItem.insertMany(sampleFoodItems);
    logger.info(`✅ Created ${foodItems.length} food items`);

    // Seed donations
    logger.info('🎁 Seeding donations...');
    const donations = await Donation.insertMany(sampleDonations);
    logger.info(`✅ Created ${donations.length} donations`);

    // Summary
    logger.info('\n📊 Seeding Summary:');
    logger.info(`   Users: ${users.length}`);
    logger.info(`   - Regular Users: ${users.filter(u => u.role === UserRole.USER).length}`);
    logger.info(`   - Hostels: ${users.filter(u => u.role === UserRole.HOSTEL).length}`);
    logger.info(`   - Restaurants: ${users.filter(u => u.role === UserRole.RESTAURANT).length}`);
    logger.info(`   - NGOs: ${users.filter(u => u.role === UserRole.NGO).length}`);
    logger.info(`   Food Items: ${foodItems.length}`);
    logger.info(`   - Fresh: ${foodItems.filter(f => f.status === FoodStatus.FRESH).length}`);
    logger.info(`   - Expiring: ${foodItems.filter(f => f.status === FoodStatus.EXPIRING).length}`);
    logger.info(`   - Expired: ${foodItems.filter(f => f.status === FoodStatus.EXPIRED).length}`);
    logger.info(`   Donations: ${donations.length}`);
    logger.info(`   - Available: ${donations.filter(d => d.status === DonationStatus.AVAILABLE).length}`);
    logger.info(`   - Claimed: ${donations.filter(d => d.status === DonationStatus.CLAIMED).length}`);
    logger.info(`   - Completed: ${donations.filter(d => d.status === DonationStatus.COMPLETED).length}`);

    logger.info('\n✅ Database seeding completed successfully!');
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
