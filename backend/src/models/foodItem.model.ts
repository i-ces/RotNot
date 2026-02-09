import mongoose, { Schema, Document } from 'mongoose';

export enum FoodStatus {
  FRESH = 'fresh',
  EXPIRING = 'expiring',
  EXPIRED = 'expired',
  DONATED = 'donated',
  CONSUMED = 'consumed',
}

export interface IFoodItem extends Document {
  name: string;
  category: string;
  quantity: number;
  unit: string;
  addedAt: Date;
  expiryDate: Date;
  status: FoodStatus;
  ownerId: string;
}

const foodItemSchema = new Schema<IFoodItem>(
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
      default: Date.now,
    },
    expiryDate: {
      type: Date,
      required: [true, 'Expiry date is required'],
    },
    status: {
      type: String,
      enum: Object.values(FoodStatus),
      default: FoodStatus.FRESH,
    },
    ownerId: {
      type: String,
      required: [true, 'Owner ID is required'],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster lookups
foodItemSchema.index({ ownerId: 1 });
foodItemSchema.index({ status: 1 });
foodItemSchema.index({ expiryDate: 1 });

const FoodItem = mongoose.model<IFoodItem>('FoodItem', foodItemSchema);

export default FoodItem;
