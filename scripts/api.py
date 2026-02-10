
import base64
from pathlib import Path
from collections import Counter

import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from ultralytics import YOLO

from receipe import generate_recipe_names, get_full_recipe

CONFIDENCE_THRESHOLD = 0.5
MODEL_PATH = Path(__file__).parent / "yolov8n.pt"

FOOD_CLASSES = {
    46: "banana", 47: "apple", 48: "sandwich", 49: "orange",
    50: "broccoli", 51: "carrot", 52: "hot dog", 53: "pizza",
    54: "donut", 55: "cake"
}

app = FastAPI(
    title="RotNot API",
    description="Unified API for food detection and recipe generation",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = None

def get_model():
    global model
    if model is None:
        model = YOLO(MODEL_PATH)
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


class RecipeNamesRequest(BaseModel):
    ingredients: list[str]
    num_recipes: int = 3


class RecipeNamesResponse(BaseModel):
    success: bool
    recipes: list[str]
    message: str = ""


class FullRecipeRequest(BaseModel):
    recipe_name: str
    available_ingredients: list[str] | None = None


class FullRecipeResponse(BaseModel):
    success: bool
    recipe_name: str
    full_description: str
    message: str = ""


def detect_foods_from_image(image: np.ndarray) -> list[dict]:
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
    return {"message": "RotNot API is running", "status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy", "model_loaded": model is not None}


@app.post("/detect", response_model=DetectionResponse)
async def detect_food(file: UploadFile = File(...)):
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
        
        return DetectionResponse(
            success=True,
            foods=foods,
            message=f"Detected {len(foods)} food type(s)" if foods else "No food items detected"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/detect/base64", response_model=DetectionResponse)
async def detect_food_base64(data: Base64ImageRequest):
    try:
        if not data.image:
            raise HTTPException(status_code=400, detail="No image data provided")
        
        image_b64 = data.image
        if "," in image_b64:
            image_b64 = image_b64.split(",")[1]
        
        try:
            image_bytes = base64.b64decode(image_b64)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid base64 encoding: {str(e)}")
        
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Could not decode image")
        
        detections = detect_foods_from_image(image)
        foods = aggregate_detections(detections)
        
        return DetectionResponse(
            success=True,
            foods=foods,
            message=f"Detected {len(foods)} food type(s)" if foods else "No food items detected"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/recipes/suggest", response_model=RecipeNamesResponse)
async def suggest_recipes(data: RecipeNamesRequest):
    try:
        if not data.ingredients:
            raise HTTPException(status_code=400, detail="No ingredients provided")
        
        recipe_names = generate_recipe_names(
            food_items=data.ingredients,
            num_recipes=data.num_recipes
        )
        
        return RecipeNamesResponse(
            success=True,
            recipes=recipe_names,
            message=f"Generated {len(recipe_names)} recipe suggestion(s)"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recipe generation failed: {str(e)}")


@app.post("/recipes/full", response_model=FullRecipeResponse)
async def get_recipe_details(data: FullRecipeRequest):
    try:
        if not data.recipe_name:
            raise HTTPException(status_code=400, detail="No recipe name provided")
        
        recipe = get_full_recipe(
            recipe_name=data.recipe_name,
            available_ingredients=data.available_ingredients
        )
        
        return FullRecipeResponse(
            success=True,
            recipe_name=recipe["recipe_name"],
            full_description=recipe["full_description"],
            message="Recipe generated successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recipe fetch failed: {str(e)}")


@app.post("/recipes/surprise", response_model=FullRecipeResponse)
async def surprise_recipe(data: RecipeNamesRequest):
    try:
        if not data.ingredients:
            raise HTTPException(status_code=400, detail="No ingredients provided")
        
        recipe_names = generate_recipe_names(food_items=data.ingredients, num_recipes=1)
        
        if not recipe_names:
            raise HTTPException(status_code=404, detail="Could not generate a recipe suggestion")
        
        recipe = get_full_recipe(
            recipe_name=recipe_names[0],
            available_ingredients=data.ingredients
        )
        
        return FullRecipeResponse(
            success=True,
            recipe_name=recipe["recipe_name"],
            full_description=recipe["full_description"],
            message="Surprise recipe generated!"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Surprise recipe failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
