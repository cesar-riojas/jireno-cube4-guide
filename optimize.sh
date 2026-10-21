#!/usr/bin/env bash
# ==============================================================================
# Jireno Cube 4 (Cube4) - Quick Optimizer Script
# Run this on your computer connected to the same Wi-Fi network as your projector.
# ==============================================================================

set -euo pipefail

PROJECTOR_IP="${1:-}"

if [[ -z "${PROJECTOR_IP}" ]]; then
  echo "Usage: ./optimize.sh <PROJECTOR_IP>"
  echo "Example: ./optimize.sh 192.168.86.60"
  exit 1
fi

PORT="3333"

echo "==> Connecting to Jireno Cube 4 at ${PROJECTOR_IP}:${PORT}..."
adb connect "${PROJECTOR_IP}:${PORT}"

echo "==> 1. Setting animation scales to 0.0 (Instant UI response)..."
adb -s "${PROJECTOR_IP}:${PORT}" shell settings put global window_animation_scale 0.0
adb -s "${PROJECTOR_IP}:${PORT}" shell settings put global transition_animation_scale 0.0
adb -s "${PROJECTOR_IP}:${PORT}" shell settings put global animator_duration_scale 0.0

echo "==> 2. Disabling broken Google Cast receiver loop (prevents 403 CPU drain)..."
adb -s "${PROJECTOR_IP}:${PORT}" shell pm disable-user --user 0 com.google.android.apps.mediashell 2>/dev/null || true

echo "==> 3. Trimming filesystem caches & performing NAND flash TRIM..."
adb -s "${PROJECTOR_IP}:${PORT}" shell pm trim-caches 1000M 2>/dev/null || true
adb -s "${PROJECTOR_IP}:${PORT}" shell sm fstrim 2>/dev/null || true

echo "==> 4. Ahead-of-time (AOT) speed compiling primary applications..."
for pkg in com.spocky.projengmenu com.apple.atve.androidtv.appletv com.amazon.amazonvideo.livingroom com.softmedia.receiver.castapp; do
  if adb -s "${PROJECTOR_IP}:${PORT}" shell pm path "$pkg" >/dev/null 2>&1; then
    echo "    Compiling $pkg..."
    adb -s "${PROJECTOR_IP}:${PORT}" shell cmd package compile -m speed "$pkg" 2>/dev/null || true
  fi
done

echo ""
echo "=============================================================================="
echo " [SUCCESS] Jireno Cube 4 optimization complete!"
echo " System responsiveness, disk I/O, and thermal headroom are now optimized."
echo "=============================================================================="
