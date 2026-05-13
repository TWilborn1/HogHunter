#!/bin/bash

# =====================================================
# X11 AUTH
# =====================================================
export DISPLAY=:1
export XAUTHORITY=/run/user/1000/gdm/Xauthority
xhost +local: > /dev/null 2>&1

# =====================================================
# CONFIG
# =====================================================
GAME_NAME="$1"

if [ -z "$GAME_NAME" ]; then
    echo "[INFO] No game specified. Defaulting to MainMenuV2.pck"
    GAME_NAME="MainMenuV2.pck"
fi

GAME_PACK="/home/nano/GodotGames/$GAME_NAME"
TRACKER="/home/nano/GodotGames/green_tracker.py"
TRACKER_LOG="/home/nano/GodotGames/tracker_log.txt"
GODOT_LOG="/home/nano/GodotGames/godot_log.txt"
TRACKER_PID_FILE="/tmp/green_tracker.pid"

# =====================================================
# VALIDATE GAME FILE
# =====================================================
if [ ! -f "$GAME_PACK" ]; then
    echo "[ERROR] Game pack not found: $GAME_PACK"
    exit 1
fi

# =====================================================
# ADDITIONAL ENV
# =====================================================
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}
export GST_PLUGIN_PATH=/usr/lib/aarch64-linux-gnu/gstreamer-1.0
export GST_PLUGIN_SCANNER=/usr/lib/aarch64-linux-gnu/gstreamer1.0/gstreamer-1.0/gst-plugin-scanner
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
export EGL_PLATFORM=x11
export PYTHONPATH=/usr/local/lib/python3.6/site-packages:$PYTHONPATH

# =====================================================
# KILL ANY STALE TRACKER
# =====================================================
if [ "$GAME_NAME" = "HogHunterV2.pck" ]; then
    echo "[INFO] Killing any existing tracker instances..."
    pkill -9 -f green_tracker.py > /dev/null 2>&1

    while pgrep -f green_tracker.py > /dev/null 2>&1; do
        echo "[INFO] Waiting for tracker to die..."
        sleep 1
    done

    rm -f "$TRACKER_PID_FILE"

    echo "[INFO] Restarting nvargus-daemon..."
    sudo systemctl restart nvargus-daemon
    sleep 3
fi

# =====================================================
# START GODOT FIRST
# =====================================================
echo "[INFO] Launching Godot with: $GAME_PACK"
nohup /home/nano/GodotGames/godot.x11.opt.arm64 \
    --main-pack "$GAME_PACK" \
    > "$GODOT_LOG" 2>&1 &

GODOT_PID=$!
echo "[INFO] Godot PID: $GODOT_PID"

# =====================================================
# START TRACKER AFTER GODOT (HogHunterV2 only)
# =====================================================
if [ "$GAME_NAME" = "HogHunterV2.pck" ]; then
    echo "[INFO] Waiting for Godot to initialize..."
    sleep 3 #Change this if to slow on startup or to fast

    pkill -9 -f green_tracker.py > /dev/null 2>&1
    sleep 2

    echo "[INFO] Starting green tracker..."
    python3 -u "$TRACKER" > "$TRACKER_LOG" 2>&1 &
    TRACKER_PID=$!
    echo $TRACKER_PID > "$TRACKER_PID_FILE"
    echo "[INFO] Tracker started with PID $TRACKER_PID"
fi

wait $GODOT_PID
echo "[INFO] Godot exited"

# =====================================================
# CHECK FOR NEXT GAME REQUEST
# =====================================================
if [ -f "/home/nano/GodotGames/next_game.txt" ]; then
    NEXT_GAME=$(cat /home/nano/GodotGames/next_game.txt)
    rm -f /home/nano/GodotGames/next_game.txt
    echo "[INFO] Launching next game: $NEXT_GAME"
    exec /home/nano/GodotGames/launch_game.sh "$NEXT_GAME"
fi

# =====================================================
# CLEANUP
# =====================================================
if [ "$GAME_NAME" = "HogHunterV2.pck" ]; then
    echo "[INFO] Stopping tracker..."
    pkill -9 -f green_tracker.py > /dev/null 2>&1
    rm -f "$TRACKER_PID_FILE"
fi

echo "[INFO] Cleanup complete"
