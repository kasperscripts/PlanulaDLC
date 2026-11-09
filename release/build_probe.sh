#!/usr/bin/env bash
set -euo pipefail
PROBE_BUILD=probe-build
mkdir -p "$PROBE_BUILD/classes" "$PROBE_BUILD/dex"
ANDROID_PLATFORM_JAR="$ANDROID_HOME/platforms/android-35/android.jar"
PROBE_SIGNER=$(printf '%s\n' "$ANDROID_HOME"/build-tools/*/apksigner | sort -V | tail -1)
PROBE_TOOLS=$(dirname "$PROBE_SIGNER")
javac -source 8 -target 8 -cp "$ANDROID_PLATFORM_JAR" -d "$PROBE_BUILD/classes" release/ProbeRunner.java
"$PROBE_TOOLS/d8" --min-api 26 --lib "$ANDROID_PLATFORM_JAR" --output "$PROBE_BUILD/dex" "$PROBE_BUILD"/classes/com/iconcrack/probe/*.class
cat > "$PROBE_BUILD/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.iconcrack.probe">
  <uses-sdk android:minSdkVersion="26" android:targetSdkVersion="35"/>
  <application android:label="Startup verification" android:testOnly="true"/>
  <instrumentation android:name="com.iconcrack.probe.ProbeRunner" android:targetPackage="com.ScarletWork.CounterFlame"/>
</manifest>
XML
"$PROBE_TOOLS/aapt2" link --manifest "$PROBE_BUILD/AndroidManifest.xml" -I "$ANDROID_PLATFORM_JAR" -o "$PROBE_BUILD/probe-unsigned.apk"
python3 - <<'PY'
from pathlib import Path
import zipfile
p=Path('probe-build')
with zipfile.ZipFile(p/'probe-unsigned.apk','a') as z:z.write(p/'dex/classes.dex','classes.dex',compress_type=zipfile.ZIP_DEFLATED)
PY
curl --fail --location --retry 3 --output "$PROBE_BUILD/signer.jar" https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar
python3 - <<'PY'
from pathlib import Path
import zipfile
p=Path('probe-build')
with zipfile.ZipFile(p/'signer.jar') as z:(p/'debug.keystore').write_bytes(z.read('debug.keystore'))
PY
"$PROBE_TOOLS/zipalign" -f 4 "$PROBE_BUILD/probe-unsigned.apk" "$PROBE_BUILD/probe-aligned.apk"
"$PROBE_SIGNER" sign --ks "$PROBE_BUILD/debug.keystore" --ks-pass pass:android --key-pass pass:android --out "$PROBE_BUILD/probe.apk" "$PROBE_BUILD/probe-aligned.apk"
