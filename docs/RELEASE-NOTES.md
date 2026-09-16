# Hourstone 0.2.3 — 2026-09-16

This is the first public 0.2.x release. Since 0.1.1, Hourstone adds guild tracking
and guild search, reversible deletion of overview entries, and optional protocol 3
integration with the separate Windows [Hourstone Companion](https://github.com/krebs3r/hourstone-companion).
The addon continues to work independently. Companion is currently a source/development
preview; a signed public installer is not yet available.

Realm and client filters now sit together above the table. A dedicated, sortable
client column sits beside playtime; unknown clients sort last in both directions.
The minimap button uses Blizzard's native tracking border, background and highlight
with Retail/Classic placement and the complete logo. Tooltips keep the last server
timestamp on one line and explain estimates without an online/offline claim.
The footer reads `v0.2.3 with ♥ by krebs3r`.

Right-click an entry and confirm **Delete** to exclude it from the overview and
its totals. Your WoW character and saved playtime remain intact. In the gear menu,
choose **Deleted characters** and right-click to restore an entry. A new character
login also restores deletions already known to the addon; `/reload`, zoning and
`/played` do not. After an offline deletion on another PC, synchronize before
logging in again.

## Installation and compatibility

With WoW closed, extract `Hourstone-0.2.3.zip` into each client's `Interface/AddOns`
folder. Keep existing SavedVariables. Upgrading from public 0.1.1 migrates data to
schema 3 while preserving character records, settings and minimap position. Existing
playtime is retained as the last unconfirmed value until a new server measurement.
The 0.2.2 development build already uses schema/protocol 3 and needs no further
migration. Guild information is recorded as you log in with each character.

Companion 0.1.3 and later can read the saved data after WoW logs out or `/reload`s.
The addon reads the shared overview at the next login or `/reload`. After the first
installation of the Companion data addon, fully close and restart WoW once. Between
PCs, a service such as Dropbox or OneDrive transfers the chosen, locally available
sync folder; this is a delayed exchange, not a live update of a running session.

Validation: 60 Lua scenario suites and 33 Python tests passed. The new layout and
minimap were checked in TBC Anniversary. Native checks for the new version in the
other client families and two-PC synchronization checks remain outstanding.

## Deutsch

Dies ist die erste öffentliche Version der 0.2.x-Reihe. Gegenüber 0.1.1 sind
Gildenerfassung und Gildensuche, wiederherstellbare Löschungen aus der Übersicht
und die optionale Protokoll-3-Anbindung an den [Hourstone Companion](https://github.com/krebs3r/hourstone-companion)
für Windows hinzugekommen. Das Addon funktioniert weiterhin eigenständig. Der
Companion ist derzeit eine Quellcode-/Entwicklungsvorschau; ein signierter öffentlicher
Installer steht noch aus.

Realm- und Clientfilter stehen zusammen neben der Suche. Die eigene Clientspalte
links neben der Spielzeit ist sortierbar; unbekannte Clients stehen zuletzt.
Der Minimap-Button verwendet Blizzards Rahmen, Hintergrund und Hovereffekt mit
passenden Retail-/Classic-Abständen und vollständigem Logo. Der letzte
Serverzeitstempel bleibt im Tooltip auf einer Zeile. Geschätzte Spielzeit wird
weiter erklärt; die Online-/Offline-Angabe entfällt. Im Footer steht
`v0.2.3 with ♥ by krebs3r`.

Mit Rechtsklick und **Löschen** blendest du einen Eintrag aus der Übersicht aus.
WoW-Charakter und Spielzeit bleiben erhalten. Unter Zahnrad → **Gelöschte Charaktere**
stellt ein Rechtsklick den Eintrag wieder her. Ein neuer Login stellt bereits bekannte
Löschungen ebenfalls wieder her; `/reload` genügt nicht. Nach einer Löschung während
des Offline-Betriebs zuerst synchronisieren, dann neu mit dem Charakter einloggen.

Bei geschlossenem WoW das ZIP nach `Interface/AddOns` entpacken. Beim Upgrade von
0.1.1 werden vorhandene Daten unter Erhalt von Charakteren, Einstellungen und
Minimap-Position auf Schema 3 umgestellt. Gespeicherte Spielzeit bleibt bis zum
nächsten Serverwert als unbestätigter letzter Stand erhalten. Gegenüber dem
Entwicklungsstand 0.2.2 gibt es keine weitere Migration. Gilden werden bei den
nächsten Charakter-Logins erfasst.

Der Companion liest von WoW beim Ausloggen oder `/reload` gespeicherte Daten ein.
Die gemeinsame Übersicht erscheint beim nächsten Login oder `/reload`; nach der
ersten Einrichtung des Companion-Datenaddons WoW einmal vollständig neu starten.
Für mehrere PCs überträgt beispielsweise Dropbox oder OneDrive den ausgewählten,
dauerhaft lokal verfügbaren Syncordner.

60 Lua-Szenariosuiten und 33 Python-Tests sind erfolgreich. Neues Layout und
Minimap wurden in TBC Anniversary geprüft. Spieltests der neuen Version in den
übrigen Clientfamilien und praktische Tests zwischen zwei PCs stehen noch aus.
