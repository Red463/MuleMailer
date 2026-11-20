# Postly development record

## 0.7.0 identity and branding

Public name and runtime identity: Postly. Folder/TOC: Postly/Postly.toc. Saved variables: PostlyDB. Slash command: /postly (and /postly debug for cached diagnostics). The supplied transparent golden mailroom emblem is packed directly into native TGA textures without redrawing it.

The addon provides bank alt friendly names, same-faction discovery, material and individual-item destination dropdowns, per-item material overrides, integer and percentage keeps, named presets, review exclusions, mini bar and detailed mail history. Settings are presented in a draggable native frame with Bank alts, Materials, Individual items, Presets, Sending, Display and History tabs. Native Settings provides a launcher.

Percentage keeps round up and resolve at transfer start to fixed reserves retained across batches. Item-data replies update labels without replacing uncommitted field edits. Current regression coverage includes routing, configuration persistence, eligibility, locks, queue identity checks, native adapter flow and coalesced item-event processing.

PostlyDB is a new saved-data identity; automatic imports from other addon identities are not included. No game files are modified by development tools. No live mail has been sent in development. Each mail submission requires a real user click; native restrictions, draft protection, stop behavior and uncertain-outcome handling remain in place. Appearance, UI scaling, drag/drop and server behavior must be checked in-game.
