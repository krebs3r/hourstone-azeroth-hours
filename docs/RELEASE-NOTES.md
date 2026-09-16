# Hourstone 0.2.2 — development

Right-click a character and confirm **Remove** to hide it from the overview and
its totals. Its playtime and your WoW character are preserved. Choose **Removed
characters** in the gear menu and right-click an entry to restore it. The summary
cards always count tracked characters only.

A new character login also restores removals already known to the addon. Reloads,
zoning and `/played` do not. An active removed character continues to record time.
If another PC removed it while you were offline, synchronize first, then log in
with the character again. Changes are saved when WoW logs out or reloads.

Update Hourstone to 0.2.2 and Companion to 0.1.3 on every PC for protocol 3 removal
and restore synchronization. Guild tracking is retained. Legacy protocol 1 and 2
input remains readable; existing characters and settings migrate automatically
to saved-data schema 3. The addon remains usable without Companion.

## Installation

With WoW closed, extract `Hourstone-0.2.2.zip` into each client's `Interface/AddOns`
folder. Keep existing SavedVariables and settings. The companion imports after
WoW saves and makes its data addon available on the next game start or reload.
The first installation of the data addon requires a complete WoW restart.

## Deutsch

Charaktere lassen sich nach einem Rechtsklick und einer Bestätigung aus der
Übersicht entfernen. Die Spielzeit bleibt gespeichert, dein WoW-Charakter wird
nicht gelöscht. Unter Zahnrad → **Entfernte Charaktere** stellt ein Rechtsklick
den Eintrag wieder her. Die Kennzahlen zählen nur die nicht entfernten Charaktere.

Ein neuer Charakter-Login stellt bekannte Entfernungen ebenfalls wieder her;
`/reload`, Gebietswechsel und `/played` nicht. Nach einer Offline-Entfernung auf
einem anderen Rechner zuerst synchronisieren und anschließend erneut einloggen.
Auch ein ausgeblendeter aktiver Charakter erfasst seine Spielzeit weiter.
Aktualisiere Addon auf 0.2.2 und Companion auf 0.1.3 auf allen PCs. Bestehende
Charakter-, Gilden- und Einstellungsdaten bleiben erhalten.

Automated contract, tracking and layout tests use synthetic data. Live-client
and two-device provider checks remain necessary before public release.
