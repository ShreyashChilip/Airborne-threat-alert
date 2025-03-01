import os
import shutil
import uuid
import glob
from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import JSONResponse, FileResponse
from ultralytics import YOLO
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow all origins (for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Ensure YOLO model is loaded once
model = YOLO("best.pt")

# Define directories
UPLOAD_DIR = "/workspaces/BichdeHueDost_AB2_01/uploads"
OUTPUT_DIR = "/workspaces/BichdeHueDost_AB2_01/processed_videos"
YOLO_OUTPUT_DIR = "/workspaces/BichdeHueDost_AB2_01/runs/detect"

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

def process_video(video_path: str, output_dir: str):
    """Runs YOLO detection on the video, saves processed video, and returns detection log."""
    results = model.predict(source=video_path, conf=0.6, save=True, show=False)

    detection_log = []
    for result in results:
        frame_data = {"detections": []}
        if hasattr(result, "boxes"):
            for box in result.boxes:
                frame_data["detections"].append({
                    "class": model.names[int(box.cls)],
                    "confidence": float(box.conf),
                    "bounding_box": box.xyxy.tolist()
                })
        detection_log.append(frame_data)

    # Find the latest predict folder
    predict_dirs = sorted(glob.glob(os.path.join(YOLO_OUTPUT_DIR, "predict*")), key=os.path.getmtime, reverse=True)
    latest_predict_dir = predict_dirs[0] if predict_dirs else None

    if latest_predict_dir:
        # Find the processed AVI file inside predict folder
        avi_files = glob.glob(os.path.join(latest_predict_dir, "*.avi"))
        if avi_files:
            processed_video_path = os.path.join(output_dir, os.path.basename(video_path).replace(".mp4", ".avi"))
            shutil.move(avi_files[0], processed_video_path)
            return detection_log, processed_video_path

    return detection_log, None

@app.post("/process-video/")
async def process_uploaded_video(request: Request, video: UploadFile = File(...)):
    """API endpoint to process uploaded video, return detection log, and processed video."""
    unique_filename = f"{uuid.uuid4()}_{video.filename}"
    input_video_path = os.path.join(UPLOAD_DIR, unique_filename)

    with open(input_video_path, "wb") as buffer:
        shutil.copyfileobj(video.file, buffer)

    # Run YOLO detection
    detection_log, processed_video_path = process_video(input_video_path, OUTPUT_DIR)

    response_data = {"detection_log": detection_log}

    if processed_video_path:
        full_download_url = 'https://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/' + f"download/{os.path.basename(processed_video_path)}"
        response_data["download_url"] = full_download_url  # Return full URL

    return response_data

@app.get("/download/{file_name}")
def download_processed_video(file_name: str):
    """Endpoint to download the processed video."""
    file_path = os.path.join(OUTPUT_DIR, file_name)
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="video/x-msvideo", filename=file_name)  # Correct media type for AVI
    return JSONResponse(status_code=404, content={"error": "File not found"})


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)