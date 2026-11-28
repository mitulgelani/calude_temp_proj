#!/bin/bash
# In-browser reel: open Instagram feed, tap download immediately (no manual play) -> sheet must offer MP4.
PKG=com.pluck.pluck
U() { python3 tool/ui.py "$@"; }
adb install -r pluck.apk
adb shell am start -n $PKG/.MainActivity; sleep 20
U tap "Browser"; sleep 3
U tap "Instagram"; sleep 30
U tap "Download video"; sleep 20
U show "sheet from feed"
