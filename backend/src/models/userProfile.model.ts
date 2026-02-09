import mongoose, { Schema, Document } from 'mongoose';

export enum UserRole {
  USER = 'user',
  HOSTEL = 'hostel',
  RESTAURANT = 'restaurant',
  NGO = 'ngo',
}

export interface IUserProfile extends Document {
  firebaseUid: string;
  role: UserRole;
  name: string;
  email?: string;
  phone?: string;
  createdAt: Date;
}

const userProfileSchema = new Schema<IUserProfile>(
  {
    firebaseUid: {
      type: String,
      required: [true, 'Firebase UID is required'],
      unique: true,
      index: true,
    },
    role: {
      type: String,
      required: [true, 'Role is required'],
      enum: Object.values(UserRole),
    },
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    phone: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster lookups
userProfileSchema.index({ firebaseUid: 1 });

const UserProfile = mongoose.model<IUserProfile>('UserProfile', userProfileSchema);

export default UserProfile;
