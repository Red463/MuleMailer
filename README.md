# Mule Mailer

A WoW Forever addon for sending selected crafting materials to a saved bank character.

Open source under the [MIT License](LICENSE). Contributions and bug reports are welcome.

**0.5.3 removes an unnecessary write to Blizzard's global slash-command registry, addressing a potential source of interference with commands such as /ginvite.** It retains the 0.5.2 event-burst performance fix: unrelated item replies do not scan bags, mailbox updates are coalesced, and hidden Options pages are not rebuilt by event updates. The mini bar, presets, review controls, destinations, optional postage and detailed history remain available. Existing settings remain under Default. The user confirmed successful transfers with 0.4.5. Automated tests cover this update; the reported /ginvite failure still needs confirmation inside Forever. The installed client executable observed during development was 1.60.1.70959 (interface 16001).

## Install and configure

1. Extract the release ZIP so `World of Warcraft/_forever_/Interface/AddOns/MuleMailer/MuleMailer.toc` exists. Avoid a second nested MuleMailer directory.
2. Enable Mule Mailer in the character selection AddOns list. Start/restart the client if a newly added addon is not listed.
3. Open **Settings > AddOns > Mule Mailer**, or type `/mulemailer`.
4. Enter the full character name, for example **Mosswick Moneybags**, and click **Save**. Forever uses a first name and surname separated by a space. Do not add a realm or use a hyphen. The bank-registration button fills the complete name. Existing hyphenated saved addresses are converted automatically without dropping the surname. Alternatively log into the bank character and choose **Use this character as bank alt**. The picker lists other characters recorded while Mule Mailer was enabled, on the same faction. Characters logged in before installation are not discovered automatically; visit each alt once with this version enabled and return to your sender. The current character is excluded. You can always type a bank name directly without using the picker.
5. Select categories and keep quantities. Nothing is selected by default. Visit a mailbox to see the Mule Mailer panel.

If installing with GitHub's **Download ZIP**, rename the extracted repository folder to **MuleMailer** before copying it into AddOns.

Install the **MuleMailer** folder from the ZIP. The addon ID, TOC and settings namespace are MuleMailer, MuleMailer.toc and MuleMailerDB. Remove the previous addon folder before enabling this build so only one copy loads. Upgrades preserve MuleMailerDB. This version recovers a uniquely saved shared bank recipient from earlier per-character grouping and shares it across your same-faction characters. Do not delete your saved settings when upgrading. If several different recipients were saved, choose the intended bank character in Options instead of silently selecting one. Runtime files include the TOC, ten Lua files, Media textures, README and LICENSE.

## Presets and destinations

Keep using **Default** for the existing setup. To make a preset, enter a name at the top of Options and choose **Create copy**. Change its bank recipient, material/item rules, keep quantities and subject as usual. Those changes belong to that preset. Presets are shared with your same-faction characters; each character remembers its own selection. Select Default to return to the old shared/character settings. Rename and delete apply to the selected saved preset; deletion asks for a second click. Character rule-copy and recipient-override controls apply only to Default.

Use **To...** beside a material or an individual item to assign another recipient. The item destination wins over the material destination; otherwise the bank alt is used. Clearing a destination restores that fallback. Routing does not select items: Never send, selection, keep quantities and mail eligibility still apply.

The mailbox displays a preset selector only when saved presets exist and a destination selector only when more than one group is available. Review and Send apply to the displayed recipient. Select another destination when idle; switching never submits mail. After finishing a destination, any remaining destination is displayed for a fresh deliberate send click. A transfer never sends to a second recipient automatically.

## Mailbox

In **Options → Sending → Mail subject**, enter the subject used for each message and click **Save** or press Enter. The default remains **Mule Mailer**; **Reset to default** restores it. This setting is shared across characters and cannot change during a transfer.

The panel shows the recipient, eligible stacks and estimated messages. **Review items** shows item cards with in-game icons, stack-style quantity badges, rarity-coloured names and separate Send/Keep counts. Untick an item to exclude it for this mailbox visit. Excluded items stay visible and can be ticked again; exclusions survive preset changes and clear when the mailbox closes. Saved rules are unchanged. The **...** item menu offers Always send, Never send, item destinations and shortcuts to edit item/material settings. These edits are unavailable during a transfer.

Hover a card for the full item tooltip. Skipped items have a separate Show skipped section with quantities and specific reasons, including keep minimums, Never send rules, unselected materials and eligibility problems. Their item menus let you open relevant settings. Unknown item data uses a loading label and question-mark icon until the client supplies it. **Send to bank alt** prepares attachments and submits the first message if preparation finishes during the click.

If the client updates attachments asynchronously, wait and click **Send prepared mail**. After an accepted message, **Send next batch** prepares/sends the next batch. Each submission requires your click; the addon never submits mail from an event or timer. The actual client's attachment limit is used.

The shorter panel keeps the recipient, a one-line stack/mail summary and the main action together. Review, Options and History share the bottom row while idle; **Stop** replaces History during a transfer. Status messages expand the panel when they need more room. Closing the native mailbox hides the panel, compact button and auxiliary windows and stops further preparation, including when the native frame hides before a mailbox-close event arrives. Reopening does not resume the transfer.

**Options > Sending > Show postage preview in the mailbox** toggles the preview, initially enabled. Before preparation the amount is an estimate: the native empty-composer postage rate multiplied by planned attachment count. The exact prepared-mail price is shown when readable; unavailable values are labelled Unavailable. Actual charges remain controlled by the client. The read-only price API follows the [native mail UI's price display](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua). The estimate is an addon assumption and may differ if Forever changes its pricing rules.

## Detailed history

Choose **History** in the mailbox or **Detailed mail history** in Options. Search by sender, recipient, subject, preset, item name or ID, and filter by outcome. Click a message to expand its full details and hover item rows for tooltips. Clear history requires a second click.

The latest 500 submitted messages are stored locally, newest first. Each records a unique message ID, sender/full name/GUID/faction, recipient, preset, subject, submission/result timestamps, exact native postage if readable, attachment count and total units, and each attachment's ID, exact link/variant, quantity, position and source GUID. The window presents readable sender, recipient, subject, preset, times, postage, quantities and item tooltips; identifiers/variants remain in the saved record. History records postage even when its preview is disabled. Only Mule Mailer submissions are logged, from installation of this version onward.

**Accepted by client** means the success signal was reconciled with an empty composer and no pending command; it does not independently prove delivery. **Failed** is an explicit client failure. **Blocked** is a rejected send action. **Pending** awaits confirmation. Timeouts, mailbox closure or reload before confirmation are **Uncertain**, with the reason preserved. Duplicate success signals cannot duplicate records. Preparation errors before submission do not create sent-mail records. Check the inbox before retrying any uncertain message.

**Stop** cancels subsequent messages. A message already submitted cannot be recalled. Unsent attachments remain visible in the normal mail window so you can retrieve them yourself. A timeout or failure never triggers an automatic retry. Check the mail window and recipient's inbox before starting again after an uncertain result.

Opening or reopening a mailbox never sends or resumes a transfer automatically. Mule Mailer refuses to overwrite an existing draft, use an occupied cursor, send to the current character, or act during combat. It never sends gold or COD. Normal postage still applies. Other mail addons can interfere; changed drafts or attachments stop the transfer.

Use **-** beside Close to collapse the full window into the **mini bar**: mule logo, Send button and a separate **+** button to reopen the full window. Collapse and expand remember your display preference, including after reload. Options also offers **Use the compact mailbox mini bar**. Existing compact-button users automatically get the mini bar.

The mini bar's main button shows **Send N stacks**, **Review items**, **Send prepared mail**, **Send next batch**, **Preparing...**, **Waiting...**, **Stopping...**, **Not ready** or **Nothing ready**, matching the normal transfer state. Hover the logo or Send button for the selected destination, preset, subject, counts and status. Drag the logo to move it. The expand button remains available during a transfer so you can reach Stop. Expanding/collapsing changes display only and never starts, stops or changes the transfer.

Mini-bar Send uses the same click-driven action as the full window. Required Review opens the full review before sending. Errors reveal the full window for diagnostics. These automatic reveals retain your preferred compact setting. Closing the mailbox hides both forms and stops the queue as usual.

The Options page can disable automatic display or reset a dragged panel position. Completion output is local to your own chat; no messages are sent to other players. The addon also honors the standard Send Mail tab's account restrictions, native command state and confirmation locks. Missing required inspection APIs disable sending.

## Rules

Categories: herbs, ore, bars, stone, leather/hides, cloth, enchanting materials, gems and cooking ingredients. Item metadata classifies most groups. Ore/bars/stone and raw gems use conservative lists of known item IDs: new Forever materials or ingredients outside the recognized metadata may need an explicit item rule until classified. Item data that has not loaded is skipped until the client resolves it; data lost during an active transfer stops it.

- **Never send** overrides categories and Always send.
- **Always send** selects a specific item even with its category disabled.
- Per-item **Keep** overrides category Keep. A blank item Keep inherits the category value; an uncategorized explicit item defaults to zero.
- Keep counts units of each item ID across all carried bags, rather than stacks. With 53 Peacebloom and Keep 20, Mule Mailer sends 33.
- Bound, quest, refundable and unsupported special-binding items are excluded, including account-bound items. Always send cannot bypass eligibility checks. The server remains the final authority on mail eligibility and recipients.

Forever settings are shared across your same-faction characters, independent of the identity suffix returned by character APIs. The addon does not require a realm choice. Existing differing selections, including disabled selections, are retained as character overrides during migration. Character recipient overrides are separate from character rule copies. **Copy shared rules to this character** creates an independent selection; **Use shared rules** discards the character-specific selection. Settings are locked during a transfer.

The queue follows original bag item GUIDs, quantities and link variants rather than bag slot numbers. Moving an original stack is supported; replacement/combining that makes its identity ambiguous requires a fresh plan. Newly acquired stacks cannot substitute for those selected at the start.

WoW mail events carry no transaction identifier. Mule Mailer reconciles a success event with the native pending-command state and an empty composer, but cannot independently prove recipient delivery or distinguish every possible third-party event interference. Every next batch still needs a click; check the inbox after any uncertain result.

## Blizzard policy

Mule Mailer is distributed free with readable Lua source. It has no paywalls, advertisements, donation prompts, telemetry, external runtime helper, input simulation, protected-action workaround or gameplay bot. It uses the client-exposed addon API at an open mailbox and requires a deliberate click for every SendMail call. Restricted/blocked actions stop the operation rather than switching to a bypass. Requests for unresolved item data are throttled.

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

The supplied mule-and-envelope artwork appears in the addon list, compact mailbox mini bar, mailbox header and native settings header. Transparent TGA textures use red leather, gold and cream styling. MuleMailer-0.5.3.zip contains a single MuleMailer folder. Source art, exact built-in image-generation prompts and a labelled asset QA preview are retained under docs/branding in the source workspace. In-game layout still needs verification.

## Diagnostics

If a transfer stops, `/mulemailer debug` prints only the last cached mismatch/blocked-action description. It does not call mail APIs or inspect the native UI. Do not use /dump or /run to inspect restricted mail functions. A blocked action stops further addon mail attempts for that session; update/reload before retrying. Item-only submissions validate zero money/COD and never invoke protected money/COD setters.

Debug output includes the loaded version and queue state. All queue failures are recorded, including caught Lua errors and specific attachment mismatches. Debug only reads those cached Lua values. This build improves diagnosis; it does not claim to fix an unconfirmed native attachment failure.

Attachment preparation verifies the native mail slots rather than waiting for carried item counts to fall. The client may retain locked bag copies until sending; those quantities are reserved so they are neither selected twice nor counted toward Keep.
