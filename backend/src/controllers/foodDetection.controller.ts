import { Request, Response } from 'express';

const PYTHON_API_URL = process.env.PYTHON_API_URL || 'http://localhost:8000';

interface FoodItem {
  name: string;
  confidence: number;
  count: number;
}

interface DetectionResponse {
  success: boolean;
  foods: FoodItem[];
  message: string;
}

/**
 * Detect food from base64 image
 * POST /api/food-detection/detect
 */
export const detectFood = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { image } = req.body;

    if (!image) {
      console.log('No image data in request body');
      res.status(400).json({
        success: false,
        message: 'No image data provided',
      });
      return;
    }

    console.log(`Received image data, length: ${image.length} chars`);

    // Forward request to Python API
    console.log(`Forwarding to Python API at ${PYTHON_API_URL}/detect/base64`);
    const response = await fetch(`${PYTHON_API_URL}/detect/base64`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ image }),
    });

    console.log(`Python API response status: ${response.status}`);

    if (!response.ok) {
      const error = await response.json() as { detail?: string };
      console.log(`Python API error: ${error.detail}`);
      res.status(response.status).json({
        success: false,
        message: error.detail || 'Detection failed',
      });
      return;
    }

    const data = await response.json() as DetectionResponse;
    console.log(`Detection result: ${data.message}, foods: ${data.foods.length}`);

    res.status(200).json({
      success: true,
      message: data.message,
      data: {
        foods: data.foods,
      },
    });
  } catch (error) {
    console.error('Food detection error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to connect to detection service',
    });
  }
};

/**
 * Check Python API health
 * GET /api/food-detection/health
 */
export const checkDetectionHealth = async (
  _req: Request,
  res: Response
): Promise<void> => {
  try {
    const response = await fetch(`${PYTHON_API_URL}/health`);
    
    if (!response.ok) {
      res.status(503).json({
        success: false,
        message: 'Detection service unavailable',
      });
      return;
    }

    const data = await response.json();
    res.status(200).json({
      success: true,
      message: 'Detection service is healthy',
      data,
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'Detection service unavailable',
    });
  }
};
