# Hourstone 0.2.3 — development

Realm and client filters now sit together above the table. A dedicated client
column beside playtime shows each character's game version and sorts by its
displayed name. Unknown client families sort last in either direction.

The minimap button uses Blizzard's tracking border, background and highlight,
with Retail/Classic placement and the complete Hourstone logo. The footer reads
`v0.2.3 with ♥ by krebs3r`. Character tooltips keep the last server timestamp on
one line and explain estimated or unconfirmed time without an online/offline claim.

Right-click an entry and confirm **Delete** to exclude it from the overview and
its totals. Its playtime and your WoW character are preserved. Choose **Deleted
characters** in the gear menu and right-click to restore an entry. A new character
login restores known deletions too; `/reload`, zoning and `/played` do not. If a
deletion happened on another PC while offline, synchronize before logging in again.

## Installation and compatibility

With WoW closed, extract `Hourstone-0.2.3.zip` into each client's `Interface/AddOns`
folder. Keep existing SavedVariables. Characters, guilds, settings and the saved
minimap position are preserved. Protocol and saved-data schema remain at version
3, unchanged from Hourstone 0.2.2; no new migration is required. Companion 0.1.3
and later remains compatible. The addon also runs without Companion.

## Deutsch

Realm- und Clientfilter stehen jetzt gemeinsam neben der Suche über der Tabelle.
Eine eigene sortierbare Clientspalte links neben der Spielzeit zeigt die Spielversion
des Charakters. Unbekannte Clients stehen in beiden Sortierrichtungen zuletzt.

Der Minimap-Button nutzt Blizzards Rahmen, Hintergrund und Hovereffekt mit passenden
Retail-/Classic-Abständen und vollständigem Logo. Im Footer steht
`v0.2.3 with ♥ by krebs3r`. Im Charakter-Tooltip bleibt der letzte Serverzeitstempel
auf einer Zeile. Geschätzte oder unbestätigte Spielzeit wird erklärt; eine
Online-/Offline-Anzeige entfällt.

Einträge lassen sich per Rechtsklick und **Löschen** aus der Übersicht ausblenden.
Unter Zahnrad → **Gelöschte Charaktere** stellt ein Rechtsklick sie wieder her.
WoW-Charakter und Spielzeit bleiben erhalten. Ein neuer Login stellt bekannte
Löschungen ebenfalls wieder her; `/reload` genügt nicht. Nach einer Löschung auf
einem anderen PC während des Offline-Betriebs zuerst synchronisieren, dann einloggen.

Bei geschlossenem WoW `Hourstone-0.2.3.zip` nach `Interface/AddOns` entpacken.
Charaktere, Gilden, Einstellungen und Minimap-Position bleiben erhalten.
Protokoll und Datenschema bleiben bei Version 3; keine neue Migration erforderlich.

Automated checks use synthetic data. Native minimap/font rendering, live-client
behavior and two-device provider checks still require practical verification.
