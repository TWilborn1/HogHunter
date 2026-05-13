import cv2

cap = cv2.VideoCapture(
    "nvarguscamerasrc sensor-id=0 ! "
    "video/x-raw(memory:NVMM), width=640, height=480, framerate=30/1 ! "
    "nvvidconv ! video/x-raw, format=BGRx ! "
    "videoconvert ! video/x-raw, format=BGR ! "
    "appsink",
    cv2.CAP_GSTREAMER,
)

print("Opened:", cap.isOpened())

ret, frame = cap.read()
print("Frame:", ret, type(frame))