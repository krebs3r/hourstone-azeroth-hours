# Hourstone 0.3.6 — 2026-11-05

Hourstone 0.3.6 shows **WoW: Forever** characters as **WoW: Forever** instead of
Retail. In the Forever client, the client column, the row tooltip and the client sort
use the new label, and the client filter offers WoW: Forever next to Retail. Forever
characters still belong to the Retail client family for saved keys, removal from the
overview and Companion protocol 4, which has no separate Forever family; Hourstone
stores the label as a separate marker beside it.

If Hourstone created its database in Forever after the launch on 4 November 2026 at
23:00 UTC, the characters that 0.3.5 or earlier recorded there change their label on
the first load of 0.3.6 in Forever; so do entries that an earlier version filed under
an unknown client such as `project-18`. In an older database, such as a `WTF` folder
copied from Retail, characters stay under Retail until they log in again in Forever.
From now on, every Hourstone database records the client that last loaded it, so a
database copied from another client running 0.3.6 or later is never relabelled.

**Synchronization:** a synchronized observation of a Forever character keeps the
label in Forever, and Retail's progress view treats Forever characters as
unsupported. Protocol 4 carries no client marker, so every client, Forever included,
still lists synchronized Forever characters that the account has not recorded itself,
such as another account's or another PC's, under Retail. Companion 0.2.1 and newer
already label them as WoW: Forever.

Nothing else changes for Retail and Classic clients. Saved characters, playtime and
settings are preserved; SavedVariables schema 3 and Companion protocol 4 are
unchanged, and the Companion ignores the new markers. With WoW closed, extract
`Hourstone-0.3.6.zip` into `Interface/AddOns`.

Automated checks are described in
[validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.6/docs/VALIDATION.md).
The author tested this build in the live WoW: Forever client (build 1.60.1.70790):
characters recorded by 0.3.5 and by 0.3.6 show as WoW: Forever. The live client's
interface number has not been recorded yet, and Retail and Classic were not
separately tested in-game for this release.

## Deutsch

Hourstone 0.3.6 zeigt Charaktere aus **WoW: Forever** als **WoW: Forever** statt als
Retail an. Im Forever-Client verwenden Clientspalte, Zeilen-Tooltip und
Client-Sortierung die neue Bezeichnung, und der Clientfilter bietet WoW: Forever
neben Retail an. Für gespeicherte Schlüssel, das Löschen aus der Übersicht und
Companion-Protokoll 4, das keine eigene Forever-Familie kennt, bleiben
Forever-Charaktere in der Clientfamilie Retail; Hourstone speichert die Bezeichnung
als eigene Markierung daneben.

Hat Hourstone seine Datenbank nach dem Start am 5. November 2026 um 0:00 Uhr MEZ in
Forever angelegt, erhalten die Charaktere, die 0.3.5 oder älter dort erfasst hat, die
neue Bezeichnung beim ersten Laden von 0.3.6 in Forever; ebenso Einträge, die eine
frühere Version unter einem unbekannten Client wie `project-18` abgelegt hat. In einer
älteren Datenbank, etwa einem von Retail kopierten `WTF`-Ordner, bleiben Charaktere
unter Retail, bis sie sich erneut in Forever einloggen. Ab jetzt merkt sich jede
Hourstone-Datenbank, welcher Client sie zuletzt geladen hat; eine von einem anderen
Client mit 0.3.6 oder neuer kopierte Datenbank wird daher nie umbenannt.

**Abgleich:** Eine synchronisierte Beobachtung eines Forever-Charakters behält in
Forever die Bezeichnung, und die Retail-Fortschrittsansicht behandelt
Forever-Charaktere als nicht unterstützt. Weil Protokoll 4 keine Client-Markierung
überträgt, führt jeder Client, auch Forever, synchronisierte Forever-Charaktere, die
der Account nicht selbst erfasst hat, etwa die eines anderen Accounts oder PCs,
weiterhin unter Retail. Companion ab 0.2.1 zeigt sie bereits als WoW: Forever an.

Sonst ändert sich für Retail- und Classic-Clients nichts. Charaktere, Spielzeit und
Einstellungen bleiben erhalten; Schema 3 und Companion-Protokoll 4 sind unverändert,
und der Companion ignoriert die neuen Markierungen. Das ZIP bei geschlossenem WoW nach
`Interface/AddOns` entpacken. Die automatischen Prüfungen stehen in der verlinkten
Validierung. Der Autor hat diesen Build im Live-Client von WoW: Forever (Build
1.60.1.70790) getestet: Von 0.3.5 und von 0.3.6 erfasste Charaktere erscheinen als
WoW: Forever. Die Interface-Nummer des Live-Clients ist noch nicht erfasst, und
Retail und Classic wurden für diese Version nicht gesondert im Spiel getestet.
