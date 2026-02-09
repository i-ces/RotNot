import cv2
import json
from pathlib import Path
from collections import Counter
from ultralytics import YOLO

# Configuration
CONFIDENCE_THRESHOLD = 0.5
MODEL_PATH = Path(__file__).parent / "yolov8n.pt"
OUTPUT_FILE = Path(__file__).parent / "detected_foods.json"

# COCO food classes (class_id: name)
FOOD_CLASSES = {
    46: "banana", 47: "apple", 48: "sandwich", 49: "orange",
    50: "broccoli", 51: "carrot", 52: "hot dog", 53: "pizza",
    54: "donut", 55: "cake"
}

def detect_foods(frame, model: YOLO) -> list[dict]:
    """Run detection and return only food items."""
    results = model(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
    
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

def save_results(detections: list[dict]):
    """Save unique foods to JSON."""
    food_summary = {}
    for item in detections:
        name = item["name"]
        if name not in food_summary or item["confidence"] > food_summary[name]["confidence"]:
            food_summary[name] = item.copy()
    
    counts = Counter(d["name"] for d in detections)
    for name in food_summary:
        food_summary[name]["count"] = counts[name]
    
    result = {"foods": list(food_summary.values())}
    with open(OUTPUT_FILE, "w") as f:
        json.dump(result, f, indent=2)
    return result

def main():
    model = YOLO(MODEL_PATH)
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("Error: Could not open camera")
        return
    
    print("Press Q to capture and quit")
    all_detections = []
    
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            foods = detect_foods(frame, model)
            all_detections.extend(foods)
            
            results = model(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
            annotated = results[0].plot()
            cv2.imshow("RotNot - Food Detection", annotated)
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()
        
        if all_detections:
            result = save_results(all_detections)
            print(f"Saved to {OUTPUT_FILE}:")
            for food in result["foods"]:
                print(f"  - {food['name']} ({food['confidence']:.0%})")
        else:
            print("No food detected")

if __name__ == "__main__":
    main()