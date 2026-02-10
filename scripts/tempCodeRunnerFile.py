from fastapi import FastAPI

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

print(f"✓ FastAPI app created: {app.title}")
print(f"✓ Food classes: {', '.join(FOOD_CLASSES.values())}")
