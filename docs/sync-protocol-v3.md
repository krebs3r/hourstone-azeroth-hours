# Hourstone synchronization contract v3

This version adds reversible removal from the overview. Playtime observations,
guild membership, source selection and device revision rules from
[contract v2](sync-protocol-v2.md) continue to apply unless specified below.
Companion 0.1.3 and Hourstone 0.2.2 produce version 3. All participating PCs and
WoW clients should be upgraded together. Readers retain support for older inputs;
older readers reject version 3 and keep their last valid data.

## Storage and identity

Hourstone SavedVariables use `version = 3`. Schema 1 and 2 migrate without losing
observations or settings. The new `visibility` array holds control records;
`characters` remains the local measurement store, including removed characters.
The generated data addon and device snapshots use `formatVersion = 3`, with a
required `visibility` array alongside `observations`. Formats 1 and 2 do not carry
these controls. Their canonical snapshot serialization remains unchanged.

```json
{
  "sourceId": "synthetic-source",
  "region": "eu",
  "flavor": "retail",
  "guid": "Player-1-SYNTHETIC",
  "removed": { "synthetic-writer": 1 },
  "restored": {}
}
```

Identity is `region:flavor:guid`, or `unknown:sourceId:flavor:guid` until the region
is known. Names are display metadata. A new character with the same name and a
different GUID is a separate identity. Each control identity uses the same text
and source constraints as observations. Merging records for a known region uses
the greatest sourceId in ordinal UTF-8 order as representative metadata. Learning
a local character's region carries its controls to the new identity before any
login restoration is considered; a reload cannot bypass a removal this way.

## Removal and restoration

`removed` and `restored` map writer IDs to positive integer revisions, bounded by
9,007,199,254,740,991. Writer IDs follow the source ID character and length rules.
Every restored entry must have a corresponding removed entry and must not exceed
that removal revision. A record supports at most 1,024 distinct writers; a list
supports at most 10,000 distinct identities. Existing file and parser size limits
also apply. Exceeding a limit is an error that preserves the last valid state.

For each identity, merge both maps independently by componentwise maximum.
An absent component is zero. A character is removed if **any** removal component
is greater than its matching restoration component. Otherwise it is visible.
Merge is associative, commutative and idempotent; neither PC wall clocks nor
file modification times determine the result.

Each app/addon runtime obtains a fresh random writer ID before its first removal.
It is not reused from copied settings or SavedVariables. Removing increments
that writer's removal component. Restoring acknowledges **all currently known**
removals by copying their maxima into `restored`; it never erases either map.
Consequently an unseen concurrent removal wins over a restoration. The complete
removal context accompanies each acknowledgment. Repeated remove/restore cycles
within a runtime advance the same writer's sequence.

Removal affects the overview and its total only. Measurements continue locally;
the character and its playtime are not deleted from WoW or the measurement store.
The addon and Companion offer an explicit removed-character view and restoration.

## Automatic restoration on login

Only a fresh login reported by WoW through `PLAYER_ENTERING_WORLD` with
`isInitialLogin == true` may acknowledge removals for the current character.
If identity is not yet available, that explicit login intent can wait for it.
Reloads, zone changes, periodic reads, `/played`, guild updates and saving do not
restore a character. Removing the currently played character therefore keeps it
hidden for the rest of that session while time measurement continues.

Automatic restoration acknowledges controls that have already reached the addon.
Without a trusted shared clock, an offline PC cannot prove that its unobserved
login happened after a removal elsewhere. It must receive the removal first and
then perform a fresh login. Old snapshots or old SavedVariables can never count
as that acknowledgment. A Companion restart alone does not restore anything.
The restored state reaches the Companion after WoW saves and then propagates
through the usual local-folder synchronization.

## Propagation and failure handling

Unlike foreign playtime observations, control records are deliberately merged,
persisted and relayed by all participants. A device snapshot still exports only
selected **local** measurements, including hidden ones, plus the accumulated
control context. Received measurements never become local measurements.

The generated data addon supplies the selected union of measurements, including
hidden entries, and controls in each source scope. The addon validates the full
payload before adopting any controls and persists those controls in its next
SavedVariables save. This allows a standalone addon to remove and restore entries
without a running Companion.

Readers validate the aggregate merge before durable adoption; a valid individual
file must not make the aggregate exceed limits. Failed reads or merges preserve
the previous control state and measurements. Atomic persistence keeps a removal
and its context together. Missing files, source deselection and pausing are not
deletion or restoration commands. Disconnecting drops foreign measurements but
retains learned control context, preventing stale files from undoing decisions
if the sources or sync folder are selected again.

Transport is limited to controls whose identities occur in currently selected
local measurements or cached peers of the current group, including hidden
measurements. Unrelated identities learned in a previous group are not published
into a newly joined group or generated data addon. A personal decision still
applies if that same character is selected again later.

## Canonical form and conformance

Canonical snapshots sort observations as in v2, visibility records by identity,
and writer maps by ordinal key order. Known-region source representatives are
selected deterministically. Writers never emit a control field in a legacy
snapshot. The group metadata file remains format 1; its transport identity is
independent of snapshot format.

`tests/fixtures/sync/visibility-v3.json` defines synthetic control merges shared
by Lua and .NET. `contract-v3.json` retains observation conformance cases, and
`snapshot-v3.json` provides a complete version-3 snapshot. Tests cover removal,
explicit and login restoration, stale files, concurrent actions, source and
device boundaries, unknown regions, malformed input, limits and restart safety.
