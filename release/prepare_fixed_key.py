import hashlib
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parent
BASE=ROOT/'base.apk'
TARGET=ROOT/'PlanulaDLC-1.4.1-icon_crack-fixed-key.apk'

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

subprocess.run(['curl','--fail','--location','--retry','3','--output',str(BASE),'https://github.com/kasperscripts/PlanulaDLC/releases/download/v1.4.1-install-fix/PlanulaDLC-1.4.1-icon_crack-install-fix.apk'],check=True)
assert sha(BASE)=='e0b750965b05204929d1120f309ee61d581319db285dfc7836a50a8303805200'
subprocess.run(['xdelta3','-d','-s',str(BASE),str(ROOT/'fixed-key.delta'),str(TARGET)],check=True)
assert sha(TARGET)=='7a604fb801f88f568c110989bf4c155d020215085dd9c3522eeec5f0a1fe84b7'
assert TARGET.stat().st_size==1963086071
BASE.unlink()
print('Verified fixed-key APK:',TARGET.name,TARGET.stat().st_size)
