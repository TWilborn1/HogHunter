import cv2
import numpy as np
import socket

# -------------------------
# UDP SETTINGS (Godot)
# -------------------------
GODOT_IP = "127.0.0.1"
GODOT_PORT = 4242
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# -------------------------
# CSI CAMERA PIPELINE
# -------------------------
pipeline = (
    "nvarguscamerasrc ! "
    "video/x-raw(memory:NVMM), width=640, height=480, framerate=30/1 ! "
    "nvvidconv ! video/x-raw, format=BGRx ! "
    "videoconvert ! video/x-raw, format=BGR ! "
    "appsink"
)

cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

if not cap.isOpened():
    print("Camera failed to open.")
    exit()

print("Green tracker started. Press ESC to quit.")

# -------------------------
# CUDA Setup
# -------------------------
gpu_frame = cv2.cuda_GpuMat()
gpu_hsv = cv2.cuda_GpuMat()

# -------------------------
# GREEN HSV RANGE
# -------------------------
LOWER_GREEN = (60, 225, 41)
UPPER_GREEN = (70, 255, 44)


# -------------------------
# SMOOTHING (for stable aim)
# -------------------------
smooth_x = 320
smooth_y = 240
alpha = 0.25

# Morphology kernel
kernel = np.ones((5,5), np.uint8)

while True:

    ret, frame = cap.read()
    if not ret:
        print("Failed to grab frame.")
        break

    # -------------------------
    # Upload frame to GPU
    # -------------------------
    gpu_frame.upload(frame)

    # Convert BGR → HSV
    gpu_hsv = cv2.cuda.cvtColor(gpu_frame, cv2.COLOR_BGR2HSV)

    # CUDA inRange
    gpu_mask = cv2.cuda.inRange(gpu_hsv, LOWER_GREEN, UPPER_GREEN)

    # Download mask to CPU
    mask = gpu_mask.download()

    # -------------------------
    # Noise removal
    # -------------------------
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    # -------------------------
    # Find contours
    # -------------------------
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if contours:

        c = max(contours, key=cv2.contourArea)

        # Ignore tiny green noise
        if cv2.contourArea(c) > 1200:

            x, y, w, h = cv2.boundingRect(c)

            cx = x + w // 2
            cy = y + h // 2

            # -------------------------
            # Smooth movement
            # -------------------------
            smooth_x = int(alpha * cx + (1 - alpha) * smooth_x)
            smooth_y = int(alpha * cy + (1 - alpha) * smooth_y)

            # -------------------------
            # Send coordinates to Godot
            # -------------------------
            msg = f"{smooth_x},{smooth_y}".encode()
            sock.sendto(msg, (GODOT_IP, GODOT_PORT))

            # Draw tracking circle
            cv2.circle(frame, (smooth_x, smooth_y), 10, (0,255,0), 2)

    # -------------------------
    # Display windows
    # -------------------------
    cv2.imshow("Camera", frame)
    cv2.imshow("Mask", mask)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()