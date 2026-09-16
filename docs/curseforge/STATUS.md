# Veröffentlichungsstand — 16.09.2026

## Freigabe für Classic und Classic Era

- Der Nutzer hat zusätzlich erfolgreiche Ingame-Tests in Classic und Classic Era bestätigt. Mists of Pandaria Classic **5.5.4** und Classic Era **1.15.9** sind jetzt neben Retail **12.1.0** und TBC Anniversary **2.5.6** für Version **0.1.1** freigegeben.
- Die bestehende CurseForge-Datei **8886212** wurde aktualisiert: Typ **Release**, Status **Approved**, alle vier Spielversionen. Die öffentliche [Dateiseite](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/8886212) zeigt alle vier Clientfamilien sowie Download und „Install Via App“.
- Englische und deutsche CurseForge-Beschreibung, Datei-Changelog und GitHub-Release-Notizen sind aktualisiert. `project.json` enthält alle vier bestätigten Versionen für zukünftige automatische Uploads.
- Addondateien, ZIP, Versionsnummer und SHA-256 bleiben unverändert. Es wurde keine zweite Datei hochgeladen.
- Die 14 CurseForge-Publishing-Tests bestehen am 16.09.2026. Die vollständige lokale Python-Prüfung konnte in der vorhandenen Umgebung wegen fehlendem Pillow nicht ausgeführt werden; für diese Änderung sind nur Dokumentation und Veröffentlichungsmetadaten betroffen. Die CI führt die vollständigen Prüfungen nach dem Push erneut aus.

## Historie des ersten Releases — 15.09.2026

## Erledigt

- **Hourstone v0.1.1** ist als [reguläres GitHub-Release](https://github.com/krebs3r/hourstone-azeroth-hours/releases/tag/v0.1.1) veröffentlicht.
- Release-Commit: `dbe7c7871f26124e78d23a309456d083da888cc3`. [Validate](https://github.com/krebs3r/hourstone-azeroth-hours/actions/runs/34971445276) und [Release](https://github.com/krebs3r/hourstone-azeroth-hours/actions/runs/34971521982) sind erfolgreich.
- 30 Lua-Prüfsuiten und 8 Python-Tests bestehen lokal und in der CI. Das ZIP enthält 41 Dateien (708840 Bytes) direkt unter `Hourstone/`.
- SHA-256 von freigegebenem Test5-ZIP, lokalem finalem ZIP und GitHubs Release-Asset-Digest stimmt überein: `8b38daa8a75abc48b043c4eb7bcca7790d799c7dc7d821b63dc2d7581c8c446b`.
- Nutzerbestätigung für Retail und TBC Anniversary dokumentiert; siehe [Abnahme](acceptance/v0.1.1.md).
- CurseForge-Projekt **Hourstone – Azeroth Hours**, ID **1697059**, unter dem Konto `krebs3r` erstellt: Kategorie Miscellaneous, MIT, Kommentare und Drittanbieter-Verteilung erlaubt.
- Englische/deutsche Beschreibung, 400×400-Logo, GitHub-Quellcode-Verweis und GitHub-Issues-Link in der Beschreibung eingerichtet.
- Eine echte, als früherer Test3-Stand beschriftete Spielaufnahme ist in der Galerie gespeichert.
- Datei **8886212**, **Hourstone 0.1.1**, Typ **Release**, für **Retail 12.1.0** und **TBC Anniversary 2.5.6** erfolgreich hochgeladen. Automatische Veröffentlichung nach Genehmigung ausgewählt.
- Alle Projektdaten einschließlich Git-Historie, Mockups, Arbeitsdateien, früheren Testpaketen und Nutzeraufnahmen liegen jetzt unter `C:\Users\krebs3r\Documents\Codex\Hourstone – Azeroth Hours`. Alte Arbeits-/Vorschaupfade sind Verzeichnisverknüpfungen; die drei lokalen Vorschau-Server funktionieren wieder.

## CurseForge-Status beim ersten Upload — 15.09.2026

Beim ersten Upload stand die Datei auf **Processing** und wartete auf Moderation. Am 16.09.2026 ist sie **Approved** und öffentlich verfügbar. Der [Upload-Beleg](releases/v0.1.1.json) enthält die tatsächliche Datei-ID und ursprüngliche Versionszuordnung; die spätere Freigabe ist dort separat ergänzt. Nicht erneut hochladen.

## Noch offen

- GitHub- und CurseForge-CDN-Rückdownloads wurden vom Remotehost abgebrochen. Die GitHub-Asset-Prüfsumme und die tatsächlich für CurseForge ausgewählte lokale ZIP sind geprüft; ein vollständiger CDN-Rückdownload ist noch nicht belegt.
- Installation über die CurseForge-App, eigene Tests für Hardcore/Season of Discovery und separat dokumentierte manuelle Detailprüfungen.

Der erste CurseForge-Upload erfolgte manuell über das Autoren-Dashboard. Der Release-Workflow enthält jetzt einen nachgelagerten CurseForge-Upload mit Prüfsummenprüfung und Schutz vor doppelten Uploads. Der eigene Token **Hourstone GitHub Releases** ist seit 15.09.2026 als GitHub-Actions-Secret `CF_API_TOKEN` hinterlegt. Der [Verbindungscheck](https://github.com/krebs3r/hourstone-azeroth-hours/actions/runs/34979326762) war erfolgreich: Token akzeptiert, Retail 12.1.0 und TBC Anniversary 2.5.6 aufgelöst, keine Datei hochgeladen. Die [vollständige CI-Prüfung](https://github.com/krebs3r/hourstone-azeroth-hours/actions/runs/34979015385) besteht einschließlich der 14 neuen Upload-Tests. Einrichtung und Wiederholungen sind in [README.md](README.md) beschrieben. Ein echter automatischer Release-Upload steht noch aus.
