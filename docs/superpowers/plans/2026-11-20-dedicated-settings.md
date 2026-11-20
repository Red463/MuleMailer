# Dedicated settings implementation plan

User authorized proceeding with judgement on 2026-11-20.

Goal: standalone tabbed settings with named bank alts, material item overrides, percentage retention and embedded history.
Architecture: retain native Lua widgets, Store schema v1 and address-based queue routes. Add a scoped named-bank directory without replacing saved addresses. Resolve percentage rules into integer keep counts in Planner; MailQueue retains these counts unchanged.
Tech stack: Lua 5.1, native game frames, existing Python/Lupa test runner.

Constraints: preserve presets, character overrides and history; settings locked during transfers; one deliberate click for every mail; no new runtime dependencies. No installation or live mail.

1. Add failing Store/Planner tests for percent validation, rounding and inherited item keeps, bank migration, unique names, address updates and safe deletion. Implement Store directory operations and Planner keep resolution. Run suite.
2. Add failing UI tests for standalone settings launcher, tab switching, bank CRUD/selection, material detail controls, destination menus and embedded searchable history. Rebuild Options into focused pages; adapt Workflows history/preset integration. Keep public control handles needed by existing callers.
3. Verify real queue preserves percentage reserve across multiple batches. Exercise settings locks, preset routes, unknown item data, empty directories and current bank character. Update docs/version; run complete suite and package allow-listed release.

Review focus: legacy routes cannot silently redirect; character/preset data must survive migration; percentage keeps include all carried units and round up; unseen material membership must be described honestly; hidden settings must preserve event-burst performance.

Completed: named banks/percent rules, standalone UI/material views/history, review correction, documentation/version and release package. Final verification: 113 tests pass; ten Lua 5.1 files compile; textures validate; release ZIP has 15 allow-listed files. Independent reviewer confirmed the cache-edit fix. Work remains in the user's current workspace; no live installation or mailing performed.
