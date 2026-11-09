import hashlib
import json
import os
from pathlib import Path
import time
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / 'full/manifest.json').read_text())
target = ROOT / manifest['name']
repository = os.environ['GITHUB_REPOSITORY']
revision = os.environ['GITHUB_SHA']

with target.open('wb') as out:
    for index, part in enumerate(manifest['parts'], 1):
        offset = out.tell()
        url = f'https://raw.githubusercontent.com/{repository}/{revision}/{part["path"]}'
        for attempt in range(4):
            try:
                out.seek(offset)
                out.truncate()
                digest = hashlib.sha256()
                count = 0
                request = Request(url, headers={'User-Agent': 'PlanulaDLC-release-assembler'})
                with urlopen(request, timeout=180) as response:
                    while block := response.read(4 * 1024 * 1024):
                        out.write(block)
                        digest.update(block)
                        count += len(block)
                if count != part['size'] or digest.hexdigest() != part['sha256']:
                    raise ValueError('Internal block checksum mismatch')
                break
            except Exception:
                if attempt == 3:
                    raise
                time.sleep(3)
        print(f'Verified data {index}/{len(manifest["parts"])}', flush=True)

if target.stat().st_size != manifest['size']:
    raise ValueError('Final APK size mismatch')
with target.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
if digest != manifest['sha256']:
    raise ValueError('Final APK checksum mismatch')
print('Verified full APK:', target.name, target.stat().st_size, digest)
