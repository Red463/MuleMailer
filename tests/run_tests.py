from pathlib import Path
import os
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.test-deps'))
from lupa.lua51 import LuaRuntime

os.chdir(root)
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'tests/run.lua').read_text(encoding='utf-8'))
toc = root / 'Postly.toc'
if toc.exists():
    files = [s.strip() for s in toc.read_text().splitlines() if s.strip() and not s.startswith('#')]
    for name in files:
        assert (root / name).is_file(), name
        lua.execute('assert(loadfile(...))', str(root / name))
    print(f'TOC: {len(files)} runtime files present and compile under Lua 5.1')

from PIL import Image
for name, size in [('Icon', (256, 256)), ('Header', (1024, 512))]:
    path = root / 'Media' / f'{name}.tga'
    header = path.read_bytes()[:18]
    assert header[2] == 2 and header[16] == 32, f'{name}: expected uncompressed 32-bit TGA'
    with Image.open(path) as art:
        assert art.size == size and art.mode == 'RGBA', name
        assert art.getchannel('A').getextrema() == (0, 255), name
assert '## IconTexture: Interface\\AddOns\\Postly\\Media\\Icon' in toc.read_text()
print('Brand assets: power-of-two sizes, 32-bit uncompressed TGA, alpha and TOC icon path verified.')
