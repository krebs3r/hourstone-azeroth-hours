# Validation — v0.1.1

Local checks on 2026-09-15: **30 Lua scenario suites and 8 Python tests passed**. Tests execute the real TOC-ordered Lua modules using `lupa.lua51` and a strict, deliberately small WoW API simulator.

## Mockup 05 implementation

Independent live DOM measurements are in [mockup-05-measurements.json](mockup-05-measurements.json). They were captured from the approved browser reference at the user's 115% preview scale and normalized to 100%. [Test4 adjustments](layout-test4-adjustments.json) record the explicitly changed search, format, statistics and column bounds following native feedback; these are design specifications, not a new independent DOM or game measurement. Mockup 04 and Mockup 05 HTML references remain unchanged by this native implementation.

- **40 geometry states:** Retail / Classic × German / English × combined / hours × 0 / 1 / 8 / 20 / 141 records. Main sections, header, title, labels, inputs, buttons, settings and footer rectangles differ by no more than one design pixel. Columns are 280 / 245 / 175; rows are 36px.
- **360 size cases:** 1080p / 1440p / 2160p × global scale .64 / .8 / 1 / 1.5 × addon scale .65 / 1 / 1.1 / 1.15 / 1.2 / 1.3 × 0 / 1 / 2 / 8 / 20 rows. At 100% the window measures 720 × 248, 720 × 284 or 720 × 500 physical pixels as appropriate. Small-screen fitting preserves 10px margins and the saved preference.
- Filtering grows/shrinks the window while retaining its header anchor; offsets, legacy settings and character records survive. Sort menus, all five sort keys, direct time/update headings, a long realm menu, slider, search clearing, scroll persistence and minimap controls are exercised.
- First open, reopen and a fresh namespace `/reload` are checked in eight client/language combinations, including a simulator returning **zero font metrics** while hidden or throughout the first render. Title and statistics still have full fixed-width regions. Metrics affect only spacing between neighboring labels.
- Native font selection is `STANDARD_TEXT_FONT` with `Fonts\FRIZQT__.TTF` fallback. The simulator uses licensed Gelasio as a metric approximation; the browser uses Georgia. Neither establishes native glyph rendering.
- The combined-format label reserves 95px, compared with 55px in test 3. Both languages pass a width check with 35% added allowance over the approximate font metric plus 8px extra room. Native font rendering remains separately reviewed.
- Original Soundstone source PNG hashes and every RGBA pixel are compared with the shipping TGAs. Heart placement, minimap alpha containment and unchanged font-file bytes also pass.
- The Lua-derived preview includes Classic/German single-character views at 100 / 110 / 120%, generated with 2560 × 1440 and global UI scale .8, plus settings, Retail eight-character, English hours/many characters and empty states. All preview text regions are untruncated. The gear image and font are browser approximations.

## Checkbox and minimap correction — test 5

The additional native captures show the custom checkbox as a filled block and the 36-unit minimap circle larger than neighboring icons. The checkbox now uses `UICheckButtonTemplate` at 24 × 24, positioned so its inset artwork aligns with the previous label. This follows [Soundstone's native checkbox implementation](https://github.com/krebs3r/soundstone-azeroth-audio/blob/85290d29c3de18f8612d679b093e509e6725d890/Soundstone/UI.lua). Blizzard supplies its checked, pressed and hover textures; none are redistributed. The browser preview draws an explicitly approximate checkbox.

The minimap button is 28 × 28 UI units, with the full 18 × 18 motif centered at (14,14) and a 24-unit mask. Source-alpha measurement gives a maximum artwork radius of 9.8725 units, against an inner rim radius of 12.25: clearance is **2.3775 units**. Background, rim, hover and hitbox shrink together. The motif occupies a slightly larger fraction of the button than in test 4; no artwork is cropped.

Existing simulations now include native checkbox auto-toggle behavior and synchronization after checkbox, label and slash-command clicks. Containment, minimap-scale inheritance, dragging and accidental-click suppression still pass. Tracking and saved settings are unchanged. The user subsequently accepted the final appearance and explicitly requested publication. Retail and TBC Anniversary were confirmed on 2026-09-15; this is user acceptance, not an automated measurement of native textures.

## Tracking and packaging

Formatting, sums, missing-value counts, filters, sorting and duplicate name/GUID ties pass. Tracking coverage includes delayed answers, the 60-second request interval, retries, replacement of estimates, level changes, character switches, zoning, `/reload` carry, real login resets and offline exclusion. Tracking/model code is unchanged by the Mockup 05 implementation.

Five simulated project IDs (1 / 19 / 5 / 2 / unknown 999), with and without BackdropTemplateMixin, cover deDE / enUS and the frFR-to-English fallback. Packaging checks TOC/version/interfaces, direct `Hourstone` ZIP structure, TGA headers, licenses, CRC, deterministic bytes and SHA-256. The existing GitHub workflows run these same test commands; the final release reruns the same checks in GitHub Actions.

## Previous native captures and remaining limits

User-supplied Classic-style test2 captures showed corrected overall pixel sizing but still omitted “Hourstone” and the statistics labels. Native zero-metric behavior was not captured by the prior simulator. Test 3 replaces the split/auto-sized title and individually positioned statistic glyphs with fixed-width native-font regions. The code and regression tests address that failure path; the subsequent supplied test3 capture now confirms the complete title and labels, along with the compact single-character frame. The user reports 1440p and 80% global UI scale; the exact Classic family/client build was not supplied. The screenshot showed the combined-format label truncated, so full native acceptance was not marked complete. Test 4 addresses that remaining label and the requested spacing. The default stays at 100%; saved size choices are preserved.

The physical conversion remains `pixels = UI units × effectiveScale × physicalHeight / 768`, following [Blizzard PixelUtil](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/PixelUtil.lua). Layout simulation cannot prove native glyph rendering, interaction during combat, taint safety or WoW's actual SavedVariables file writes.

## Actual in-game matrix — test 5

| Client | Declared interface | Load / UI | `/played` | Logout / reload | Combat / minimap |
| --- | ---: | --- | --- | --- | --- |
| Retail | 120100 | User confirmed | Not separately reported | Not separately reported | Visual acceptance; combat not separately reported |
| Mists Classic | 50504 | User confirmed (2026-09-16) | Not separately reported | Not separately reported | Not separately reported |
| TBC Anniversary | 20506 | User confirmed | Not separately reported | Not separately reported | Visual acceptance; combat not separately reported |
| Era | 11509 | User confirmed (2026-09-16) | Not separately reported | Not separately reported | Not separately reported |
| Hardcore | 11509 | Pending | Pending | Pending | Pending |
| Season of Discovery | 11509 | Pending | Pending | Pending | Pending |

## Publication checkpoint

The user approved the final test5 appearance, requested GitHub and CurseForge publication, and confirmed testing in **Retail and TBC Anniversary** on 2026-09-15. The release ZIP is byte-identical to the accepted test5 ZIP: SHA-256 `8b38daa8a75abc48b043c4eb7bcca7790d799c7dc7d821b63dc2d7581c8c446b`.

Installed Battle.net metadata on the confirmation date identifies Retail **12.1.0.69814** and Anniversary **2.5.6.69795**. These build numbers are installation metadata, not separately transcribed by the tester. No per-action claim is inferred for the remaining manual checklist.

On **2026-09-16**, the user additionally reported successful testing in **Classic and Classic Era** and requested publication for both. Classic is recorded as Mists of Pandaria Classic, matching the existing supported-client matrix. The configured versions are **5.5.4 / 50504** and **1.15.9 / 11509**; the user did not separately supply build numbers. Both client families are enabled on the existing CurseForge file. The release ZIP remains unchanged. Hardcore and Season of Discovery have not been separately tested.

## In-game acceptance checklist

1. Record `GetBuildInfo()` / client language and enable Lua errors. Install the release ZIP without other required addons.
2. Log in, wait for the initial server answer and compare with `/played`. Open twice within 60 seconds; verify the queue and no burst of addon requests.
3. Wait several minutes and compare again. Confirm a response replaces the estimate and that AFK time is included.
4. Reload. Confirm the session continues and requests retain the 60-second interval. Zone to a new map; the session must not reset.
5. Log out for several minutes, then log in. The session starts fresh; offline minutes must not be added. Switch to another character, including one with the same name on another realm.
6. Gain a level. Reopen and verify name / level / realm. Relaunch WoW and verify retained records, format, scale and position.
7. Use search, all sort columns, realm menu, many records, long names and both formats. Verify all-character and filtered totals with known `/played` values.
8. Check 65%, 100%, 130% addon scales, global UI scaling and smaller displays. Hover truncated rows. Check settings and scrolling in both languages.
9. Drag the window and minimap button, hide/recover the button, use both commands, Escape and close buttons. Repeat during combat and inspect Lua/taint errors.
10. Capture real Retail / Classic screenshots and add the tested client build plus results here.

## Interface reference

Interface versions were cross-checked on 2026-09-15 against Blizzard UI source snapshots:
[Retail 12.1.0](https://github.com/Gethe/wow-ui-source/commit/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59),
[Mists 5.5.4](https://github.com/Gethe/wow-ui-source/commit/ecadf9d3326fa87828cacca7f13c0ab5f41840a6),
[TBC 2.5.6](https://github.com/Gethe/wow-ui-source/commit/1463c686270b6c64e2c5c228f447c4597c0f8ba6),
[Era 1.15.9](https://github.com/Gethe/wow-ui-source/commit/33e177d9bf38d76d5c6c6e05d5da78db1899659a).
