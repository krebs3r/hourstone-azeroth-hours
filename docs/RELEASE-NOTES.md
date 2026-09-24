# Hourstone 0.3.3 — 2026-09-24

Hourstone now appears in WoW's **Addons menu** below the clock wherever the client
provides it. A left click opens or closes the window, just like the minimap button.
On those clients the minimap button is hidden once after this update; turn it back
on in the settings or with `/hourstone minimap`, and that choice is kept. Clients
without the Addons menu keep the minimap button unchanged. When you hide the
button, Hourstone tells you in chat where to open it instead.

This release adds the **WoW: Forever** beta (interface 16001). Forever uses the
Retail API, but Hourstone keeps its Classic design and playtime view there, because
keystones and the Great Vault do not exist in Forever. Companion protocol 4 has no
separate Forever client family, so Forever characters are recorded and shown under
Retail.

Saved characters, settings and the minimap position are preserved. SavedVariables
schema 3 and Companion protocol 4 are unchanged. With WoW closed, extract
`Hourstone-0.3.3.zip` into `Interface/AddOns`.

Automated checks are described in
[validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.3/docs/VALIDATION.md).
The author tested the 0.3.3 build in-game in Retail, Classic and the WoW: Forever
beta (1.60.1). There was no new game patch since 0.3.2; client families not
separately tested for this version are released on the author's compatibility
statement.

## Deutsch

Hourstone erscheint jetzt im **Addons-Menü** unter der Uhr, sofern der Client es
anbietet. Ein Linksklick öffnet und schließt das Fenster wie der Minimap-Button.
Auf diesen Clients wird der Minimap-Button nach dem Update einmalig ausgeblendet;
in den Einstellungen oder mit `/hourstone minimap` lässt er sich wieder einblenden,
und diese Wahl bleibt erhalten. Clients ohne Addons-Menü behalten den
Minimap-Button unverändert. Beim Ausblenden nennt Hourstone im Chat, wo sich das
Fenster weiterhin öffnen lässt.

Neu unterstützt wird die Beta von **WoW: Forever** (Interface 16001). Forever nutzt
die Retail-API, Hourstone zeigt dort aber das Classic-Design und die
Spielzeitansicht, denn Schlüsselsteine und Schatzkammer gibt es in Forever nicht.
Companion-Protokoll 4 kennt keine eigene Forever-Clientfamilie; Forever-Charaktere
werden deshalb unter Retail erfasst und angezeigt.

Charaktere, Einstellungen und die Minimap-Position bleiben erhalten; Schema 3 und
Companion-Protokoll 4 sind unverändert. Das ZIP bei geschlossenem WoW nach
`Interface/AddOns` entpacken. Die automatischen Prüfungen stehen in der verlinkten
Validierung. Der Autor hat den Build von 0.3.3 im Spiel in Retail, Classic und der
Forever-Beta (1.60.1) getestet. Seit 0.3.2 gab es keinen neuen Spielpatch;
Clientfamilien, die für diese Version nicht einzeln getestet wurden, sind auf
Grundlage der Kompatibilitätsaussage des Autors freigegeben.
