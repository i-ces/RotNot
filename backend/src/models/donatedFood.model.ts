import mongoose, { Schema, Document } from 'mongoose';

export interface IDonatedFood extends Document {
  name: string;
  category: string;
  quantity: number;
  unit: string;
  addedAt: Date;
  expiryDate: Date;
  donatedAt: Date;
  originalOwnerId: string;
  donationId: mongoose.Types.ObjectId;
  foodBankId: mongoose.Types.ObjectId;
}

const donatedFoodSchema = new Schema<IDonatedFood>(
  {
    name: {
      type: String,
      required: [true, 'Food item name is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [0, 'Quantity must be a positive number'],
    },
    unit: {
      type: String,
      required: [true, 'Unit is required'],
      trim: true,
    },
    addedAt: {
      type: Date,
      required: true,
    },
    expiryDate: {
      type: Date,
      required: [true, 'Expiry date is required'],
    },
    donatedAt: {
      type: Date,
      default: Date.now,
    },
    originalOwnerId: {
      type: String,
      required: [true, 'Original owner ID is required'],
      index: true,
    },
    donationId: {
      type: Schema.Types.ObjectId,
      ref: 'Donation',
      required: [true, 'Donation ID is required'],
      index: true,
    },
    foodBankId: {
      type: Schema.Types.ObjectId,
      ref: 'FoodBank',
      required: [true, 'Food bank ID is required'],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster lookups
donatedFoodSchema.index({ originalOwnerId: 1 });
donatedFoodSchema.index({ donationId: 1 });
donatedFoodSchema.index({ foodBankId: 1 });
donatedFoodSchema.index({ donatedAt: 1 });

const DonatedFood = mongoose.model<IDonatedFood>('DonatedFood', donatedFoodSchema);

export default DonatedFood;
