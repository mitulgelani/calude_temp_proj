#!/bin/bash
# No-login check: fresh install (never logged in), share an Instagram reel, download it, confirm the file.
PKG=com.pluck.pluck
U() { python3 tool/ui.py "$@"; }
adb install -r pluck.apk
adb shell am start -n $PKG/.MainActivity; sleep 20
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "'https://www.instagram.com/p/DeJfc72SR0V/'" -n $PKG/.MainActivity
sleep 40; U show "sheet"
U tap "Download"; sleep 35
U tap "Saved"; sleep 3; U show "saved"
echo "=== gallery"; adb shell ls -la /sdcard/Pictures/Pluck /sdcard/Movies/Pluck 2>&1
