# Hourstone synchronization contract v4: WoW: Forever addendum

This addendum adds one optional field to the generated `Hourstone_Sync` data of
[version 4](sync-protocol-v4.md). It tells the addon which synchronized observations
come from WoW: Forever installations, so that every client labels them as
**WoW: Forever**. Companion 0.2.2 writes the field and Hourstone 0.3.7 reads it.
The format version stays 4 and the capability stays `## X-Hourstone-Sync-Protocol: 4`.
Device snapshots, `group.json` and the Companion's
[client hints](https://github.com/krebs3r/hourstone-companion/blob/main/docs/sync-client-hints.md)
keep their formats.

Forever characters stay in the `retail` family. Keys, identities, the playtime and
guild merge, totals, visibility and progress are unchanged; the list is display data.

## Field

A format 4 source scope may carry `foreverSources`, a Lua sequence of source IDs:

```lua
["hs-retail-account"] = { observations = { ... }, visibility = { ... },
  progressObservations = {}, foreverSources = { "hs-forever-account", "hs-forever-pc" } },
```

A listed source ID names a Hourstone database whose observations were recorded in a
WoW: Forever installation. The field follows `progressObservations` and is absent
when no source is listed. Formats 1–3 never carry it.

## Writing

The Companion first collects candidate sources:

- its enabled local sources whose client folder is `_forever_`;
- for each cached peer snapshot, the source IDs of that snapshot's observations
  that the peer's own client hint names.

A copied `WTF` folder keeps the source ID of the database it was copied from. As in
the Companion's source discovery, the Forever copy yields to the other client: a
source ID is removed when an enabled local source outside `_forever_` uses it, or
when a peer snapshot carries an observation with it that the peer's hint does not
name. A peer without a hint, such as Companion 0.2.0, therefore never makes a source
Forever. Hints label only the publishing peer's own observations.

Each scope then lists those of the remaining source IDs that a written observation
carries, unique and in ordinal order; every scope of one file carries the same list.
An idle or deselected Forever installation adds nothing, and data without a listed
source is byte-for-byte what Companion 0.2.1 writes. An invalid source ID fails the
generation, and the previous data addon stays in place. The Companion's own character
list uses the same set and the same rule as the addon below.

## Reading

Hourstone accepts the field only in format 4. A valid list is a sequence with keys 1
to n and no gaps, at most 20,000 entries, each a unique source ID of 1 to 128 ASCII
letters, digits, `-` or `_`. Any other value, or the field in formats 1–3, rejects
the payload like any other invalid field: Hourstone then shows no received
observations, progress or labels. An absent field is an empty list. Every import
starts from an empty list, so a missing, foreign, incompatible or rejected payload
never keeps an earlier list.

After the existing merge, a received row is labelled WoW: Forever when

1. its flavor is `retail`,
2. the `sourceId` of its winning playtime observation is listed, and
3. this database has not recorded the character itself.

For characters this database has recorded, its own `client = "forever"` marker
decides, as in Hourstone 0.3.6, so a database copied from Retail into Forever keeps
its Retail entries. The label never enters SavedVariables or the received
observations. Labelled rows use the WoW: Forever client name, tooltip, sort and
filter, and Retail's progress view treats them as unsupported. The client filter
offers WoW: Forever in the Forever client, whenever a row of the current view is a
Forever row, and while it is the selected filter.

## Compatibility

Hourstone 0.3.2 to 0.3.6 read only `formatVersion`, `sources` and each scope's
`observations`, `visibility` and `progressObservations`; they ignore the list and
keep listing these characters under Retail. Their behaviour is checked against the
release tags. Hourstone 0.3.7 with Companion 0.2.1 or earlier receives no list, so
synchronized Forever characters that the account has not recorded stay under
Retail. Companions need not be upgraded together: 0.2.2 publishes the same client
hints as 0.2.1, and the list depends only on the reading PC's Companion.

## Limits

The list labels whole sources. If a database was copied into Forever and the
database it was copied from is not synchronized, other clients label all of its
characters as WoW: Forever; the Forever client itself keeps its own markers. A
character observed in a Forever and in another source is labelled by the source of
its winning playtime observation.

## Fixtures

`tests/fixtures/sync/forever-v4.json` lists the Companion's input set, the list it
writes and the identities the addon labels, together with invalid source IDs and
lists. `tests/fixtures/sync/forever-data-v4.lua` is the Companion's generated data
for the first case, byte for byte. The Companion checks the lists it writes and the
golden file; the addon imports both in the Retail and the Forever client. The addon
also imports both payload shapes and the golden file with each tagged release from
0.3.2 to 0.3.6 and checks that the list changes nothing there.
