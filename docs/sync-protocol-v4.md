# Hourstone synchronization contract v4

Version 4 adds Retail progress as a separate observation channel. The playtime,
guild, visibility, source routing, group identity and device revision rules from
[version 3](sync-protocol-v3.md) remain unchanged. Hourstone 0.3.2 reads versions
1–4. New Companion device snapshots use version 4; older Companions reject these
and preserve their last valid data. Upgrade the participating Companions together.

## Capability and compatibility

The installed Hourstone TOC explicitly advertises `## X-Hourstone-Sync-Protocol: 4`.
The Companion generates version 4 data only for a client installation advertising
exactly one known capability value `4`. Missing, duplicate, malformed or future
capabilities fall back to version 3. This decision is independent of the saved
schema and the human-readable addon version. Thus an older addon continues to
receive playtime, guild and visibility data. Its locally saved Retail progress
can still be displayed by the new Companion, but it cannot receive progress until
the addon is updated.

SavedVariables remain `HourstoneDB.version = 3`. The optional **local** cache is
`HourstoneDB.progress = { version = 1, characters = { ... } }`. Receiving a data
addon never writes foreign progress into this local cache. A future cache version
is left untouched and does not block playtime or received progress display.

## Transport shape

Device snapshots with `formatVersion: 4` require `progressObservations: []` beside
the existing `observations` and `visibility` arrays. Each generated data-addon
source scope likewise requires `progressObservations = {}`. Formats 1–3 contain
no progress field, and their canonical JSON remains unchanged. The shared
`group.json` still uses format 1.

Each progress observation retains its actual source:

```json
{
  "sourceId": "synthetic-source",
  "region": "eu",
  "flavor": "retail",
  "guid": "Player-1-SYNTHETIC",
  "keystone": {
    "present": true, "mapID": 42, "level": 10, "name": "Synthetic Dungeon",
    "updatedAt": 1800000000, "resetAt": 1800500000
  },
  "weekly": {
    "level": 12, "seasonID": 1,
    "updatedAt": 1800000000, "resetAt": 1800500000
  },
  "vault": {
    "rows": {
      "dungeon": {
        "updatedAt": 1800000000, "resetAt": 1800500000,
        "slots": [
          { "progress": 3, "threshold": 1, "level": 10, "unlocked": true },
          { "progress": 3, "threshold": 4, "level": 0, "unlocked": false },
          { "progress": 3, "threshold": 8, "level": 0, "unlocked": false }
        ]
      }
    }
  }
}
```

All five families are independently optional: `keystone`, `weekly`, and the
`dungeon`, `raid`, and `world` vault rows. A valid identity without any sampled
family is permitted. Optional values are omitted in canonical output. Empty
vault containers normalize to absence. Vault slots may include `difficultyName`.
Names and difficulty descriptions retain the capturing WoW client's language;
they are not translation keys or stable identities.

Identity is the existing region/flavor/GUID tuple. Unknown regions remain scoped
to their source ID. A progress observation is never selected using playtime's
winning source, confirmed baseline, total seconds, character name or guild.
Classic flavors do not contribute progress. Character visibility applies to both
views without erasing their measurements.

## Validation and explicit empty values

Identity fields follow version 3's source/region/GUID constraints; flavor must be
`retail`. Progress numbers are integers from 0 through 9,007,199,254,740,991.
Every present family requires `updatedAt` and `resetAt`, with `resetAt > updatedAt`.
Time is a Blizzard server timestamp, not a file modification or device revision
timestamp. Unknown transport properties are rejected.

A present keystone requires a boolean `present`. When true, `mapID` and `level`
must be positive integers. When false, map, level and name have no meaning and
normalize away. `present=false` is a confirmed absence, not an unavailable API.
A weekly record requires nonnegative `level` and `seasonID`; level zero is a
confirmed empty result. Each vault row is a whole record with exactly three
contiguous slots. Every slot requires nonnegative progress and level and a
positive threshold. `unlocked` is derived from `progress >= threshold`, regardless
of a supplied boolean's value. Names, when present, are nonempty valid UTF-8 text
of at most 1,024 bytes without control characters.

Missing families remain unknown. A sampled family is current only while
`updatedAt <= now < resetAt`; otherwise it is stale. Keep stale values available
for display with their timestamps rather than replacing them with zero. In
particular, an expired keystone is not a confirmed absent keystone. The current
display clock never changes merge ordering, cache contents, hashes or revisions.

## Deterministic per-family merge

Keep source observations separate in storage and transport. First merge repeated
records for the same `(sourceId, identity)` independently for each family. For
display, project all source candidates of an identity independently for those
same five families. A vault row's three slots are never assembled from different
records. A terminal projection can use the greatest UTF-8 source ID as envelope
metadata, but must never be fed back into storage or merging as a real source.

For each family, the greatest tuple wins:

1. `updatedAt`, numerically.
2. The candidate's actual `sourceId`, in ordinal UTF-8 byte order.
3. The following typed payload tuple, beginning with `resetAt`:
   - Keystone: `resetAt`, `present` (false before true), `mapID` (absent = 0),
     `level` (absent = 0), `name` (absent = empty text).
   - Weekly: `resetAt`, `level`, `seasonID`.
   - Vault row: `resetAt`, then slots 1 through 3, comparing each slot's
     `progress`, `threshold`, `level`, `difficultyName` (absent = empty text).

Text comparisons use ordinal UTF-8 bytes. Do not compare JSON formatting or
localized text with culture-dependent collation. All candidates for an absent
keystone are normalized before comparison. `unlocked` does not participate.

This makes the source-preserving merge associative, commutative and idempotent.
Do not perform a pairwise "same week within two seconds" fold: that relation is
not transitive. `resetAt` is not an exact epoch identifier because separate server
API calls can differ by seconds between sources. It is not the primary ordering
key. Whole-family latest observation semantics intentionally allow newer confirmed
zero values, lowered keystones, and new seasons or weeks to replace larger values.
The addon's existing local collection safeguards against temporary API regressions
remain in place; transport does not invent additional seasonal maxima.

## Persistence, provenance and failure behavior

The Companion database migrates atomically from schema 1 to 2, adding a separate
`source_progress` table. Existing settings, measurements, visibility context and
cached snapshots are retained. Only enabled local sources contribute to the
device's published progress array. Peer progress stays in the group/device
snapshot cache and can be included in generated addon data; it never becomes a
local source contribution. No Companion operation writes Hourstone SavedVariables.

Local progress parsing is independent of playtime parsing after the full bounded
Lua literal document has been validated. Missing, unsupported or invalid progress
caches preserve the last valid local progress. An invalid family preserves its
last valid value while valid sibling families and playtime may advance; this is
reported rather than converted to a zero observation. Records from explicitly
foreign sources or marked as imported are excluded. Source IDs learned from the
root SavedVariables identity are adopted without relabeling foreign records.
Cached local progress remains scoped to characters in that source's measurements.

Invalid or truncated Lua documents preserve the complete previous source. Invalid
remote snapshots preserve that peer's complete prior revision and cannot prevent
independent valid peers from advancing. A valid newer remote snapshot replaces
that peer's complete contribution; legacy peers supply no progress channel.
Same-revision/different-content, cloned-device and group conflicts retain the
existing version 3 behavior.

A progress list and its merged source-preserving aggregate support at most 10,000
observations. A snapshot cannot repeat a `(sourceId, identity)` progress key.
Existing file, parser and cloud-folder limits remain in force. Version 4 snapshots
and generated data must fit the 8 MiB file limit. Local prospective state and
combined progress counts are checked before durable adoption; failed transactions
preserve the previous data. Generated files are built completely before an atomic
replacement, so an output failure leaves the previous data addon usable.

Source deselection withdraws its local progress alongside playtime. Pausing keeps
cached peers without accepting new cloud data. Disconnecting removes foreign
progress from the view and generated addon while retaining local measurements.
Hidden characters remain in transport so restoring visibility does not lose their
progress. A progress-only change advances the device revision; identical canonical
contents do not. Simply crossing a weekly reset does not generate a new observation.

## Canonical form and fixtures

Canonical progress arrays sort by source ID, then identity, each independently
in ordinal UTF-8 order. Projection arrays sort by identity. Preserve the fixed
family and slot structure and normalize empty vaults, absent keystone payload and
derived unlocks. Canonical legacy snapshots must not acquire a null progress field.

`tests/fixtures/sync/progress-v4.json` and `snapshot-v4.json` are shared with the
Companion fixtures. They cover separate family timestamps, confirmed empty values,
new seasons, reset jitter, source and typed-payload ties, unknown region isolation,
atomic vault rows and derived unlocks. Lua and .NET execute the same cases and
verify source-preserving merge convergence. Two-device integration tests also
verify non-republication, capability fallback, independent playtime winners,
failure preservation, revision stability, visibility, deselection, pause, detach
and database migration.
