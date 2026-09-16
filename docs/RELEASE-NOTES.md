# Hourstone 0.2.1 — development

Character rows now show the last recorded guild, distinguish guildless characters
from missing information, and include guild names in search and full tooltips.
Guild changes use a separate server timestamp and cannot change the selected
playtime baseline or add duplicate totals.

For synchronization, update Hourstone to 0.2.1 and Companion to 0.1.2 on all PCs.
Protocol 2 transports guild membership; legacy protocol 1 input and existing
SavedVariables remain readable. Log in with each character, then log out or
`/reload` to populate its guild information. Offline characters retain their last
saved status. The addon remains usable without a companion.

## Installation

With WoW closed, extract `Hourstone-0.2.1.zip` into each client's `Interface/AddOns`
folder. Keep existing SavedVariables and settings. The companion imports after
WoW saves and makes its data addon available on the next game start or reload.
The first installation of the data addon requires a complete WoW restart.

## Deutsch

Die Charakterliste zeigt die Gilde und lässt sich nach Gildennamen durchsuchen.
„Keine Gilde“ unterscheidet sich von „Noch nicht erfasst“. Gildenwechsel werden
unabhängig von der Spielzeit zusammengeführt. Für den Abgleich müssen Addon
0.2.1 und Companion 0.1.2 auf allen Rechnern installiert sein. Jeder Charakter
muss einmal mit dem neuen Addon eingeloggt und durch `/reload` oder Ausloggen
gespeichert werden. Bestehende Daten und Einstellungen bleiben erhalten.

Automated contract, tracking and layout tests use synthetic data. Live-client
and two-device provider checks remain necessary before public release.
