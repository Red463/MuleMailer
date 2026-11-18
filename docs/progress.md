# Mule Mailer development record

Current deliverable: MuleMailer 0.3.0, a Forever-only client-validation build.

## Implemented

- Native settings, compact mailbox controls, category/item filters, per-item keep quantities, original-stack identity checks, manual-draft preservation and click-driven mail batches.
- Red/gold/cream branding from user-supplied artwork. Transparent icon/header assets, original references and exact image-edit prompts are preserved in docs/branding.
- Runtime identity, folder and TOC use MuleMailer; saved settings use MuleMailerDB; only /mulemailer is registered.

## Identity cleanup

The user explicitly requested removal of every reference to the earlier addon name and its commands. Removed compatibility aliases and subject-migration code, renamed source/docs paths, updated all tests/tools/documentation, and removed obsolete release archives. This build does not import settings from earlier namespaces. No installed game files were modified.

Watched the new identity/sole-command assertions fail (46 pass, 2 fail), applied the clean rename and verified 48 tests passing. Tests include full TOC startup and native settings callbacks, mail safety/error ordering, UTF-8 self-recipient checks and settings validation. Eight runtime Lua files compile under Lua 5.1. Asset checks verify power-of-two dimensions, uncompressed 32-bit TGA and transparent alpha.

## Verification limits

No live mail was sent. Actual Forever API permissions, persistence across a full client restart and in-game layout/scaling remain unverified. The build is labelled client-validation and includes a manual checklist. Native restrictions are honored; every mail submission requires a deliberate UI click and uncertain outcomes never retry automatically.

## Character setup and discovery 0.3.1

The user reported an empty character picker and confusing realm input. Read-only inspection found one recorded character in the current saved namespace, so excluding the current character legitimately leaves an empty list. No retroactive account roster is claimed.

Regression tests reproduced two additional startup paths: UnitFullName returning an empty realm prevented the fallback; early discovery keys were not refreshed by PLAYER_LOGIN once initialization had run. Fixed nonempty identity validation and realm fallback, refresh at PLAYER_LOGIN and PLAYER_ENTERING_WORLD. Tests also cover same-realm name-only labels and selecting another recorded character through the actual picker callbacks.

UI now asks for Character name, explains no realm is required, displays same-realm names without suffixes and gives a precise empty-list explanation. Internal address normalization, faction scoping and self-mail safety remain intact. Existing current-namespace settings are preserved. No game files changed and no live mail sent.

Verification: 52 tests pass; eight Lua files compile; runtime texture checks pass. Actual multi-character logins on the user's client remain to be checked by visiting each character with Mule Mailer enabled.

## Shared bank recipient recovery 0.3.2

Read-only inspection of the installed 0.3.0 saved configuration confirmed the recipient was saved under moneybags:Alliance while the main used eppingworth:Alliance. This was scope fragmentation, not proven SavedVariables loss. The earlier realm/faction interpretation was incorrect for the user's single-realm Forever setup.

Client and Store now use one shared scope per faction. Migration gathers prior same-faction scopes, recovers a unique recipient unchanged, updates observed character scope metadata and preserves original source data. Multiple recipient candidates require an explicit selection. A scope marker makes migration idempotent; populated key collisions are copied to scopeBackups before replacing the canonical key. Differing prior rules, including all-disabled defaults, become character overrides so no character unexpectedly gains enabled selections.

Typed name-only recipients stay name-only; the full native bank address remains intact for RegisterBank. Current-character self-mail detection covers both forms. Existing overrides and faction separation remain intentional. No installed addon or saved-variable files were modified during development.

Watched the realistic two-character recipient regression fail before the fix. Independent targeted review found default-selection preservation and populated-key collision issues; both were reproduced with failing tests and fixed. Final suite: 59 passing tests; eight runtime files compile; asset checks pass. Runtime account persistence and actual mail delivery still require client verification.

## Item review cards 0.4.0

User requested item pictures and a clearer review section. Implemented native in-game item icons with rarity borders/names, quantity badges, separate Send/Keep counts, full hyperlink tooltips and pooled card frames. Skipped items are separate, collapsed by default, and expand with a reason per item. Reduced unused space above the review viewport without widening the mailbox panel. Review expansion and tooltips are read-only; no mail submission paths changed.

Client.ItemDisplay uses cached item metadata and the native icon getter, with safe loading/unknown fallbacks and existing throttled data requests. API signatures checked against the Forever Blizzard item documentation. Automated behaviour tests cover metadata, uncached icons, quantity labels, row reuse, tooltip identity, collapsed skipped rows and no sends while inspecting/toggling review. Watched three failures before implementation; final suite has 62 passing tests. Actual native card appearance remains pending a game screenshot; mocks prove callbacks/state only.

Independent targeted review found no serious actionable defects, independently reran 62 passing tests and confirmed static geometry/pooling state. Release 0.4.0 keeps the same MuleMailerDB namespace and all prior recipient-recovery behaviour. Archive verified against all 13 allow-listed runtime files, including unchanged brand textures. Native font/template rendering and actual game scroll clipping remain live checks.

## Selected mail-tab guard 0.4.1

User screenshot showed the Send Mail composer open while the addon claimed account access was unavailable. Root cause: the guard interpreted IsEnabled=false on a selected native tab as an account restriction. Blizzard panel templates disable selected tabs to prevent redundant clicks.

Regression reproduced a click-disabled but selected/active/visible composer. The guard now accepts that precise state, while retaining limited-account, hidden-tab, explicit isDisabled, unselected disabled-tab, native pending-command, confirmation-lock and native send-button checks. Selected state uses PanelTemplates_GetSelectedTab with selectedTab fallback, requires activeSubFrame==SendMailFrame, and does not enable or override any native control.

Watched the selected-tab regression fail and then pass; explicit disabled-state regression also failed before its guard was added. Final suite: 63 tests pass, eight Lua files compile and texture checks pass. No live mail sent. Reference: Blizzard SharedUIPanelTemplates SelectTab disables clicks, while DisableTab sets isDisabled explicitly: https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXML/Classic/SharedUIPanelTemplates.lua .

## Protected-action and draft diagnostics 0.4.2

The user's attempted script diagnostic produced a protected-action popup. Do not repeat that script; a script context is not a reliable way to inspect restricted client state. The precise one-item draft mismatch remains unconfirmed.

Audit found unnecessary protected SetSendMailMoney/SetSendMailCOD calls in the addon submission path. Removed them: zero money/COD is already required by verification, so no reset is needed or permitted. Regression proves valid item-only submission succeeds when those setters throw. No bypass was added.

MatchesDraft now records/reports which field failed without printing private contents. /mulemailer debug prints only a cached string and calls no native UI/mail APIs. Blocked-action events capture the function identifier and latch further mail actions off until reload. Tests cover cached-only diagnostics and blocked-action latching. 65 tests pass with eight runtime Lua files compiling and texture checks passing. This is a diagnostic build; live first-attachment mismatch is not claimed fixed.

## Complete queue diagnostics 0.4.3

User confirmed retrying before debug, yet no diagnostic was recorded. Read-only inspection verified installed 0.4.2 files match workspace. Root cause in diagnostic coverage: only MatchesDraft and blocked-action events cached messages; Fail for attachment errors/timeouts and caught Pump errors did not. Pump also discarded its caught error value.

All Fail paths now cache the stop reason; caught Lua error text is safely bounded and retained. Attachment checks distinguish occupancy, loading, ID, count, position and link differences. /mulemailer debug prints loaded version, queue state and cached failure without invoking native APIs. Regression failed for an attachment mismatch and now checks caught native-update errors; debug metadata assertions also failed before the change. 66 tests pass. Actual one-item stop remains unconfirmed and needs this captured diagnostic, not another guessed permission change.

## Forever first-name/surname correction 0.4.4

Cached diagnostic identified a recipient mismatch, and the user confirmed manual mail uses Mosswick Moneybags, with a space. The earlier assumption that UnitFullName's second Forever component was a realm was wrong: it is a surname. Primary addon release notes confirm this client distinction: https://github.com/tomqwu/wow_forever_classmate/releases . Blizzard's two-name feature: https://worldofwarcraft.blizzard.com/en-gb/news/24304161/create-a-name-of-your-own-in-wow-forever .

Normalize now produces full space-separated names, upgrading legacy hyphen separators while retaining both parts. Resolve converts shared and character recipient values, picker labels preserve surnames, RegisterBank constructs the full name and the queue normalizes before preparing/submitting. Both queue and client submission use full-address comparison permitting case/spacing but rejecting different surnames, different first names or first-name shortening. Mismatch diagnostics retain quoted expected/actual addresses. Tests reproduce async attachment updates with a formatting change and ensure every planned stack is attached before a deliberate send click.

69 tests pass; eight runtime files compile and textures validate. Independent focused review found no blocking recipient-safety issue. No live mail sent. Residual API fallback to actual realm if UnitFullName has no surname is unverified; current observed two-part names are retained correctly.

## Bag echo during mail preparation 0.4.5

Screenshot showed first native attachment and preparation timeout. Old pending condition required carried item total to decrease before proceeding. Added a client simulation retaining all attached items as locked bag slots: old code stalled at one instead of five. New code confirms exact native attachment contents and treats attached quantities as reservations by original source GUID. Effective stock handles both reflected removals and retained bag echoes, and is used by selection, validation and pre-submit keep checks. Intermediate quantities are handled conservatively.

Partial stack regression covers 53 carried, 33 attached, 20 retained with unchanged bag echo. A decreased echoed count correctly blocks if retained stock was lost. Original source/variant/quota checks remain enforced; events/timers never submit mail. A fixture initially had a stale original-source quota of20 despite53 stock, corrected to the planner's real53 count before final passing result. 71 tests pass, all runtime files compile and texture checks pass. Live behaviour still needs confirmation after updating.

Independent focused review found no serious findings for reservations, source quotas, partial stacks or multiple batches. When counts are inherently ambiguous, the code cannot prove every possible external inventory mutation; this is not an absolute external-loss detector. Standard echoed/removal behaviours and keep regression cases are tested. No native guard or protected-action restriction was removed.
## Mailbox layout and native close handling 0.4.6

User confirmed 0.4.5 transfers worked, then requested a clearer mailbox panel and closure alongside the native mailbox. Reduced header and vertical spacing, changed totals to natural singular/plural text on one line, and show Stop only during a transfer. Review and Options use the available footer width while idle. Status text is measured before positioning buttons so longer diagnostics retain space; item cards and their tooltip behavior are unchanged.

Both displays are parented to the native MailFrame. A native OnHide hook clears review state, delivers the existing queue close transition, and explicitly hides both displays, supplementing MAIL_CLOSED and preventing automatic reappearance on parent show. Regressions first failed for native hide without MAIL_CLOSED and idle Stop visibility, then passed. Coverage includes expanded review, compact mode and reopening without resuming. 73 tests pass, with eight runtime files compiling under Lua 5.1 and texture validation passing. Native visual verification remains in game; no live mail was sent during development.

## Configurable mail subject clarity 0.4.7

The existing sending.subject setting already flowed into every plan and mail batch, but its buried Subject prefix label was unclear. Renamed it Mail subject and added explicit Save and Reset to default controls in Sending, with a shared-setting/default hint. Default remains Mule Mailer; existing custom settings are preserved. Reject whitespace-only and control-character subjects. Existing settings locking protects changes during transfers. Regression tests first failed for missing controls, then passed for saving into the real plan, reloading saved data, reset, invalid input and active-transfer rejection. All 75 tests pass; eight runtime files compile under Lua 5.1 and texture checks pass. No mail API or protected-action path changed. Native UI verification remains in game.

## Mailing workflows 0.5.0

Implemented all seven requested improvements: named presets; temporary Review exclusions; quick Always/Never rules; clearer skipped reasons and settings shortcuts; toggleable postage preview; detailed history; category/item recipient routing. The native mailbox remains the starting point and only extra selectors relevant to the current setup are shown. Default retains legacy shared and character settings. Presets are same-faction copies with per-character selection. Routes are disjoint by item ID, with item > category > bank precedence; destination changes require idle state and never send.

History snapshots every submitted batch before the call, preserving full sender identity, recipient, subject, preset, timestamps, quantities, original item links/variants, source GUIDs and readable native postage. Reconciled acceptance is separate from blocked, failed and uncertain results. Pending records become uncertain after reload. Retain latest 500, with search, outcome filters, expandable details and item tooltips. Postage preview is independently toggleable; the pre-composer estimate explicitly assumes the empty-composer native rate applies per attachment, while prepared/history cost uses the native price. Source for native display: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua . No protected setters, event/timer send calls, simulated clicks or auto retries were added.

Tests exercised preset persistence/isolation/deletion, default migration, routing and exclusion keep safety, review menus/checks, configuration locks, optional preview reads, exact native-adapter history, search/details and failure outcomes. Independent review found preset-switch exclusion clearing and native-block outcome ordering; both reproduced with failing regression tests and are corrected. Exclusions now persist until mailbox close. Native blocked SendMail during submission is classified before the generic queue failure. Final focused review found no remaining issues. 91 tests pass; ten runtime Lua files compile and branding textures validate. The package contains 15 allow-listed files. No game installation was modified or live mail sent; native layout and server behavior remain for in-game validation.
