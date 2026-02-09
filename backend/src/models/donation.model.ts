import mongoose, { Schema, Document } from 'mongoose';

export enum DonorType {
  HOSTEL = 'hostel',
  RESTAURANT = 'restaurant',
  EVENT = 'event',
}

export enum DonationStatus {
  AVAILABLE = 'available',
  CLAIMED = 'claimed',
  COMPLETED = 'completed',
}

export interface IDonation extends Document {
  foodName: string;
  quantity: string;
  preparedAt: Date;
  expiryTime: Date;
  donorType: DonorType;
  location: string;
  donorName: string;
  donorPhone: string;
  pickupAddress: string;
  status: DonationStatus;
  donorId: string;
  claimedBy?: string;
}

const donationSchema = new Schema<IDonation>(
  {
    foodName: {
      type: String,
      required: [true, 'Food name is required'],
      trim: true,
    },
    quantity: {
      type: String,
      required: [true, 'Quantity is required'],
      trim: true,
    },
    preparedAt: {
      type: Date,
      required: [true, 'Prepared at time is required'],
    },
    expiryTime: {
      type: Date,
      required: [true, 'Expiry time is required'],
    },
    donorType: {
      type: String,
      required: [true, 'Donor type is required'],
      enum: Object.values(DonorType),
    },
    location: {
      type: String,
      required: [true, 'Location is required'],
      trim: true,
    },
    donorName: {
      type: String,
      required: [true, 'Donor name is required'],
      trim: true,
    },
    donorPhone: {
      type: String,
      required: [true, 'Donor phone is required'],
      trim: true,
    },
    pickupAddress: {
      type: String,
      required: [true, 'Pickup address is required'],
      trim: true,
    },
    status: {
      type: String,
      enum: Object.values(DonationStatus),
      default: DonationStatus.AVAILABLE,
    },
    donorId: {
      type: String,
      required: [true, 'Donor ID is required'],
      index: true,
    },
    claimedBy: {
      type: String,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster lookups
donationSchema.index({ donorId: 1 });
donationSchema.index({ claimedBy: 1 });
donationSchema.index({ status: 1 });
donationSchema.index({ expiryTime: 1 });

const Donation = mongoose.model<IDonation>('Donation', donationSchema);

export default Donation;
