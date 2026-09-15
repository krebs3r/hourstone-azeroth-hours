# Validation — v0.1.0

Local checks on 2026-09-15: **30 Lua scenario suites and 2 packaging tests passed**. The generated Retail / German, Classic / English and settings layouts were inspected in a browser. These are approximate renders of the Lua frame definitions, not game captures.

## Automated coverage

The addon is executed by `lupa.lua51` using a deliberately small WoW API simulator, not a WoW client. Tests run the actual TOC-ordered Lua files.

| Area | Covered |
| --- | --- |
| Formatting | Decimal hours, combined time, zero, unknown, invalid values, German comma |
| List | Totals, missing-value counts, visible totals, name/realm filters, numeric/text sorts, duplicate names and stable GUID ties |
| Tracking | Initial request, delayed answer, 60-second request interval, missing-answer retry, server baseline replacement, manual answer acceptance |
| Lifecycle | Level changes, zoning, UI reload carry, real login reset, one-day offline gap, character switch, invalid monotonic carry |
| UI | Window open/close, escape callback, both slash aliases, format persistence, 141-character list, long names, 16 realms, scrolling, filtering, sort buttons, settings, minimap toggle, scale limit |
| Clients | Projects 1 / 19 / 5 / 2 and unknown 999, with and without BackdropTemplateMixin; deDE / enUS / frFR fallback |
| Package | Lua manifest, version-tag match, interface list, TGA encoding, license, direct Hourstone folder, repeatable bytes, CRC and SHA-256 |

Run the commands in the README to reproduce. The GitHub Actions run for each commit supplies the independent Linux result.

## Actual in-game matrix

| Client | Declared interface | Load / UI | `/played` | Logout / reload | Combat / minimap |
| --- | ---: | --- | --- | --- | --- |
| Retail | 120100 | Pending | Pending | Pending | Pending |
| Mists Classic | 50504 | Pending | Pending | Pending | Pending |
| TBC Anniversary | 20506 | Pending | Pending | Pending | Pending |
| Era | 11509 | Pending | Pending | Pending | Pending |
| Hardcore | 11509 | Pending | Pending | Pending | Pending |
| Season of Discovery | 11509 | Pending | Pending | Pending | Pending |

No in-game results are claimed. Simulations cannot establish native rendering, taint behavior or file writes performed by the WoW client.

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
