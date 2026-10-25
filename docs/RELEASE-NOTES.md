# Hourstone 0.3.4 — 2026-10-25

Hourstone 0.3.4 declares interface 120105, so **WoW 12.1.5** no longer lists it as
out of date. The Retail client expects that number since the patch and treated
Hourstone 0.3.3 as out of date. None of the game functions
Hourstone uses changed with the patch, so for Retail this release only updates the
declared interface. If WoW disabled Hourstone after the patch, enable it again in
the AddOn list at character selection.

**WoW: Forever** builds since 1.60.1.70170 report their own project instead of
Retail. Hourstone 0.3.3 therefore listed Forever characters as an unknown client,
outside the Retail family that Companion protocol 4 exchanges, and could not remove
them from the overview. 0.3.4 keeps them in the Retail client family again. When
Hourstone loads on Forever, entries recorded by 0.3.3 return to Retail and merge
with an earlier Retail entry of the same character, without adding its playtime
twice. If you deleted a Retail duplicate of such a character under 0.3.3, the merged
character stays under **Deleted characters** until its next login or until you
restore it there.

The Companion data addon Hourstone_Sync declares its own interface. If its
`Hourstone_Sync.toc` still lists 120100, WoW 12.1.5 skips it as out of date, and
synchronized characters from other installations do not appear in Retail until a
Companion update declares 120105. Until then, enable **Load out of date AddOns** in
the AddOn list to keep receiving them.

Updating directly from 0.3.2 or earlier: where WoW offers the Addons menu below the
clock, Hourstone hides its minimap button once; `/hourstone minimap` or the settings
bring it back. Saved characters, settings and the minimap position are preserved. SavedVariables
schema 3 and Companion protocol 4 are unchanged. With WoW closed, extract
`Hourstone-0.3.4.zip` into `Interface/AddOns`.

Automated checks are described in
[validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.4/docs/VALIDATION.md).
The author tested the 0.3.4 build in-game in Retail 12.1.5. The WoW: Forever change
is covered by automated checks; an in-game test on current Forever builds is still
pending. Client families not separately tested for this version are released on the
author's compatibility statement.

## Deutsch

Hourstone 0.3.4 gibt Interface 120105 an, damit **WoW 12.1.5** es nicht mehr als
veraltet einstuft. Der Retail-Client erwartet diese Nummer seit dem Patch und hat
Hourstone 0.3.3 als veraltet eingestuft. Keine der von
Hourstone genutzten Spielfunktionen hat sich mit dem Patch geändert; für Retail
passt dieses Release daher nur das angegebene Interface an. Falls WoW Hourstone
nach dem Patch deaktiviert hat, in der AddOn-Liste bei der Charakterauswahl wieder
aktivieren.

**WoW: Forever** meldet seit Build 1.60.1.70170 ein eigenes Projekt statt Retail.
Hourstone 0.3.3 hat Forever-Charaktere deshalb als unbekannten Client außerhalb
der Retail-Familie geführt, die Companion-Protokoll 4 austauscht, und konnte sie
nicht aus der Übersicht entfernen. 0.3.4 ordnet sie wieder der Clientfamilie
Retail zu. Beim Laden auf Forever kehren von 0.3.3 angelegte Einträge zu Retail
zurück und werden mit einem früheren Retail-Eintrag desselben Charakters
zusammengeführt, ohne die Spielzeit doppelt zu zählen. Wurde unter 0.3.3 eine
Retail-Doublette eines solchen Charakters gelöscht, bleibt der zusammengeführte
Charakter bis zu seinem nächsten Login unter **Gelöschte Charaktere**, sofern er
dort nicht vorher wiederhergestellt wird.

Das Companion-Datenaddon Hourstone_Sync gibt ein eigenes Interface an. Steht in
seiner `Hourstone_Sync.toc` noch 120100, überspringt WoW 12.1.5 es als veraltet.
Abgeglichene Charaktere anderer Installationen erscheinen in Retail dann erst
wieder, wenn ein Companion-Update 120105 angibt. Bis dahin in der AddOn-Liste das
**Laden veralteter AddOns** erlauben, um sie weiter zu empfangen.

Bei einem Update direkt von 0.3.2 oder älter blendet Hourstone dort, wo WoW das
Addons-Menü unter der Uhr anbietet, den Minimap-Button einmalig aus;
`/hourstone minimap` oder die Einstellungen blenden ihn wieder ein. Charaktere,
Einstellungen und die Minimap-Position bleiben erhalten; Schema 3 und
Companion-Protokoll 4 sind unverändert. Das ZIP bei geschlossenem WoW nach
`Interface/AddOns` entpacken. Die automatischen Prüfungen stehen in der verlinkten
Validierung. Der Autor hat den Build von 0.3.4 im Spiel in Retail 12.1.5 getestet.
Die Forever-Änderung ist durch automatische Prüfungen abgedeckt; ein Spieltest auf
aktuellen Forever-Builds steht noch aus. Clientfamilien, die für diese Version
nicht einzeln getestet wurden, sind auf Grundlage der Kompatibilitätsaussage des
Autors freigegeben.
