# Changelog

## 0.1.1 compatibility update — 2026-09-16

- In-game testing confirmed for Mists of Pandaria Classic and Classic Era, in addition to Retail and TBC Anniversary.
- Enable Mists Classic 5.5.4 and Classic Era 1.15.9 for the existing CurseForge release and future uploads. Update GitHub and CurseForge compatibility documentation; addon files and the release ZIP are unchanged.
- Hardcore and Season of Discovery have not been separately tested.

## 0.1.1 — 2026-09-15

- Replace the flat custom minimap checkbox with the native UICheckButtonTemplate used by Soundstone. Keep checked state synchronized through checkbox, label and slash-command changes.
- Reduce minimap button / motif / mask from 36 / 22 / 32 to 28 / 18 / 24 UI units, retaining the entire motif and over two units of rim clearance.

- Native test3 feedback: full title and statistics are confirmed; the German combined-format label was clipped. Narrow the search field 402 → 362px and widen that button 71 → 111px, retaining its font size.
- Narrow the identity column to 280px, enlarge playtime to 245px and keep updates at 175px. Reduce the left statistics section to 38%.
- Keep 100% as the default and preserve saved 110–120% preferences. Extend physical scaling checks to 110 / 115 / 120%.
- Implement approved Mockup 05: 720px width, 248–500px dynamic height, 36px rows, at most eight visible characters. Search and realm filters adjust the height.
- Use the original Soundstone 7px Retail / 10px Classic panel corners, framed inputs, red buttons, grip rivets and slider thumbs. Place a small native gear beside the 28px logo.
- Use WoW's standard font and fixed text regions for the complete title and all statistics labels, avoiding dependence on initially unavailable font metrics. Remove the in-window slogan.
- Combine name / level / realm in a 40% identity column, with 35% playtime and 25% update columns. Add a name / level / realm sort menu, direct time / update sorting and search clearing.
- Add a 252 × 190px settings menu with checkbox, 65–130% size slider, reset and close buttons.
- Preserve the physical pixel conversion, existing data and preferences; keep the header in place when list height changes. Dragged positions record their placement height without changing schema 1.
- Retain the 9px pink heart, footer totals, complete minimap artwork and click/drag behavior. Remove the redundant eye control.
- Keep session time free of leading zero days. Tracking modules are unchanged in test 3.
- Validate independent Mockup 05 dimensions, dynamic-height states, physical scaling, hidden/zero font metrics, reloads and the pixel-exact conversion of original Soundstone assets.
- Final test5 interface accepted for publication; the user confirmed Retail and TBC Anniversary. Other client families remain pending in game.

## 0.1.0 — 2026-09-15 (prerelease)

- First standalone playtime tracker, with account-wide GUID-based records.
- Server `/played` synchronization, active-character estimates, reload-aware sessions and offline exclusion.
- Sortable character list, name search, realm filter, totals and two time formats.
- German / English localization, saved window position and scale, compact rows and optional draggable minimap icon.
- Approved hourglass logo and Soundstone Retail / Classic frames.
- Lua 5.1 simulations, deterministic addon ZIP, SHA-256 checksum and GitHub build/release workflows.
- Actual WoW client verification remains pending.
