#!/bin/bash
# Quick visual check: light home, toggle to dark, then each tab in dark.
PKG=com.pluck.pluck
U() { python3 tool/ui.py "$@"; }
shot() { adb exec-out screencap -p > "s$1.png"; }
adb install -r pluck.apk
adb shell am start -n $PKG/.MainActivity; sleep 25; shot t1_light
U tap "Dark theme"; sleep 3; shot t2_dark_home
adb shell input swipe 300 560 300 200 900; sleep 2; shot t3_dark_grid
U tap "Browser"; sleep 3; shot t4_dark_browser
U tap "Saved"; sleep 3; shot t5_dark_saved
gh release create screens --title "UI screenshots" --notes "Emulator screenshots" >/dev/null 2>&1 || true
gh release upload screens s*.png --clobber && echo "uploaded screenshots"
