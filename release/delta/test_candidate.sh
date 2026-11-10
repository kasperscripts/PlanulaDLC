#!/usr/bin/env bash
set -euo pipefail
adb install --streaming --no-incremental release/delta/Delta-2.745.1142-Icon_Crack.apk
adb root || true
adb wait-for-device
adb shell appops set --uid com.roblox.client MANAGE_EXTERNAL_STORAGE allow || true
adb logcat -c
adb shell monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1
sleep 45
mkdir -p delta-candidate-evidence
adb shell pidof com.roblox.client | tee delta-candidate-evidence/process.txt
adb shell dumpsys activity activities > delta-candidate-evidence/activities.txt
adb shell dumpsys activity lastanr > delta-candidate-evidence/anr.txt || true
timeout 10s adb logcat -d > delta-candidate-evidence/logcat.txt 2>&1 || true
adb shell screencap -p /data/local/tmp/delta-candidate.png
adb pull /data/local/tmp/delta-candidate.png delta-candidate-evidence/screen.png
# The launcher must reach Roblox's native login activity in this unauthenticated emulator.
grep -q 'topResumedActivity=.*com.roblox.client/.ActivityNativeMain' delta-candidate-evidence/activities.txt
printf '%s\n' 'PASS: modified APK installs and reaches native Roblox login on Android 16'
