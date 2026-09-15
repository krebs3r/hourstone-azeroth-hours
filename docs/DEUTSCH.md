# Hourstone – Azeroth Hours

**Deine Charaktere. Deine Spielzeit.**

Hourstone zeigt die gesamte Spielzeit deiner erfassten WoW-Charaktere. Der graue Runenstein mit blauer Rune und goldener Sanduhr gehört gestalterisch zur Familie von [Soundstone – Azeroth Audio](https://github.com/krebs3r/soundstone-azeroth-audio).

## Installation

1. Lade `Hourstone-0.1.0.zip` aus den [GitHub-Releases](https://github.com/krebs3r/hourstone-azeroth-hours/releases).
2. Beende WoW und entpacke das ZIP in `Interface/AddOns` des gewünschten Clients.
3. Die Datei muss anschließend unter `Interface/AddOns/Hourstone/Hourstone.toc` liegen.
4. Aktiviere Hourstone in der Addon-Liste und logge dich ein.

Die Vorabversion ist für Retail, Mists of Pandaria Classic, Burning Crusade Classic Anniversary sowie Classic Era inklusive Hardcore und Season of Discovery vorbereitet. **Echte Tests in diesen Clients stehen noch aus.** Die automatisierten Prüfungen verwenden simulierte WoW-Ereignisse und UI-APIs.

## Bedienung

- Öffnen und schließen: Minimap-Button, `/hourstone` oder `/azerothhours`.
- Das Fenster lässt sich am Kopfbereich verschieben. Position und Skalierung werden gespeichert.
- Das Zahnrad öffnet Einstellungen für Minimap-Button, Zeilenabstand, Größe und Positionsrücksetzung.
- Suche nach Namen, filtere einen Realm oder sortiere durch Klick auf eine Spaltenüberschrift.
- Wähle zwischen `312,5 Std.` und `13 T. 0 Std. 30 Min.`. Bei Filtern erscheint zusätzlich die Summe der sichtbaren Charaktere.
- Lange Namen und der letzte Serverabgleich sind im Tooltip lesbar.
- `/hourstone minimap` blendet einen versteckten Minimap-Button wieder ein. `/hourstone reset` setzt die Fensterposition zurück.
- Escape und beide roten Kopfschaltflächen schließen das Fenster.

## Welche Zeit wird gezählt?

Ein Charakter erscheint nach seinem ersten Login mit aktiviertem Addon. Der Server liefert über `/played` auch die **vor der Installation gespielte Zeit**. Bis zur Antwort steht dort „Noch nicht verfügbar“ oder der letzte bekannte Stand. Zwischen den Antworten zählt nur der aktive Charakter lokal weiter. Neue Serverwerte ersetzen die Hochrechnung.

Eigene Anfragen erfolgen beim Login und Öffnen des Fensters, mindestens 60 Sekunden auseinander. Eine frühere Öffnung merkt eine Anfrage vor. Bei fehlenden Antworten wird im gleichen Abstand erneut gefragt. Die normale `/played`-Chat-Ausgabe bleibt erhalten und kann auch bei automatischen Anfragen erscheinen.

Ausgeloggte Zeit zählt nicht. AFK-Zeit zählt wie bei `/played`. `/reload` erhält die aktuelle Sitzung, ein erneuter Login setzt sie zurück. Bei regulärem Logout und Reload speichert WoW die Daten; nach einem Absturz können die letzten Änderungen fehlen.

Gespeichert wird accountweit in `HourstoneDB`, **getrennt je WoW-Installation und WoW-Account**. Es gibt keine automatische Synchronisierung zwischen Retail und Classic. Unbesuchte Charaktere können nicht automatisch abgefragt werden. Das Erstelldatum wird nicht angezeigt.

## Vorschau und Rückmeldungen

Das [freigegebene Mockup](mockup/index.html) zeigt Beispieldaten im Browser. Es ist keine Spielaufnahme. Echte Screenshots und Ergebnisse je Client folgen nach den [Ingame-Prüfungen](VALIDATION.md).

Bitte melde Fehler über [GitHub Issues](https://github.com/krebs3r/hourstone-azeroth-hours/issues) mit Client-Version, Sprache, Schritten zum Nachstellen und gegebenenfalls der Lua-Fehlermeldung.
