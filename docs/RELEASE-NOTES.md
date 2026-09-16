# Hourstone 0.2.0 — development

- Add optional integration with [Hourstone Companion](https://github.com/krebs3r/hourstone-companion) protocol 1 for a combined character overview across selected local WoW installations.
- Separate confirmed `/played` measurements from local estimates and migrate saved data to schema 2.
- Merge repeated observations of the same character without adding cumulative totals. Keep UI preferences, session state and request timing local.
- Add a client-family filter for the combined character list.
- Retain reproducible assets and regression fixtures while simplifying repository documentation and adding commit-aware privacy checks.

The addon works independently. For synchronization, use Hourstone 0.2.x with Companion 0.1.x (protocol 1) and close all WoW clients before syncing; the imported view appears after the next start. Native-client acceptance of this new flow is still required. Historical release assets remain unchanged.

## Installation

Download the `Hourstone-X.Y.Z.zip` asset from [GitHub Releases](https://github.com/krebs3r/hourstone-azeroth-hours/releases/latest) and extract `Hourstone` into the client's `Interface/AddOns` folder while WoW is closed. Keep existing SavedVariables to migrate tracked characters and preferences. Use the companion's backup and setup guidance before synchronizing.

## Deutsch

Version 0.2.0 ergänzt die optionale Anbindung an den Hourstone Companion mit Protokoll 1, eine gemeinsame Charakterübersicht und einen Clientfilter. Bestätigte Serverzeiten und lokale Schätzungen werden getrennt gespeichert; vorhandene Daten wechseln zu Schema 2. Mehrfach vorliegende Gesamtzeiten desselben Charakters werden nicht addiert. Einstellungen und Sitzungen bleiben lokal.

Der Companion gleicht Daten bei vollständig beendetem WoW ab. Die neue Übersicht erscheint beim nächsten Start. Der Ablauf benötigt noch Tests in den echten Clients; das Addon funktioniert weiterhin eigenständig.
