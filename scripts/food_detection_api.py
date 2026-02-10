"""
Food Detection API Service
FastAPI server that accepts images and returns detected food items using YOLOv8
"""

import io
import base64
from pathlib import Path
from collections import Counter

import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from ultralytics import YOLO

# Configuration
CONFIDENCE_THRESHOLD = 0.5
MODEL_PATH = Path(__file__).parent / "yolov8n.pt"

# COCO food classes (class_id: name)
FOOD_CLASSES = {
    46: "banana", 47: "apple", 48: "sandwich", 49: "orange",
    50: "broccoli", 51: "carrot", 52: "hot dog", 53: "pizza",
    54: "donut", 55: "cake"
}

# Initialize FastAPI app
app = FastAPI(
    title="RotNot Food Detection API",
    description="Detect food items in images using YOLOv8",
    version="1.0.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model globally
model = None

def get_model():
    global model
    if model is None:
        print("Loading YOLOv8 model...")
        model = YOLO(MODEL_PATH)
        print("Model loaded successfully!")
    return model


class FoodItem(BaseModel):
    name: str
    confidence: float
    count: int = 1


class DetectionResponse(BaseModel):
    success: bool
    foods: list[FoodItem]
    message: str = ""


class Base64ImageRequest(BaseModel):
    image: str


def detect_foods_from_image(image: np.ndarray) -> list[dict]:
    """Run detection and return only food items."""
    yolo = get_model()
    results = yolo(image, conf=CONFIDENCE_THRESHOLD, verbose=False)
    
    foods = []
    for r in results:
        for box in r.boxes:
            cls_id = int(box.cls[0])
            if cls_id in FOOD_CLASSES:
                foods.append({
                    "name": FOOD_CLASSES[cls_id],
                    "confidence": round(float(box.conf[0]), 3)
                })
    return foods


def aggregate_detections(detections: list[dict]) -> list[FoodItem]:
    """Aggregate detections, keeping highest confidence per food type."""
    food_summary = {}
    for item in detections:
        name = item["name"]
        if name not in food_summary or item["confidence"] > food_summary[name]["confidence"]:
            food_summary[name] = item.copy()
    
    counts = Counter(d["name"] for d in detections)
    result = []
    for name, data in food_summary.items():
        result.append(FoodItem(
            name=name,
            confidence=data["confidence"],
            count=counts[name]
        ))
    
    return result


@app.get("/")
async def root():
    return {"message": "Food Detection API is running", "status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy", "model_loaded": model is not None}


@app.post("/detect", response_model=DetectionResponse)
async def detect_food(file: UploadFile = File(...)):
    """
    Detect food items in an uploaded image.
    
    Accepts: image file (JPEG, PNG)
    Returns: list of detected food items with confidence scores
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Could not decode image")
        
        detections = detect_foods_from_image(image)
        foods = aggregate_detections(detections)
        
        if not foods:
            return DetectionResponse(
                success=True,
                foods=[],
                message="No food items detected in the image"
            )
        
        return DetectionResponse(
            success=True,
            foods=foods,
            message=f"Detected {len(foods)} food type(s)"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/detect/base64", response_model=DetectionResponse)
async def detect_food_base64(data: Base64ImageRequest):
    """
    Detect food items from a base64 encoded image.
    
    Body: {"image": "base64_encoded_image_string"}
    """
    try:
        image_b64 = data.image
        if not image_b64:
            raise HTTPException(status_code=400, detail="No image data provided")
        
        print(f"Received base64 image, length: {len(image_b64)}")
        
        # Remove data URL prefix if present (e.g., "data:image/jpeg;base64,...")
        if "," in image_b64:
            image_b64 = image_b64.split(",")[1]
            print("Stripped data URL prefix")
        
        # Decode base64
        try:
            image_bytes = base64.b64decode(image_b64)
            print(f"Decoded to {len(image_bytes)} bytes")
        except Exception as decode_err:
            print(f"Base64 decode error: {decode_err}")
            raise HTTPException(status_code=400, detail=f"Invalid base64 encoding: {str(decode_err)}")
        
        # Convert to numpy array and decode image
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            print("Failed to decode image with OpenCV")
            raise HTTPException(status_code=400, detail="Could not decode image - invalid image format")
        
        print(f"Image decoded successfully: {image.shape}")
        
        # Run detection
        detections = detect_foods_from_image(image)
        print(f"Raw detections: {detections}")
        
        foods = aggregate_detections(detections)
        print(f"Aggregated foods: {[f.name for f in foods]}")
        
        if not foods:
            return DetectionResponse(
                success=True,
                foods=[],
                message="No food items detected in the image"
            )
        
        return DetectionResponse(
            success=True,
            foods=foods,
            message=f"Detected {len(foods)} food type(s)"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Detection error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    print("Starting Food Detection API on http://0.0.0.0:8000")
    print("Docs: http://0.0.0.0:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
