import cv2

pipeline = (
    "nvarguscamerasrc ! "
    "video/x-raw(memory:NVMM), width=640, height=480, framerate=30/1 ! "
    "nvvidconv ! video/x-raw, format=BGRx ! "
    "videoconvert ! video/x-raw, format=BGR ! "
    "appsink"
)

cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

if not cap.isOpened():
    print("Camera failed to open")
    exit()

print("Point the center crosshair at your green object.")
print("HSV values will appear in the terminal.")

while True:

    ret, frame = cap.read()
    if not ret:
        break

    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

    h, w, _ = frame.shape
    cx = w // 2
    cy = h // 2

    # HSV value at center pixel
    pixel = hsv[cy, cx]

    # Print HSV
    print("HSV:", pixel)

    # draw crosshair
    cv2.circle(frame, (cx, cy), 6, (0,255,0), 2)

    # show video
    cv2.imshow("Camera", frame)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()