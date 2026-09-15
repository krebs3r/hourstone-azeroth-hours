<p align="center"><img src="docs/assets/Logo.png" width="170" alt="Hourstone: blue rune stone with a golden hourglass"></p>

# Hourstone – Azeroth Hours

**Your characters. Your time.**

A standalone World of Warcraft addon that keeps a list of your characters and their total playtime. A sibling to [Soundstone – Azeroth Audio](https://github.com/krebs3r/soundstone-azeroth-audio), with the same blue rune stone, warm gold details and Retail / Classic frames.

[Download Hourstone 0.1.1](https://github.com/krebs3r/hourstone-azeroth-hours/releases/download/v0.1.1/Hourstone-0.1.1.zip) · [CurseForge](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours) · [Deutsche Anleitung](docs/DEUTSCH.md) · [Report an issue](https://github.com/krebs3r/hourstone-azeroth-hours/issues)

## Features

- Class-colored character names, level, realm, total playtime and last update.
- Account total, character count and current session; filtered totals when searching.
- Name search, realm filter and sortable columns. Highest playtime comes first.
- Switch between decimal hours (`312.5 hrs`) and days / hours / minutes (`13d 0h 30m`).
- Movable window, saved position and scale, compact rows and an optional draggable minimap button.
- German on `deDE` clients, English on all other locales.
- No dependencies or external service. Your data stays in WoW's local SavedVariables.

## Supported clients

| Client family | Interface declared | In-game verification |
| --- | ---: | --- |
| Retail (12.1.0) | 120100 | User confirmed (2026-09-15) |
| Mists of Pandaria Classic (5.5.4) | 50504 | Pending |
| Burning Crusade Classic Anniversary (2.5.6) | 20506 | User confirmed (2026-09-15) |
| Classic Era, Hardcore and Season of Discovery (1.15.9) | 11509 | Pending |

**v0.1.1** contains the user-approved compact interface. The final test5 package was approved for publication and confirmed in Retail and TBC Anniversary on 2026-09-15. Other client families remain unverified in game. Lua 5.1 event and UI simulations cover these families; they do not replace testing inside the game. See [validation and client checklist](docs/VALIDATION.md). Historical private-server clients are outside this release's scope.

## Install

1. Download **`Hourstone-0.1.1.zip`** from [GitHub Releases](https://github.com/krebs3r/hourstone-azeroth-hours/releases/tag/v0.1.1). GitHub's automatically generated source archives are for development.
2. Exit WoW, extract the ZIP into the relevant client's `Interface/AddOns` folder.
3. Confirm the result is **`Interface/AddOns/Hourstone/Hourstone.toc`**.
4. Enable Hourstone in the character selection AddOns list and log in.

Repeat for each WoW installation you use. No extra addon or library is required.

## Use

| Control | Action |
| --- | --- |
| `/hourstone` or `/azerothhours` | Open / close the window |
| `/hourstone minimap` | Toggle the minimap button, even when hidden |
| `/hourstone reset` | Reset the window position |
| Header drag | Move the window |
| Gear button | Minimap visibility, size slider and position reset |
| Character heading | Menu for name, level or realm sorting; select again to reverse |
| Playtime / Updated heading | Sort directly; click again to reverse |
| Mouse wheel | Scroll characters or a long realm menu |
| Escape or red X | Close the window |

Hover a character for its full name, realm and last server synchronization. Long text is shortened in rows so columns remain readable.

## How tracking works

Each character appears after its first login with Hourstone enabled. `RequestTimePlayed()` supplies the server's complete `/played` total, including time before installation. Until the server answers, the addon shows “Not yet available” or the last known value.

Hourstone requests a value at login and when opening the window. Its own requests are at least **60 seconds apart**, including across UI reloads. A request made during this interval is queued; missing replies are retried at that interval. Between answers, only the active character advances using WoW's monotonic timer. New server values replace the local estimate. A manual `/played` answer is accepted too. Blizzard's normal `/played` chat output is left intact, so automatic requests may also print that output.

The session survives `/reload` when WoW explicitly identifies a UI reload. A real login starts a new session. Offline time is never added. AFK time counts as it does in `/played`. Normal logout / reload writes the current snapshot; a crash can lose changes since the last SavedVariables write.

`HourstoneDB` uses schema version 1 and keys records by game flavor plus character GUID. Names, levels and realms refresh while playing. WoW saves data **per installation and WoW account**: Retail and Classic installations do not share or synchronize files. Characters you have not visited cannot be discovered automatically.

Creation dates, import/export, daily/weekly statistics and deletion of tracked records are outside this version.

## Compact interface in v0.1.1

The approved **Mockup 05** is implemented as a **720px-wide** native window. Its height follows the filtered list: **248px for zero or one result, 284px for two, and 500px for eight or more**, at 100% addon scale. Rows are always 36px high; additional records scroll. Names and levels share a line, with the realm below. The columns now use 40% for identity, 35% for playtime and 25% for the last update. The update narrows the search field by 40px and assigns that space to the combined-format button: 111px wide with a 95px text region, so the native German label has ample room.

Original Soundstone panel corners, input framing, red buttons, grip rivets and slider thumbs are used. The small gear sits beside the 28px logo. The complete title and normal-case statistics labels have fixed text regions and use WoW's own standard font. They do not depend on initial text measurements. The footer retains the pink heart, counts and filtered sum. Settings occupy 252 × 190px.

The settings menu uses the native `UICheckButtonTemplate` for the minimap checkbox, as Soundstone does. Checkbox clicks, label clicks and the minimap slash command stay synchronized. The minimap button is reduced from 36 to 28 UI units to match the neighboring buttons more closely: the complete motif occupies 18 units inside a 24-unit mask, with over two units of inner-rim clearance. Existing character records, format, scale and position remain compatible with schema 1. Legacy `compact` values are ignored. Filtering grows the window down from the same header; dragging also saves the height used for that placement. Automatic fitting keeps ten physical pixels per side without changing the saved scale.

See the [German game-test guide](docs/TESTING-0.1.1-DE.md). The supplied test3 game capture confirms the full title, statistics and compact single-character layout at 1440p with 80% global UI scale. It exposed truncation of the combined-format button, addressed in test 4. **100% remains the default**, as requested; saved 110–120% preferences remain unchanged. The size setting is independent of global UI scale. The next native capture identified the flat checkbox appearance and oversized minimap circle. Both corrections were accepted by the user before publication.

## Design preview

The approved [interactive Mockup 05](docs/mockup-05/index.html) contains **sample data and browser rendering**, not an in-game screenshot. [Mockup 04](docs/mockup/index.html) remains available for comparison. Open the HTML locally to interact with it. Mockup 05 uses Georgia as a browser approximation of WoW's native font. The approved stone/hourglass logo is unchanged. The [native game capture](docs/curseforge/screenshots/compact-ingame.png) documents the preceding test3 layout; the later label, checkbox and minimap corrections are described in its gallery caption.

## Development

Python 3.12 and the pinned development dependencies are used for tests and asset conversion:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p 'test_*.py'
python tools/package.py --tag v0.1.1
```

`tools/assets.py` regenerates the shipping TGA textures from the PNG masters. Packaging validates the TOC, version, client interfaces, referenced files, texture headers and ZIP structure. Builds are deterministic and include a SHA-256 file.

`python tools/preview.py` produces `dist/lua-ui-preview.html` from the actual Lua frame definitions for layout review. This is a development approximation with fictional data, Georgia and a browser approximation of the client-owned gear. Browser rendering is not evidence of in-game pixel accuracy.

Pushes and pull requests run **Validate** and upload an installable ZIP. Pushing a matching `v*` tag runs **Release** and publishes only after the same checks pass. Its manual action also accepts a matching tag and creates it after validation. Existing published releases are preserved.

## License and artwork

[MIT](LICENSE), © 2026 krebs3r. Includes Soundstone frame textures under the same license. Bundled Gelasio and Selawik fonts retain their respective SIL Open Font Licenses; see [font provenance](docs/FONTS.md). See [artwork provenance](docs/ARTWORK.md). World of Warcraft is a trademark of Blizzard Entertainment; Hourstone is an independent community addon.
