# Postly

<img src="docs/branding/postly-emblem.png" alt="Postly golden mailroom emblem" width="420">

A WoW Forever addon for sending selected crafting materials to a saved bank character.

Open source under the [MIT License](LICENSE). Contributions and bug reports are welcome.

**0.7.0 introduces the Postly name and golden mailroom emblem.** The addon folder and TOC are `Postly` and `Postly.toc`, saved data uses `PostlyDB`, and `/postly` opens the dedicated settings window. This identity uses its own saved settings; configure your bank alts and rules after installation. The tabbed window, friendly bank names, material/item destination dropdowns, per-item material controls, percentage keeps and detailed History tab are included. Native appearance still requires in-game verification.

## Install and configure

1. Extract the release ZIP so `World of Warcraft/_forever_/Interface/AddOns/Postly/Postly.toc` exists. Avoid a second nested Postly directory.
2. Enable Postly in the character selection AddOns list. Start/restart the client if a newly added addon is not listed.
3. Type `/postly` to open the dedicated settings window. **Settings > AddOns > Postly** provides the same command and an **Open Postly settings** button.
4. On **Bank alts**, enter a friendly name (for example **Crafting**) and the full character name (for example **Mosswick Moneybags**), then click **Add bank alt**. You can type a name, choose a character recorded while the addon was enabled, or fill in the current character. Forever uses a first name and surname separated by a space; do not add a realm or hyphen. Record as many bank alts as needed and select a default destination. Current-character entries are available for your other characters; you cannot choose yourself as a sending destination.
5. On **Materials**, select categories, set Keep values, and select each destination using its bank alt's friendly name. Choose **More...** to inspect known base materials and additional materials encountered by the addon, exclude individual items, or set custom Keep values. The catalog can grow as you encounter new items; classification and mail eligibility still use item metadata.
6. On **Individual items**, type an item ID or drag an item from your bags onto the clearly labelled Item ID box. Choose Always send, Never send, or Use material selection, enter an optional Keep override, and click **Add / Update**. Each item also has a destination dropdown. Visit a mailbox to review and send.

Bank alt friendly names are shared across same-faction characters. Editing a bank alt's address updates its saved default and routes across presets and character overrides; historical records retain the original recipient. Deleting an entry in use is blocked until you reassign those destinations. Legacy recipients and custom destinations appear automatically with their character names as initial friendly names.

If installing with GitHub's **Download ZIP**, rename the extracted repository folder to **Postly** before copying it into AddOns.

Install the **Postly** folder from the ZIP. Only one copy of the addon should be enabled. The addon ID, TOC and saved-data namespace are Postly, Postly.toc and PostlyDB. This installation starts with its own settings; automatic import from a different addon identity is not included. Runtime files include the TOC, ten Lua files, Media textures, README and LICENSE.

## Presets and destinations

Keep using **Default** for the existing setup. To make a preset, enter a name on the Presets tab and choose **Create copy**. Change its bank recipient, material/item rules, keep quantities and subject as usual. Those changes belong to that preset. Presets are shared with your same-faction characters; each character remembers its own selection. Select Default to return to the old shared/character settings. Rename and delete apply to the selected saved preset; deletion asks for a second click. Character rule-copy and recipient-override controls apply only to Default.

Use the **destination dropdown** beside a material or individual item to select a configured bank alt by friendly name. The item destination wins over the material destination; otherwise the bank alt is used. Choosing **Use default destination** restores that fallback. Routing does not select items: Never send, selection, keep quantities and mail eligibility still apply.

The mailbox displays a preset selector only when saved presets exist and a destination selector only when more than one group is available. Review and Send apply to the displayed recipient. Select another destination when idle; switching never submits mail. After finishing a destination, any remaining destination is displayed for a fresh deliberate send click. A transfer never sends to a second recipient automatically.

## Mailbox

In **Options â†’ Sending â†’ Mail subject**, enter the subject used for each message and click **Save** or press Enter. The default remains **Postly**; **Reset to default** restores it. This setting is shared across characters and cannot change during a transfer.

The panel shows the recipient, eligible stacks and estimated messages. **Review items** shows item cards with in-game icons, stack-style quantity badges, rarity-coloured names and separate Send/Keep counts. Untick an item to exclude it for this mailbox visit. Excluded items stay visible and can be ticked again; exclusions survive preset changes and clear when the mailbox closes. Saved rules are unchanged. The **...** item menu offers Always send, Never send, item destinations and shortcuts to edit item/material settings. These edits are unavailable during a transfer.

Hover a card for the full item tooltip. Skipped items have a separate Show skipped section with quantities and specific reasons, including keep minimums, Never send rules, unselected materials and eligibility problems. Their item menus let you open relevant settings. Unknown item data uses a loading label and question-mark icon until the client supplies it. **Send to bank alt** prepares attachments and submits the first message if preparation finishes during the click.

If the client updates attachments asynchronously, wait and click **Send prepared mail**. After an accepted message, **Send next batch** prepares/sends the next batch. Each submission requires your click; the addon never submits mail from an event or timer. The actual client's attachment limit is used.

The shorter panel keeps the recipient, a one-line stack/mail summary and the main action together. Review, Options and History share the bottom row while idle; **Stop** replaces History during a transfer. Status messages expand the panel when they need more room. Closing the native mailbox hides the panel, compact button and auxiliary windows and stops further preparation, including when the native frame hides before a mailbox-close event arrives. Reopening does not resume the transfer.

**Sending > Show postage preview in the mailbox** toggles the preview, initially enabled. Before preparation the amount is an estimate: the native empty-composer postage rate multiplied by planned attachment count. The exact prepared-mail price is shown when readable; unavailable values are labelled Unavailable. Actual charges remain controlled by the client. The read-only price API follows the [native mail UI's price display](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua). The estimate is an addon assumption and may differ if Forever changes its pricing rules.

## Detailed history

Choose the **History** tab in settings, or **History** in the mailbox to open that tab. Search by sender, recipient, subject, preset, item name or ID, and filter by outcome. Click a message to expand its full details and hover item rows for tooltips. Clear history requires a second click.

The latest 500 submitted messages are stored locally, newest first. Each records a unique message ID, sender/full name/GUID/faction, recipient, preset, subject, submission/result timestamps, exact native postage if readable, attachment count and total units, and each attachment's ID, exact link/variant, quantity, position and source GUID. The window presents readable sender, recipient, subject, preset, times, postage, quantities and item tooltips; identifiers/variants remain in the saved record. History records postage even when its preview is disabled. Only Postly submissions are logged, from installation of this version onward.

**Accepted by client** means the success signal was reconciled with an empty composer and no pending command; it does not independently prove delivery. **Failed** is an explicit client failure. **Blocked** is a rejected send action. **Pending** awaits confirmation. Timeouts, mailbox closure or reload before confirmation are **Uncertain**, with the reason preserved. Duplicate success signals cannot duplicate records. Preparation errors before submission do not create sent-mail records. Check the inbox before retrying any uncertain message.

**Stop** cancels subsequent messages. A message already submitted cannot be recalled. Unsent attachments remain visible in the normal mail window so you can retrieve them yourself. A timeout or failure never triggers an automatic retry. Check the mail window and recipient's inbox before starting again after an uncertain result.

Opening or reopening a mailbox never sends or resumes a transfer automatically. Postly refuses to overwrite an existing draft, use an occupied cursor, send to the current character, or act during combat. It never sends gold or COD. Normal postage still applies. Other mail addons can interfere; changed drafts or attachments stop the transfer.

Use **-** beside Close to collapse the full window into the **mini bar**: Postly logo, Send button and a separate **+** button to reopen the full window. Collapse and expand remember your display preference, including after reload. Options also offers **Use the compact mailbox mini bar**. Existing compact-button users automatically get the mini bar.

The mini bar's main button shows **Send N stacks**, **Review items**, **Send prepared mail**, **Send next batch**, **Preparing...**, **Waiting...**, **Stopping...**, **Not ready** or **Nothing ready**, matching the normal transfer state. Hover the logo or Send button for the selected destination, preset, subject, counts and status. Drag the logo to move it. The expand button remains available during a transfer so you can reach Stop. Expanding/collapsing changes display only and never starts, stops or changes the transfer.

Mini-bar Send uses the same click-driven action as the full window. Required Review opens the full review before sending. Errors reveal the full window for diagnostics. These automatic reveals retain your preferred compact setting. Closing the mailbox hides both forms and stops the queue as usual.

The Options page can disable automatic display or reset a dragged panel position. Completion output is local to your own chat; no messages are sent to other players. The addon also honors the standard Send Mail tab's account restrictions, native command state and confirmation locks. Missing required inspection APIs disable sending.

## Rules

Categories: herbs, ore, bars, stone, leather/hides, cloth, enchanting materials, gems and cooking ingredients. Item metadata classifies most groups. Ore/bars/stone and raw gems use conservative lists of known item IDs: new Forever materials or ingredients outside the recognized metadata may need an explicit item rule until classified. Item data that has not loaded is skipped until the client resolves it; data lost during an active transfer stops it.

- **Never send** overrides categories and Always send.
- **Always send** selects a specific item even with its category disabled.
- Per-item **Keep** overrides category Keep. A blank item Keep inherits the category value; an uncategorized explicit item defaults to zero. **Use material selection** allows an override without selecting an item when its category is disabled. **Reset** in a material detail view removes its individual rule; saved routing is separate.
- Keep accepts nonnegative whole units or a whole percentage from **0% to 100%**, calculated separately for each item ID across carried bags. With 53 Peacebloom and Keep **20**, send 33; Keep **20%** reserves 11 (rounded up) and sends 42. The reserve is calculated at transfer start and remains fixed through every batch. Bank contents are excluded.
- Bound, quest, refundable and unsupported special-binding items are excluded, including account-bound items. Always send cannot bypass eligibility checks. The server remains the final authority on mail eligibility and recipients.

Forever settings are shared across your same-faction characters, independent of the identity suffix returned by character APIs. The addon does not require a realm choice. Existing differing selections, including disabled selections, are retained as character overrides during migration. Character recipient overrides are separate from character rule copies. **Copy shared rules to this character** creates an independent selection; **Use shared rules** discards the character-specific selection. Settings are locked during a transfer.

The queue follows original bag item GUIDs, quantities and link variants rather than bag slot numbers. Moving an original stack is supported; replacement/combining that makes its identity ambiguous requires a fresh plan. Newly acquired stacks cannot substitute for those selected at the start.

WoW mail events carry no transaction identifier. Postly reconciles a success event with the native pending-command state and an empty composer, but cannot independently prove recipient delivery or distinguish every possible third-party event interference. Every next batch still needs a click; check the inbox after any uncertain result.

## Blizzard policy

Postly is distributed free with readable Lua source. It has no paywalls, advertisements, donation prompts, telemetry, external runtime helper, input simulation, protected-action workaround or gameplay bot. It uses the client-exposed addon API at an open mailbox and requires a deliberate click for every SendMail call. Restricted/blocked actions stop the operation rather than switching to a bypass. Requests for unresolved item data are throttled.

These are engineering constraints based on [Blizzard's UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1); this addon has not been reviewed or endorsed by Blizzard. Blizzard retains control over permitted functionality.

## Development

Runtime: Lua 5.1; no libraries required. For tests only:

```powershell
python -m pip install --target .test-deps lupa==2.8 pillow==13.0.0
python tests/run_tests.py
python tools/prepare_branding.py
python tools/build_release.py
```

The Python commands are development/build tools, never a companion process for the game. Tests include rule precedence, retention, queue cancellation, interference, duplicate events, actual client-adapter flow under widget/API fakes, native settings callbacks and TOC syntax/load order. Fakes cannot establish real client permissions, appearance or persistence.

See `docs/client-verification.md` in the source workspace for the live test checklist and evidence.

## Branding

The supplied golden mailroom emblem appears in the addon list, compact mailbox mini bar, mailbox header and dedicated settings header. Transparent TGA textures preserve the supplied design and use gold, red and cream styling. Postly-0.7.0.zip contains a single Postly folder. The unchanged source logo and a labelled asset preview are retained under docs/branding. In-game layout still needs verification.

## Diagnostics

If a transfer stops, `/postly debug` prints only the last cached mismatch/blocked-action description. It does not call mail APIs or inspect the native UI. Do not use /dump or /run to inspect restricted mail functions. A blocked action stops further addon mail attempts for that session; update/reload before retrying. Item-only submissions validate zero money/COD and never invoke protected money/COD setters.

Debug output includes the loaded version and queue state. All queue failures are recorded, including caught Lua errors and specific attachment mismatches. Debug only reads those cached Lua values. This build improves diagnosis; it does not claim to fix an unconfirmed native attachment failure.

Attachment preparation verifies the native mail slots rather than waiting for carried item counts to fall. The client may retain locked bag copies until sending; those quantities are reserved so they are neither selected twice nor counted toward Keep.
