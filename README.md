# 🛡️ AeroSentinel: AI-Powered Airborne Threat Detection System

**Team BichdeHueDost**

Shreyash Milind Chilip
Kiran Anil Thorat
Ram Belitkar

**Problem Statement ID:** PS01  
**AlphaByte 2.0 Hackathon:** GDGC PCCOE - Develop, Design, Innovate

---

## 📌 Project Overview

AeroSentinel is an **AI-driven airborne threat detection system** designed to revolutionize modern security and defense operations. By leveraging advanced object detection, tracking, and trajectory prediction, AeroSentinel automatically identifies and classifies airborne objects such as **birds**, **drones**, and **missiles** in surveillance footage. It differentiates between harmless objects (e.g., birds) and potential threats (e.g., drones or missiles), minimizing false alarms and enabling rapid, informed decision-making in critical scenarios.

Built with **YOLOv8** for object detection, **DeepSORT** for tracking, and **Kalman Filters** for trajectory prediction, AeroSentinel ensures high-speed inference and accuracy, even in challenging conditions like low-light or night-vision environments. The system features a user-friendly Flutter-based frontend for seamless interaction, a FastAPI backend for efficient video processing, and real-time threat analysis for enhanced situational awareness.

---

## 🎯 Problem Statement

Traditional surveillance methods for airborne threat detection rely heavily on manual monitoring, which is inefficient and prone to human error. Distinguishing between non-threatening objects (e.g., birds) and real threats (e.g., drones, missiles) is a significant challenge, often leading to false alarms and delayed responses. AeroSentinel addresses these issues by:

1. **Automating Detection and Classification:** Using AI to detect and classify airborne objects in real-time surveillance footage.
2. **Reducing False Alarms:** Accurately distinguishing between birds and threats like drones or missiles.
3. **Ensuring High-Speed Inference:** Prioritizing rapid detection to support timely decision-making in operational environments.
4. **Enhancing Accuracy:** Fine-tuning models with transfer learning and data augmentation to handle diverse scenarios (e.g., varying backgrounds, lighting, and motion blur).

---

## 🚀 Features

✅ **Real-Time Object Detection**  
- Identifies and classifies airborne objects (birds, drones, missiles) in surveillance videos with high accuracy using YOLOv8.

✅ **Object Tracking**  
- Assigns unique IDs to detected objects and tracks their movement across frames using DeepSORT.

✅ **Trajectory Prediction**  
- Estimates the future position of airborne objects using Kalman Filters, aiding in threat assessment.

✅ **Threat Level Assessment**  
- Categorizes threats as **Low** (birds), **High** (drones), or **Critical** (missiles) based on object type, speed, and direction.

✅ **Live Visualization**  
- Provides real-time trajectory plots and detailed threat analysis reports for enhanced situational awareness.

✅ **User-Friendly Interface**  
- A Flutter-based mobile app allows users to upload videos, view threat analysis, and download annotated footage.

✅ **Scalable Backend**  
- A FastAPI backend processes videos efficiently, logs detections, and serves annotated results.

---

## 🛠️ Technical Implementation

### Technologies Used
- **Python** 🐍: Core language for backend development.
- **YOLOv8 (Ultralytics)** 🏹: For real-time object detection of birds, drones, and missiles.
- **DeepSORT** 🔄: For tracking objects across video frames with unique IDs.
- **Kalman Filters** 📈: For predicting the trajectory of detected objects.
- **OpenCV** 🎥: For video processing and frame extraction.
- **Matplotlib** 📊: For visualizing object trajectories.
- **FastAPI** ⚡: For building a high-performance API to process videos and serve results.
- **Flutter** 📱: For developing a cross-platform mobile app with an intuitive UI.
- **Dio & Flutter Downloader**: For handling file uploads and downloads in the Flutter app.

### System Architecture
1. **Frontend (Flutter App)**  
   - Users upload surveillance videos via the AeroSentinel app.
   - The app displays real-time analysis, including threat counts, risk assessments, and detection timelines.
   - Users can download annotated videos with marked threats.

2. **Backend (FastAPI)**  
   - Receives uploaded videos and processes them using the YOLOv8 model.
   - Logs detection results (e.g., object type, confidence, bounding boxes) and threat summaries.
   - Generates annotated videos and provides download links.

3. **AI Pipeline**  
   - **Object Detection:** YOLOv8 detects and classifies airborne objects in each frame.
   - **Object Tracking:** DeepSORT assigns unique IDs and tracks objects across frames.
   - **Trajectory Prediction:** Kalman Filters estimate future positions based on velocity and direction.
   - **Threat Assessment:** Objects are categorized into threat levels (Low, High, Critical) based on their class and behavior.

### Model Training
- **Dataset:** 30-minute video clips containing birds, drones, and missiles under diverse conditions (e.g., different lighting, backgrounds, and object speeds).
- **Training Approach:** Fine-tuned YOLOv8 using transfer learning on a pre-trained model.
- **Data Augmentation:** Applied techniques like brightness adjustment, motion blur, and background variation to improve model robustness.
- **Inference Optimization:** Achieved high-speed inference with a confidence threshold of 0.6 to balance accuracy and performance.

---

## 📸 App Output Screenshots

Below are some key outputs from the AeroSentinel app, demonstrating its functionality in real-world scenarios.

<div style="display: flex; justify-content: center; gap: 20px; align-items: center;">
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/xKb6QJv4/Screenshot-2025-03-02-055456.png" alt="Initial App Screen" width="100%">
    <p><strong>Initial App Screen (No Footage Analyzed)</strong><br>The app prompts users to upload surveillance footage to begin analysis.</p>
  </div>
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/XrbzQs0K/Screenshot-2025-03-02-055515.png" alt="Video Analysis Summary" width="100%">
    <p><strong>Video Analysis Summary</strong><br>After uploading a video, the app displays a summary of detected objects: 3008 birds, 0 drones, and 0 missiles.</p>
  </div>
</div>

<div style="display: flex; justify-content: center; gap: 20px; align-items: center;">
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/1Y5tL7V0/Screenshot-2025-03-02-055532.png" alt="Threat Analysis Report - Low Threat" width="100%">
    <p><strong>Threat Analysis Report (Low Threat - Birds Only)</strong><br>For a video with only birds, the threat level is Low. The app recommends logging for wildlife monitoring.</p>
  </div>
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/Dfxb6K5W/Screenshot-2025-03-02-055600.png" alt="Threat Analysis Report - Critical Threat" width="100%">
    <p><strong>Threat Analysis Report (Critical Threat - Missiles Detected)</strong><br>For a video with 104 missiles detected, the threat level is Critical. The app recommends immediate emergency protocols.</p>
  </div>
</div>

<div style="display: flex; justify-content: center; gap: 20px; align-items: center;">
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/9ksNyb32/Screenshot-2025-03-02-055747.png" alt="Detection Frame - Missile" width="100%">
    <p><strong>Detection Frame (Missile Launch)</strong><br>A frame from a surveillance video showing a missile launch detected with 62% confidence.</p>
  </div>
  <div style="text-align: center; width: 45%;">
    <img src="https://i.ibb.co/35Ywc5JZ/Screenshot-2025-03-02-055704.png" alt="Detection Frame - Birds" width="100%">
    <p><strong>Detection Frame (Birds Only)</strong><br>A frame showing multiple birds detected with high confidence, indicating no immediate threat.</p>
  </div>
</div>

---

## 🔥 Future Enhancements

🔹 **LSTM-Based Trajectory Prediction**  
- Implement LSTM models for long-term motion forecasting to predict complex object trajectories.

🔹 **Geofencing Alerts**  
- Add geofencing capabilities to trigger alerts when detected objects enter restricted airspace.

🔹 **Enhanced Visualization**  
- Integrate 3D trajectory mapping and heatmaps to provide deeper insights into object movements.

---

## 🌟 Impact and Significance

AeroSentinel represents a transformative step in modern security and defense strategies. Its key impacts include:

- **Improved Situational Awareness:** Real-time detection and tracking provide defense teams with actionable insights.
- **Reduced False Alarms:** Accurate classification minimizes unnecessary escalations caused by harmless objects like birds.
- **Rapid Response:** High-speed inference ensures timely threat identification, enabling proactive measures.
- **Operational Efficiency:** Automation reduces the need for manual monitoring, freeing up resources for critical tasks.
- **Versatility:** The system performs reliably across diverse environments, including low-light and night-vision conditions.

By integrating cutting-edge AI technologies, AeroSentinel fortifies security operations, mitigates risks, and enhances safety in high-stakes scenarios.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 📬 Contact

For inquiries, feedback feel free to reach out:
Contributors:
**Shreyash Milind Chilip - VIT, Pune**
- **Email (Personal):** shreyash06chilip@gmail.com
- **Email (Work):** shreyash.chilip24@vit.edu
- **GitHub:** https://github.com/ShreyashChilip
- **LinkedIn:** [Profile](https://linkedin.com/in/shreyash-chilip-346196291/)

**Kiran Anil Thorat - Sinhgad College of Engineering, Pune**
- **Email (Personal):** kiranaanilthoratt@gmail.com
- **GitHub:** https://github.com/kiranthorat-200
- **LinkedIn:** [Profile](https://www.linkedin.com/in/kiran-thorat-3a39aa32a/)

**Ram Belitkar**
- **Email (Personal):** ram27belitkar@gmail.com
- **GitHub:** https://github.com/Rambelitkar
- **LinkedIn:** [Profile](https://www.linkedin.com/in/ram-belitkar-270b37264/)

---

## 🏆 Acknowledgments

- **GDGC PCCOE AlphaByte 2.0 Hackathon** for providing the problem statement and inspiration.
- **Ultralytics Team** for the YOLOv8 framework.
- **Flutter and FastAPI Communities** for their amazing tools and resources.
