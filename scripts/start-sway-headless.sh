#!/usr/bin/env bash

# Start Sway with headless backend and custom config

echo "Starting Sway with headless backend..."

# Set environment variables
export WLR_BACKENDS=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
export SWAYSOCK="/tmp/sway-headless-ipc.sock"
export XDG_RUNTIME_DIR="/tmp"
export WAYLAND_DISPLAY="wayland-1"

# Skip cleanup to avoid termination issues
echo "Skipping cleanup phase..."

echo "Environment variables set:"
echo "  WLR_BACKENDS=$WLR_BACKENDS"
echo "  WLR_LIBINPUT_NO_DEVICES=$WLR_LIBINPUT_NO_DEVICES"
echo "  WLR_RENDERER=$WLR_RENDERER"
echo "  SWAYSOCK=$SWAYSOCK"
echo "  XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "  WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/sway-headless-config"

echo ""
echo "Config file: $CONFIG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

echo "Starting Sway with headless config..."
echo "Command: sway -c \"$CONFIG_FILE\" -d"

# Start Sway with the custom config in background
sway -c "$CONFIG_FILE" -d &
SWAY_PID=$!

echo "Sway started with PID: $SWAY_PID"
echo "Press Ctrl+C to stop"

# Wait for Sway to start
echo "Waiting for Sway to initialize..."
sleep 3

# Check if Sway is still running
if ps -p $SWAY_PID > /dev/null; then
    echo "✅ Sway is running successfully (PID: $SWAY_PID)"
    echo "Socket: $SWAYSOCK"
    echo "Wayland display: $WAYLAND_DISPLAY"
    
    # Start wayvnc
    echo "Starting wayvnc..."
    wayvnc 0.0.0.0 5910 &
    WAYVNC_PID=$!
    sleep 2
    
    if ps -p $WAYVNC_PID > /dev/null; then
        echo "✅ wayvnc is running (PID: $WAYVNC_PID)"
        echo ""
        echo "Starting VNC viewer..."
        sleep 1
        vncviewer localhost:5910 &
        VNCVIEWER_PID=$!
        sleep 2
        
        if ps -p $VNCVIEWER_PID > /dev/null; then
            echo "✅ VNC viewer started (PID: $VNCVIEWER_PID)"
        else
            echo "⚠️  VNC viewer may have failed to start"
        fi
        
        echo ""
        echo "You can now:"
        echo "  - Use swaymsg commands: export SWAYSOCK=$SWAYSOCK && swaymsg -t get_outputs"
        echo "  - Launch applications: export SWAYSOCK=$SWAYSOCK && swaymsg exec alacritty"
        echo "  - Use automation script: ./scripts/sway-automation.sh"
    else
        echo "❌ wayvnc failed to start"
        echo "Sway is still running, but VNC is not available"
    fi
else
    echo "❌ Sway failed to start or crashed"
    echo "Check the logs above for error messages"
    exit 1
fi

# Wait for user to stop
echo ""
echo "Sway and wayvnc are running. Press Ctrl+C to stop..."

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up..."
    if [ ! -z "$VNCVIEWER_PID" ] && ps -p $VNCVIEWER_PID > /dev/null; then
        echo "Stopping VNC viewer (PID: $VNCVIEWER_PID)..."
        kill $VNCVIEWER_PID 2>/dev/null || true
    fi
    if [ ! -z "$WAYVNC_PID" ] && ps -p $WAYVNC_PID > /dev/null; then
        echo "Stopping wayvnc (PID: $WAYVNC_PID)..."
        kill $WAYVNC_PID 2>/dev/null || true
    fi
    if [ ! -z "$SWAY_PID" ] && ps -p $SWAY_PID > /dev/null; then
        echo "Stopping Sway (PID: $SWAY_PID)..."
        kill $SWAY_PID 2>/dev/null || true
    fi
    echo "Cleanup complete"
    exit 0
}

# Set up signal handlers
trap cleanup EXIT INT TERM

wait
