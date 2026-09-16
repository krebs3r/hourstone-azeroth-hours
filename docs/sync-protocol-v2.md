# Hourstone synchronization protocol 2

This contract is shared by Hourstone 0.2.1 and Hourstone Companion 0.1.2.
The addon repository is the canonical source. Companion builds retain a pinned
copy of this document and the synthetic contract fixtures.

## Local observations

`HourstoneDB.version = 2` stores a persistent `sourceId` for the selected account
database. A source ID contains 1–128 ASCII letters, digits, underscores or hyphens.
It identifies a logical source, not a computer. Copying a database preserves its
source ID; companion device IDs remain unique to each installation.

`HourstoneDB.characters` contains only observations made by that local addon.
Companion imports never enter this table. The following observation fields form
the public interface:

| Field | Value |
| --- | --- |
| `sourceId` | Source identifier; matches the local database when exported |
| `region` | `us`, `kr`, `eu`, `tw`, `cn`, or `unknown` |
| `flavor` | `retail`, `mists`, `tbc`, or `era` |
| `guid` | Character GUID, 1–128 UTF-8 bytes |
| `name`, `realm` | Display values, each 1–128 UTF-8 bytes |
| `class` | WoW class token, 1–32 UTF-8 bytes |
| `level` | Integer, 0–1000 |
| `seconds` | Saved total including any estimate attached to the baseline |
| `updatedAt` | WoW server epoch of the saved observation |
| `serverSeconds`, `serverAt` | Optional pair: confirmed `/played` total and its WoW server epoch |
| `guild`, `guildUpdatedAt` | Optional pair: last known guild membership and its independent WoW server epoch |

Text fields exclude ASCII control characters (U+0000–U+001F and U+007F).
Time values are finite, nonnegative numbers no greater than 9,007,199,254,740,991.
For a confirmed observation, `seconds >= serverSeconds` and
`updatedAt >= serverAt`. Both confirmation fields must be present together;
unconfirmed JSON values may omit both or use `null` for both. Lua omits nil values.
`guild` and `guildUpdatedAt` must be present together. Omitting both or using
`null` for both means unknown. An empty guild string means explicitly no guild;
a nonempty string names the guild. Guild strings allow 0–128 UTF-8 bytes and
exclude the same ASCII controls. The timestamp has the same finite nonnegative
range as other time values, but is independent of `updatedAt` and `serverAt`.

The addon samples its own guild using `IsInGuild()` and `GetGuildInfo("player")`.
A missing API value or an unresolved name for a guild member does not clear a
known guild. Initial login does not interpret an empty cache as a departure.
The player's own `PLAYER_GUILD_UPDATE`, `GUILD_ROSTER_UPDATE`, later world-entry
events and saving recheck available metadata without busy polling. Explicit
absence is recorded only when the membership API reports false after an own
guild event or on save. Only `GetServerTime()` may timestamp guild membership.

Characters awaiting their first `/played` value may remain in local SavedVariables
without `seconds`; they are shown locally but are not exported as observations.

Schema 1 migration preserves its last total as an unconfirmed observation.
Its `syncedAt` timestamp does not reconstruct the old baseline and must not be
used as `serverAt`. The updated addon must log in and save once to establish
`sourceId` before a companion can enable that source. Newer database or protocol
versions are rejected without rewriting them.

## Identity and selection

A known character identity is `region:flavor:guid`. With an unknown region it is
`unknown:sourceId:flavor:guid`; the source prevents cross-region accidental merges.
Learning the local region migrates matching local unknown-region records to that
identity. A computer name, filename, upload time or filesystem clock never
determines which time value wins.

Each identity selects one complete playtime observation; totals are never added and an
estimate is never attached to another baseline. Compare observations in this
order, choosing the greater value at the first difference:

1. Presence of the confirmed pair (confirmed wins over unconfirmed).
2. For confirmed observations, `serverAt`, then `serverSeconds`.
3. `updatedAt`, then `seconds`.
4. `sourceId`, `name`, `realm`, `class` in ordinal UTF-8 byte order, then `level`.

Exact ties are interchangeable. The newest server answer may lower a previous
estimate. Strings use UTF-8 byte ordering for the same result in Lua and .NET.

Guild membership is merged independently of that playtime winner. Among known
pairs, select the greatest `guildUpdatedAt`; a tie selects the greatest guild
string in ordinal UTF-8 byte order. Unknown never replaces known, while a newer
empty string clears an older name. This ordering is commutative and associative,
so input order and grouping do not change the result. A newer guild from an
older or unconfirmed playtime observation does not change the chosen playtime
baseline, name, realm, class, level, or local/received provenance.

## Version compatibility

Database schema remains 2; existing characters simply have unknown guilds until
observed. New device snapshots and generated data addons use `formatVersion: 2`.
Readers accept formats 1 and 2. Format 1 must not contain non-null `guild` or
`guildUpdatedAt` fields; such mixed input is rejected. Existing format-1 fixtures
remain unchanged and continue to define their original canonical serialization.
Version-1 readers reject version 2 and retain their last valid data. Both devices
need Companion 0.1.2 or newer and the target client needs Hourstone 0.2.1 or newer
for guild synchronization. Unsupported newer formats remain errors.

## Device snapshot

The provider folder contains one complete UTF-8 JSON snapshot per device:

```json
{
  "formatVersion": 2,
  "groupId": "11111111-1111-4111-8111-111111111111",
  "deviceId": "22222222-2222-4222-8222-222222222222",
  "deviceName": "Gaming PC",
  "revision": 1,
  "observations": []
}
```

Group and device IDs are GUIDs. Revisions are positive signed 64-bit integers and
are compared only within one device. The device ID and monotonic revision counter
are persisted locally, never obtained from the shared folder. Every device is
the sole writer of its own snapshot; imported observations are not re-exported.
Each new snapshot replaces that device's entire prior contribution, including
explicit source deselection. Missing files do not delete cached contributions.

Readers validate complete stable files and keep the last good contribution after
an error. Identical conflict copies are deduplicated by content. A lower revision
is ignored. Different content claiming the same device and revision is an error;
the last good contribution is retained. Publication uses an atomic file replace.
The companion scans on startup, observes changes, and rescans every 30 seconds.

The folder must be permanently available offline in Dropbox or OneDrive. Its
provider handles transport; the companion cannot attest cloud upload completion
or another computer being online. Published, received and ready-for-WoW are
separate statuses. Pausing preserves cached peers; disconnecting clears their
local contribution without requesting a remote deletion.

## Generated data addon

Companion owns only `Interface/AddOns/Hourstone_Sync`. This data addon declares
no SavedVariables and provides a Lua table:

```lua
HourstoneSync = {
    formatVersion = 2,
    sources = {
        ["local-account-source-id"] = { observations = { --[[ merged observations ]] } },
    },
}
```

Each selected local source receives the selected union for its sync group. The
main addon loads only `sources[HourstoneDB.sourceId]` into an in-memory projection
and accepts at most 20,000 observation rows. This is logical account selection,
not an access control boundary: addon files are visible to accounts sharing an
installation. Unsupported or malformed data is ignored as a whole. With no
matching source, local operation continues normally.

`Hourstone` declares an optional dependency on `Hourstone_Sync`. It consumes that
payload only during login or reload; it never promotes received observations into
its tracker baseline, active session, or future exports. A current character with
only an imported total still requests `/played` and establishes its own local
baseline. No executable Lua from SavedVariables is evaluated by the companion.

## Conformance

`tests/fixtures/sync/contract-v2.json` supplies synthetic merge scenarios.
`tests/fixtures/sync/snapshot-v2.json` is a valid complete snapshot. Implementations
apply the selection rules per identity and compare the sorted selected totals
with each case's `expectedSeconds`. Invalid input and local isolation are also
tested in the addon Lua suites and companion tests.

Guild fixture cases additionally compare sorted `expectedGuilds` and
`expectedGuildUpdatedAts`, with unknown (`null`) ordered before known values.
`invalidCases` supplies observations that must be rejected. The unchanged
version-1 document and fixtures are retained for compatibility tests.

The UI treats guild text as data, escaping WoW markup before display. It shows
known names, no guild, and unknown distinctly; the full guild value is available
in the character tooltip. Name/guild search changes only the displayed list.
