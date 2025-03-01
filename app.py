import cv2
import numpy as np
import matplotlib.pyplot as plt
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort
from filterpy.kalman import KalmanFilter
model = YOLO("yolov8n.pt")  

ALLOWED_CLASSES = {0: "missile", 1: "drone", 2: "bird"}  

tracker = DeepSort(max_age=30, n_init=3, nms_max_overlap=1.0)

kf = KalmanFilter(dim_x=4, dim_z=2)
kf.F = np.array([[1, 1, 0, 0], [0, 1, 0, 0], [0, 0, 1, 1], [0, 0, 0, 1]])
kf.H = np.array([[1, 0, 0, 0], [0, 0, 1, 0]])
kf.P *= 1000  
kf.R = np.array([[5, 0], [0, 5]])
kf.Q = np.array([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])

cap = cv2.VideoCapture("sample.mp4")  
frame_width = int(cap.get(3))
frame_height = int(cap.get(4))

out = cv2.VideoWriter("output_with_trajectory.mp4", cv2.VideoWriter_fourcc(*'mp4v'), 30, (frame_width, frame_height))
trajectories = {}
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    detections = model(frame)[0].boxes.data.cpu().numpy()
    detection_list = []
    
    for d in detections:
        class_id = int(d[5])
        if class_id in ALLOWED_CLASSES:  
            detection_list.append((d[:4], d[4], class_id))  
    
    
    tracks = tracker.update_tracks(detection_list, frame=frame)
    
    for track in tracks:
        if not track.is_confirmed():
            continue
        
        track_id = track.track_id
        bbox = track.to_tlbr()
        x, y = int((bbox[0] + bbox[2]) / 2), int((bbox[1] + bbox[3]) / 2)
        
        
        kf.predict()
        kf.update(np.array([x, y]))
        predicted_x, predicted_y = kf.x[:2]
        
        
        if track_id not in trajectories:
            trajectories[track_id] = []
        trajectories[track_id].append((predicted_x, predicted_y))
        
        
        cv2.rectangle(frame, (int(bbox[0]), int(bbox[1])), (int(bbox[2]), int(bbox[3])), (0, 255, 0), 2)
        cv2.circle(frame, (int(predicted_x), int(predicted_y)), 5, (0, 0, 255), -1)
        cv2.putText(frame, f"ID {track_id} ({ALLOWED_CLASSES[class_id]})", (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
        
    
    for track_id, trajectory in trajectories.items():
        for i in range(1, len(trajectory)):
            cv2.line(frame, (int(trajectory[i-1][0]), int(trajectory[i-1][1])),
                     (int(trajectory[i][0]), int(trajectory[i][1])), (0, 255, 255), 2)
    
    
    out.write(frame)
    
    
    cv2.imshow("Tracking", frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
