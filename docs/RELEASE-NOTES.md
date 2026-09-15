# Hourstone 0.1.1 – Azeroth Hours

A compact playtime tracker in the Soundstone addon family. This release contains the approved test5 addon files without further runtime changes.

## Changes

- Compact 720px window with height following the visible character list (248–500px at 100%). Up to eight rows are visible; additional characters scroll.
- Soundstone-style Retail and Classic frames, native WoW fonts, red buttons and a small settings gear.
- Complete title and statistics labels, wider German time-format button and better balanced columns.
- Character name and level together, realm beneath; sortable name, level, realm, playtime and last update.
- Native minimap checkbox and a smaller, centered minimap button with the complete hourglass motif.
- Footer totals and pink heart; preserved character data, time format, position and scale. Default scale remains 100%.

## Installation

Download **Hourstone-0.1.1.zip** and extract the contained **Hourstone** folder into your client's **Interface/AddOns** directory. Replace the existing Hourstone folder when updating. Keep **WTF** to preserve your saved characters and settings.

## Validation and supported clients

The final package was approved by the user in **Retail 12.1.0** and **TBC Anniversary 2.5.6**. Local checks pass: 30 Lua scenario suites and 8 Python tests, including tracking, reloads, offline exclusion, 40 layout states, 360 scaling cases, minimap containment and deterministic packaging. GitHub Actions repeats these checks before publishing.

Mists Classic, Classic Era, Hardcore and Season of Discovery are implemented and simulated, but remain unverified in game. They are not selected for this CurseForge file. Combat/taint behavior and the full manual per-client checklist have not been separately reported.

SHA-256: `8b38daa8a75abc48b043c4eb7bcca7790d799c7dc7d821b63dc2d7581c8c446b`

## Deutsch

Kompakte Oberfläche im Soundstone-Stil, vollständiger Titel, breiterer Zeitformat-Button, native Checkbox und kleinerer Minimap-Button. Charakterdaten und Einstellungen bleiben erhalten; 100 % bleibt der Standard.

Der freigegebene Test-5-Stand wurde unverändert übernommen. Der Nutzer hat Retail und TBC Anniversary bestätigt; weitere Clientfamilien und die vollständige manuelle Prüfliste bleiben offen. Zum Installieren den enthaltenen Ordner **Hourstone** in **Interface/AddOns** ersetzen und **WTF** beibehalten.
