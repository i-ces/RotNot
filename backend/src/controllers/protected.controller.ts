import { Request, Response } from 'express';
import { ApiResponse } from '../types';

/**
 * Example protected controller demonstrating Firebase authentication
 * This route requires Firebase token verification
 * Note: verifyFirebaseToken middleware ensures req.user exists
 */
export const getProtectedResource = (req: Request, res: Response) => {
  // User is guaranteed to exist due to verifyFirebaseToken middleware
  const { uid, email, name } = req.user!;

  const response: ApiResponse = {
    success: true,
    message: 'Access granted to protected resource',
    data: {
      userId: uid,
      email,
      name,
      timestamp: new Date().toISOString(),
    },
  };

  res.status(200).json(response);
};

/**
 * Example user profile endpoint
 */
export const getUserProfile = (req: Request, res: Response) => {
  const response: ApiResponse = {
    success: true,
    data: {
      profile: req.user,
    },
  };

  res.status(200).json(response);
};
