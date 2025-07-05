import time
import asyncio
import torch

from torchvision.models import swin_t, Swin_T_Weights
from torchvision.transforms import Compose, Resize, ToTensor

from PIL import Image
from fastapi import FastAPI, File, UploadFile, Request, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = swin_t(weights=Swin_T_Weights.IMAGENET1K_V1).to(device)
transform = Compose([
    Resize((224, 224)),
    ToTensor()]
    )

app = FastAPI()

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration in seconds', ['method', 'endpoint'])

async def get_prediction(file: UploadFile):
    image = Image.open(file.file)
    input_tensor = transform(image).unsqueeze(0).to(device)

    # Track model prediction time
    with torch.inference_mode():
        output = model(input_tensor)
        
    _, predicted_class = torch.max(output, 1)
    class_names = Swin_T_Weights.IMAGENET1K_V1.meta["categories"]
    predicted_class_name = class_names[predicted_class]
    return {"class": predicted_class_name}

@app.post("/predict")
async def predict(file: UploadFile = File()):
    start_time = time.time()
    prediction = await get_prediction(file)
    end_time = time.time()

    REQUEST_DURATION.labels(method="POST", endpoint="/predict").observe(end_time - start_time)
    REQUEST_COUNT.labels(method="POST", endpoint="/predict", status=200).inc()
    return prediction

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "OK"}