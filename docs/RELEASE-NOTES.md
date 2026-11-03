# Hourstone 0.3.5 — 2026-11-03

Hourstone 0.3.5 prepares for the launch of **WoW: Forever** on 4 November 2026 at
23:00 UTC (00:00 CET on 5 November). On a Forever client (interface 16xxx),
Hourstone now files every character under the Retail client family, whatever
project ID the client reports, so Forever characters cannot end up under an
unknown client even if a live build reports a different project ID. When Hourstone loads on Forever, characters that an earlier version
filed under an unknown client (for example `project-18` from 0.3.3) return to Retail
and merge with an earlier Retail entry of the same character, without adding its
playtime twice. An entry that cannot be merged keeps its previous client.

WoW: Forever replaces realms with rulesets. Hourstone no longer saves an empty realm
or name: if the game reports a character without a realm, Hourstone asks WoW for the
current realm name and otherwise saves `?`; an empty name also becomes `?`. The
Companion rejects an empty realm, and a single such entry would block the whole
account there.

**Coming from the Forever beta?** Beta characters do not carry over to the live
game. If you copied the beta's `WTF` folder into `_forever_`, close WoW and move
`Hourstone.lua` out of `_forever_\WTF\Account\*\SavedVariables` before your first
live login (move it, do not delete it); otherwise the beta characters stay in the
list.

**Companion 0.2.1** is released alongside this version. Its data addon
Hourstone_Sync now declares 120105 and 16001, so WoW 12.1.5 and WoW: Forever no
longer list it as out of date, and the **Load out of date AddOns** workaround from
the 0.3.4 notes is no longer needed for it. After updating the Companion, fully
close and restart WoW once. Companion 0.2.1 shows Forever installations and their
characters as **WoW: Forever**; in Hourstone they stay under Retail, because
Companion protocol 4 has no separate Forever family.

Nothing changes for Retail and Classic clients. Updating directly from 0.3.2 or
earlier: where WoW offers the Addons menu below the clock, Hourstone hides its
minimap button once; `/hourstone minimap` or the settings bring it back. Saved
characters, settings and the minimap position are preserved. SavedVariables schema 3
and Companion protocol 4 are unchanged. With WoW closed, extract
`Hourstone-0.3.5.zip` into `Interface/AddOns`.

Automated checks are described in
[validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.5/docs/VALIDATION.md).
They cover the Forever changes. No Hourstone build has run in the live WoW: Forever
client yet, and interface 16001 is so far confirmed only on Forever beta and test
builds. In-game testing of 0.3.5 is pending; this release does not claim that
coverage.

## Deutsch

Hourstone 0.3.5 ist für den Start von **WoW: Forever** am 5. November 2026 um
0:00 Uhr MEZ (4. November, 23:00 UTC) vorbereitet. Auf einem Forever-Client (Interface
16xxx) ordnet Hourstone jetzt jeden Charakter der Clientfamilie Retail zu, ganz
gleich, welche Projekt-ID der Client meldet. Forever-Charaktere landen damit auch
dann nicht unter einem unbekannten Client, wenn ein Live-Build eine andere
Projekt-ID meldet. Beim Laden auf Forever kehren Charaktere, die
eine frühere Version unter einem unbekannten Client abgelegt hat (etwa `project-18`
aus 0.3.3), zu Retail zurück und werden mit einem früheren Retail-Eintrag desselben
Charakters zusammengeführt, ohne die Spielzeit doppelt zu zählen. Ein Eintrag, der
sich nicht zusammenführen lässt, behält seinen bisherigen Client.

WoW: Forever ersetzt Realms durch Regelwerke. Hourstone speichert keinen leeren Realm
und keinen leeren Namen mehr: Meldet das Spiel einen Charakter ohne Realm, fragt
Hourstone den aktuellen Realmnamen bei WoW ab und speichert andernfalls `?`; ein
leerer Name wird ebenfalls zu `?`. Der Companion lehnt einen leeren Realm ab, und
schon ein einziger solcher Eintrag würde dort den ganzen Account blockieren.

**Forever-Beta gespielt?** Beta-Charaktere werden nicht ins Live-Spiel übernommen.
Falls der `WTF`-Ordner der Beta nach `_forever_` kopiert wurde: WoW schließen und vor
dem ersten Live-Login `Hourstone.lua` aus `_forever_\WTF\Account\*\SavedVariables`
herausverschieben (verschieben, nicht löschen). Sonst bleiben die Beta-Charaktere in
der Liste.

**Companion 0.2.1** erscheint zusammen mit dieser Version. Sein Datenaddon
Hourstone_Sync gibt jetzt 120105 und 16001 an. WoW 12.1.5 und WoW: Forever stufen es
daher nicht mehr als veraltet ein, und das in den Hinweisen zu 0.3.4 empfohlene
**Laden veralteter AddOns** ist dafür nicht mehr nötig. Nach dem Companion-Update WoW
einmal vollständig schließen und neu starten. Companion 0.2.1 zeigt
Forever-Installationen und ihre Charaktere als **WoW: Forever** an; in Hourstone
bleiben sie unter Retail, weil Companion-Protokoll 4 keine eigene Forever-Familie
kennt.

Für Retail- und Classic-Clients ändert sich nichts. Bei einem Update direkt von
0.3.2 oder älter blendet Hourstone dort, wo WoW das Addons-Menü unter der Uhr
anbietet, den Minimap-Button einmalig aus; `/hourstone minimap` oder die
Einstellungen blenden ihn wieder ein. Charaktere, Einstellungen und die
Minimap-Position bleiben erhalten; Schema 3 und Companion-Protokoll 4 sind
unverändert. Das ZIP bei geschlossenem WoW nach `Interface/AddOns` entpacken. Die
automatischen Prüfungen stehen in der verlinkten Validierung und decken die
Forever-Änderungen ab. Im Live-Client von WoW: Forever lief noch kein
Hourstone-Build, und Interface 16001 ist bisher nur auf Beta- und Test-Builds von
Forever bestätigt. Ein Spieltest von 0.3.5 steht noch aus und wird nicht als
bestanden ausgewiesen.
