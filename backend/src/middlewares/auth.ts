import { Request, Response, NextFunction } from 'express';
import { auth } from '../config/firebase';
import { AppError } from './errorHandler';
import UserProfile, { UserRole } from '../models/userProfile.model';

// User information attached to request
export interface RequestUser {
  uid: string;
  email?: string;
  name?: string;
}

// Request with authenticated user
export interface RequestWithUser extends Request {
  user: RequestUser;
}

// Extend Express Request to include user info
declare global {
  namespace Express {
    interface Request {
      user?: RequestUser;
    }
  }
}

/**
 * Middleware to verify Firebase ID token from Authorization header
 * Usage: Add to routes that require authentication
 * Example: router.get('/protected', verifyFirebaseToken, controller);
 */
export const verifyFirebaseToken = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Check if Firebase Admin is initialized
    if (!auth) {
      throw new AppError('Firebase Admin SDK is not initialized', 500);
    }

    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided. Please provide a valid Firebase ID token.', 401);
    }

    // Extract token
    const token = authHeader.split('Bearer ')[1];

    if (!token) {
      throw new AppError('Invalid token format', 401);
    }

    // Verify the Firebase ID token
    const decodedToken = await auth.verifyIdToken(token);

    // Auto-create user profile if it doesn't exist
    let userProfile = await UserProfile.findOne({ firebaseUid: decodedToken.uid });
    
    if (!userProfile) {
      userProfile = await UserProfile.create({
        firebaseUid: decodedToken.uid,
        role: UserRole.USER,
        name: decodedToken.name || 'User',
        email: decodedToken.email,
        phone: decodedToken.phone_number || '',
      });
    }

    // Attach user info to request object
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      name: decodedToken.name,
    };

    // Continue to next middleware/controller
    next();
  } catch (error) {
    if (error instanceof AppError) {
      next(error);
    } else if (error instanceof Error) {
      // Handle Firebase-specific errors
      if (error.message.includes('auth/id-token-expired')) {
        next(new AppError('Token has expired. Please login again.', 401));
      } else if (error.message.includes('auth/id-token-revoked')) {
        next(new AppError('Token has been revoked. Please login again.', 401));
      } else if (error.message.includes('auth/invalid-id-token')) {
        next(new AppError('Invalid token. Please provide a valid Firebase ID token.', 401));
      } else {
        next(new AppError('Failed to authenticate token', 401));
      }
    } else {
      next(new AppError('Authentication failed', 401));
    }
  }
};

/**
 * Optional middleware to verify Firebase token but don't fail if not present
 * This allows routes to work for both authenticated and unauthenticated users
 */
export const optionalFirebaseAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ') || !auth) {
      // No token or Firebase not initialized, continue without user
      next();
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    
    if (token) {
      const decodedToken = await auth.verifyIdToken(token);
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        name: decodedToken.name,
      };
    }
  } catch (error) {
    // Silently fail for optional auth
    console.error('Optional auth failed:', error);
  }
  
  next();
};
