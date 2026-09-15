# Hourstone — Mockup 05

Separate, interactive design study based on Soundstone. Open [index.html](index.html) directly in a browser; all artwork is embedded and no network connection is needed. [Mockup 04](../mockup/index.html) remains unchanged.

Default view: Classic, German, one fictional character, combined time format, 100% size. Preview state stays in memory and resets when the page reloads. It does not read or write `HourstoneDB`.

## Layout

At 100% browser zoom and 100% preview size, dimensions are in CSS pixels:

| Region | Size |
| --- | --- |
| Window | 720 wide; `212 + 36 × max(1, min(8, filteredCount))` high |
| Outer padding | 10 on each side |
| Header | 700 × 40 |
| Summary | 700 × 64 |
| Toolbar | 700 × 38 |
| Table heading | 700 × 24 |
| Rows | 36 high; 8 visible at most |
| Columns | 322 / 203 / 175 (46 / 29 / 25 percent) |
| Footer | 700 × 26 |
| Settings | 252 × 190; attached below the header gear |
| Minimap | 36; full logo at 22 with the existing 32-unit circular limit |

Zero / one result: **720 × 248**. Two results: **720 × 284**. Eight or more: **720 × 500**. All-character totals remain visible when filtering; the footer also shows the filtered sum. The character heading's menu sorts by name, level and realm. Clicking the selected sort field reverses its direction. Extra records scroll vertically.

The prototype includes both skins, both languages, 0 / 1 / 8 / 20 fictional records, both formats, search, realm filters, sort menus, a 65–130% size slider, window dragging and reset, a minimap checkbox, minimap drag/click, and close/reopen/Escape behavior. The size slider changes the preview window; browser presentation controls and minimap remain independent.

## Soundstone sources

Frames, red controls, input framing, grip rivets and slider thumb artwork use Soundstone's MIT-licensed assets. Original PNG bytes for the additional assets are retained in `soundstone-assets.json`, pinned to commit `85290d29c3de18f8612d679b093e509e6725d890`; the builder verifies Git blob hashes. Existing shared frames, Hourstone artwork, heart and minimap artwork are read from `docs/assets`.

- [Soundstone layout](https://github.com/krebs3r/soundstone-azeroth-audio/blob/85290d29c3de18f8612d679b093e509e6725d890/Soundstone/Layout.lua)
- [Soundstone UI and frame crops](https://github.com/krebs3r/soundstone-azeroth-audio/blob/85290d29c3de18f8612d679b093e509e6725d890/Soundstone/UI.lua)
- [Soundstone browser approximation](https://github.com/krebs3r/soundstone-azeroth-audio/blob/85290d29c3de18f8612d679b093e509e6725d890/docs/ui-preview.html)
- [MIT license](../../LICENSE), copyright 2026 krebs3r.

Nine-region frame drawing keeps corners at 7px Retail / 10px Classic. Buttons preserve 4px corners. Georgia and the small eight-tooth gear follow Soundstone's browser approximation. The intended future addon font is WoW's native standard font; no Blizzard font or client gear file is distributed here. The approved stone/hourglass artwork is unchanged.

## Rebuild

From the repository root, run `python tools/mockup05.py`. This only rebuilds `docs/mockup-05/index.html`; it does not rebuild Mockup 04 or the addon.

## Browser verification — 2026-09-15

- 32 combinations of Retail / Classic × German / English × 0 / 1 / 8 / 20 records × combined / hours passed live DOM checks for width, height, row count, 36px rows, scroll threshold and complete title.
- Measured region heights and 322 / 203 / 175 column widths match the table above.
- Duplicate name search returns two separate realm records at 720 × 284; combined filtered sum is `3 T. 12 Std. 15 Min.`. Realm filtering reduces this to one row; unmatched searches show a single empty slot and a zero filtered sum.
- Sort controls, keyboard scrolling, settings, 65 / 100 / 130% preview scale, minimap visibility, window dragging / position reset and close / minimap reopen were exercised.
- Retail and Classic were visually inspected, including the attached settings panel, complete header, heart and full minimap motif. No browser console errors were observed.

This is a **browser mockup with fictional data**, not an in-game rendering check. The design was approved on 2026-09-15. Its native implementation, including subsequent user-requested corrections, is available in v0.1.1. The final test5 appearance was accepted and the user confirmed Retail and TBC Anniversary before publication.
