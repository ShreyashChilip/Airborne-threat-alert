from ultralytics import YOLO

# Load a YOLO model (Pre-trained or new)
model = YOLO("yolov8n.pt")  # You can change to yolov8s.pt, yolov8m.pt, etc.

# Train the model
results = model.train(
    data="datasets/final/data.yaml",  # Path to dataset configuration
    epochs=100,                        # Number of training epochs
    batch=16,                           # Adjust based on GPU memory
    imgsz=640,                          # Use GPU if available
)

print("Training Complete! Model saved in 'runs/detect/train'")
