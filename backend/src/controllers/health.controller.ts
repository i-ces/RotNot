import { Request, Response } from 'express';
import { ApiResponse } from '../types';

export const getHealth = (_req: Request, res: Response) => {
  const response: ApiResponse = {
    success: true,
    message: 'RotNot API is running',
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
    },
  };

  res.status(200).json(response);
};
