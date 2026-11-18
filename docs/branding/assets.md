# Mule Mailer artwork

The user supplied four original PNG references and approved Mule Mailer as the public name. Originals are retained under `references/`: icon, wide-logo, mascot-logo and parchment. Runtime art uses the square icon and wide logo. The illustrated mascot logo and parchment sheet remain available for future promotional/layout work.

Built-in image generation was used in edit/background-extraction mode with transparent_background=true. No external image API/CLI or API key was used. Generated originals were copied into the workspace as `icon-transparent.png` and `header-transparent.png`; alpha was retained. The supplied artwork was the edit target, not a source of software instructions.

## Exact icon prompt

Edit target: the supplied square mule mail app icon. Background-extraction only. Remove the white exterior background outside the rounded golden square frame and replace with true transparent alpha. Keep the entire golden frame, screws, red leather interior, brown smiling mule, cream envelope and red wax seal exactly as supplied. Do not redraw or change the character, do not add text. Square composition, frame nearly fills image with a small transparent margin, complete frame unclipped. This is the runtime icon for the Mule Mailer WoW addon.

## Exact header prompt

Edit target: supplied wide Mule Mailer logo. Background-extraction only: remove white exterior background and leave true transparent alpha. Preserve the smiling mule, envelope, ornate gold and dark red leather plaque and the exact words 'Mule Mailer' unchanged. Wide horizontal header composition, logo fills available width, tight transparent margin, ears and bottom gold point fully included. No additional text or decorations. This is the options header logo for the Mule Mailer WoW addon.

## Runtime preparation and QA

`tools/prepare_branding.py` performs deterministic alpha-bound packing and aspect-preserving resizing of these already edited assets. It creates 256×256 Icon.tga and 1024×512 Header.tga, both uncompressed 32-bit RGBA with power-of-two dimensions. No creative repainting or synthetic background removal occurs in the conversion script.

`asset-preview.png` is an asset QA contact sheet, explicitly not an in-game screenshot. It shows the 300×150 header and icon sizes 32, 38, 48 and 64 pixels on a dark background. Visual inspection confirmed readable logo text, preserved ear/frame contours, no white rectangles, and recognizable small icons. Actual game layout remains unverified.

Palette: deep red leather backdrop, warm gold border/title, cream supporting text; native WoW buttons and validation/progress text remain live UI controls.
