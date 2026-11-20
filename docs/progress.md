# Postly development record

## 0.7.0 identity and branding

Public name and runtime identity: Postly. Folder/TOC: Postly/Postly.toc. Saved variables: PostlyDB. Slash command: /postly (and /postly debug for cached diagnostics). The supplied transparent golden mailroom emblem is packed directly into native TGA textures without redrawing it.

The addon provides bank alt friendly names, same-faction discovery, material and individual-item destination dropdowns, per-item material overrides, integer and percentage keeps, named presets, review exclusions, mini bar and detailed mail history. Settings are presented in a draggable native frame with Bank alts, Materials, Individual items, Presets, Sending, Display and History tabs. Native Settings provides a launcher.

Percentage keeps round up and resolve at transfer start to fixed reserves retained across batches. Item-data replies update labels without replacing uncommitted field edits. Current regression coverage includes routing, configuration persistence, eligibility, locks, queue identity checks, native adapter flow and coalesced item-event processing.

PostlyDB is a new saved-data identity; automatic imports from other addon identities are not included. No game files are modified by development tools. No live mail has been sent in development. Each mail submission requires a real user click; native restrictions, draft protection, stop behavior and uncertain-outcome handling remain in place. Appearance, UI scaling, drag/drop and server behavior must be checked in-game.

## 0.7.1 Gatherly-style native theme

Matched the local Gatherly Skin.lua reference: opaque panel RGB .19/.18/.16, field .15/.145/.13, edge .52/.48/.40, cream text and gold accents. Settings uses PortraitFrameTemplate with the Postly emblem and native top tabs where available; the existing native-button fallback remains available. Shared widgets apply the palette to mailbox/mini bar and auxiliary menus and fields. Review rows use matching inset and hover colours while retaining item rarity and status cues. Field focus borders reset correctly through existing commit callbacks. Existing layouts and transfer behavior remain unchanged. Automated verification: 115 tests; native appearance remains an in-game check.

## 0.7.2 material popup stacking

The in-game screenshot showed settings controls interleaved with the More popup. The popup inherited only one frame level above settings, below nested scroll-child controls. Each open now assigns parent level +40 before showing it and enables mouse interception across its opaque background. This preserves child controls above the popup and follows a raised parent when reopening. A regression first failed on popup versus settings-control stacking; it also checks mouse interception and reopen behavior. All 116 tests pass; native screenshot confirmation remains in-game.

## 0.7.3 readable mailbox branding

Approved design: enlarged full mailbox emblem at 64px plus simplified envelope/seal compact icon. Added 24px header clearance to static and dynamic mailbox layout, including preset/destination and postage variants. Mini bar remains 252x52 with a 34px icon. Generated a transparent brand-consistent envelope asset using the built-in image tool, preserved the original full emblem, and extended deterministic packing/QA/release allow-list for MiniIcon.tga. Actual-size asset preview inspected; 34px icon reads clearly. Regression failed on the old 40px full emblem, then passed for larger emblem, separate mini texture, layout clearance and unchanged mini-bar width. All 117 tests pass with three textures validated. Native rendering remains an in-game check.

## 0.8.0 item icons and list search

Both the Individual items list and material More popup display 32px item icons with native item tooltips. Each list has a separately labelled name/item-ID search and a Clear search button. Matching is literal, case-insensitive name/ID substring filtering; empty results show a clear message. Filtering repositions visible existing rows and never changes settings or row-action targets. Material queries reset when opening a category, while Individual items retains its query.

Metadata replies update names/icons and reapply filters without rebuilding editors. A focused Keep editor remains visible during cache updates, preserving uncommitted input. Search remains available during transfers because it is read-only; saved edits still use the existing lock. Regression tests first failed on missing icon controls, then passed for name/ID filtering, literal special characters, filtered Edit targets, clear/no-match results, placeholder textures, loading-name discovery and preservation of a 35% pending Keep edit. Full suite: 119 tests pass, all runtime Lua files compile and all three textures validate. Native visual confirmation remains in-game.

## Postly 1.0 release

User requested pushing all pending code and publishing version 1.0 on GitHub. Version synchronized in Core.lua/Postly.toc and README release/install text updated. Includes the Gatherly theme, popup stacking fix, Clear form/inherit labels, larger mailbox emblem, gold-P mini icon, and searchable item-icon lists. Release packaging retains the allow-listed Postly folder and excludes development dependencies and sources from the installable ZIP. Final validation passed: 119 tests, ten Lua 5.1 runtime files, three transparent textures and an exact-source 16-file release ZIP.
