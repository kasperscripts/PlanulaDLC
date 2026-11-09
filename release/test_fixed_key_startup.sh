#!/usr/bin/env bash
set -euo pipefail
adb install --streaming --no-incremental release/PlanulaDLC-1.4.1-icon_crack-fixed-key.apk
adb install --no-incremental -t probe-build/probe.apk
adb root || true
adb wait-for-device
adb shell appops set --uid com.ScarletWork.CounterFlame MANAGE_EXTERNAL_STORAGE allow
adb shell wm size 1600x2560
adb shell wm density 320
adb logcat -c
timeout 120s adb shell am instrument -w -r com.iconcrack.probe/com.iconcrack.probe.ProbeRunner > fixed-key-probe.txt 2>&1 || true
cat fixed-key-probe.txt
adb shell dumpsys activity lastanr > fixed-key-anr.txt || true
adb logcat -d -t 1800 > fixed-key-logcat.txt
adb pull /data/user/0/com.ScarletWork.CounterFlame/files/fixed-key-screen.png fixed-key-screen.png || true
grep -q 'PASS: only @icon_crack accepted' fixed-key-probe.txt
