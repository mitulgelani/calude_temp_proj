#!/bin/bash
# End-to-end: install the APK, share an Instagram reel into Pluck, download it, check the gallery.
set -x
PKG=com.pluck.pluck
adb install -r pluck.apk
adb shell pm grant $PKG android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
adb shell am start -n $PKG/.MainActivity; sleep 25
python3 tool/ui.py show "start page"
adb exec-out screencap -p > s1_start.png

REEL="${REEL:-https://www.instagram.com/reel/Df172vGP3bh/}"
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "'$REEL'" -n $PKG/.MainActivity
sleep 45
python3 tool/ui.py show "after sharing reel"
adb exec-out screencap -p > s2_sheet.png
python3 tool/ui.py tap "Download" && sleep 5
python3 tool/ui.py show "after tapping download"
sleep 40
python3 tool/ui.py tap "Finished"; sleep 4
python3 tool/ui.py show "finished tab"
adb exec-out screencap -p > s3_finished.png
echo "=== gallery files"; adb shell ls -la /sdcard/Movies/Pluck /sdcard/Pictures/Pluck /sdcard/DCIM/Pluck 2>&1

echo "=== paste-a-link flow: TikTok in the search bar"
python3 tool/ui.py tap "Tab"; sleep 2
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "'https://www.tiktok.com/@scout2015/video/6718335390845095173'" -n $PKG/.MainActivity
sleep 60
python3 tool/ui.py show "tiktok"
python3 tool/ui.py tap "Download" && sleep 30 && python3 tool/ui.py tap "Finished" && sleep 3 && python3 tool/ui.py show "finished after tiktok"
python3 tool/ui.py tap "Tab"; sleep 2

echo "=== browse: Instagram tile -> reels feed -> red button"
adb shell input keyevent KEYCODE_BACK; sleep 2
python3 tool/ui.py tap "Instagram"; sleep 30
python3 tool/ui.py show "instagram reels in browser"
adb exec-out screencap -p > s4_reels.png
python3 tool/ui.py tap "Download video" && sleep 20
python3 tool/ui.py show "sheet from red button"
python3 tool/ui.py tap "Download" && sleep 35
python3 tool/ui.py tap "Finished"; sleep 3
python3 tool/ui.py show "finished after red button"
echo "=== gallery files (end)"; adb shell ls -la /sdcard/Pictures/Pluck 2>&1
echo "=== logcat"
adb logcat -d | grep -iE "flutter|python|chaquo|pluck|AndroidRuntime" | grep -v "^--" | tail -120
