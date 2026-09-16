# Hourstone – Azeroth Hours

**Deine Charaktere. Deine Spielzeit.**

Hourstone zeigt die gesamte Spielzeit deiner erfassten WoW-Charaktere. Der graue Runenstein mit blauer Rune und goldener Sanduhr gehört gestalterisch zur Familie von [Soundstone – Azeroth Audio](https://github.com/krebs3r/soundstone-azeroth-audio).

## Warum ich Hourstone entwickelt habe

Ich wünsche mir schon lange eine übersichtliche Spielzeitanzeige im Battle.net-Launcher. Ich wollte sehen, wie viel Zeit ich insgesamt in Azeroth verbracht habe und wie sie sich auf meine Charaktere verteilt. Daraus ist Hourstone entstanden: ein Addon, das diese Zahlen an einem Ort zusammenführt.

Ich hoffe weiterhin, dass Blizzard eine Spielzeiterfassung direkt in Battle.net integriert. Bis dahin bietet uns Hourstone diesen Überblick in einem kompakten Fenster, das sich in WoW einfügt.

## Installation

1. Lade `Hourstone-0.1.1.zip` von [GitHub Releases](https://github.com/krebs3r/hourstone-azeroth-hours/releases/tag/v0.1.1) herunter.
2. Beende WoW und entpacke das ZIP in `Interface/AddOns` des gewünschten Clients.
3. Die Datei muss anschließend unter `Interface/AddOns/Hourstone/Hourstone.toc` liegen.
4. Aktiviere Hourstone in der Addon-Liste und logge dich ein.

Version **0.1.1** ist als reguläres Release für Retail, Mists of Pandaria Classic, Burning Crusade Classic Anniversary und Classic Era freigegeben. **Der Nutzer hat alle vier Clientfamilien im Spiel getestet; Classic und Classic Era wurden am 16.09.2026 bestätigt.** Hardcore und Season of Discovery nutzen dieselbe Schnittstelle wie Era, wurden aber nicht separat getestet. Die automatisierten Prüfungen verwenden simulierte WoW-Ereignisse und UI-APIs.

## Bedienung

- Öffnen und schließen: Minimap-Button, `/hourstone` oder `/azerothhours`.
- Das Fenster lässt sich am Kopfbereich verschieben. Position und Skalierung werden gespeichert.
- Das Zahnrad öffnet Einstellungen für Minimap-Button, Größe und Positionsrücksetzung.
- Suche nach Namen und filtere nach Realm. Im Charakter-Tabellenkopf wählst du Name, Level oder Realm zur Sortierung. Spielzeit und Aktualisierung sortierst du direkt über die Überschrift; erneuter Klick kehrt die Reihenfolge um.
- Wähle zwischen `312,5 Std.` und `13 T. 0 Std. 30 Min.`. Bei Filtern erscheint zusätzlich die Summe der sichtbaren Charaktere.
- Lange Namen und der letzte Serverabgleich sind im Tooltip lesbar.
- `/hourstone minimap` blendet einen versteckten Minimap-Button wieder ein. `/hourstone reset` setzt die Fensterposition zurück.
- Escape und das rote X schließen das Fenster.

## Welche Zeit wird gezählt?

Ein Charakter erscheint nach seinem ersten Login mit aktiviertem Addon. Der Server liefert über `/played` auch die **vor der Installation gespielte Zeit**. Bis zur Antwort steht dort „Noch nicht verfügbar“ oder der letzte bekannte Stand. Zwischen den Antworten zählt nur der aktive Charakter lokal weiter. Neue Serverwerte ersetzen die Hochrechnung.

Eigene Anfragen erfolgen beim Login und Öffnen des Fensters, mindestens 60 Sekunden auseinander. Eine frühere Öffnung merkt eine Anfrage vor. Bei fehlenden Antworten wird im gleichen Abstand erneut gefragt. Die normale `/played`-Chat-Ausgabe bleibt erhalten und kann auch bei automatischen Anfragen erscheinen.

Ausgeloggte Zeit zählt nicht. AFK-Zeit zählt wie bei `/played`. `/reload` erhält die aktuelle Sitzung, ein erneuter Login setzt sie zurück. Bei regulärem Logout und Reload speichert WoW die Daten; nach einem Absturz können die letzten Änderungen fehlen.

Gespeichert wird accountweit in `HourstoneDB`, **getrennt je WoW-Installation und WoW-Account**. Es gibt keine automatische Synchronisierung zwischen Retail und Classic. Unbesuchte Charaktere können nicht automatisch abgefragt werden. Das Erstelldatum wird nicht angezeigt.

## Oberfläche v0.1.1

Die native Umsetzung folgt dem freigegebenen **Mockup 05**: **720 Pixel breit**, mit **248 Pixeln Höhe bei null oder einem Treffer** und maximal **500 Pixeln bei acht sichtbaren Zeilen**. Jede Zeile ist 36 Pixel hoch; weitere Charaktere scrollen. Auch Suche und Realm-Filter passen die Höhe an. Name und Level stehen zusammen, der Realm darunter.

Soundstones Rahmen mit kleinen Ecken, rote Schaltflächen und das kleine linke Zahnrad bilden die gemeinsame Gestaltung. Der vollständige Titel und die drei Statistiküberschriften erhalten feste Textbereiche mit WoWs Standardschrift. Das Einstellungsmenü enthält Minimap-Checkbox, Größenregler und Positionsrücksetzung. Das rosa Herz bleibt erhalten. Test 5 ersetzt die Minimap-Checkbox durch WoWs native Vorlage wie bei Soundstone. Der Minimap-Button wird von 36 auf 28 UI-Einheiten verkleinert, das vollständige Motiv auf 18; der Abstand zum inneren Rahmen bleibt größer als zwei Einheiten.

Charakterdaten, Zeitformat, Fenstergröße und Position bleiben erhalten; die Datenversion bleibt 1. Alte Zeilenabstand-Einstellungen werden ignoriert. Nur bei Platzmangel wird das Fenster mit zehn Pixeln Reserve je Seite eingepasst. Der Header bleibt beim Filtern an derselben Stelle, solange ausreichend Bildschirmplatz vorhanden ist.

Die Test3-Spielaufnahme bestätigt Titel, Statistiküberschriften und das kompakte Fenster. Test 4 gibt dem bisher gekürzten „Tage + Std.“-Button 40 Pixel mehr Breite, indem das Suchfeld kürzer wird. Charakterspalte und linker Statistikbereich sind ebenfalls schmaler.

**100 % bleibt der Standard.** Deine gespeicherte Größe, beispielsweise 110 oder 120 %, bleibt beim Update erhalten. Bei einem Charakter entsprechen 110 % etwa 792 × 273 und 120 % etwa 864 × 298 Bildschirmpixeln, auch bei 1440p mit 80 % globaler UI-Skalierung. Die zusätzlichen Aufnahmen zeigten eine ungewöhnlich flache Checkbox und einen zu großen Minimap-Kreis. Beide Korrekturen wurden anschließend vom Nutzer für die Veröffentlichung akzeptiert.

Für weitere Funktionsprüfungen kann die [kurze Testanleitung](TESTING-0.1.1-DE.md) verwendet werden.

## Vorschau und Rückmeldungen

Das [freigegebene Mockup](mockup-05/index.html) zeigt Beispieldaten im Browser. Es ist keine Spielaufnahme. Die [vorhandene Spielaufnahme](curseforge/screenshots/compact-ingame.png) stammt aus Test 3; die nachfolgenden Korrekturen und die Nutzerbestätigung für Retail und TBC Anniversary sind in den [Prüfergebnissen](VALIDATION.md) dokumentiert.

Bitte melde Fehler über [GitHub Issues](https://github.com/krebs3r/hourstone-azeroth-hours/issues) mit Client-Version, Sprache, Schritten zum Nachstellen und gegebenenfalls der Lua-Fehlermeldung.
