#!/usr/bin/env bash

# Get the current Reaper binary path
REAPER_BIN="/nix/store/x9sqjm7d36ccbz5w51gm59vmy67fv10j-reaper-7.42/opt/REAPER/.reaper-wrapped"

# Get GTK3 library path
GTK3_LIB_PATH="/nix/store/j9x63rkvf4jzkshacpzabvi6xhdj87by-gtk+3-3.24.49/lib"

# Check if the binary exists
if [ ! -f "$REAPER_BIN" ]; then
    echo "Reaper binary not found at: $REAPER_BIN"
    echo "Please update the path in this script"
    exit 1
fi

# Get current RPATH
CURRENT_RPATH=$(patchelf --print-rpath "$REAPER_BIN")
echo "Current RPATH: $CURRENT_RPATH"

# Add GTK3 library path to RPATH if not already present
if [[ "$CURRENT_RPATH" != *"$GTK3_LIB_PATH"* ]]; then
    NEW_RPATH="$GTK3_LIB_PATH:$CURRENT_RPATH"
    echo "Setting new RPATH: $NEW_RPATH"
    patchelf --set-rpath "$NEW_RPATH" "$REAPER_BIN"
    echo "Reaper binary patched successfully!"
else
    echo "GTK3 library path already in RPATH"
fi

# Verify the patch
echo "New RPATH: $(patchelf --print-rpath "$REAPER_BIN")"
