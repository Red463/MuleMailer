# Postly artwork

The user supplied `postly-emblem.png`, a golden mailroom emblem with transparent alpha. It is the branding source for the addon icon, mini bar, mailbox and dedicated settings header. The source is used unchanged; no generative redraw or background removal was needed.

`icon-transparent.png` and `header-transparent.png` are exact copies of that supplied source. `tools/prepare_branding.py` crops only transparent margins, preserves aspect ratio, and packs the artwork into uncompressed 32-bit RGBA WoW textures: Icon.tga at 256x256 and Header.tga at 1024x512.

`asset-preview.png` is an asset check sheet, not an in-game screenshot. Verify the final appearance at native UI scales in the game. The interface follows the Gatherly warm-stone theme: opaque warm grey panels, darker inset fields, neutral borders, cream text and gold accents. The supplied emblem retains its original colours.


## Small-size branding (0.7.3)

The full mailbox header retains the original emblem, enlarged from 40px to 64px with 24px additional space below the header. The compact mini bar uses `Media/MiniIcon.tga`, built from `mini-icon-transparent.png`: a simplified cream envelope, large red wax seal and gold envelope motif, without lettering or surrounding decoration. The 252x52 mini bar and its 34px icon region retain their dimensions. The supplied full emblem remains unchanged for the addon list and settings portrait.

The simplified asset was generated using the built-in image tool with transparent_background=true, using `postly-emblem.png` as the style and subject reference. No external image API was used. The generated source was copied into the repository; alpha is preserved through the deterministic texture pipeline. The preview now shows the full 64px emblem and simplified icon at actual small sizes on the warm-grey theme.

Prompt: Create one standalone cream parchment envelope derived from the supplied emblem, with bold dark-brown outlines, warm golden edging, a large glossy red wax seal with a gold envelope outline, and two short ribbon ends. Match the warm hand-painted fantasy aesthetic while simplifying for 34px readability. Square canvas, small transparent margin, minimal texture, broad highlights. No text, eagle, building, bags, foliage or outer frame. True transparent background.


## Postly P seal (0.8.1)

Replaced the gold envelope outline inside the mini icon wax seal with the ornate gold capital P from the supplied Postly wordmark. The edit used the current mini icon as target and full emblem as lettering reference, via the built-in image tool with transparent_background=true. The envelope, cream parchment, red seal and ribbons remain. The full emblem is unchanged.

Edit prompt: Replace only the small gold envelope symbol in the red wax seal with one uppercase gold P matching the flared pointed serif letter at the start of Postly in the full emblem. Centre it boldly for 34px readability with red negative space around it. Preserve the envelope silhouette, cream parchment, gold edges, seal shape, ribbons, composition and lighting. No other letters or decorations; preserve transparent alpha.
