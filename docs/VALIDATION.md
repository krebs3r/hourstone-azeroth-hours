# Validation

## Automated checks

```sh
python tools/privacy_guard.py
python tests/run.py
python -m unittest discover -s tests -p 'test_*.py'
python tools/package.py
```

Lua tests execute the actual TOC-ordered addon modules through Lua 5.1, with a limited WoW API simulator. The matrix covers supported project IDs, WoW: Forever (interface 16001, as current project 18 and as project 1 from builds before 1.60.1.70170), an unknown-project fallback, German, English and fallback localization, with and without backdrop support. Retail and Forever simulate the Addons menu; all other configurations run without it.

- Tracking: delayed server answers, request intervals, retries, authoritative replacement of estimates, level and character changes, zoning, reload session carry, new-login resets and offline exclusion.
- Guilds: delayed API information, joining/leaving, Unicode names, safe tooltip text, independent metadata merging, legacy snapshots and guild search.
- Removal and restoration: confirmation/cancel, visible-only totals, retained playtime, removed-character view, new-login restoration, missing GUID retries, reload/zoning exclusion, unknown-region adoption, offline and concurrent controls, idempotent merges and bounded validation.
- Model and synchronization: record validation, schema migration, server measurements versus estimates, deterministic merging, duplicate handling and imported records. Protocol fixtures contain synthetic data only.
- Layout: retained [baseline](../tests/fixtures/layout/baseline.json) and [adjustments](../tests/fixtures/layout/adjustments.json), dynamic list height, upper realm/client filters, menu exclusivity and anchors, client sorting including unknown values, column boundaries, nowrap server timestamps, footer credits with unavailable font metrics, saved settings and native minimap references/geometry across four client families.
- Progress: Retail API observations, completed weekly runs, keystone changes and confirmed absence, category/index-based Vault slots, unknown/protected values, reset expiry, offline reads and local identity adoption. Progress stays outside legacy protocol-3 payloads; protocol 4 carries independent progress observations.
- Addons menu and WoW: Forever: runtime registration with logo, tooltip owner fallback, left/right click inputs as string or table, failed registration, the one-time minimap migration including later opt-in across reloads, clients without the menu, Forever detection with Forever's own look (the Classic sprite set beneath it), Classic minimap geometry and no Retail progress view. Forever's project-ID change keeps the Retail family, and so does any other project ID reported on a Forever interface. Loading on Forever migrates every entry recorded under a `project-` client, including `project-18` from 0.3.3, characters that are not logged in and a reload session; Retail leaves such entries untouched. An empty realm from `UnitFullName` falls back to `GetRealmName`, then `GetNormalizedRealmName`, then `?`; an empty name is stored as `?`. On Forever, the simulator reports the surname where other clients report the realm, as the live client does; Hourstone saves name and surname as the name and the realm from `GetRealmName`, corrects the logged-in character's earlier split, leaves other characters until their login and keeps name and realm unchanged on every other client. Forever marks the characters it records and labels them WoW: Forever without changing flavor or key; the first load marks every Retail-family entry, including one saved without playtime, of an unstamped database created from the launch second on, and migrated `project-` entries; it leaves databases created earlier, without a creation time or with a replaced source ID, and databases stamped by any client untouched, other clients stamp their database without marking, and a login outside Forever clears a stale marker. A synchronized observation that wins the merge keeps the label without changing the received data. The protocol 4 addendum's `foreverSources` list labels received Retail-family characters of another account or PC in the Retail and the Forever client when their winning observation comes from a listed source, while the database's own markers decide for characters it has recorded; a malformed list, one in formats 1–3 and every absent, foreign, incompatible or rejected payload leave no list behind. The shared fixtures run in both repositories, including the Companion's generated data byte for byte, and the tagged releases 0.3.2 to 0.3.6 import that data and both payload shapes unchanged. The client filter, client sort and Retail progress support follow the label; the menu offers WoW: Forever in the Forever client, whenever the current view lists a Forever row and while it is selected.
- Scaling: 65%, 130%, 150%, 175% and 200% across display sizes and global UI scales; adaptive visible row capacity, complete scrolling and minimum-size fitting.
- Looks: the client's look in all seven configurations, `forever` on WoW: Forever and `standard` elsewhere, with no switch and a development build's saved `settings.theme` removed. **Forever's frame**, with the mocked `C_Texture.GetAtlasInfo` knowing every name (the mock's atlas sizes are stand-ins): the `ButtonFrameTemplateNoPortrait` border on the window, the settings and the delete dialog at its anchors and levels, rock ground and streaks, corner cropping with the border's height at build and on every height change (and no call where the function is missing); the red gear, Blizzard's red close button and the title in the strip at their computed places; the content 20 units up and the window 20 units shorter, with a saved top edge kept; every visible region of the window, the settings and the dialog clear of the frame (29.75 below the top, 8.3 above the bottom, 8.6 from the sides) at one to eight rows; `UIPanelButtonTemplate` push buttons at their controls' rectangles, forwarding the click and tooltip; the dropdown field and arrow through Blizzard's five states; the format toggle in one dropdown field with a one-pixel divider and its chosen, unchosen and hovered labels; the dropdown list on all three menus with Blizzard's bottom inset; the slider track, fill and diamond; the inset under the table over the window's rock, darkened to 45 %; the search field in the dropdown field; class colors unchanged. **Fallback:** with every name missing from load, the flat look and no atlas, nine-slice call or template button; with each group missing alone, only its pieces fall back, and without the frame the window keeps 0.3.7's height; nothing is built on a repeated apply, and forever → standard → forever restores every visible region and the saved position. **The flat look** on every client: every visible region painted from the palette, or an information region in its own color (with recorded Vault progress, unlocked slots and the tooltip's slot marks too, also after a repaint without a Refresh), only Hourstone's icons and Blizzard's files shown as files; the palette pinned key by key; every plate line, control outline and inner-shadow step one physical pixel and anchored inside the edge at 65, 100, 135 and 200 % on three screen heights and three UI scales, also when only `UI_SCALE_CHANGED` or `DISPLAY_SIZE_CHANGED` reports the change; `NORMAL_FONT_COLOR` on the window titles only, and its fallback; `PixelUtil` missing; the hover label across a Refresh; every bronze, accent, muted and button-symbol value at least 11 CIEDE2000 from the warrior color. **Other clients:** no flat plate region, atlas or nine-slice call exists, and every visible region in nine window states, and in Retail's progress view and its tooltip, matches the tagged 0.3.7 release in position, size, layer, color, alpha, texture, atlas, texture coordinates, desaturation and text, apart from the version the footer names; so does WoW: Forever with the standard look applied after its frame was built.
- Assets and packaging: source hashes, exact RGBA conversion, font hashes and licenses, TOC metadata, archive structure, deterministic bytes and SHA-256.
- Publishing: checksum verification and duplicate-upload prevention, without contacting external publishing services in tests.
- Repository privacy: private-path and secret detection, ignored local artifacts, and inspection of intermediate commits even when a later commit removes their contents.

Layout references are design specifications. The approved Progress mockup is kept locally at `dist/design/approved-progress-mockup.png`, outside version control. Its tab hierarchy, dark/gold skin, character/key/week/Vault columns and three-by-three slot grid are binding; fictional values and external explanatory panels are not product data or permanent UI. Progress uses 64-unit rows and 230/164/122/184 column widths. Compare the actual Lua-derived views, tooltips and settings with that reference.

The simulator's font metrics and the Lua-derived browser preview approximate native rendering. They do not prove real font appearance, combat behavior, taint safety or SavedVariables file timing.

## Native-client coverage

Version 0.4.0 keeps the declared interfaces of 0.3.7 and gives the window WoW: Forever's own window frame on the Forever client ([theme document](FOREVER-THEME.md)). 154 Lua scenario suites in seven simulated configurations and 77 Python tests pass; on Retail, Mists Classic, TBC Anniversary and Classic Era every visible region matches the tagged 0.3.7 release in the simulation. On 2026-11-10 the author installed the build in the live Forever client, asked for changes to the format toggle, the search field and the ground under the table, and accepted the frame after a `/reload` with those changes. The positions of the frame are computed from Soundstone 0.4.0's measurements; nothing of it was measured on screenshots, and the theme document's in-game checklist has not been worked through. The tested build differed from the release only in its version number. Its flat fallback, the look first built for Forever and shown in 0.4.0 only where a piece of Forever's art is missing, was measured in the live Forever client on 9 November 2026 at 135 % Hourstone size on lossless screenshots: every plate line, the control outlines and each inner-shadow step one physical pixel in the planned colors and window titles exactly `#FFD200`. Retail, Mists, the Anniversary realms and Classic Era were not tested in-game for 0.4.0.

Version 0.3.7 keeps the declared interfaces of 0.3.6 and closes its synchronization
gap: with Companion 0.2.2, synchronized WoW: Forever characters that the account has
not recorded itself show as WoW: Forever on every client, Forever included. The
Companion lists the Forever source IDs in the generated format 4 data
([addendum](sync-protocol-v4-forever.md)); protocol 4, the Retail flavor, keys,
merging and SavedVariables schema 3 are unchanged, and Hourstone 0.3.2 to 0.3.6
ignore the list. It also saves Forever surnames as part of the name. 140 Lua
scenario suites in seven simulated configurations and 74 Python tests pass, and so
do the Companion's tests for the list.

On 2026-11-05 the author installed a preliminary 0.3.7 build, without the surname
fix, in the live clients next to Companion 0.2.2 built from its main branch, added
the Forever installation to the Companion and reported that synchronized Forever
characters show as WoW: Forever. The Retail data addon carried the Forever
installation's source in `foreverSources`. The same test showed that live Forever
(build 1.60.1.70790) returns the surname in the realm slot: `UnitFullName("player")`
and `UnitName("player")` gave "Magni", "Wildschuss", `GetUnitName("player", true)`
"Magni Wildschuss", and `GetRealmName()` / `GetNormalizedRealmName()`
"CAMWOW EU4 Realm 10 RP" / "CAMWOWEU4Realm10RP". The author then installed the
build with the surname correction in all five live clients (ZIP SHA-256
`b1aad55f24c3acb444d82767509d69f70576cab38368deb95cc31b5ffe9b078f`) and confirmed in
live Forever that a character logging in shows its full name with the realm WoW
reports. The client filter and progress exclusion in Retail and the Classic clients
have not been separately tested in-game for 0.3.7.

The v0.3.7 GitHub release ZIP has SHA-256
`4e7bad0a8aa3a431673c5a013226901c1c452dd081d08e37d271d991a05c0f78`. It is not the
same ZIP file as the tested build, contrary to the release commit's message: that
build was packaged locally with Python 3.14, whose zlib-ng compresses differently.
Both ZIPs contain the same 45 files byte for byte, in the same order and with the same
metadata, so the tested addon is the published one, and a local rebuild with Python
3.12 reproduces the release ZIP exactly. The CurseForge upload created
[file 9463844](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/9463844)
with game versions 12.1.5, 2.5.6, 5.5.4, 1.15.9 and 1.60.1, awaiting CurseForge
approval. The receipt is recorded in [releases/v0.3.7.json](curseforge/releases/v0.3.7.json).

Version 0.3.6 keeps the declared interfaces of 0.3.5 and labels WoW: Forever
characters as WoW: Forever. In the Forever client, Hourstone marks each character it
records with `client = "forever"` beside the Retail flavor; keys, overview removal,
SavedVariables schema 3 and Companion protocol 4 are unchanged. The first load of
0.3.6 in Forever also marks the Retail-family entries of a database that Hourstone
created after the launch (2026-11-04 23:00 UTC, the time at the start of its source
ID) and entries migrated from a `project-` client. An older database, such as a
copied `WTF` folder, keeps Retail until each Forever character logs in again, and a
database that any client running 0.3.6 has stamped is not marked again. Synchronized
Forever characters that the account has not recorded itself stay under Retail,
because protocol 4 carries no client marker. 140 Lua scenario suites in seven
simulated configurations and 64 Python tests pass.

Hourstone 0.3.5 ran in the live WoW: Forever client (build 1.60.1.70790) on the
author's installation on 2026-11-05. It saved characters under the Retail family with
the eu region, a non-empty realm and a confirmed `/played` value, and the client
column showed Retail, which 0.3.6 changes. The live client's interface number was not
recorded.

The author tested the 0.3.6 build in the same live Forever client on 2026-11-05; the
tested ZIP has SHA-256
`5d05f60f5ad178abb8af5bd4dc68402d40b54a41c9c129e55a46894bac38d0f1`. After a full
restart the footer showed v0.3.6, and the client column showed WoW: Forever for two
characters that 0.3.5 had recorded in a database created after the launch and for a
new character recorded by 0.3.6. The client filter, tooltip and sort, copied
databases, synchronization and the Retail and Classic clients were not separately
tested in-game for 0.3.6; they are covered by the simulation.

The v0.3.6 GitHub release ZIP matches the tested build byte for byte (SHA-256
`5d05f60f5ad178abb8af5bd4dc68402d40b54a41c9c129e55a46894bac38d0f1`). The CurseForge
upload created
[file 9458425](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/9458425)
with game versions 12.1.5, 2.5.6, 5.5.4, 1.15.9 and 1.60.1 (Retail 12.1.5, ID 16984),
awaiting CurseForge approval. The receipt is recorded in
[releases/v0.3.6.json](curseforge/releases/v0.3.6.json).

Version 0.3.5 keeps the declared interfaces of 0.3.4 and prepares for the WoW: Forever
launch on 2026-11-04 at 23:00 UTC. On a Forever interface (16xxx), every project ID
counts as the Retail client family, and loading on Forever returns every entry
recorded under a `project-` client to Retail; a record whose merge fails keeps its
original client. If `UnitFullName` reports no realm, Hourstone uses `GetRealmName`,
then `GetNormalizedRealmName`, then `?`; an empty name is stored as `?`. Forever
replaces realms with rulesets, and the Companion and Hourstone's received-data
validation reject an empty realm. Retail and Classic clients behave as in 0.3.4.
140 Lua scenario suites in seven simulated configurations and 55 Python tests pass.
No Hourstone build has run in the live Forever client yet, and interface 16001 is
confirmed only on Forever beta and test builds. In-game testing of 0.3.5 is pending.

The v0.3.5 GitHub release ZIP has SHA-256
`d523b29dd0947acc688feb9c4b19d755ddf9ee6e324677d416fdc96821aa502d`. The CurseForge
upload created
[file 9428480](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/9428480)
with game versions 12.1.5, 2.5.6, 5.5.4, 1.15.9 and 1.60.1 (Retail 12.1.5, ID 16984),
awaiting CurseForge approval. The receipt is recorded in
[releases/v0.3.5.json](curseforge/releases/v0.3.5.json).

Version 0.3.4 declares Retail interface 120105 for WoW 12.1.5. A comparison of
Blizzard's UI source and generated API documentation between 12.1.0 (69933) and
12.1.5 (70575) found no change to any API, event, widget method or template that
Hourstone uses; the outdated interface number alone kept Retail from loading the
addon. WoW: Forever builds since 1.60.1.70170 set `WOW_PROJECT_ID` to
`WOW_PROJECT_CAMELOT` (18), which 0.3.3 recorded as an unknown client family.
Mists Classic 5.5.4, TBC Anniversary 2.5.6, Classic Era 1.15.9 and Forever 1.60.1
keep their interface numbers. 140 Lua scenario suites in seven simulated
configurations and 52 Python tests pass. The author reported a successful in-game
test of the 0.3.4 build in Retail 12.1.5 (build 70575) on 2026-10-25; the tested ZIP
has SHA-256 `ce8819306c9e75c6bcffba6e15e08afceff1e3091e4035cc5a5c3e4c919dcf76`.
The WoW: Forever client has not run 0.3.4 yet, so the Forever project-ID handling
and migration are covered only by the simulation. Mists Classic, TBC Anniversary and
Classic Era were not separately tested for 0.3.4; their code paths are unchanged,
and they are released on the author's compatibility statement.

The v0.3.4 GitHub release ZIP matches the tested build byte for byte (SHA-256
`ce8819306c9e75c6bcffba6e15e08afceff1e3091e4035cc5a5c3e4c919dcf76`). The first
CurseForge upload attempt uploaded
[file 9326047](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/9326047)
with game versions 12.1.5, 2.5.6, 5.5.4, 1.15.9 and 1.60.1 (Retail 12.1.5, ID 16984),
awaiting CurseForge approval. The receipt is recorded in
[releases/v0.3.4.json](curseforge/releases/v0.3.4.json).

Version 0.3.3 has 120 passing Lua scenario suites in six simulated configurations
and 45 passing Python tests. The author reported a successful in-game test of the
0.3.3 build in Retail, Classic and the WoW: Forever beta (build 1.60.1.69977). No
game patch was released since 0.3.2; the CurseForge game versions 12.1.0, 5.5.4,
2.5.6 and 1.15.9 are kept, and client families not separately tested for 0.3.3 are
released on the author's compatibility statement. 1.60.1 is added for Forever.

The v0.3.3 GitHub release ZIP matches the tested build byte for byte (SHA-256
`151824b5c779d13aa25cba4bdb6aa4caa05c6e1bcf99d54cab43b3b266e97465`). The first
CurseForge upload attempt ended with HTTP 500 and no file on CurseForge; after
removing the pending marker, the rerun uploaded
[file 8963102](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/8963102)
with game versions 12.1.0, 2.5.6, 5.5.4, 1.15.9 and 1.60.1 (WoW: Forever, ID 17053),
awaiting CurseForge approval. The receipt is recorded in
[releases/v0.3.3.json](curseforge/releases/v0.3.3.json).

Release 0.3.2 proceeds on 2026-09-18 with the native-client and physical two-PC
checks below still pending. Publication does not convert automated or simulated
results into native-client acceptance.

Version 0.3.2 has 90 passing Lua scenario suites and 38 passing Python tests. Shared
protocol-4 golden fixtures execute in both Lua and .NET, covering family-level
merge convergence, reset timestamp jitter, explicit empty values, source isolation
and legacy compatibility. Tests also verify that receiving progress never writes
it into the local collection cache and that future local cache versions remain
untouched. Native-client acceptance of 0.3.2 and practical two-PC synchronization
remain pending.

Version 0.3.1 adds a drag regression that fails against 0.3.0: moving anchors must survive the real one-second Core refresh and display events until release. It covers both Retail views, Classic, three global UI scales, closing during a drag and a late drag-stop event. All 80 Lua scenario suites and 34 Python tests pass. The patch was loaded in Retail; sustained manual dragging requires native confirmation because the desktop automation's short drag gestures did not move the frame.

Version 0.1.1 has reported in-game coverage for Retail, Mists Classic, TBC Anniversary and Classic Era. Hardcore and Season of Discovery have not been separately tested. Those reports do not establish per-action coverage for every item below or validate the new 0.2.x companion protocol.

Version 0.2.3's updated layout and minimap button were checked in TBC Anniversary.

Version 0.3.0 has 80 passing Lua scenario suites and 34 passing Python tests (including six layout tests). Fifteen additional checks use the actual Companion reader/writer with Lua-generated SavedVariables and 250 synthetic progress records. The main schema and protocol remain version 3, and the writer preserves the local progress cache unchanged.

The actual Lua-derived Progress, tooltip and settings previews were visually compared with the binding mockup. Synthetic German/English examples cover empty, unknown and expired records, all nine slots and 200% settings. The local reference and generated comparisons remain in ignored `dist/design`; browser fonts and native controls are approximations.

The 0.3.0 Classic layout was opened in TBC Anniversary at 2560×1440, in German, with six existing characters. The scale endpoints 65% and 200%, retained playtime/guild rows, settings and Classic-only view were visually checked.

Retail additionally passed native scale checks at 65%, 130%, 150%, 175% and 200%, including direct track clicks and a complete 200-to-65 slider drag. The requested scale stayed stable after release; all six rows, settings and window controls remained reachable. The original Retail preference of 130% was restored. Native testing caught and fixed a slider event-order feedback loop and missing tooltip glyphs; slot marks now use actual frames/textures.

Retail was checked at the same resolution and language with one logged-in Retail character and five imported Classic characters. Hourstone correctly displayed the current guild, confirmed no owned key, no completed weekly Mythic+ run and all nine open Vault slots. Its tooltips matched Blizzard's live Great Vault: Dungeon 0/1, 0/4, 0/8; Raid 0/2, 0/4, 0/6; World 0/2, 0/4, 0/8. These are observed values for that character and week, not addon constants. Imported Classic characters showed unavailable progress. Reload and reopening confirmed collection without requiring a new Vault update event.

Native acceptance with an owned key, completed runs, unlocked rewards, an unclaimed prior-week reward and a real weekly rollover remains outstanding; those states have automated regression coverage. Native checks in other client families and practical two-PC synchronization also remain outstanding. Automated checks and synthetic previews do not replace those checks. No private character databases or native-client screenshots are included in the repository.

## In-game checklist

1. Record addon version, client build and language. Enable Lua errors and install the package without other required addons.
2. Log in and compare Hourstone with `/played`. Reopen within 60 seconds and verify the request interval. After several minutes, verify a fresh server response replaces the estimate.
3. Reload and change zones; verify session continuity. Log out, wait and log in; verify a new session and no offline time. Switch characters and verify independent values.
4. Verify search by character and guild, realm and client filters, all sort columns, totals, both formats, long character/guild names and large lists. Check a guild member and a guildless character; leave/join on a test character and confirm reload persistence and synchronization without changing playtime.
5. Check addon scales 65%, 100%, 130%, 150%, 175% and 200%, global UI scaling, smaller displays, settings, drag behavior, minimap visibility, both slash commands and controls during combat. At high scales, scroll to every character with fewer visible rows. Compare the 31-unit minimap button with an unchanged LibDBIcon button in each client family: rim thickness, center, hover and full logo. Check drag-click suppression and retained angle/visibility after reload. Compare the filter positions, client column, timestamp line and footer against the synthetic layout; native textures and fonts are not reproduced by the simulator.
6. For companion sync, close every WoW client, sync two installations with synthetic or private local data, then start each client and compare the merged list. Repeat the same sync to verify no double counting and verify that settings and sessions remain local.
7. Remove an offline character and the active character. Check the confirmation, overview totals, removed list, manual restoration and continued local tracking. Reload and change zones; both must remain removed. Make a new character login; the known removal must be restored without changing saved playtime. Repeat between two devices, including an offline removal that only reaches the character after its earlier login: synchronize, then make another actual login.
8. Verify the companion refuses writes while WoW is running, preserves backups and reports malformed or newer-protocol data without overwriting it. Keep logs and real SavedVariables outside the repository.
9. Where the client has the Addons menu: after updating from 0.3.2, verify the Hourstone entry with logo and tooltip, left click open/close, no action on right click, the minimap button hidden once, the chat hint when hiding it, and that turning it back on survives `/reload` and relog. Clients without the menu keep the button.
10. In WoW: Forever, record the build and interface, go through the frame checklist in [the theme document](FOREVER-THEME.md#in-the-game) on lossless screenshots (frame, header, layout, settings and dialog, filters and menus, slider, colors under the rows, sizes), then the playtime-only view, the minimap geometry when enabled, that characters show as WoW: Forever in the client column, tooltip and filter with their full name including the surname and the realm WoW reports (`/dump GetRealmName()`), that a character saved by 0.3.6 with its surname as realm is corrected at its next login, that entries an earlier version recorded in a database created after the launch or under a `project-` client show as WoW: Forever after the update, and that characters from a `WTF` folder copied from Retail stay under Retail. With Companion 0.2.2, sync a Forever character of a second account or PC and verify that it shows as WoW: Forever in Forever and in Retail, that Retail's client filter then offers WoW: Forever and its progress view treats the character as unsupported, and that it shows under Retail again after the Companion stops listing its source.
11. In Retail, open Progress and compare the owned key with the bag item and weekly best with completed runs. Compare all three Vault rows and their slot thresholds with Blizzard's UI, both with and without an unclaimed previous reward. Complete a run, obtain/change/remove a key, reload and switch characters; confirm the latest captured data and distinct unknown/empty/stale states. Check the server weekly reset and a character not visited since reset. Verify that Classic does not register Retail progress APIs or display the Progress tab.

Use issue reports to describe reproducible behavior without including personal account paths, credentials or raw character databases.
