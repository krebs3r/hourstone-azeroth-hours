# Hourstone 0.1.0 – Azeroth Hours

**Your characters. Your time. / Deine Charaktere. Deine Spielzeit.**

The first Hourstone prerelease tracks character playtime with a golden hourglass logo and the same Retail / Classic frame family as Soundstone.

## Included

- Character names in class colors, level, realm, playtime and last update.
- Total playtime, session time, name search, realm filter, sorting and filtered totals.
- Decimal hours or days / hours / minutes; German and English.
- Saved window position / scale, compact rows and an optional minimap button.
- Server `/played` totals, local active-character counting, preserved sessions on `/reload`, no offline time.
- Shared code for Retail, Mists Classic, TBC Anniversary and Classic Era / Hardcore / SoD.

## Install

Download **Hourstone-0.1.0.zip** and extract it into your client's `Interface/AddOns` folder. The resulting path must be `Interface/AddOns/Hourstone/Hourstone.toc`. A SHA-256 checksum is attached. GitHub's source archives are not the installation package.

## Validation and limitations

- Automated Lua 5.1 model, tracking and native-UI simulations pass for the four intended client families plus an unknown-project fallback, in German / English / fallback locale configurations.
- Simulations cover delayed / absent replies, throttling, server replacement, reloads, offline periods, character changes, duplicate names, filters, sorting, long lists and scale constraints.
- Package checks validate versions, interface metadata, assets, deterministic output and install layout.
- **No actual WoW client has been verified yet.** Loading, `/played` parity, real SavedVariables persistence, combat interaction, minimap positioning and rendering need in-game checks in every family. Mockups are previews with sample data.
- Each character must be visited once with Hourstone enabled. Separate WoW installations / accounts keep separate data. AFK time counts as `/played`; automatic queries may show Blizzard's regular `/played` chat output.

Please report client version, locale and reproduction steps in GitHub Issues.
