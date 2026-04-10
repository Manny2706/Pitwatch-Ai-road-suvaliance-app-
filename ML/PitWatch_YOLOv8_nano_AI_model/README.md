# PitWatch: AI-Powered Road Guardian

**PitWatch** is an intelligent road safety solution developed for the **Innovate Bharat Hackathon 2026**. It leverages Computer Vision to detect road hazards—specifically potholes and waterlogging—to assist municipal authorities in proactive infrastructure maintenance.


**[View the Live API](https://pitwatch-api.onrender.com/predict)**

--------------------------------------------------------------------------------------------------------------

## Key Features
* **Real-time Hazard Detection:** Utilizes a fine-tuned **YOLOv8** model to identify potholes and waterlogging with high precision.
* **Optimized for Performance:** Model converted to **ONNX** format, ensuring low-latency inference and high FPS even on standard cloud CPUs.
* **Streamlined Web Interface:** A minimalist **Streamlit** dashboard allowing users to upload images for instant analysis.

--------------------------------------------------------------------------------------------------------------

## Tech Stack
* **AI/ML:** Ultralytics YOLOv8 nano, ONNX Runtime, OpenCV
* **Web Framework:** Streamlit
* **Deployment:** Streamlit Cloud
* **Language:** Python

--------------------------------------------------------------------------------------------------------------

# Project Architecture
1. Input: Image upload via Streamlit.
2. Processing: Image preprocessing via OpenCV.
3. Inference: YOLOv8-ONNX engine identifies bounding boxes and confidence scores.
4. Output: Visualized results with hazard classification and count.

--------------------------------------------------------------------------------------------------------------

# Impact & Vision
Aligned with UN Sustainable Development Goal 11 (Sustainable Cities and Communities), Neer-Nirikshan aims to reduce road accidents and vehicle wear-and-tear by digitizing the road inspection process.
