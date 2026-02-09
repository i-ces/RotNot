import mongoose, { Schema, Document } from 'mongoose';

export enum DonationStatus {
  PENDING = 'pending',
  SCHEDULED = 'scheduled',
  PICKED_UP = 'picked_up',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

export interface IDonation extends Document {
  donorId: string; // Firebase UID
  foodBankId: mongoose.Types.ObjectId;
  foodItems: Array<{
    foodItemId: mongoose.Types.ObjectId;
    name: string;
    quantity: number;
    unit: string;
  }>;
  status: DonationStatus;
  pickupScheduledAt?: Date;
  pickupCompletedAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const donationSchema = new Schema<IDonation>(
  {
    donorId: {
      type: String,
      required: [true, 'Donor ID is required'],
      index: true,
    },
    foodBankId: {
      type: Schema.Types.ObjectId,
      ref: 'FoodBank',
      required: [true, 'Food bank ID is required'],
    },
    foodItems: [
      {
        foodItemId: {
          type: Schema.Types.ObjectId,
          ref: 'FoodItem',
          required: true,
        },
        name: {
          type: String,
          required: true,
        },
        quantity: {
          type: Number,
          required: true,
        },
        unit: {
          type: String,
          required: true,
        },
      },
    ],
    status: {
      type: String,
      enum: Object.values(DonationStatus),
      default: DonationStatus.PENDING,
    },
    pickupScheduledAt: {
      type: Date,
    },
    pickupCompletedAt: {
      type: Date,
    },
    notes: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster lookups
donationSchema.index({ donorId: 1 });
donationSchema.index({ status: 1 });

const Donation = mongoose.model<IDonation>('Donation', donationSchema);

export default Donation;

const Donation = mongoose.model<IDonation>('Donation', donationSchema);

export default Donation;
