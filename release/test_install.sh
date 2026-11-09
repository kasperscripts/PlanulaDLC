#!/usr/bin/env bash
set -euo pipefail
adb shell getprop ro.build.version.release
adb shell getprop ro.product.cpu.abilist
adb shell df -h /data
adb logcat -c
if adb install --streaming --no-incremental release/base.apk > baseline-install.txt 2>&1; then
  cat baseline-install.txt
  adb uninstall com.ScarletWork.CounterFlame
else
  cat baseline-install.txt
fi
adb logcat -c
if adb install --streaming --no-incremental release/PlanulaDLC-1.4.1-icon_crack-install-fix.apk > fixed-install.txt 2>&1; then
  cat fixed-install.txt
  adb shell pm path com.ScarletWork.CounterFlame
  adb shell dumpsys package com.ScarletWork.CounterFlame | grep -E 'versionCode|targetSdk|primaryCpuAbi|codePath|volumeUuid|pkgFlags' | tee fixed-package.txt
else
  cat fixed-install.txt
  adb logcat -d -v brief | grep -E 'CounterFlame|PackageInstallerSession|ziparchive|NativeLibraryHelper|INSTALL_|Failed to' | tail -150 | tee fixed-install-logcat.txt
  exit 1
fi
