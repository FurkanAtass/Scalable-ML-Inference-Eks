import torch

from torchvision.models import swin_t, Swin_T_Weights
from torchvision.transforms import Compose, Resize, ToTensor

from PIL import Image
from fastapi import FastAPI, File, UploadFile

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = swin_t(weights=Swin_T_Weights.IMAGENET1K_V1).to(device)

transform = Compose([
    Resize((224, 224)),
    ToTensor()]
    )

app = FastAPI()

@app.post("/predict")
async def predict(file: UploadFile = File()):
    image = Image.open(file.file)
    input_tensor = transform(image).unsqueeze(0).to(device)

    with torch.inference_mode():
        output = model(input_tensor)
        
    _, predicted_class = torch.max(output, 1)
    class_names = Swin_T_Weights.IMAGENET1K_V1.meta["categories"]

    return {"class": class_names[predicted_class]}