# Changelog

## 0.4.0 — 2026-11-10

- Give the window WoW: Forever's own look on Forever, as Soundstone 0.4.0 wears it: the client's bronze window frame with its rock ground and title strip, a red gear button and Blizzard's red close button in the strip, and the title in the client's `NORMAL_FONT_COLOR`. The settings and the delete dialog wear the same frame; the realm and client buttons and their menus take Forever's dropdown art, the format toggle one dropdown field divided between Combined and Hours, the search field the same field, Reset position, Done, Deleted characters, Cancel and Delete Blizzard's red buttons, the size slider Forever's track and copper diamond, and the character table Blizzard's inset over the window's rock, darkened. Inside the frame the window is 20 units shorter, and its top edge stays where it was. Class colors, the current character's marker, Vault states and the heart are unchanged. The plan and the measurements it rests on are in the [theme document](docs/FOREVER-THEME.md).
- Fall back piece by piece where the client lacks a piece of Forever's art: to a flat near-black plate with an inner shadow and a one-pixel bronze line, lit from the top like Forever's tooltips, flat controls with a thin bronze outline, and a warm white, a muted warm gray and a pale gold accent for the interface text. Every line, outline and inner-shadow step of this fallback is one physical pixel wide at every Hourstone size, UI scale and resolution.
- Use Forever's art on the Forever client only; the look follows the client and has no switch. Retail, Mists Classic, TBC Anniversary and Classic Era stay exactly as in 0.3.7: a test compares every visible region with 0.3.7 on all client families.
- Cover the frame, each fallback and the pixel width in the simulation. The fallback's flat look was measured in the live WoW: Forever client on 9 November 2026 (one-pixel lines in the planned colors at 135 %, titles in `#FFD200`); the author tested the frame in the live Forever client on 10 November 2026 and accepted it after three changes (the format toggle, the search field and the ground under the table).

## 0.3.7 — 2026-11-05

- Label synchronized WoW: Forever characters that this account has not recorded itself, such as another account's or another PC's, as **WoW: Forever** on every client, Forever included. Companion 0.2.2 adds an optional `foreverSources` list of Forever source IDs to the generated format 4 data ([addendum](docs/sync-protocol-v4-forever.md)); Hourstone labels a received Retail-family row whose winning observation comes from a listed source. Protocol 4, the `retail` flavor, keys, merging, totals and SavedVariables schema 3 are unchanged.
- Keep this database's own markers authoritative for the characters it has recorded, so a `WTF` folder copied from Retail into Forever keeps its Retail entries.
- Validate the list like every other received field: a malformed list, or one in formats 1–3, rejects the payload, and every import starts without a list. Hourstone 0.3.2 to 0.3.6 ignore the list.
- Offer WoW: Forever in the client filter on every client whenever a row of the current view is a Forever character, and keep the entry while it is selected. Retail's progress view treats labelled characters as unsupported.
- Save WoW: Forever surnames as part of the name. Live Forever returns the surname where other clients return the realm (`UnitFullName` gives "Magni", "Wildschuss"), so 0.3.5 and 0.3.6 showed "Magni" with the realm "Wildschuss" and listed surnames in the realm filter. Hourstone now saves "Magni Wildschuss" and the realm from `GetRealmName()`, such as "CAMWOW EU4 Realm 10 RP". Each character is corrected at its next login in Forever; other clients are unchanged.
- Cover the list with fixtures shared with the Companion, including the Companion's generated data byte for byte, the labels in the Retail and the Forever client, validation and reset, the menu, and imports by the tagged releases 0.3.2 to 0.3.6.

## 0.3.6 — 2026-11-05

- Show WoW: Forever characters as **WoW: Forever** instead of Retail in the client column, the row tooltip and the client sort. In the Forever client, the client filter offers WoW: Forever next to Retail. The label is a display marker (`client = "forever"`) beside the Retail flavor; character keys, overview removal, SavedVariables schema 3 and Companion protocol 4 are unchanged.
- Mark every character Hourstone records in Forever. On the first load of this version in Forever, also mark every Retail-family entry of a database that Hourstone created after the Forever launch (2026-11-04 23:00 UTC, read from the source ID), and entries returned from a `project-` client. An older database, such as a `WTF` folder copied from Retail, keeps Retail; its Forever characters switch at their next login. Each database now records the client that last loaded it, so one copied from another client running 0.3.6 or later is never marked.
- Keep the label when a synchronized observation of a Forever character wins the merge. Retail's progress view treats Forever characters as unsupported. Protocol 4 carries no client marker, so every client, Forever included, still lists synchronized Forever characters that this account's own database has not recorded, such as another account's or another PC's, under Retail.
- Record that 0.3.5 ran in the live Forever client (build 1.60.1.70790) and saved its characters with a non-empty realm and the eu region, and the author's in-game test of this build there.
- Cover the marking, the one-time update of earlier entries, copied databases, synchronized observations, the client filter and sort, the progress exclusion and the menu in the simulation.

## 0.3.5 — 2026-11-03

- Never record an unknown client on WoW: Forever. On a Forever interface (16xxx), every project ID the client reports counts as the Retail client family, so a further change of Forever's project ID cannot split its characters off again.
- When Hourstone loads on Forever, return characters that an earlier version filed under any unknown client (`project-…`, such as `project-18` from 0.3.3) to the Retail family and merge them with an earlier Retail entry of the same character without double-counting playtime. A record whose merge fails keeps its original client.
- Never save an empty realm or character name. WoW: Forever replaces realms with rulesets; if `UnitFullName` reports no realm, Hourstone uses `GetRealmName`, then `GetNormalizedRealmName`, then `?`, and an empty name becomes `?`. The Companion and Hourstone's checks for received data reject an empty realm, and in the Companion one such entry would block the whole account.
- Retail and Classic clients, SavedVariables schema 3 and Companion protocol 4 are unchanged.
- Cover any project ID on a Forever interface, the migration of every unknown client and the realm and name fallbacks in the simulation.
- Stop calling WoW: Forever a beta ahead of its launch on 2026-11-04 at 23:00 UTC and refer to Companion 0.2.1, whose Hourstone_Sync data addon declares 120105 and 16001 and is therefore no longer out of date in WoW 12.1.5 and Forever.

## 0.3.4 — 2026-10-25

- Declare Retail interface 120105 so WoW 12.1.5 no longer lists Hourstone as out of date. None of the APIs, events, widgets or templates Hourstone uses changed between 12.1.0 and 12.1.5.
- Keep WoW: Forever characters in the Retail client family on Forever builds that report their own project (1.60.1.70170 and later). When Hourstone loads on Forever, every character that 0.3.3 recorded there as an unknown client returns to the Retail family and merges with an earlier Retail entry of the same character without double-counting playtime. Removing them from the overview works again, and Companion protocol 4 exchanges them as Retail characters.
- Simulate current Forever builds next to earlier ones and cover the migration, including characters that are not logged in and a reload directly from 0.3.3.

## 0.3.3 — 2026-09-24

- Register Hourstone in WoW's Addons menu at runtime where the client provides it. Left click opens or closes the window like the minimap button; the tooltip uses the existing helpers. Right clicks are ignored, as on the minimap button.
- Hide the minimap button once on clients with the Addons menu. The settings option and `/hourstone minimap` still work, and turning the button back on persists. Clients without the menu keep the button unchanged. Hiding the button prints where Hourstone can still be opened.
- Support the WoW: Forever beta (interface 16001). Forever uses the Retail API with Hourstone's Classic design and playtime view; the Retail progress view is not offered there. Forever characters keep the Retail client family required by Companion protocol 4.
- Resolve CurseForge game versions only within WoW client families, including WoW: Forever (1.60.1).
- Add simulation coverage for WoW: Forever, the Addons menu entry, and the migration across reloads.

## 0.3.2 — 2026-09-18

- Receive Retail keystones, weekly Mythic+ best and all three Great Vault rows through Companion protocol 4, while retaining protocol 1–3 input support.
- Merge the five progress families independently using their server capture times and deterministic ties. Keep received observations separate from locally collected SavedVariables; a newer keystone may decrease or be absent.
- Preserve schema 3 and the version-1 local progress cache, unknown/empty/stale states and server-provided weekly reset deadlines. Future local cache versions remain untouched.
- Advertise protocol-4 support in the TOC so the Companion can continue writing protocol 3 to older addon installations.
- Add cross-language progress fixtures and regressions for source provenance, weekly expiry, malformed input and legacy compatibility.

## 0.3.1 — 2026-09-17

- First public 0.3.x release: includes the Retail progress view and scaling improvements from the development milestone below.
- Prevent periodic refreshes and display events from repositioning the window during a drag. Save the released position before recalculating the layout, including when the window is closed mid-drag.
- Add regression coverage for both Retail views, Classic clients, global UI scales and interrupted drags.

## 0.3.0 — development milestone included in 0.3.1

- Add a Retail Progress tab: current keystone, highest completed Mythic+ level this week and three Great Vault rows with three slots each.
- Read localized dungeon names, key levels, weekly completions and Vault thresholds from Blizzard APIs; distinguish confirmed empty, unknown and stale data.
- Capture progress for the logged-in character, retain offline observations and invalidate old weekly data at the server reset. Keep progress local; SavedVariables schema and Companion protocol remain 3.
- Extend scale to 65–200% in 5% steps, reducing visible rows before fitting the window to smaller screens.
- Preserve Classic playtime views, character/guild filters, removal/restoration and the existing synchronization contract.
- Add progress, layout and scaling regressions and synthetic visual previews. Native-client acceptance is recorded separately in the validation guide.

## 0.2.3 — 2026-09-16

- First public 0.2.x release: includes the development milestones below, adding guild tracking, reversible overview deletion and optional Companion protocol 3 integration since public 0.1.1.

- Put realm and client filters together above the table and show the client in a dedicated sortable column beside playtime.
- Use Blizzard's native minimap tracking border, background and highlight with Retail/Classic geometry and the complete Hourstone logo.
- Keep the server timestamp on one tooltip line, remove presence-status claims and clarify estimated or unconfirmed time.
- Add "with" before the footer heart and consistently label deleted overview entries and their restore actions.
- Preserve character/guild data, saved settings and minimap position. Public 0.1.1 data migrates to schema 3; the 0.2.2 development build already uses that schema and needs no further migration.

## 0.2.2 — development milestone included in 0.2.3

- Remove a character from the overview and totals after confirmation, retaining its saved playtime. Restore it in the removed-character view or at a subsequent actual character login.
- Synchronize removal and restoration across devices with protocol 3 and Companion 0.1.3. SavedVariables schema 3 preserves existing characters, guilds and settings.
- Keep offline and concurrent removals hidden until observed and explicitly restored; reloads, zoning and server playtime updates never restore a character.

## 0.2.1 — development milestone included in 0.2.3

- Record and display each character’s guild, including confirmed guildless and not-yet-recorded states.
- Search character and guild names; keep full guild details in row tooltips.
- Exchange guild changes independently of playtime through protocol 2 with Companion 0.1.2. Legacy protocol 1 input and existing saved data remain readable.

## 0.2.0 — development milestone included in 0.2.3

- Optional Hourstone Companion protocol 1 integration for a combined overview across local client installations.
- Schema 2 stores confirmed server measurements separately from local playtime estimates.
- Deterministic character merge and client-family filtering; session state and settings remain local.
- Neutral product and validation documentation, retained asset provenance and regression fixtures, and repository privacy checks for new commit contents.

## 0.1.1 compatibility update — 2026-09-16

- Add Mists Classic 5.5.4 and Classic Era 1.15.9 to the existing CurseForge release's supported game versions. Addon files and the published ZIP are unchanged.
- Retail, TBC Anniversary, Mists Classic and Classic Era have reported in-game coverage. Hardcore and Season of Discovery are not separately verified.

## 0.1.1 — 2026-09-15

- Native settings checkbox and a 28-unit minimap button with complete logo artwork.
- Dynamic 720-unit-wide window with one to eight visible rows, scrolling, search and realm filtering.
- Soundstone frames and controls, native WoW fonts, fixed title and statistics regions, and improved German format-label spacing.
- Sort by name, level, realm, playtime or last update. Add settings for minimap visibility and 65–130% scale.
- Preserve physical size, saved positions, preferences and header placement as list height changes.
- Expand regression coverage for geometry, scaling, missing font metrics, reload behavior and asset conversion.

## 0.1.0 — 2026-09-15 (prerelease)

- Standalone playtime tracker with account-wide GUID-based character records.
- Server `/played` requests, active-character estimates, reload-aware sessions and offline exclusion.
- Sortable character list, name search, realm filter, totals and two time formats.
- German and English localization, saved window position and scale, and an optional minimap icon.
- Hourglass logo, Soundstone frames, Lua 5.1 simulation tests, deterministic ZIP builds and release workflows.
