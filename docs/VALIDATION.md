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
- Model and synchronization: record validation, schema migration, server measurements versus estimates, deterministic merging, duplicate handling and imported records. Protocol fixtures contain synthetic data only.
- Layout: retained [baseline](../tests/fixtures/layout/baseline.json) and [adjustments](../tests/fixtures/layout/adjustments.json), dynamic list height, scrolling, filters, anchors, labels with unavailable metrics, saved settings and minimap containment.
- Scaling: multiple display sizes, global and addon scales, and small-screen fitting.
- Assets and packaging: source hashes, exact RGBA conversion, font hashes and licenses, TOC metadata, archive structure, deterministic bytes and SHA-256.
- Publishing: checksum verification and duplicate-upload prevention, without contacting external publishing services in tests.
- Repository privacy: private-path and secret detection, ignored local artifacts, and inspection of intermediate commits even when a later commit removes their contents.

Layout references are design specifications. The simulator's font metrics and the Lua-derived browser preview approximate native rendering. They do not prove real font appearance, combat behavior, taint safety or SavedVariables file timing.

## Native-client coverage

Version 0.1.1 has reported in-game coverage for Retail, Mists Classic, TBC Anniversary and Classic Era. Hardcore and Season of Discovery have not been separately tested. Those reports do not establish per-action coverage for every item below or validate the new 0.2.x companion protocol.

## In-game checklist

1. Record addon version, client build and language. Enable Lua errors and install the package without other required addons.
2. Log in and compare Hourstone with `/played`. Reopen within 60 seconds and verify the request interval. After several minutes, verify a fresh server response replaces the estimate.
3. Reload and change zones; verify session continuity. Log out, wait and log in; verify a new session and no offline time. Switch characters and verify independent values.
4. Verify search by character and guild, realm and client filters, all sort columns, totals, both formats, long character/guild names and large lists. Check a guild member and a guildless character; leave/join on a test character and confirm reload persistence and synchronization without changing playtime.
5. Check addon scales 65%, 100% and 130%, global UI scaling, smaller displays, settings, drag behavior, minimap visibility, both slash commands and controls during combat.
6. For companion sync, close every WoW client, sync two installations with synthetic or private local data, then start each client and compare the merged list. Repeat the same sync to verify no double counting and verify that settings and sessions remain local.
7. Verify the companion refuses writes while WoW is running, preserves backups and reports malformed or newer-protocol data without overwriting it. Keep logs and real SavedVariables outside the repository.

Use issue reports to describe reproducible behavior without including personal account paths, credentials or raw character databases.
