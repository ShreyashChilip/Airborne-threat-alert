import shutil
import os
from ultralytics import YOLO


# Get the file name
video_path = 'birds-flying.mp4'
print(f"Uploaded Video: {video_path}")

# Load your trained model
model = YOLO("best.pt")  # Ensure best.pt is in the correct directory

# Run detection on the uploaded video
results = model.predict(
    source=video_path,  # Video file name
    conf=0.4,  # Confidence threshold
    save=True,  # Save output video
    show=False  # Set to True if running locally to display output
)

# Define the directory where YOLO saves predictions
yolo_output_dir = "/content/runs/detect/predict"

# Find the latest generated video file
output_files = [f for f in os.listdir(yolo_output_dir) if f.endswith(".mp4")]
if output_files:
    output_video_path = os.path.join(yolo_output_dir, output_files[0])
    destination_path = f"/content/{output_files[0]}"

    # Move the file to the root directory (/content/)
    shutil.move(output_video_path, destination_path)
    print(f"Output video saved to: {destination_path}")

    # Provide download link
    files.download(destination_path)
else:
    print("No output video found!")
