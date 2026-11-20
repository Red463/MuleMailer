"""Package an allow-listed addon; never install into or control the game."""
from pathlib import Path
import hashlib
import re
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
toc = root / 'Postly.toc'
text = toc.read_text(encoding='utf-8')
version = re.search(r'^## Version:\s*(\S+)', text, re.M).group(1)
runtime = [s.strip() for s in text.splitlines() if s.strip() and not s.startswith('#')]
assert len(runtime) == 10 and all(Path(s).name == s and s.endswith('.lua') for s in runtime)
names = ['Postly.toc', *runtime, 'Media/Icon.tga', 'Media/Header.tga', 'README.md', 'LICENSE']
archive = root / 'dist' / f'Postly-{version}.zip'
archive.parent.mkdir(exist_ok=True)
with ZipFile(archive, 'w', ZIP_DEFLATED) as z:
    for name in names:
        z.write(root / name, f'Postly/{name}')
with ZipFile(archive) as z:
    assert z.namelist() == [f'Postly/{name}' for name in names]
    assert z.testzip() is None
print(archive)
print(f'{len(names)} files; SHA256 {hashlib.sha256(archive.read_bytes()).hexdigest()}')
