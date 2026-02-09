# Database Seeding Guide

This guide explains how to populate your RotNot database with initial sample data.

## What Gets Seeded

The seed script creates:

### **User Profiles** (5 users)
- 1 Regular User
- 1 Hostel
- 1 Restaurant  
- 2 NGOs

### **Food Items** (5 items)
- Fresh items (rice, apples)
- Expiring items (milk, tomatoes)
- Expired items (bread)

### **Donations** (5 donations)
- Available donations (from hostel & restaurant)
- Claimed donations (by NGO)
- Completed donations
- Mix of donor types (HOSTEL, RESTAURANT, EVENT)

## How to Run

### Development (TypeScript)
```bash
cd backend
npm run seed
```

### Production (Compiled JS)
```bash
cd backend
npm run build
npm run seed:prod
```

## ⚠️ Warning

**The seed script will DELETE all existing data** before inserting sample data!

Only run this on:
- Fresh databases
- Development/testing environments
- When you want to reset your data

**DO NOT run this on production databases with real user data!**

## Sample Data Details

### User Credentials (Firebase UIDs)
- Regular User: `user_001`
- Hostel: `hostel_001`
- Restaurant: `restaurant_001`
- NGO 1: `ngo_001`
- NGO 2: `ngo_002`

### Food Categories
- Fruits & Vegetables
- Dairy
- Bakery
- Raw Food

### Donation Scenarios
1. **Active Hostel Donation** - 50 servings of rice, available for pickup
2. **Active Restaurant Donation** - 30 servings biryani, ready to claim
3. **Claimed Event Donation** - 20 sandwiches, claimed by NGO
4. **Completed Donation** - 40 pasta servings, already delivered
5. **Fresh Salads** - 25 salad bowls, just prepared

## Customizing Seed Data

To add your own sample data, edit `src/scripts/seed.ts`:

```typescript
const sampleUsers = [
  {
    firebaseUid: 'your_uid',
    role: UserRole.USER,
    name: 'Your Name',
    phone: '+1-555-0000',
  },
  // Add more...
];
```

## Troubleshooting

### Error: Cannot connect to database
- Ensure MongoDB is running
- Check your `.env` file has correct `MONGODB_URI`
- Verify network connection

### Error: Module not found
```bash
npm install
```

### Error: TypeScript compilation failed
```bash
npm run build
```

## Next Steps

After seeding:
1. Start your backend: `npm run dev`
2. Test the API endpoints
3. Verify data in MongoDB Compass or your database client
4. Use the sample Firebase UIDs for authentication testing
