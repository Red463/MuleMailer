# Postly artwork

The user supplied `postly-emblem.png`, a golden mailroom emblem with transparent alpha. It is the branding source for the addon icon, mini bar, mailbox and dedicated settings header. The source is used unchanged; no generative redraw or background removal was needed.

`icon-transparent.png` and `header-transparent.png` are exact copies of that supplied source. `tools/prepare_branding.py` crops only transparent margins, preserves aspect ratio, and packs the artwork into uncompressed 32-bit RGBA WoW textures: Icon.tga at 256x256 and Header.tga at 1024x512.

`asset-preview.png` is an asset check sheet, not an in-game screenshot. Verify the final appearance at native UI scales in the game. Gold, dark red and cream remain the interface palette.
