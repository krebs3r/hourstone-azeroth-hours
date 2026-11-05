# Hourstone 0.3.7 — unreleased

Hourstone 0.3.7 shows synchronized **WoW: Forever** characters as **WoW: Forever**
on every client. Until now, Hourstone labelled only the Forever characters that the
account's own database had recorded; those of another account or another PC appeared
under Retail everywhere, Forever included. **This needs Companion 0.2.2 or newer** on
the PC that runs WoW. It names the Forever installations, its own and those that other
PCs report, in the `Hourstone_Sync` data addon, and Hourstone labels the received
characters that come from them. With an older Companion, these characters stay under
Retail as before.

The client filter now offers WoW: Forever on every client whenever the list shows a
Forever character, and Retail's progress view treats these characters as
unsupported. For characters the account has recorded itself, its own label still
decides, so a `WTF` folder copied from Retail into Forever keeps its Retail entries.
A database copied into Forever counts as the client it was copied from wherever that
original is also synchronized.

The list is an optional addition to Companion protocol 4
([addendum](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.7/docs/sync-protocol-v4-forever.md)).
Forever characters stay in the Retail client family; saved keys, playtime, merging,
SavedVariables schema 3 and protocol 4 are unchanged. Hourstone 0.3.2 to 0.3.6
ignore the list, so PCs can be updated one at a time. Nothing else changes for
Retail and Classic clients. With WoW closed, extract `Hourstone-0.3.7.zip` into
`Interface/AddOns`.

Automated checks are described in
[validation](https://github.com/krebs3r/hourstone-azeroth-hours/blob/v0.3.7/docs/VALIDATION.md).
This build has not been tested in-game yet.

## Deutsch

Hourstone 0.3.7 zeigt synchronisierte Charaktere aus **WoW: Forever** auf jedem
Client als **WoW: Forever** an. Bisher hat Hourstone nur die Forever-Charaktere so
gekennzeichnet, die die eigene Datenbank des Accounts erfasst hat; die eines anderen
Accounts oder PCs standen überall unter Retail, auch in Forever. **Dafür ist Companion
ab 0.2.2** auf dem PC nötig, auf dem WoW läuft. Er nennt die Forever-Installationen,
die eigenen und die von anderen PCs gemeldeten, im Datenaddon `Hourstone_Sync`, und
Hourstone kennzeichnet die empfangenen Charaktere daraus. Mit einem älteren Companion
bleiben diese Charaktere wie bisher unter Retail.

Der Clientfilter bietet WoW: Forever jetzt auf jedem Client an, sobald die Liste einen
Forever-Charakter zeigt, und die Retail-Fortschrittsansicht behandelt diese
Charaktere als nicht unterstützt. Für selbst erfasste Charaktere entscheidet weiter
die Kennzeichnung des eigenen Accounts; ein von Retail nach Forever kopierter
`WTF`-Ordner behält daher seine Retail-Einträge. Eine nach Forever kopierte Datenbank
zählt als der Client, von dem sie stammt, sofern dieses Original ebenfalls abgeglichen
wird.

Die Liste ist eine optionale Ergänzung zu Companion-Protokoll 4. Forever-Charaktere
bleiben in der Clientfamilie Retail; Schlüssel, Spielzeit, Zusammenführung, Schema 3
und Protokoll 4 sind unverändert. Hourstone 0.3.2 bis 0.3.6 ignorieren die Liste,
die PCs können also einzeln aktualisiert werden. Sonst ändert sich für Retail- und
Classic-Clients nichts. Das ZIP bei geschlossenem WoW nach `Interface/AddOns`
entpacken. Die automatischen Prüfungen stehen in der verlinkten Validierung. Dieser
Build wurde noch nicht im Spiel getestet.
