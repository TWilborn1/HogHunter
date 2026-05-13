import os
import sys
import cv2
import numpy as np
import socket
import time
import subprocess

# =====================================================
# UDP SETTINGS (Godot)
# =====================================================
GODOT_IP = "127.0.0.1"
GODOT_PORT = 4242
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# =====================================================
# SCREEN SETTINGS
# =====================================================
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
print("[INFO] Using fixed screen:", SCREEN_WIDTH, SCREEN_HEIGHT)

# =====================================================
# CAMERA PIPELINE: Need this or nano won't give proper permissions
# =====================================================
# Framerate at 30 seems to work best as already heavy on GPU
pipeline = (
    "nvarguscamerasrc ! "
    "video/x-raw(memory:NVMM), width=640, height=480, framerate=30/1 ! "
    "nvvidconv ! video/x-raw, format=BGRx ! "
    "videoconvert ! video/x-raw, format=BGR ! "
    "appsink drop=1"
)

# =====================================================
# CAMERA START
# =====================================================
print("[INFO] Waiting for camera daemon...")
for i in range(10):
    result = subprocess.run(
        "pgrep nvargus-daemon",
        shell=True,
        stdout=subprocess.PIPE
    )
    if result.returncode == 0:
        print("[INFO] nvargus-daemon is running")
        break
    print(f"[WARN] Waiting for nvargus-daemon... {i+1}/10")
    time.sleep(1)

print("[INFO] Opening camera pipeline...")
cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

for i in range(10):
    if cap.isOpened():
        break
    print(f"[WARN] Camera open failed retry {i+1}/10")
    time.sleep(3)
    cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

if not cap.isOpened():
    print("[ERROR] Camera failed permanently")
    exit()

print("[INFO] Camera successfully opened")

# =====================================================
# TRACKING STATE
# =====================================================
smooth_x = 320
smooth_y = 240
# 0.25-0.60 seem to work the best
alpha = 0.40

LOWER_GREEN = np.array([30, 80, 40])
UPPER_GREEN = np.array([90, 255, 255])

kernel = np.ones((5, 5), np.uint8)

sock.sendto(b"TRACKER_READY", (GODOT_IP, GODOT_PORT))
print("[INFO] Tracker ready sent")
print("[INFO] Running headless!:)")

# =====================================================
# MAIN LOOP
# =====================================================
try:
    while True:
        ret, frame = cap.read()

        if not ret:
            time.sleep(0.001)
            continue

        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, LOWER_GREEN, UPPER_GREEN)

        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if contours:
            c = max(contours, key=cv2.contourArea)
            if cv2.contourArea(c) > 1000:
                x, y, w, h = cv2.boundingRect(c)
                cx = x + w // 2
                cy = y + h // 2

                smooth_x = int(alpha * cx + (1 - alpha) * smooth_x)
                smooth_y = int(alpha * cy + (1 - alpha) * smooth_y)

                mapped_x = int((smooth_x / 640) * SCREEN_WIDTH)
                mapped_x = SCREEN_WIDTH - mapped_x
                mapped_y = int((smooth_y / 480) * SCREEN_HEIGHT)

                sock.sendto(f"{mapped_x},{mapped_y}".encode(), (GODOT_IP, GODOT_PORT))

        time.sleep(0.001)

except KeyboardInterrupt:
    print("[INFO] Tracker stopped by user")

finally:
    cap.release()
    print("[INFO] Camera released")
