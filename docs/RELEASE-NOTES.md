# Hourstone 0.3.1 — 2026-09-17

Fixes the window jumping back during a drag: timed refreshes wait until release,
then use the newly saved position. Closing the window during a drag is also handled.

Retail now has **Time played / Progress** tabs in the existing window. The Progress
view shows character and guild, the owned keystone,
the highest completed Mythic+ level this week and three Great Vault rows with three
slots each. Hover a cell for full names, slot requirements and the capture time.

![Hourstone Retail progress overview](https://raw.githubusercontent.com/krebs3r/hourstone-azeroth-hours/v0.3.1/docs/assets/addon-progress-en.png)

Rendered interface with example characters.

Dungeon names, keystones, completed runs and Vault thresholds come from Blizzard's
APIs. Completed overtime runs count; abandoned runs do not. Unknown data, a confirmed
missing key and stale data have distinct displays. Previous reward data is not
presented as this week's progress.

The size control now covers **65–200%** in 5% steps. Larger settings first reduce
the number of visible rows; scrolling keeps every character accessible. The window
only shrinks below the requested size when its width or minimum height cannot fit.
Classic clients keep the playtime view with the larger scale range.

## Installation and compatibility

Extract `Hourstone-0.3.1.zip` into `Interface/AddOns` with WoW closed. Keep existing
SavedVariables. Settings, character/guild data and removal controls are preserved.
Existing Companion synchronization remains compatible. Progress stays local to
the WoW installation and account; Companion continues to exchange playtime, guilds
and delete/restore controls.

Log in with each desired Retail character to record it. Offline entries show their
last observation, and weekly data becomes stale after the server reset until it is
observed again. WoW persists the cache on logout or `/reload`.

See [validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.1/docs/VALIDATION.md) for in-game coverage, automated checks and
Companion compatibility tests.

## Deutsch

Behebt das Zurückspringen des Fensters beim Ziehen: Zeitgesteuerte Aktualisierungen
warten bis zum Loslassen und verwenden dann die neu gespeicherte Position. Auch
das Schließen während des Ziehens wird berücksichtigt.

Retail erhält im bestehenden Fenster **Spielzeit | Fortschritt**. Die neue Ansicht
zeigt Charakter und Gilde, den eigenen Schlüsselstein, die höchste
abgeschlossene M+-Stufe dieser Woche sowie je drei Schatzkammer-Slots für Dungeon,
Raid und Welt. Tooltips zeigen vollständige Namen, Anforderungen und Erfassungszeit.

![Hourstone-Fortschrittsübersicht in Retail](https://raw.githubusercontent.com/krebs3r/hourstone-azeroth-hours/v0.3.1/docs/assets/addon-progress-de.png)

Gerenderte Addon-Oberfläche mit Beispielcharakteren.

Hourstone liest diese Daten direkt aus WoW. Instanznamen, Schlüsselsteinstufen und
Vault-Schwellen müssen nicht manuell gepflegt werden. Auch Abschlüsse außerhalb der
Zeit zählen; abgebrochene Läufe nicht. Unbekannte Daten, ein bestätigter fehlender
Schlüsselstein und veraltete Daten sind klar unterscheidbar. Vorwochenbelohnungen
werden nicht als aktueller Wochenfortschritt ausgegeben.

Die Größe lässt sich in 5-%-Schritten von **65 bis 200 %** einstellen. Bei hoher
Skalierung erscheinen zuerst weniger Zeilen; alle Charaktere bleiben durch Scrollen
erreichbar. Erst bei zu geringer Breite oder Mindesthöhe wird das Fenster kleiner
als gewünscht. Classic behält seine Spielzeitansicht mit erweitertem Größenbereich.

Das ZIP bei geschlossenem WoW nach `Interface/AddOns` entpacken. Vorhandene
SavedVariables behalten. Der Companion-Abgleich bleibt kompatibel. Fortschritt
wird lokal je Installation und Account gespeichert und nicht vom Companion übertragen.
Für jeden gewünschten Charakter einmal einloggen. WoW speichert beim Logout oder
`/reload`; nach dem Wochenreset bleiben alte Wochenstände bis zur nächsten Erfassung
als veraltet erkennbar.

Spieltests, automatische Prüfungen und Tests zur Companion-Kompatibilität stehen
in der [Validierung](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.1/docs/VALIDATION.md).
