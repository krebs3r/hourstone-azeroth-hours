# Hourstone – Azeroth Hours

**Your characters. Your time.** See your World of Warcraft characters' total `/played` time and your current session in one compact window. Hourstone works on its own: no other addon, desktop app or external account is required.

![Hourstone overview with character, guild and client information](https://raw.githubusercontent.com/krebs3r/hourstone-azeroth-hours/c7d39d43373e2ce5e4a5388cbb92e7c067a9ed5b/docs/assets/addon-overview-en.png)

Synthetic sample data; browser approximation of the layout, not an in-game screenshot.

## Your character overview

- Character name, class color, level, realm and last recorded guild.
- A separate client column beside playtime and the last update.
- Search by character or guild, filter by realm and client, and sort the list.
- Total and filtered playtime, displayed as decimal hours or days, hours and minutes.
- A movable, scalable window and an optional draggable minimap button with Blizzard's native frame.
- German and English interfaces.

Open with `/hourstone` or `/azerothhours`. Use the gear button for display settings and hover a character to see its full recorded details. Every character appears after its first login with Hourstone enabled. The server's total includes time played before installation; offline time is excluded. WoW saves the data per installation and account when you log out or use `/reload`. Characters you have not visited with Hourstone cannot be discovered automatically.

Guild information updates when you play the character. **No guild** means the character was confirmed to be guildless; **Not yet recorded** means Hourstone has not recorded its guild status yet.

Right-click a character and confirm **Delete** to exclude the entry from the overview and totals. Your WoW character and saved playtime remain intact. Under the gear menu, choose **Deleted characters** and right-click an entry to restore it. A new character login also restores a deletion already known to the addon; `/reload` alone does not.

## Optional Windows Companion

**Playing several WoW versions or using more than one PC? We recommend the optional [Hourstone Companion](https://github.com/krebs3r/hourstone-companion).** It brings the saved Hourstone data from your selected installations and accounts into one overview, including characters, guilds and playtime. The same character is counted once even if it is played on several devices.

For multiple PCs, choose a shared folder that Dropbox, OneDrive or another folder-sync service keeps synchronized and available locally on every device. The Companion exchanges its data through that folder; no Hourstone server or separate Companion account is needed. Without a shared folder, it can still combine data from local installations.

The exchange is automatic but not live: WoW must first save by logging out or using `/reload`, the Companion processes the saved data, and the folder service transfers changes between PCs. Hourstone reads the combined overview at the next login or `/reload`; after the first setup of the Companion data addon, fully close and restart WoW once. A deletion made while another PC was offline must reach that PC before a new character login can restore the entry.

Use **Hourstone 0.2.2 or newer** and **Companion 0.1.3 or newer** on all participating PCs. Older Hourstone 0.1.x versions do not support the Companion. The Windows Companion is currently a source/development preview; its signed public installer is still pending. Setup information, source code and release status are in the [Companion repository](https://github.com/krebs3r/hourstone-companion). The addon remains fully usable without it.

## Supported clients

Retail, Mists of Pandaria Classic, TBC Anniversary and Classic Era are supported client families. Hardcore and Season of Discovery use the Era family and have not been separately verified. See each release's notes for compatibility and validation.

[Source and installation guide](https://github.com/krebs3r/hourstone-azeroth-hours) · [Report an issue](https://github.com/krebs3r/hourstone-azeroth-hours/issues)

Also from krebs3r: [Soundstone – Azeroth Audio](https://www.curseforge.com/wow/addons/soundstone-azeroth-audio).

## Deutsch

**Deine Charaktere. Deine Spielzeit.** Hourstone zeigt die gesamte `/played`-Zeit deiner erfassten Charaktere und die aktuelle Sitzung in einem kompakten Fenster. Das Addon funktioniert eigenständig; eine zusätzliche App oder ein externes Konto ist nicht erforderlich.

![Hourstone-Übersicht mit Charakteren, Gilden und eigener Clientspalte](https://raw.githubusercontent.com/krebs3r/hourstone-azeroth-hours/c7d39d43373e2ce5e4a5388cbb92e7c067a9ed5b/docs/assets/addon-overview-de.png)

Synthetische Beispieldaten; Layout als Browser-Näherung, keine Ingame-Aufnahme.

Die Übersicht zeigt Name, Klassenfarbe, Level, Realm, zuletzt erfasste Gilde, Client, Spielzeit und letzte Aktualisierung. Suche nach Charakter oder Gilde, kombiniere Realm- und Clientfilter und sortiere die Spalten. Wähle zwischen Dezimalstunden und Tagen, Stunden und Minuten. Fensterposition, Größe und Minimap-Einstellung bleiben gespeichert.

Öffnen mit `/hourstone` oder `/azerothhours`. Jeder Charakter erscheint nach dem ersten Login mit aktiviertem Addon; auch zuvor gespielte Zeit zählt. WoW speichert die Daten je Installation und Account beim Ausloggen oder mit `/reload`. **Keine Gilde** ist ein bestätigter Zustand; **Noch nicht erfasst** bedeutet, dass noch keine Gildeninformation vorliegt.

Per Rechtsklick und **Löschen** lässt sich ein Eintrag aus der Übersicht und ihren Summen ausblenden. Dein WoW-Charakter und die gespeicherte Spielzeit bleiben erhalten. Unter Zahnrad → **Gelöschte Charaktere** stellt ein Rechtsklick den Eintrag wieder her. Ein neuer Charakter-Login stellt bereits bekannte Löschungen ebenfalls wieder her; `/reload` allein genügt nicht.

### Empfehlung: Hourstone Companion für Windows

**Wenn du mehrere WoW-Versionen oder mehrere PCs nutzt, empfehlen wir den optionalen [Hourstone Companion](https://github.com/krebs3r/hourstone-companion).** Er führt die gespeicherten Charakter-, Gilden- und Spielzeitdaten deiner ausgewählten Installationen und Accounts zusammen. Derselbe Charakter wird auch bei Nutzung auf mehreren Geräten nur einmal gezählt.

Für den Austausch zwischen PCs wählst du einen gemeinsamen Ordner, den beispielsweise Dropbox oder OneDrive auf allen Geräten synchronisiert und dauerhaft lokal verfügbar hält. Ein eigener Hourstone-Server oder ein zusätzliches Companion-Konto ist nicht nötig. Ohne gemeinsamen Ordner bleibt der Abgleich lokaler Installationen verfügbar.

Der Austausch erfolgt automatisch und zeitversetzt: WoW speichert beim Ausloggen oder mit `/reload`, der Companion liest den gespeicherten Stand ein und der Ordnerdienst überträgt die Änderungen. Das Addon übernimmt die gemeinsame Übersicht beim nächsten Login oder `/reload`. Nach der ersten Einrichtung des Companion-Datenaddons WoW einmal vollständig schließen und neu starten. Nach einer Löschung während des Offline-Betriebs zuerst synchronisieren, danach erneut mit dem Charakter einloggen, um den Eintrag wiederherzustellen.

Benötigt werden **Hourstone ab 0.2.2** und **Companion ab 0.1.3** auf allen beteiligten PCs. Die alten Addon-Versionen 0.1.x unterstützen den Companion noch nicht. Der Windows-Companion ist derzeit eine Quellcode-/Entwicklungsvorschau; ein signierter öffentlicher Installer steht noch aus. Anleitung, Quellcode und Veröffentlichungsstand stehen im [Companion-Repository](https://github.com/krebs3r/hourstone-companion). Das Addon bleibt ohne Companion nutzbar und wird weiterhin separat über CurseForge aktualisiert.
