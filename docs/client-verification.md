# Forever client verification

Date: 2026-11-18. Build status: client-validation build, not live-verified.

## Evidence

| Check | Result |
|---|---|
| Installed Forever executable | File/Product version 1.60.1.70959 at `_forever_/Wow.exe`; read-only inspection. |
| Interface target | 16001, consistent with the existing Forever addons in this workspace and the published beta API investigation. |
| Item API signatures | Installed Baganator uses C_Item.GetItemInfo, C_Item.IsBound, C_Item.GetItemGUID, C_Item.CanBeRefunded and C_Container.GetContainerItemQuestInfo; source inspection only. |
| Native settings API | Installed Baganator registers a canvas category through Settings.RegisterCanvasLayoutCategory; source inspection only. |
| Attachment API signature | Installed DataStore_Mails reads GetSendMailItem as name, itemID, icon, count; source inspection only. |
| Automated tests | Run `python Postly/tests/run_tests.py` for current count and output. Tests use Lua 5.1 and fakes, not the live client. |
| Live mail transactions | Not attempted. No mail was sent during development. |
| Settings reload / logout / full restart | Not verified in game. No persistence workaround is installed. |
| Native panel appearance / UI scale | Not verified in game. |

Published foundations: [Forever beta API investigation](https://github.com/Thunderz96/forever-addon-kit), [Blizzard mail UI](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua), [mail events](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MailInfoDocumentation.lua), [item API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [Settings API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua).

The beta investigation reported a SavedVariables loading bug. Its status on the installed release build is unknown; do not infer it is still broken or fixed. A failure to persist is a release blocker for a verified release.

The independent review located the actual [Forever mail UI branch](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua), [Forever mail API definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MailInfoDocumentation.lua) and [Forever container definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua). These establish the hidden trial-account Send Mail tab, native confirmation lock, attachment occupancy check and native command-pending predicate used by the final guards. Runtime presence checks still govern availability.

Attachment identity is checked using the full item-string variant from the original bag and native composer; carried stock is restricted by original item GUID and initial quantity. Native attachments expose link identity rather than their bag GUID, so indistinguishable replacements of identical fungible items cannot be proven separately. Mail events likewise expose no per-submission identifier: success is a candidate until the composer is empty and the native mail command is no longer pending. These checks prevent the reproduced timing failures, but do not establish recipient delivery. Uncertain outcomes stop without retry.

## Policy decisions

Based on [Blizzard's published policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1): keep source readable, distribute free, include no ads/donation prompts, avoid adverse server/player impact, and honor disabled addon functionality and game terms. Every SendMail invocation comes from the actual addon button callback. Event handlers/timers only inspect or prepare; no synthesized clicks, macros that bypass restrictions, external automation, file-copy settings bridge or secret-value extraction are present.

## Live checklist

Use inexpensive materials and a recipient you have checked yourself. Review the attachments before deliberately submitting mail. Record actual results/build here before calling a release live-verified.

- [ ] Native Settings > AddOns > Postly registers; `/postly` opens it. Check layout at UI scales 0.75, 1.0 and 1.25.
- [ ] Set recipient/rules; test `/reload`, logout/login and then full client exit/restart. Confirm all three retain settings.
- [ ] Register the bank alt on that character; sender sees the shared recipient. The bank cannot send to itself.
- [ ] Confirm full carried-bag coverage, including any material bag; bank contents are excluded.
- [ ] Check one representative item from every selected category. New mining materials remain excluded unless explicitly configured.
- [ ] Keep 20 of 53 units across multiple stacks; preview sends 33 and actual retained bags contain 20. Verify partial-stack attachments work without blocked-action messages.
- [ ] Check actual outgoing attachment slot limit and a transfer spanning two mails. No second SendMail call occurs until another click.
- [ ] Delay preparation: Send prepared mail appears after asynchronous updates and requires a click.
- [ ] Draft text, attachments, money, COD and occupied cursor each prevent a new transfer without erasing anything.
- [ ] Insufficient postage, invalid recipient, changed attachments and changed inventory stop safely.
- [ ] Stop during preparation and while a mail is pending; only an already submitted message can finish. Unsent attachments remain accessible.
- [ ] Closing the mailbox stops the transfer; reopening does not resume.
- [ ] Ordinary manual mailing works after completion/error recovery, including alongside other installed mail addons.
- [ ] Clearing a manual draft re-enables Send without another bag event. Hidden money/COD, unresolved occupied slots, trial restrictions, pending native commands and refundable-item confirmations prevent Postly submissions.
- [ ] Move an original stack between batches and acquire another stack of the same item. Only the original GUID may be selected. Changed attachment suffix/enchant identity stops submission.
- [ ] Verify no protected-action attempts are retried or bypassed, and no error floods occur.

## Identity update 0.3.0

The display name is Postly. Folder, runtime addon ID, TOC and settings namespace are Postly, Postly, Postly.toc and PostlyDB. Only /postly is registered. This build does not import earlier settings. User-supplied art and texture validation are retained; actual client layout remains unverified.

## Recipient scope recovery 0.3.2

Observed installed 0.3.0 data retained the bank recipient under a different character identity suffix from the main. The update uses a shared per-faction Forever scope, migrates unique saved recipients, preserves disabled/different per-character selections and retains source records/backups. Test updating without deleting PostlyDB, then verify the bank recipient from the main. Confirm characters appear in the picker across different identity suffixes and never cross faction boundaries.

## Dedicated settings 0.6.0 checks

- [ ] `/postly` opens the standalone tabbed frame; native Settings shows a launcher and the command. Launcher brings the standalone frame into view. Close and Escape work; drag the header and check UI scales 0.75, 1.0 and 1.25.
- [ ] Legacy recipients, routes, presets, character copies and history survive the upgrade and reload. Friendly names persist across same-faction alts.
- [ ] Add two named banks using typed and recorded character names. Select their friendly names from default, material and item dropdowns. Rename/readdress an entry and verify relevant preset/character routes. In-use Delete reports how to reassign first.
- [ ] Materials More lists base and discovered items with loading names resolving. While names load, type an unfinished keep override and verify it remains intact. Untick/re-tick an item, enter an override and Reset it; disabled categories must remain disabled unless Always send is selected.
- [ ] Drag an item into the Individual items ID box; save it with its own destination and percentage keep. Blank item keep inherits the material rule.
- [ ] Keep 20% of 53: preview reserves 11 and sends 42. Verify the 11-unit reserve remains fixed across batches; 0% and 100% behave as expected.
- [ ] Open History from the mailbox and settings. Search, expand and filter records; changing tabs cancels Clear confirmation. Closing the mailbox leaves standalone settings usable.
