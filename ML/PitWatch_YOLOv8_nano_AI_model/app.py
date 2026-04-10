import streamlit as st
from ultralytics import YOLO
from PIL import Image
import numpy as np

#Page Configuration
st.set_page_config(page_title="Neer-Nirikshan AI Demo", layout="wide")

st.title("🚧 PitWatch: Pothole & Waterlogging Detection")
st.write("Upload a road image to see the AI identify hazards in real-time.")

#Loading our model
@st.cache_resource
def load_model():
    model = YOLO("best.onnx", task="detect")
    return model

model = load_model()

#Sidebar for settings
conf_threshold = st.sidebar.slider("Confidence Threshold", 0.0, 1.0, 0.45)

#File Uploader
uploaded_file = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    #Converting uploaded file to OpenCV format
    image = Image.open(uploaded_file)
    img_array = np.array(image)
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.image(image, caption="Original Image", use_container_width=True)
        
    with col2:
        #running our prediction
        results = model.predict(source=img_array, conf=conf_threshold)
        
        #Plotting the results (bounding boxes) on the uploaded image
        annotated_img = results[0].plot()
        
        st.image(annotated_img, caption="AI Detection Result", use_container_width=True)
        
        #Display detected hazards count
        st.success(f"Detected {len(results[0])} hazards on this road.")
