#!/bin/bash
# Quick visual + flow check: screenshots of each screen, one real Instagram download.
PKG=com.pluck.pluck
U() { python3 tool/ui.py "$@"; }
shot() { adb exec-out screencap -p > "s$1.png"; }
adb install -r pluck.apk
adb shell am start -n $PKG/.MainActivity; sleep 25; shot 1_home
U tap "Instagram"; sleep 3; shot 2_guide
U tap "Open Instagram"; sleep 25; shot 3_browser
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "'https://www.instagram.com/reel/Df172vGP3bh/'" -n $PKG/.MainActivity
sleep 40; shot 4_sheet; U show "sheet"
U tap "Download"; sleep 35
U tap "Saved"; sleep 3; shot 5_saved; U show "saved"
U tap "Home"; sleep 3
adb shell input swipe 160 520 160 120 400; sleep 2; shot 6_home_scrolled
U tap "Status saver"; sleep 3; shot 7_status_guide
gh release create screens --title "UI screenshots" --notes "Emulator screenshots" >/dev/null 2>&1 || true
gh release upload screens s*.png --clobber && echo "uploaded screenshots"
