<p align="center"><img src="docs/assets/Logo.png" width="170" alt="Hourstone: blue rune stone with a golden hourglass"></p>

# Hourstone – Azeroth Hours

**Your characters. Your time.**

A standalone World of Warcraft addon that keeps a list of your characters and their total playtime. A sibling to [Soundstone – Azeroth Audio](https://github.com/krebs3r/soundstone-azeroth-audio), with the same blue rune stone, warm gold details and Retail / Classic frames.

[Download the prerelease](https://github.com/krebs3r/hourstone-azeroth-hours/releases) · [Deutsche Anleitung](docs/DEUTSCH.md) · [Report an issue](https://github.com/krebs3r/hourstone-azeroth-hours/issues)

## Features

- Class-colored character names, level, realm, total playtime and last update.
- Account total, character count and current session; filtered totals when searching.
- Name search, realm filter and sortable columns. Highest playtime comes first.
- Switch between decimal hours (`312.5 hr`) and days / hours / minutes (`13 d 0 hr 30 min`).
- Movable window, saved position and scale, compact rows and an optional draggable minimap button.
- German on `deDE` clients, English on all other locales.
- No dependencies or external service. Your data stays in WoW's local SavedVariables.

## Supported clients

| Client family | Interface declared | In-game verification |
| --- | ---: | --- |
| Retail (12.1.0) | 120100 | Pending |
| Mists of Pandaria Classic (5.5.4) | 50504 | Pending |
| Burning Crusade Classic Anniversary (2.5.6) | 20506 | Pending |
| Classic Era, Hardcore and Season of Discovery (1.15.9) | 11509 | Pending |

This is **v0.1.0, a prerelease**. Lua 5.1 event and UI simulations cover these families; they do not replace testing inside the game. See [validation and client checklist](docs/VALIDATION.md). Historical private-server clients are outside this release's scope.

## Install

1. Download **`Hourstone-0.1.0.zip`** from [Releases](https://github.com/krebs3r/hourstone-azeroth-hours/releases). GitHub's automatically generated source archives are for development.
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
| Gear button | Minimap visibility, row spacing, scale and position reset |
| Column title | Sort; click again to reverse |
| Mouse wheel | Scroll characters or a long realm menu |
| Escape, close or hide button | Close the window |

Hover a character for its full name, realm and last server synchronization. Long text is shortened in rows so columns remain readable.

## How tracking works

Each character appears after its first login with Hourstone enabled. `RequestTimePlayed()` supplies the server's complete `/played` total, including time before installation. Until the server answers, the addon shows “Not yet available” or the last known value.

Hourstone requests a value at login and when opening the window. Its own requests are at least **60 seconds apart**, including across UI reloads. A request made during this interval is queued; missing replies are retried at that interval. Between answers, only the active character advances using WoW's monotonic timer. New server values replace the local estimate. A manual `/played` answer is accepted too. Blizzard's normal `/played` chat output is left intact, so automatic requests may also print that output.

The session survives `/reload` when WoW explicitly identifies a UI reload. A real login starts a new session. Offline time is never added. AFK time counts as it does in `/played`. Normal logout / reload writes the current snapshot; a crash can lose changes since the last SavedVariables write.

`HourstoneDB` uses schema version 1 and keys records by game flavor plus character GUID. Names, levels and realms refresh while playing. WoW saves data **per installation and WoW account**: Retail and Classic installations do not share or synchronize files. Characters you have not visited cannot be discovered automatically.

Creation dates, import/export, daily/weekly statistics and deletion of tracked records are outside v0.1.0.

## Design preview

The approved [interactive mockup](docs/mockup/index.html) contains **sample data and browser rendering**, not an in-game screenshot. Download the repository and open that HTML locally to interact with it. Its Retail and Classic skins use the Soundstone textures. The final logo uses a golden hourglass; the earlier clock concepts were discarded. Actual game screenshots will be added after client testing.

## Development

Python 3.12 and the pinned development dependencies are used for tests and asset conversion:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p 'test_*.py'
python tools/package.py --tag v0.1.0
```

`tools/assets.py` regenerates the shipping TGA textures from the PNG masters. Packaging validates the TOC, version, client interfaces, referenced files, texture headers and ZIP structure. Builds are deterministic and include a SHA-256 file.

`python tools/preview.py` produces `dist/lua-ui-preview.html` from the actual Lua frame definitions for layout review. This is a development approximation with fictional data and substitute browser fonts.

Pushes and pull requests run **Validate** and upload an installable ZIP. Pushing a matching `v*` tag runs **Prerelease** and publishes only after the same checks pass. Its manual action also accepts a matching tag, creates it after validation and publishes the first prerelease. Existing published releases are preserved.

## License and artwork

[MIT](LICENSE), © 2026 krebs3r. Includes Soundstone frame textures under the same license. See [artwork provenance](docs/ARTWORK.md). World of Warcraft is a trademark of Blizzard Entertainment; Hourstone is an independent community addon.
