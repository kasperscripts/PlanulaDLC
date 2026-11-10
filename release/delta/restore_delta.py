from pathlib import Path
import hashlib,subprocess,zipfile
ROOT=Path(__file__).resolve().parent
BASE=ROOT/'original.apk';TARGET=ROOT/'Delta-2.745.1142-Icon_Crack.apk'
def sha(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
subprocess.run(['curl','--fail','--location','--retry','2','--output',str(BASE),'https://www.dropbox.com/scl/fi/kvmuy3i9q8ieg7kpehf5r/Delta-2.745.1142-1.apk?rlkey=vyt71ccums4fh484el6lobh22&dl=1'],check=True)
assert sha(BASE)=='4d22c8be0f81251d18dc53a49b42a4c27ec64eb1ee039106a33913987027c3f2'
subprocess.run(['xdelta3','-d','-s',str(BASE),str(ROOT/'Delta-2.745.1142-Icon_Crack.delta'),str(TARGET)],check=True)
assert sha(TARGET)=='ea02b20018ddd8a914c744555a0955a8a87bede9265a7a60364a787dc0565305'
assert TARGET.stat().st_size==167457412
with zipfile.ZipFile(TARGET) as z:
 native=z.read('lib/arm64-v8a/libzstd-jni-1.5.7-6.so')
 decoded=bytes(v^((167*i+145)&255) for i,v in enumerate(native[0x1425b1:0x1425b1+144]))
 assert b'https://raw.githubusercontent.com/kasperscripts/PlanulaDLC/main/delta.lua' in decoded
 assert b'https://t.me/Icon_Crack' in z.read('classes4.dex')
BASE.unlink()
print('PASS: candidate APK SHA256, size, native startup route and Telegram callback verified')
