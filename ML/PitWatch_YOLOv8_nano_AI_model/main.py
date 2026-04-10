from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
from io import BytesIO
from PIL import Image
from ultralytics import YOLO
import uvicorn

# 1. FastAPI app initialize karein
app = FastAPI(title="Pitwatch AI API", description="Severity-based Pothole Detection")

# 2. YOLOv8 ONNX model load karein (Ye server start hote hi ek baar load hoga)
model = YOLO("best.onnx", task="detect")

# 3. Input validation ke liye Pydantic Model (JSON structure define kar rahe hain)
class ImageRequest(BaseModel):
    image_base64: str
    confidence_threshold: float = 0.25

# 4. API Endpoint banayein
@app.post("/predict")
async def predict_pothole(request: ImageRequest):
    try:
        # Agar App Dev Base64 mein "data:image/jpeg;base64," laga kar bhejta hai, toh use hata dein
        base64_str = request.image_base64
        if "," in base64_str:
            base64_str = base64_str.split(",")[1]

        # Base64 string ko wapas Image mein convert karein
        image_data = base64.b64decode(base64_str)
        image = Image.open(BytesIO(image_data)).convert("RGB")

        # YOLO Model se prediction karwayein
        results = model.predict(image, conf=request.confidence_threshold)
        result = results[0] # Pehli (aur ek lauti) image ka result

        # Output JSON ke liye variables ready karein
        severity_counts = {"pothole_low": 0, "pothole_medium": 0, "pothole_high": 0}
        detections = []
        class_names = {0: "pothole_low", 1: "pothole_medium", 2: "pothole_high"}

        # Detections ko parse karein
        for box in result.boxes:
            cls_id = int(box.cls[0].item())
            conf = round(box.conf[0].item(), 2)
            # Coordinates nikalein
            x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
            
            cls_name = class_names.get(cls_id, "unknown")
            
            # Severity Count badhayein
            if cls_name in severity_counts:
                severity_counts[cls_name] += 1

            # Detections list mein add karein
            detections.append({
                "class_id": cls_id,
                "class_name": cls_name,
                "confidence": conf,
                "bounding_box": {"x_min": x1, "y_min": y1, "x_max": x2, "y_max": y2}
            })

        # App Developer ko clean JSON return karein
        return {
            "status": "success",
            "message": "Hazards detected successfully",
            "total_hazards": len(detections),
            "severity_counts": severity_counts,
            "detections": detections
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing image: {str(e)}")

# (Optional) Local par run karne ke liye
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)