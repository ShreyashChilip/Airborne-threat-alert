# 🛡️ AeroSentinel: AI-Powered Airborne Threat Detection System

**Team BichdeHueDost**

Shreyash Milind Chilip
Kiran Anil Thorat
Ram Belitkar

## 📌 Project Overview

AeroSentinel is an **AI-driven airborne threat detection app** designed to revolutionize modern security and defense operations. By using advanced object detection, tracking, AeroSentinel automatically identifies and classifies airborne objects such as **birds**, **drones**, **missiles**, **Fighter Jets**, **Landing Decks**, **Ships**, **Paragliders and persons with the paragliders**, **Hot air Balloons**, and commercial planes in surveillance footage. It differentiates between harmless objects (e.g., birds) and potential threats (e.g., drones or missiles, Ships, Landing decks), minimizing false alarms and enabling rapid, informed decision-making in critical scenarios, using YoloV11m as it is the best suited model for a great balance between accuracy, computational time, DFL losses, as well has efficient mapping.

Built with **YOLOv11m** for object detection, AeroSentinel ensures high-speed inference and accuracy, even in challenging conditions like low-light. The system features a user-friendly Flutter-based frontend for seamless interaction, a FastAPI backend for efficient video processing, and real-time threat analysis for enhanced situational awareness. The application also alerts the users registered as monitoring authorities, using the app best alerting system, using a loud alarm, that keeps on ringing until user acknowledges the threat detected, as well as places calls to the concerned monitoring authority, to ensure that the threat has been acknowledged, as relying on textual alerts like sms and emails is risky for security applications.

---

## 🎯 Problem Statement

Traditional surveillance methods for airborne threat detection rely heavily on manual monitoring, which is inefficient and prone to human error. Distinguishing between non-threatening objects (e.g., birds) and real threats (e.g., drones, missiles) is a significant challenge, often leading to false alarms and delayed responses. AeroSentinel addresses these issues by:

1. **Automating Detection and Classification:** Using AI to detect and classify airborne objects in real-time surveillance footage.
2. **Reducing False Alarms:** Accurately distinguishing between birds and threats like drones or missiles.
3. **Ensuring High-Speed Inference:** Prioritizing rapid detection to support timely decision-making in operational environments.
4. **Enhancing Accuracy:** Fine-tuning models with transfer learning and data augmentation to handle diverse scenarios (e.g., varying backgrounds, lighting, and motion blur).
5. **Sending alerts through trusted mediums like audio based alerts on monitoring authority users, as well as place calls to the users registered as monitoring authority.**

---

## 🚀 Features

✅ **Real-Time Object Detection**  
- Identifies and classifies airborne objects (birds, drones, missiles) in surveillance videos with high accuracy using YOLOv8.

✅ **Threat Level Assessment**  
- Categorizes threats as **Low** (birds), **High** (drones), or **Critical** (missiles) based on object type, speed, and direction.

✅ **Live Visualization**  
- Provides real-time plots and detailed threat analysis for enhanced situational awareness.

✅ **User-Friendly Interface**  
- A Flutter-based mobile app allows users to upload videos, view threat analysis, and download annotated footage.

✅ **Scalable Backend**  
- A FastAPI backend processes videos efficiently, logs detections, and serves annotated results.

✅ **Calls and audio based alerts **  
- Uses the best medium for alrting the authority remotely, i.e. Audio based in app alerts and placing calls to ensure sure shot acknowledgement from monitoring authority.
---

## 🛠️ Technical Implementation

### Technologies Used
- **Python** 🐍: Core language for backend development.
- **YOLOv11 (Ultralytics)** 🏹: For real-time object detection of birds, drones, and missiles.
- **OpenCV** 🎥: For video processing and frame extraction.
- **FastAPI** ⚡: For building a high-performance API to process videos and serve results.
- **Flutter** 📱: For developing a cross-platform mobile app with an intuitive UI.
- **Dio & Flutter Downloader**: For handling file uploads and downloads in the Flutter app.
- **Twilio API**: For placing calls efficiently.
  
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
- **Dataset:** combined dataset from various sources across internet containing birds, drones, and missiles, ships, landing decks, paragliders, hot air balloons, total 12 such classes under diverse conditions (e.g., different lighting, backgrounds, and object speeds).
- **Training Approach:** Fine-tuned YOLOv11m for custom dataset.
- **Inference Optimization:** Achieved high-speed inference with a confidence threshold of 0.6 to balance accuracy and performance.

---

## 📸 App Output Screenshots

Below are some key outputs from the AeroSentinel app, demonstrating its functionality in real-world scenarios.
## 📸 App Output Screenshots

Below are some key outputs from the AeroSentinel app, demonstrating its functionality in real-world scenarios.

| **Initial App Screen** | **Video Analysis Summary** | **Threat Analysis Report (Low Threat)** |
|------------------------|----------------------------|-----------------------------------------|
| ![Initial App Screen](https://i.ibb.co/xKb6QJv4/Screenshot-2025-03-02-055456.png) <br> *The app prompts users to upload surveillance footage to begin analysis.* | ![Video Analysis Summary](https://i.ibb.co/XrbzQs0K/Screenshot-2025-03-02-055515.png) <br> *After uploading a video, the app displays a summary of detected objects: 3008 birds, 0 drones, and 0 missiles.* | ![Threat Analysis Report - Low Threat](https://i.ibb.co/1Y5tL7V0/Screenshot-2025-03-02-055532.png) <br> *For a video with only birds (3008 detected), the threat level is Low. The app recommends logging for wildlife monitoring.* |

| **Threat Analysis Report (Critical Threat)** | **Detection Frame (Missile Launch)** | **Detection Frame (Birds Only)** |
|----------------------------------------------|--------------------------------------|----------------------------------|
| ![Threat Analysis Report - Critical Threat](https://i.ibb.co/Dfxb6K5W/Screenshot-2025-03-02-055600.png) <br> *For a video with 104 missiles detected, the threat level is Critical. The app recommends immediate actions like activating emergency protocols and notifying the security command center.* | ![Detection Frame - Missile](https://i.ibb.co/9ksNyb32/Screenshot-2025-03-02-055747.png) <br> *A frame from a surveillance video sourced from the Russian Defense Ministry, showing a missile launch detected with 62% confidence.* | ![Detection Frame - Birds](https://i.ibb.co/35Ywc5JZ/Screenshot-2025-03-02-055704.png) <br> *A frame showing multiple birds detected with high confidence, indicating no immediate threat.* |
---

## 🔥 Future Enhancements

🔹 **LSTM-Based Trajectory Prediction**  
- Implement LSTM models for long-term motion forecasting to predict complex object trajectories.

🔹 **Geofencing Alerts**  
- Add geofencing capabilities to trigger alerts when detected objects enter restricted airspace.

🔹 **Enhanced Visualization**  
- Integrate 3D trajectory mapping and heatmaps to provide deeper insights into object movements.

🔹 **Audio augmentation**  
- Use audio features from the video/stream to enhance the prediction for conditions like drone disguised as drone.

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

**Ram Belitkar - MES Wadia College of Engineering**
- **Email (Personal):** ram27belitkar@gmail.com
- **GitHub:** https://github.com/Rambelitkar
- **LinkedIn:** [Profile](https://www.linkedin.com/in/ram-belitkar-270b37264/)

---

## 🏆 Acknowledgments

- **Ultralytics Team** for the YOLOv8 framework.
- **Flutter and FastAPI Communities** for their amazing tools and resources.
