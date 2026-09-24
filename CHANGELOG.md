# Changelog

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
