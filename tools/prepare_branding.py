"""Pack already-edited, transparent artwork into WoW textures; no image API calls."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.test-deps'))
from PIL import Image, ImageOps, ImageDraw, ImageFont

art = root / 'docs' / 'branding'
media = root / 'Media'
media.mkdir(exist_ok=True)
for source, name, size in [('icon-transparent.png', 'Icon', (256, 256)), ('header-transparent.png', 'Header', (1024, 512))]:
    image = Image.open(art / source).convert('RGBA')
    assert image.getchannel('A').getextrema() == (0, 255), source
    bounds = image.getchannel('A').getbbox()
    image = image.crop(bounds)
    fitted = ImageOps.contain(image, (size[0] - 4, size[1] - 4), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', size)
    canvas.alpha_composite(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
    canvas.save(media / f'{name}.tga', compression=None)
    canvas.save(art / f'{name.lower()}-runtime.png')

# Asset QA contact sheet, not an in-game screenshot. Check real display sizes
# and transparency against the same red used by the addon backdrop.
sheet = Image.new('RGBA', (760, 350), '#18120f')
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 13)
d.text((20, 16), 'Mule Mailer — runtime asset check (not an in-game screenshot)', fill='#f3d599', font=font)
d.rounded_rectangle((20, 58, 740, 225), radius=8, fill='#240906', outline='#e6a63d', width=2)
header = Image.open(media / 'Header.tga').resize((300, 150), Image.Resampling.LANCZOS)
sheet.alpha_composite(header, (32, 66))
d.text((354, 110), 'A little help for your bank alt.', fill='#edc16e', font=font)
d.text((354, 145), 'Choose what travels. Keep what you need.', fill='#f4e4bd', font=small)
icon = Image.open(media / 'Icon.tga')
x = 24
for size in (32, 38, 48, 64):
    sheet.alpha_composite(icon.resize((size, size), Image.Resampling.LANCZOS), (x, 250))
    d.text((x, 320), f'{size}px', font=small, fill='#f4e4bd')
    x += 100
d.text((445, 265), 'Gold frame / red leather / cream text', font=small, fill='#f4e4bd')
sheet.convert('RGB').save(art / 'asset-preview.png')
print('Prepared Icon.tga (256×256), Header.tga (1024×512), and asset QA preview.')
