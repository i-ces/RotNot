import mongoose from 'mongoose';
import FoodBank from '../models/foodBank.model';
import dotenv from 'dotenv';

dotenv.config();

const foodBanksNearYou = [
  {
    name: 'The Love Company Nepal',
    type: 'charity',
    address: 'Lakeside-6, Pokhara-33700, Nepal',
    location: {
      type: 'Point',
      coordinates: [83.9700538, 28.2101242] // [longitude, latitude]
    },
    contactPhone: '+977-1-4123456',
    contactEmail: 'info@lovecompanynepal.org',
    openingHours: '9:00 AM - 5:00 PM',
    openUntil: '5:00 PM',
    isActive: true
  },
  {
    name: 'Children Nepal',
    type: 'charity',
    address: 'P.O. Box 267, Masbar, Pokhara-07, Kaski, Nepal',
    location: {
      type: 'Point',
      coordinates: [83.972754, 28.210473]
    },
    contactPhone: '+977-61-465732',
    contactEmail: 'info@childrennepal.org',
    openingHours: '8:00 AM - 6:00 PM',
    openUntil: '6:00 PM',
    isActive: true
  },
  {
    name: 'Himalayan Life Nepal',
    type: 'shelter',
    address: 'Baidam/Lakeside, Pokhara 33700, Nepal',
    location: {
      type: 'Point',
      coordinates: [83.9883219, 28.1985193]
    },
    contactPhone: '+977-61-534567',
    contactEmail: 'contact@himalayanlife.org',
    openingHours: '24/7',
    openUntil: '24/7',
    isActive: true
  },
  {
    name: 'NEST, Pokhara',
    type: 'community',
    address: 'Pokhara-8, Nagdhunga, Kaski, Gandaki, Nepal',
    location: {
      type: 'Point',
      coordinates: [84.1301506, 28.3974550]
    },
    contactPhone: '+977-61-578901',
    contactEmail: 'info@nestpokhara.org',
    openingHours: '10:00 AM - 4:00 PM',
    openUntil: '4:00 PM',
    isActive: true
  },
  {
    name: 'Muktinath Food Bank',
    type: 'community',
    address: 'Basundhara, Kathmandu-44600, Nepal',
    location: {
      type: 'Point',
      coordinates: [85.3248, 27.7375]
    },
    contactPhone: '+977-014950097',
    contactEmail: 'support@muktinathmission.org',
    openingHours: '9:00 AM - 5:00 PM',
    openUntil: '5:00 PM',
    isActive: true
  },
  {
    name: 'Donation for Nepal',
    type: 'charity',
    address: 'Kathmandu, Nepal',
    location: {
      type: 'Point',
      coordinates: [85.2842, 27.6934]
    },
    contactPhone: '+977-9851357013',
    contactEmail: 'help@donationnepal.org',
    openingHours: '9:00 AM - 6:00 PM',
    openUntil: '6:00 PM',
    isActive: true
  },
  {
    name: 'Feed Nepal',
    type: 'community',
    address: 'Kathmandu, Nepal',
    location: {
      type: 'Point',
      coordinates: [85.2815, 27.6938]
    },
    contactPhone: '+977-1-4567890',
    contactEmail: 'contact@feednepal.org',
    openingHours: '8:00 AM - 5:00 PM',
    openUntil: '5:00 PM',
    isActive: true
  },
  {
    name: 'Nepal Integral Mission Society',
    type: 'charity',
    address: 'Koteshwor-Shree Shanta Marga, Kathmandu-32, Nepal',
    location: {
      type: 'Point',
      coordinates: [85.3368835, 27.6778077]
    },
    contactPhone: '+977-1-4987654',
    contactEmail: 'info@nimssociety.org',
    openingHours: '9:00 AM - 5:00 PM',
    openUntil: '5:00 PM',
    isActive: true
  }
];

async function seedFoodBanks() {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MONGO_URI is not defined in environment variables');
    }

    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Clear existing food banks (optional - comment out if you want to keep existing data)
    const deletedCount = await FoodBank.deleteMany({});
    console.log(`🗑️  Cleared ${deletedCount.deletedCount} existing food banks`);

    // Insert new food banks
    const result = await FoodBank.insertMany(foodBanksNearYou);
    console.log(`\n✅ Successfully seeded ${result.length} food banks\n`);

    // Display inserted data
    result.forEach((bank, index) => {
      console.log(`${index + 1}. ${bank.name}`);
      console.log(`   Type: ${bank.type}`);
      console.log(`   Address: ${bank.address}`);
      console.log(`   Coordinates: [${bank.location.coordinates[0]}, ${bank.location.coordinates[1]}]`);
      console.log(`   Phone: ${bank.contactPhone}`);
      console.log('');
    });

    console.log('🎉 Food bank seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding food banks:', error);
    process.exit(1);
  }
}

seedFoodBanks();
