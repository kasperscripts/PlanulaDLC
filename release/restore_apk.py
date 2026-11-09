import hashlib
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent
SOURCE_SHA256 = 'd2184cb5e47cfc6c4d9c78645a1daf5fd2bd8eb4055144f1c973649db1b0c48e'
TARGET_SHA256 = 'ce989384c75f2fa8e9315619837d5e09c206f3ef2988dd3574479220b3d8012c'

event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
source_url = event['inputs']['source_url']
parts = urlsplit(source_url)
if parts.scheme != 'https' or parts.hostname not in ('www.dropbox.com', 'dropbox.com', 'dl.dropboxusercontent.com'):
    raise ValueError('An HTTPS Dropbox download URL is required')
print('::add-mask::' + source_url, flush=True)

source = ROOT / 'original.apk'
target = ROOT / 'PlanulaDLC-1.4.1-icon_crack.apk'
subprocess.run(['curl', '--fail', '--location', '--silent', '--show-error', '--retry', '3', '--retry-delay', '2', '--connect-timeout', '30', '--max-time', '900', source_url, '--output', str(source)], check=True)

def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

if sha256(source) != SOURCE_SHA256:
    raise ValueError('Original APK checksum mismatch')
subprocess.run(['xdelta3', '-d', '-s', str(source), str(ROOT / 'apk.delta'), str(target)], check=True)
if sha256(target) != TARGET_SHA256:
    raise ValueError('Restored APK checksum mismatch')
if target.stat().st_size != 1963086071:
    raise ValueError('Restored APK size mismatch')
source.unlink()
print('Verified full APK:', target.name, target.stat().st_size, TARGET_SHA256)
