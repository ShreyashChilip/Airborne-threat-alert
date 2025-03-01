import cv2
import numpy as np
import matplotlib.pyplot as plt
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort
from filterpy.kalman import KalmanFilter

# Load YOLOv8 model with specific class filtering
model = YOLO("yolov8n.pt")  # Pretrained YOLOv8 model

# Define allowed classes (missile, drone, bird) based on YOLO class IDs
ALLOWED_CLASSES = {0: "missile", 1: "drone", 2: "bird"}  # Update with correct class IDs
CONFIDENCE_THRESHOLD = 0.5  # Minimum confidence to accept a detection

# Initialize DeepSORT tracker
tracker = DeepSort(max_age=30, n_init=3, nms_max_overlap=1.0)

# Initialize Kalman Filter for trajectory prediction
kf = KalmanFilter(dim_x=4, dim_z=2)
kf.F = np.array([[1, 1, 0, 0], [0, 1, 0, 0], [0, 0, 1, 1], [0, 0, 0, 1]])
kf.H = np.array([[1, 0, 0, 0], [0, 0, 1, 0]])
kf.P *= 1000  # Initial uncertainty
kf.R = np.array([[5, 0], [0, 5]])
kf.Q = np.array([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])

# Video input and output
cap = cv2.VideoCapture("sample.mp4")  # Change the filename
frame_width = int(cap.get(3))
frame_height = int(cap.get(4))

# Define video writer to save output with trajectories
out = cv2.VideoWriter("output_with_trajectory.mp4", cv2.VideoWriter_fourcc(*'mp4v'), 30, (frame_width, frame_height))

trajectories = {}

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    # Object detection with YOLO
    detections = model(frame)[0].boxes.data.cpu().numpy()
    detection_list = []
    
    for d in detections:
        class_id = int(d[5])
        confidence = float(d[4])
        if class_id in ALLOWED_CLASSES and confidence > CONFIDENCE_THRESHOLD:  # Filter only required classes
            detection_list.append((d[:4], confidence, class_id))  # Format: (bbox, confidence, class_id)
    
    # Object tracking with DeepSORT
    tracks = tracker.update_tracks(detection_list, frame=frame)
    
    for track in tracks:
        if not track.is_confirmed():
            continue
        
        track_id = track.track_id
        bbox = track.to_tlbr()
        x, y = int((bbox[0] + bbox[2]) / 2), int((bbox[1] + bbox[3]) / 2)
        
        # Kalman Filter Prediction
        kf.predict()
        kf.update(np.array([x, y]))
        predicted_x, predicted_y = map(int, kf.x[:2])  # Ensure values are scalars
        
        # Store trajectory
        if track_id not in trajectories:
            trajectories[track_id] = []
        trajectories[track_id].append((predicted_x, predicted_y))
        
        # Draw detection and prediction on frame
        cv2.rectangle(frame, (int(bbox[0]), int(bbox[1])), (int(bbox[2]), int(bbox[3])), (0, 255, 0), 2)
        cv2.circle(frame, (predicted_x, predicted_y), 5, (0, 0, 255), -1)
        cv2.putText(frame, f"ID {track_id} ({ALLOWED_CLASSES.get(class_id, 'Unknown')})", (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
        
    # Draw trajectory lines
    for track_id, trajectory in trajectories.items():
        for i in range(1, len(trajectory)):
            cv2.line(frame, trajectory[i-1], trajectory[i], (0, 255, 255), 2)
    
    # Save frame with trajectory to video
    out.write(frame)
    
    # REMOVE DISPLAY (Fix for headless Windows environment)
    # cv2.imshow("Tracking", frame)  # Removed
    

cap.release()
out.release()

print("Processing complete. Output saved as output_with_trajectory.mp4")