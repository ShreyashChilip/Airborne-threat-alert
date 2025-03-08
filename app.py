<<<<<<< HEAD
import os
import shutil
import uuid
import glob
import json
import time
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import JSONResponse, FileResponse
from ultralytics import YOLO
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="AeroSentinel API",
    description="AI-powered airborne threat detection system for security and defense operations",
    version="1.0.0"
)

# Allow all origins (for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLO model - using your trained model for airborne threat detection
model = YOLO("best.pt")  # Assuming you've trained this on birds, drones, missiles

# Define directories
UPLOAD_DIR = "uploads"
OUTPUT_DIR = "processed_videos"
YOLO_OUTPUT_DIR = "runs/detect"
LOG_DIR = "detection_logs"

# Create necessary directories
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# Class name to threat level mapping
THREAT_LEVELS = {
    "bird": "Low",
    "drone": "High",
    "missile": "Critical"
}

def process_video(video_path: str, output_dir: str):
    """
    Runs YOLO detection on surveillance footage to identify airborne threats.
    
    Args:
        video_path: Path to the surveillance video
        output_dir: Directory to save the processed video with annotations
        
    Returns:
        Tuple containing detection log and path to processed video
    """
    # Start timing for performance metrics
    start_time = time.time()
    
    # Process with YOLO model optimized for airborne threat detection
    results = model.predict(source=video_path, conf=0.6, save=True, show=False)

    # Initialize detection log with metadata
    detection_log = []
    threat_summary = {
        "birds": 0,
        "drones": 0,
        "missiles": 0,
        "highest_threat_level": "None"
    }
    
    # Process each frame result
    for frame_idx, result in enumerate(results):
        frame_data = {
            "frame_id": frame_idx,
            "timestamp": frame_idx / 30.0,  # Assuming 30fps video
            "detections": []
        }
        
        if hasattr(result, "boxes") and len(result.boxes) > 0:
            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = model.names[class_id]
                confidence = float(box.conf[0])
                
                # Create detection entry
                detection_entry = {
                    "class": class_name,
                    "confidence": confidence,
                    "bounding_box": box.xyxy[0].tolist(),
                    "threat_level": THREAT_LEVELS.get(class_name.lower(), "Unknown")
                }
                
                # Add trajectory data if available (placeholder)
                detection_entry["trajectory"] = {
                    "velocity": "medium",  # You would calculate this for real deployment
                    "direction": "northeast",  # You would calculate this for real deployment
                }
                
                frame_data["detections"].append(detection_entry)
                
                # Update threat summary
                if "bird" in class_name.lower():
                    threat_summary["birds"] += 1
                elif "drone" in class_name.lower():
                    threat_summary["drones"] += 1
                    if threat_summary["highest_threat_level"] in ["None", "Low"]:
                        threat_summary["highest_threat_level"] = "High"
                elif "missile" in class_name.lower():
                    threat_summary["missiles"] += 1
                    threat_summary["highest_threat_level"] = "Critical"
        
        detection_log.append(frame_data)

    # Calculate processing performance
    end_time = time.time()
    processing_time = end_time - start_time
    fps = len(results) / processing_time if processing_time > 0 else 0
    
    # Add performance metrics and threat summary to log
    detection_metadata = {
        "processing_time_seconds": processing_time,
        "processed_fps": fps,
        "video_length_seconds": len(results) / 30.0,  # Assuming 30fps
        "threat_summary": threat_summary,
        "analysis_timestamp": datetime.now().isoformat()
    }

    # Find the processed video from YOLO output
    predict_dirs = sorted(glob.glob(os.path.join(YOLO_OUTPUT_DIR, "predict*")), key=os.path.getmtime, reverse=True)
    latest_predict_dir = predict_dirs[0] if predict_dirs else None
    processed_video_path = None
    
    if latest_predict_dir:
        # Find the processed AVI file inside predict folder
        avi_files = glob.glob(os.path.join(latest_predict_dir, "*.avi"))
        mp4_files = glob.glob(os.path.join(latest_predict_dir, "*.mp4"))
        video_files = avi_files + mp4_files
        
        if video_files:
            output_filename = f"aerosentinel_{os.path.basename(video_path)}"
            if output_filename.endswith('.mp4'):
                output_filename = output_filename.replace('.mp4', '.avi')
            processed_video_path = os.path.join(output_dir, output_filename)
            shutil.move(video_files[0], processed_video_path)
            
    # Save detailed detection log to file
    log_filename = f"detection_log_{uuid.uuid4()}.json"
    log_path = os.path.join(LOG_DIR, log_filename)
    with open(log_path, 'w') as f:
        json.dump({"metadata": detection_metadata, "frames": detection_log}, f, indent=2)
            
    return detection_log, detection_metadata, processed_video_path

@app.post("/process-video/")
async def process_uploaded_video(request: Request, video: UploadFile = File(...)):
    """
    API endpoint to process surveillance footage for airborne threat detection.
    
    Returns a detailed analysis of detected objects and a download link for the annotated video.
    """
    # Generate unique filename to prevent conflicts
    unique_filename = f"{uuid.uuid4()}_{video.filename}"
    input_video_path = os.path.join(UPLOAD_DIR, unique_filename)

    # Save uploaded video
    with open(input_video_path, "wb") as buffer:
        shutil.copyfileobj(video.file, buffer)

    # Process video with YOLO model
    detection_log, metadata, processed_video_path = process_video(input_video_path, OUTPUT_DIR)

    # Prepare response data
    response_data = {
        "status": "success",
        "message": "Surveillance footage processed successfully",
        "metadata": metadata,
        "detection_log": detection_log
    }

    # Add download URL if processing was successful
    if processed_video_path:
        base_url = str(request.base_url)
        # Using the same URL you provided in your code
        full_download_url = f'https://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/download/{os.path.basename(processed_video_path)}'
        response_data["download_url"] = full_download_url

    return response_data

@app.get("/download/{file_name}")
def download_processed_video(file_name: str):
    """Endpoint to download the processed video with threat annotations."""
    file_path = os.path.join(OUTPUT_DIR, file_name)
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="video/x-msvideo", filename=file_name)
    return JSONResponse(status_code=404, content={"error": "Processed surveillance footage not found"})

@app.get("/health")
def health_check():
    """Simple health check endpoint."""
    return {"status": "healthy", "model": "loaded", "version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn
=======
import os
import shutil
import uuid
import glob
import json
import time
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, Request, HTTPException, WebSocket
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import cv2
import numpy as np
import asyncio
from typing import List, Dict
from collections import deque
import math

app = FastAPI(
    title="AeroSentinel API",
    description="AI-powered airborne threat detection system for security and defense operations",
    version="1.0.0"
)

# Increase max upload size to 500MB
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add this after the middleware configuration
from fastapi.middleware.trustedhost import TrustedHostMiddleware
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["*"])

# Configure maximum upload size (500MB)
import math
from starlette.middleware.base import BaseHTTPMiddleware

class LargeUploadMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if request.method == "POST":
            request.state.max_content_length = 500 * 1024 * 1024  # 500MB
        return await call_next(request)

app.add_middleware(LargeUploadMiddleware)

# Load YOLO model - using your trained model for airborne threat detection
model = YOLO("best-ram.pt")  # Assuming you've trained this on birds, drones, missiles

# Define directories
UPLOAD_DIR = "uploads"
OUTPUT_DIR = "processed_videos"
YOLO_OUTPUT_DIR = "runs/detect"
LOG_DIR = "detection_logs"

# Create necessary directories
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# Class name to threat level mapping
THREAT_LEVELS = {
    "bird": "Low",
    "drone": "High",
    "missile": "Critical",
    'hot air balloon': "High", 'paraglider': "High", 'airplane': "Critical", 'car': "High", 'fighter jet': "Critical", 'helicopter': "Critical", 'landing deck': "Critical", 'person': "High", 'ship': "High"
}

# Shared in-memory storage for alerts (replace with a database in production)
alerts: List[Dict] = []

# Remove these functions and variables
# HISTORY_LENGTH, object_history, last_frame_time, calculate_movement_vector

# WebSocket endpoint for real-time video processing
@app.websocket("/ws/video-stream")
async def websocket_video_stream(websocket: WebSocket):
    """
    WebSocket endpoint for real-time video streaming and processing.
    """
    await websocket.accept()
    print("WebSocket connection established")

    try:
        while True:
            # Receive video frame data from the client
            data = await websocket.receive_bytes()
            frame = np.frombuffer(data, dtype=np.uint8)
            frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)

            if frame is None:
                await websocket.send_json({"error": "Invalid frame data"})
                continue

            # Perform object detection on the frame
            results = model.predict(source=frame, conf=0.6)

            # Prepare detection results
            detections = []
            for result in results:
                for box in result.boxes:
                    class_id = int(box.cls[0])
                    class_name = model.names[class_id]
                    confidence = float(box.conf[0])
                    bbox = box.xyxy[0].tolist()

                    detection = {
                        "object_class": class_name,
                        "confidence": confidence,
                        "bounding_box": bbox,
                        "threat_level": THREAT_LEVELS.get(class_name.lower(), "Unknown")
                    }

                    detections.append(detection)

                    # Add detection to alerts list
                    alerts.append(detection)

            # Send detection results back to the client
            await websocket.send_json({
                "status": "success",
                "detections": detections
            })

    except Exception as e:
        print(f"WebSocket error: {e}")
        await websocket.send_json({"error": str(e)})
    finally:
        await websocket.close()
        print("WebSocket connection closed")

# Endpoint for processing a single video frame
@app.post("/process-frame/")
async def process_frame(file: UploadFile = File(...)):
    """
    Process a single video frame sent as an image file.
    Returns detection results for the frame.
    """
    try:
        # Read the image file
        contents = await file.read()
        frame = np.frombuffer(contents, dtype=np.uint8)
        frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)

        if frame is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Get frame dimensions
        height, width, _ = frame.shape

        # Process the frame with YOLO
        results = model.predict(source=frame, conf=0.6)

        # Prepare detection results
        detections = []
        current_time = time.time()
        for result in results:
            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = model.names[class_id]
                confidence = float(box.conf[0])
                detection = process_detection(box, class_name, confidence, (width, height), current_time)
                detections.append(detection)

                # Add detection to alerts list
                alerts.append(detection)

        return JSONResponse({
            "status": "success",
            "detections": detections
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/alerts")
def get_alerts():
    """
    Fetch the list of detected threats (alerts).
    """
    return JSONResponse({
        "status": "success",
        "alerts": alerts
    })

# Health check endpoint
@app.get("/health")
def health_check():
    """Simple health check endpoint."""
    return {"status": "healthy", "model": "loaded", "version": "1.0.0"}

def process_video(video_path: str, output_dir: str):
    """
    Runs YOLO detection on surveillance footage to identify airborne threats.
    """
    start_time = time.time()
    frame_count = 0
    
    # Initialize detection log with metadata
    detection_log = []
    
    # Updated threat summary to include all classes
    threat_summary = {
        "bird": 0,
        "drone": 0,
        "missile": 0,
        "hot air balloon": 0,
        "paraglider": 0,
        "airplane": 0,
        "car": 0,
        "fighter jet": 0,
        "helicopter": 0,
        "landing deck": 0,
        "person": 0,
        "ship": 0,
        "highest_threat_level": "None"
    }
    
    # Process video with frame skipping
    results = model.predict(
        source=video_path, 
        conf=0.6, 
        save=True, 
        show=False,
        stream=True,
        vid_stride=4
    )
    
    for frame_idx, result in enumerate(results):
        frame_count += 1
        frame_data = {
            "frame_id": frame_idx * 4,
            "timestamp": (frame_idx * 4) / 30.0,
            "detections": []
        }
        
        if hasattr(result, "boxes") and len(result.boxes) > 0:
            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = model.names[class_id].lower()
                confidence = float(box.conf[0])
                
                # Create detection entry
                detection_entry = {
                    "class": class_name,
                    "confidence": confidence,
                    "bounding_box": box.xyxy[0].tolist(),
                    "threat_level": THREAT_LEVELS.get(class_name, "Unknown")
                }
                
                # Add trajectory data
                detection_entry["trajectory"] = {
                    "velocity": "medium",
                    "direction": "northeast",
                }
                
                frame_data["detections"].append(detection_entry)
                
                # Update threat summary for all classes
                if class_name in threat_summary:
                    threat_summary[class_name] += 1
                    
                    # Update highest threat level
                    current_threat = THREAT_LEVELS.get(class_name, "Unknown")
                    if current_threat == "Critical":
                        threat_summary["highest_threat_level"] = "Critical"
                    elif current_threat == "High" and threat_summary["highest_threat_level"] in ["None", "Low"]:
                        threat_summary["highest_threat_level"] = "High"
                    elif current_threat == "Low" and threat_summary["highest_threat_level"] == "None":
                        threat_summary["highest_threat_level"] = "Low"
        
        detection_log.append(frame_data)

    # Calculate processing performance
    end_time = time.time()
    processing_time = end_time - start_time
    fps = frame_count / processing_time if processing_time > 0 else 0
    
    # Add performance metrics and threat summary to log
    detection_metadata = {
        "processing_time_seconds": processing_time,
        "processed_fps": fps,
        "frames_processed": frame_count,
        "video_length_seconds": (frame_count * 4) / 30.0,
        "threat_summary": threat_summary,
        "analysis_timestamp": datetime.now().isoformat(),
        "detection_statistics": {
            "total_detections": sum(threat_summary[k] for k in threat_summary if k != "highest_threat_level"),
            "threat_levels": {
                "Critical": sum(1 for k in threat_summary if k != "highest_threat_level" 
                              and THREAT_LEVELS.get(k, "Unknown") == "Critical"),
                "High": sum(1 for k in threat_summary if k != "highest_threat_level" 
                          and THREAT_LEVELS.get(k, "Unknown") == "High"),
                "Low": sum(1 for k in threat_summary if k != "highest_threat_level" 
                         and THREAT_LEVELS.get(k, "Unknown") == "Low")
            }
        }
    }

    # Process output video file
    predict_dirs = sorted(glob.glob(os.path.join(YOLO_OUTPUT_DIR, "predict*")), key=os.path.getmtime, reverse=True)
    latest_predict_dir = predict_dirs[0] if predict_dirs else None
    processed_video_path = None
    
    if latest_predict_dir:
        avi_files = glob.glob(os.path.join(latest_predict_dir, "*.avi"))
        mp4_files = glob.glob(os.path.join(latest_predict_dir, "*.mp4"))
        video_files = avi_files + mp4_files
        
        if video_files:
            output_filename = f"aerosentinel_{os.path.basename(video_path)}"
            if output_filename.endswith('.mp4'):
                output_filename = output_filename.replace('.mp4', '.avi')
            processed_video_path = os.path.join(output_dir, output_filename)
            shutil.move(video_files[0], processed_video_path)
    
    # Save detection log
    log_filename = f"detection_log_{uuid.uuid4()}.json"
    log_path = os.path.join(LOG_DIR, log_filename)
    with open(log_path, 'w') as f:
        json.dump({"metadata": detection_metadata, "frames": detection_log}, f, indent=2)
            
    return detection_log, detection_metadata, processed_video_path

@app.post("/process-video/")
async def process_uploaded_video(request: Request, video: UploadFile = File(...)):
    """
    API endpoint to process surveillance footage for airborne threat detection.
    
    Returns a detailed analysis of detected objects and a download link for the annotated video.
    """
    # Generate unique filename to prevent conflicts
    unique_filename = f"{uuid.uuid4()}_{video.filename}"
    input_video_path = os.path.join(UPLOAD_DIR, unique_filename)

    # Save uploaded video
    with open(input_video_path, "wb") as buffer:
        shutil.copyfileobj(video.file, buffer)

    # Process video with YOLO model
    detection_log, metadata, processed_video_path = process_video(input_video_path, OUTPUT_DIR)

    # Prepare response data
    response_data = {
        "status": "success",
        "message": "Surveillance footage processed successfully",
        "metadata": metadata,
        "detection_log": detection_log
    }

    # Add download URL if processing was successful
    if processed_video_path:
        base_url = str(request.base_url)
        # Using the same URL you provided in your code
        full_download_url = f'https://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/download/{os.path.basename(processed_video_path)}'
        response_data["download_url"] = full_download_url

    return response_data

def process_detection(box, class_name, confidence, frame_dims, current_time):
    """Process a single detection for radar display"""
    width, height = frame_dims
    bbox = box.xyxy[0].tolist()
    
    # Calculate center point
    center_x = (bbox[0] + bbox[2]) / 2 / width  # Normalize to [0,1]
    center_y = (bbox[1] + bbox[3]) / 2 / height  # Normalize to [0,1]
    
    # Normalize bounding box
    normalized_bbox = [
        bbox[0] / width,
        bbox[1] / height,
        bbox[2] / width,
        bbox[3] / height
    ]
    
    return {
        "object_class": class_name,
        "confidence": confidence,
        "bounding_box": normalized_bbox,
        "threat_level": THREAT_LEVELS.get(class_name.lower(), "Unknown"),
        "position": {
            "x": center_x,
            "y": center_y
        },
        "timestamp": current_time
    }

if __name__ == "__main__":
    import uvicorn
>>>>>>> e43f7ae9 (Final commit, uploading flutter app code)
    uvicorn.run(app, host="0.0.0.0", port=8000)