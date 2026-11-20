"""Pack already-edited, transparent artwork into WoW textures; no image API calls."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.test-deps'))
from PIL import Image, ImageOps, ImageDraw, ImageFont

art = root / 'docs' / 'branding'
media = root / 'Media'
media.mkdir(exist_ok=True)
for source, name, size in [('icon-transparent.png', 'Icon', (256, 256)), ('header-transparent.png', 'Header', (1024, 512)), ('mini-icon-transparent.png', 'MiniIcon', (256, 256))]:
    image = Image.open(art / source).convert('RGBA')
    assert image.getchannel('A').getextrema() == (0, 255), source
    bounds = image.getchannel('A').getbbox()
    image = image.crop(bounds)
    fitted = ImageOps.contain(image, (size[0] - 4, size[1] - 4), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', size)
    canvas.alpha_composite(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
    canvas.save(media / f'{name}.tga', compression=None)
    canvas.save(art / f'{name.lower()}-runtime.png')

# Asset check at actual in-game pixel sizes; not a native screenshot.
sheet = Image.new('RGBA', (820, 350), '#181818')
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 13)
d.text((20, 12), 'Postly - branding size check (not an in-game screenshot)', fill='#f3d599', font=font)
d.text((20, 44), 'Mailbox header: 64px full emblem', fill='#e8d9bb', font=small)
d.rounded_rectangle((20, 70, 340, 174), radius=4, fill='#302e29', outline='#857a66')
full = Image.open(media / 'Icon.tga')
mini = Image.open(media / 'MiniIcon.tga')
sheet.alpha_composite(full.resize((64, 64), Image.Resampling.LANCZOS), (36, 82))
d.text((112, 92), 'Postly', fill='#ffd159', font=font)
d.text((112, 120), 'A little help for your bank alt.', fill='#b8ab91', font=small)
d.text((390, 44), 'Compact mini bar: 34px simplified icon', fill='#e8d9bb', font=small)
d.rounded_rectangle((390, 70, 642, 122), radius=4, fill='#302e29', outline='#857a66')
sheet.alpha_composite(mini.resize((34, 34), Image.Resampling.LANCZOS), (398, 79))
d.rounded_rectangle((440, 80, 596, 112), radius=2, fill='#650900', outline='#b59e70')
d.text((471, 85), 'Send items', fill='#ffd159', font=small)
d.text((613, 84), '+', fill='#ffd159', font=font)
d.text((20, 202), 'Simplified icon at actual sizes', fill='#f3d599', font=font)
for x, size in [(24, 24), (110, 34), (206, 48), (316, 64)]:
    sheet.alpha_composite(mini.resize((size, size), Image.Resampling.LANCZOS), (x, 238))
    d.text((x, 314), f'{size}px', font=small, fill='#e8d9bb')
sheet.convert('RGB').save(art / 'asset-preview.png')
print('Prepared Icon, Header and MiniIcon textures and actual-size asset preview.')
