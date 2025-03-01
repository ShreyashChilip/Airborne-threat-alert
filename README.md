# 🛡️ AIRBORNE THREAT DETECTION IN SURVEILLANCE VIDEOS

**Problem Statement ID:** PS01  

## 📌 Overview
This project implements an **AI-powered airborne threat detection system** capable of detecting and tracking flying objects such as **missiles, drones, and birds** in surveillance videos. It integrates **YOLOv8 for object detection**, **DeepSORT for object tracking**, and **Kalman Filters for trajectory prediction** to enhance security and threat assessment.

## 🚀 Features
✅ **Real-Time Object Detection** – Identifies drones, missiles, and birds in video footage.  
✅ **Object Tracking** – Assigns unique IDs to each detected object and tracks movement across frames.  
✅ **Trajectory Prediction** – Uses Kalman Filters to estimate the future position of flying objects.  
✅ **Threat Level Assessment** – Differentiates between harmless and potential threats based on speed and direction.  
✅ **Live Visualization** – Plots real-time trajectories on a graph for enhanced situational awareness.  



## 🛠️ Technologies Used
- **Python** 🐍
- **YOLOv8 (Ultralytics)** 🏹 – Object detection
- **DeepSORT** 🔄 – Object tracking
- **Kalman Filters** 📈 – Trajectory prediction
- **OpenCV** 🎥 – Video processing
- **Matplotlib** 📊 – Data visualization

---

## 🔥 Future Enhancements
🔹 Add **LSTM-based trajectory prediction** for long-term motion forecasting.  
🔹 Implement **Geofencing alerts** to notify when a detected object enters restricted airspace.  
🔹 Deploy as a **real-time surveillance system** using edge AI hardware (Jetson Nano, Raspberry Pi).  

---

## 📜 License
This project is under the MIT License. 

---
