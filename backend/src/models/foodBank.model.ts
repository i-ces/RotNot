import mongoose, { Schema, Document } from 'mongoose';

export enum FoodBankType {
  COMMUNITY = 'community',
  CHARITY = 'charity',
  SHELTER = 'shelter',
}

export interface IFoodBank extends Document {
  name: string;
  type: FoodBankType;
  address: string;
  location: {
    type: string;
    coordinates: [number, number]; // [longitude, latitude]
  };
  phone?: string;
  openUntil?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const foodBankSchema = new Schema<IFoodBank>(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    type: {
      type: String,
      enum: Object.values(FoodBankType),
      required: [true, 'Type is required'],
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number],
        required: true,
      },
    },
    phone: {
      type: String,
      trim: true,
    },
    openUntil: {
      type: String,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Create geospatial index for location-based queries
foodBankSchema.index({ location: '2dsphere' });

const FoodBank = mongoose.model<IFoodBank>('FoodBank', foodBankSchema);

export default FoodBank;
