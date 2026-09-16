# Changelog

## 0.2.1 — unreleased

- Record and display each character’s guild, including confirmed guildless and not-yet-recorded states.
- Search character and guild names; keep full guild details in row tooltips.
- Exchange guild changes independently of playtime through protocol 2 with Companion 0.1.2. Legacy protocol 1 input and existing saved data remain readable.

## 0.2.0 — unreleased

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
