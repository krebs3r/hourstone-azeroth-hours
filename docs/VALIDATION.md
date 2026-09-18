# Validation

## Automated checks

```sh
python tools/privacy_guard.py
python tests/run.py
python -m unittest discover -s tests -p 'test_*.py'
python tools/package.py
```

Lua tests execute the actual TOC-ordered addon modules through Lua 5.1, with a limited WoW API simulator. The matrix covers supported project IDs, an unknown-project fallback, German, English and fallback localization, with and without backdrop support.

- Tracking: delayed server answers, request intervals, retries, authoritative replacement of estimates, level and character changes, zoning, reload session carry, new-login resets and offline exclusion.
- Guilds: delayed API information, joining/leaving, Unicode names, safe tooltip text, independent metadata merging, legacy snapshots and guild search.
- Removal and restoration: confirmation/cancel, visible-only totals, retained playtime, removed-character view, new-login restoration, missing GUID retries, reload/zoning exclusion, unknown-region adoption, offline and concurrent controls, idempotent merges and bounded validation.
- Model and synchronization: record validation, schema migration, server measurements versus estimates, deterministic merging, duplicate handling and imported records. Protocol fixtures contain synthetic data only.
- Layout: retained [baseline](../tests/fixtures/layout/baseline.json) and [adjustments](../tests/fixtures/layout/adjustments.json), dynamic list height, upper realm/client filters, menu exclusivity and anchors, client sorting including unknown values, column boundaries, nowrap server timestamps, footer credits with unavailable font metrics, saved settings and native minimap references/geometry across four client families.
- Progress: Retail API observations, completed weekly runs, keystone changes and confirmed absence, category/index-based Vault slots, unknown/protected values, reset expiry, offline reads and local identity adoption. Progress stays outside legacy protocol-3 payloads; protocol 4 carries independent progress observations.
- Scaling: 65%, 130%, 150%, 175% and 200% across display sizes and global UI scales; adaptive visible row capacity, complete scrolling and minimum-size fitting.
- Assets and packaging: source hashes, exact RGBA conversion, font hashes and licenses, TOC metadata, archive structure, deterministic bytes and SHA-256.
- Publishing: checksum verification and duplicate-upload prevention, without contacting external publishing services in tests.
- Repository privacy: private-path and secret detection, ignored local artifacts, and inspection of intermediate commits even when a later commit removes their contents.

Layout references are design specifications. The approved Progress mockup is kept locally at `dist/design/approved-progress-mockup.png`, outside version control. Its tab hierarchy, dark/gold skin, character/key/week/Vault columns and three-by-three slot grid are binding; fictional values and external explanatory panels are not product data or permanent UI. Progress uses 64-unit rows and 230/164/122/184 column widths. Compare the actual Lua-derived views, tooltips and settings with that reference.

The simulator's font metrics and the Lua-derived browser preview approximate native rendering. They do not prove real font appearance, combat behavior, taint safety or SavedVariables file timing.

## Native-client coverage

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
9. In Retail, open Progress and compare the owned key with the bag item and weekly best with completed runs. Compare all three Vault rows and their slot thresholds with Blizzard's UI, both with and without an unclaimed previous reward. Complete a run, obtain/change/remove a key, reload and switch characters; confirm the latest captured data and distinct unknown/empty/stale states. Check the server weekly reset and a character not visited since reset. Verify that Classic does not register Retail progress APIs or display the Progress tab.

Use issue reports to describe reproducible behavior without including personal account paths, credentials or raw character databases.
