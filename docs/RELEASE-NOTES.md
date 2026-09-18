# Hourstone 0.3.2 — 2026-09-18

Retail progress can now be synchronized by Hourstone Companion 0.2.0:
keystones, the highest completed Mythic+ level this week and all nine Great Vault
slots are available across selected installations and PCs. Each progress family
uses its own server capture time. Unknown, confirmed empty and outdated values
remain distinct; the server's saved weekly reset deadline determines expiry.

Locally collected progress stays separate from received observations. Viewing a
remote character never makes its progress into a new local measurement. Existing
SavedVariables schema 3, version-1 progress caches, settings and character data
are preserved. Protocol 1–3 imports remain supported for older Companions.

The TOC advertises protocol-4 support. A new Companion can read local progress
from Hourstone 0.3.1 while continuing to write its legacy protocol-3 data addon;
receiving synchronized progress in WoW requires Hourstone 0.3.2. Update all
participating Companions to 0.2.0 together for progress synchronization. At this
release, Companion 0.2.0 is awaiting Microsoft Store certification; older
public Companion versions continue to support their existing features. The
addon remains fully usable without Companion.

With WoW closed, extract `Hourstone-0.3.2.zip` into `Interface/AddOns`. Keep existing
SavedVariables. Log out or `/reload` to save local observations, synchronize in
Companion, then log in or `/reload` to load the shared overview. Fully restart WoW
once after the first installation of the Companion data addon. This is not a live
connection to a running client.

Automated compatibility, provenance and deterministic merge checks are described
in [validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.2/docs/VALIDATION.md).
Native-client acceptance of 0.3.2 and actual two-PC synchronization have not yet
been performed; this release does not claim that coverage.

## Deutsch

Retail-Fortschritt lässt sich jetzt mit Hourstone Companion 0.2.0
zwischen ausgewählten Installationen und PCs abgleichen: Schlüsselsteine,
die höchste abgeschlossene M+-Stufe dieser Woche und alle neun Schatzkammer-Slots.
Jeder Bereich verwendet seine eigene vom Server erfasste Zeit. Unbekannte,
bestätigt leere und veraltete Stände bleiben unterscheidbar; der gespeicherte
Wochenreset des Servers bestimmt, wann Daten veralten.

Empfangene Daten werden angezeigt, aber nicht als lokale Messungen gespeichert
oder zurückexportiert. Charaktere, Einstellungen, Schema 3 und der lokale
Fortschrittscache bleiben erhalten. Alte Companion-Eingaben mit Protokoll 1–3
bleiben lesbar. Für empfangenen Fortschritt im Spiel wird Addon 0.3.2 benötigt;
die lokalen Daten aus 0.3.1 kann ein neuer Companion bereits einlesen. Für den
Fortschrittsabgleich alle beteiligten Companions gemeinsam auf 0.2.0 aktualisieren.
Zum Zeitpunkt dieses Releases wartet Companion 0.2.0 auf die Microsoft-Store-
Zertifizierung. Bisher veröffentlichte Companion-Versionen behalten ihre
bisherigen Funktionen; das Addon bleibt ohne Companion vollständig nutzbar.

Das ZIP bei geschlossenem WoW nach `Interface/AddOns` entpacken. Vorhandene
SavedVariables behalten. Zunächst ausloggen oder `/reload`, dann im Companion
synchronisieren und anschließend im Spiel neu einloggen oder `/reload` ausführen.
Nach der ersten Installation des Companion-Datenaddons WoW vollständig neu
starten. Die automatisierten Prüfungen sind in der verlinkten Validierung
beschrieben. Der echte Ingame-Test von 0.3.2 und der Austausch zwischen zwei
physischen PCs stehen weiterhin aus und werden nicht als bestanden ausgewiesen.
