# Jireno Cube 4 (Cube4) Optimization & Survival Guide 📽️

A complete technical survival and optimization guide for the **Jireno Cube 4** smart projector.

Since Jireno went out of business and shuttered their official domains, customer support, and OTA update servers, owners of the Cube 4 are left with uncertified hardware running an unmaintained Android 9 build. This repository provides exact solutions, ADB commands, and architectural workarounds to make the projector run like a modern, snappy Android TV device with working **Apple TV+**, **official Amazon Prime Video for TV**, **Google Cast / Chromecast**, and **Projectivy Launcher**.

---

## 📋 Device Profile & Constraints

| Specification | Value | Technical Implications |
| :--- | :--- | :--- |
| **SoC** | Amlogic (Quad-Core ARM Cortex-A53) | Hardware OMX video decoding (`OMX.amlogic.avc.decoder.awesome`) |
| **Userland ABI** | **32-bit ARM (`armeabi-v7a`)** | **Crucial:** 64-bit (`arm64-v8a`) APK splits will crash or fail to install. |
| **OS Version** | Android 9.0 Pie (API Level 28) | Apps requiring `minSdkVersion >= 29` (Android 10+) or `32` (Android 12L) will reject install. |
| **SELinux** | `Permissive` | Grants flexibility for system property tweaks and permissions via ADB. |
| **RAM / Flash** | 2 GB DDR / 16 GB eMMC | Memory is tight (~150MB free by default); aggressive background throttling needed. |
| **Native Display** | 1080p (1920x1080 @ 60Hz) | Live shader blurs in custom launchers tax the Mali GPU. |

---

## 🚀 One-Click Performance & Snappiness Script

Run this script from your computer connected to the projector over Wi-Fi (`adb connect <PROJECTOR_IP>:3333`):

```bash
#!/usr/bin/env bash
PROJECTOR_IP="192.168.86.60" # Replace with your projector IP
PORT="3333"

echo "Connecting to Jireno Cube 4..."
adb connect "${PROJECTOR_IP}:${PORT}"

echo "1. Eliminating UI animation latency (Instant navigation)..."
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0

echo "2. Disabling broken Google Cast service loop (saves CPU & RAM)..."
adb shell pm disable-user --user 0 com.google.android.apps.mediashell

echo "3. Performing NAND flash TRIM and cache cleanup..."
adb shell pm trim-caches 1000M
adb shell sm fstrim

echo "4. Pre-compiling core apps to native machine code (dex2oat)..."
adb shell cmd package compile -m speed com.spocky.projengmenu
adb shell cmd package compile -m speed com.apple.atve.androidtv.appletv
adb shell cmd package compile -m speed com.amazon.amazonvideo.livingroom
adb shell cmd package compile -m speed com.softmedia.receiver.castapp

echo "Optimization complete! Enjoy a significantly cooler and snappier system."
```

---

## 🛠️ Step-by-Step App Fixes

### 1. Apple TV+ (Smooth 1080p Video + Audio Fix)
* **The Problem:** The standard Android TV Apple TV+ app either spins the loader forever, stutters, or plays choppy video without sound due to Amlogic OMX buffer allocation conflicts with Widevine DRM.
* **The Fix:**
  1. Install the official Android TV build of Apple TV (`com.apple.atve.androidtv.appletv`).
  2. Configure the media audio pipeline to output stereo 16-bit PCM (`AudioTrack` mode) rather than passthrough Dolby Digital bitstreams that the internal SoC audio HAL drops.
  3. Force Widevine L3 fallback for stable software DRM decryption. Video plays smoothly at 1080p with full stereo audio.

---

### 2. Amazon Prime Video (Official Android TV Living Room Edition)
* **The Problem:** The preinstalled Prime Video app is an outdated mobile/tablet touch build (`luxcine_PrimeVideo.apk`). Launching a movie results in `"We are unable to show this content"`, and navigating requires an awkward mouse pointer.
* **The Fix:**
  1. Install **Aurora Store** (open-source Google Play frontend).
  2. In Aurora Store Settings > **Device Spoofing**, select a certified Android TV profile (e.g. **Sony BRAVIA VU2**).
  3. Search for and install the official TV package:
     `com.amazon.amazonvideo.livingroom` (v6.24.8+ Living Room Edition).
  4. Launch the app. It will present a 6-letter pairing code (e.g. `amazon.com/mytv`) designed for the projector remote with 10-foot D-pad navigation and 1080p streaming.
  5. *Optional cleanup:* Disable the old tablet stub via ADB:
     ```bash
     adb shell pm disable-user --user 0 com.amazon.avod.thirdpartyclient
     ```

---

### 3. Google Cast / Chromecast Enablement
* **The Problem:** The stock Google Cast receiver (`com.google.android.apps.mediashell`) crashes continuously on boot with:
  ```
  cast_ClientAuthCredsWidevine: Server returned HTTP error code 403
  AbandonAllHopeException: Server returned error code 403
  ```
  Because Jireno hardware lacks authentic Google Play Services certification keys. Furthermore, modern **AirScreen** (v2.18.0) cannot be installed because it requires **Android 12L (API 32)**.
* **The Fix: CastReceiver (32-bit `armeabi-v7a`)**
  1. In Aurora Store (or via ADB), install **CastReceiver** (`com.softmedia.receiver.castapp`).
  2. **Crucial:** Ensure the `split_config.armeabi_v7a.apk` architecture split is installed alongside `base.apk` so `libAirReceiver.so` is loaded.
  3. In CastReceiver settings:
     * Check **Google Cast Receiver**.
     * Check **Use HW Codec** (enables Amlogic hardware decoding).
  4. The projector will now broadcast as an authentic Cast target (e.g. `JIRENOCUBE4-60` on port 8010) detectable by Chrome, YouTube, and Android screen mirroring.

---

### 4. Replacing the Stock Launcher with Projectivy Launcher
* **The Problem:** The default OEM launcher is cluttered with broken links, unremovable recommendation cards, and sluggish widgets.
* **The Fix:**
  1. Install **Projectivy Launcher** (`com.spocky.projengmenu`).
  2. Enable accessibility service or set it as default home in Android Settings.
  3. **Performance Tip for Mali GPU:** In Projectivy Settings > **Appearance**:
     * Set **Wallpaper** to a static image instead of dynamic video backdrops.
     * Disable or reduce **Background Blur** (rendering live Gaussian blurs over 1080p is the #1 cause of launcher frame drops on the Cube 4).

---

## ⚡ Useful ADB Diagnostics

```bash
# Check memory consumption
adb shell "free -m"

# View top CPU-consuming apps
adb shell "top -n 1 -b -m 5"

# Verify active mDNS Cast advertisement on your local network (from Mac/Linux)
dns-sd -B _googlecast._tcp local
```

---

## 🤝 Contributing
Have additional tweaks or patches for the Jireno Cube 4? Pull requests and issues are welcome!
