#!/usr/bin/env bash
set -euo pipefail
adb install --streaming --no-incremental app.apk
adb root || true
adb wait-for-device
adb shell appops set --uid com.ScarletWork.CounterFlame MANAGE_EXTERNAL_STORAGE allow || true
adb logcat -c
timeout 25s adb shell am start -W -n com.ScarletWork.CounterFlame/androidx.tyuuws.hnxoq.GateActivity > startup-result.txt 2>&1 || true
sleep 15
cat startup-result.txt
timeout 15s adb shell uiautomator dump /sdcard/window.xml || true
adb pull /sdcard/window.xml startup-ui.xml || true
adb exec-out screencap -p > startup.png || true
adb shell dumpsys activity lastanr > startup-anr.txt || true
adb shell dumpsys dropbox --print data_app_anr >> startup-anr.txt || true
adb logcat -d -t 2500 > startup-logcat.txt
cat startup-anr.txt
cat startup-ui.xml || true
grep -E 'CounterFlame|Hnxoq|ANR in|FATAL EXCEPTION|MediaDrm|IconCrack' startup-logcat.txt | tail -100 || true
