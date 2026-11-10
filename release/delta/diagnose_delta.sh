#!/usr/bin/env bash
set -euo pipefail
adb install --streaming --no-incremental original.apk
adb root || true
adb wait-for-device
adb shell appops set --uid com.roblox.client MANAGE_EXTERNAL_STORAGE allow || true
adb logcat -c
adb shell monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1 || true
sleep 45
mkdir -p delta-evidence/modules
timeout 10s adb logcat -d -t 4000 > delta-evidence/logcat.txt 2>&1 || true
adb shell dumpsys activity lastanr > delta-evidence/anr.txt || true
adb shell dumpsys activity activities > delta-evidence/activities.txt || true
adb shell find /data/user/0/com.roblox.client -maxdepth 5 -type f > delta-evidence/files.txt || true
cat delta-evidence/files.txt
while IFS= read -r path; do
 path=${path%$'\r'}
 case "$path" in
  *.so|*shared_cache*|*gloopversioncache.txt) adb pull "$path" delta-evidence/modules/ || true ;;
 esac
done < delta-evidence/files.txt
adb shell screencap -p /data/local/tmp/delta-screen.png
adb pull /data/local/tmp/delta-screen.png delta-evidence/screen.png || true
find delta-evidence/modules -type f -printf '%f %s bytes\n'
