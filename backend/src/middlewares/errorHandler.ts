import { Request, Response, NextFunction } from 'express';
import { ErrorResponse } from '../types';

class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

const errorHandler = (err: AppError | Error, _req: Request, res: Response, _next: NextFunction) => {
  let statusCode = 500;
  let message = 'Internal Server Error';
  let isOperational = false;

  if (err instanceof AppError) {
    statusCode = err.statusCode;
    message = err.message;
    isOperational = err.isOperational;
  } else if (err instanceof Error) {
    message = err.message;
  }

  const errorResponse: ErrorResponse = {
    success: false,
    message,
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  };

  console.error('Error:', {
    statusCode,
    message,
    isOperational,
    stack: err.stack,
  });

  res.status(statusCode).json(errorResponse);
};

export { AppError, errorHandler };
