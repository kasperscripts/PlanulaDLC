import hashlib
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parent
BASE=ROOT/'base.apk'
TARGET=ROOT/'PlanulaDLC-1.4.1-icon_crack-install-fix.apk'
BASE_SHA='ce989384c75f2fa8e9315619837d5e09c206f3ef2988dd3574479220b3d8012c'
TARGET_SHA='e0b750965b05204929d1120f309ee61d581319db285dfc7836a50a8303805200'

def sha256(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

subprocess.run(['curl','--fail','--location','--retry','3','--output',str(BASE),'https://github.com/kasperscripts/PlanulaDLC/releases/download/v1.4.1-icon-crack/PlanulaDLC-1.4.1-icon_crack.apk'],check=True)
assert sha256(BASE)==BASE_SHA,'Base APK checksum mismatch'
subprocess.run(['xdelta3','-d','-s',str(BASE),str(ROOT/'install-fix.delta'),str(TARGET)],check=True)
assert sha256(TARGET)==TARGET_SHA,'Fixed APK checksum mismatch'
assert TARGET.stat().st_size==1963086071
print('Verified fixed APK:',TARGET.name,TARGET.stat().st_size,TARGET_SHA)
