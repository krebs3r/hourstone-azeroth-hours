"""WoW: Forever stays in the Retail client family and is labelled as its own client."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import CAMELOT, FOREVER, runtime

GUID = "Player-1-AAA"  # IDENTITY.guid in wow_mock.lua
SCOPE = "unknown:local-source"  # the simulator has no region API
LIVE = 1793833200  # M.FOREVER_LIVE: WoW: Forever launched on 2026-11-04 at 23:00 UTC


def record(flavor, seconds, updated_at):
    return {"guid": GUID, "flavor": flavor, "region": "unknown", "sourceId": "local-source", "name": "Elarion",
            "realm": "Blackhand", "class": "MAGE", "level": 90, "seconds": seconds, "updatedAt": updated_at}


def login(project, interface, characters, runtime_state=None, reload=False, setup=None, client=None, source="local-source"):
    lua = runtime(project, "enUS", interface=interface)
    if setup:
        lua.execute(setup)
    saved = {"version": 3, "visibility": {}, "sourceId": source, "characters": characters}
    if runtime_state:
        saved["runtime"] = runtime_state
    if client is not None:
        saved["client"] = client
    lua.globals().HourstoneDB = lua.table_from(saved, recursive=True)
    lua.execute('fire("ADDON_LOADED","Hourstone")')
    lua.execute('fire("PLAYER_ENTERING_WORLD",false,true)' if reload else 'fire("PLAYER_ENTERING_WORLD",true,false)')
    return lua, lua.globals().HourstoneDB


class ForeverFamily(unittest.TestCase):
    def test_camelot_project_records_retail_characters(self):
        for project in (CAMELOT, 1):
            with self.subTest(project=project):
                lua, db = login(project, FOREVER, {})
                C, T = lua.globals().H.C, lua.globals().H.T
                self.assertEqual(C.Flavor(), "retail")
                self.assertTrue(C.IsForever())
                self.assertFalse(C.RetailStyle())
                self.assertFalse(C.RetailProgress())
                self.assertEqual(T.key, f"{SCOPE}:retail:{GUID}")
                # The display marker never changes the family, key or protocol flavor.
                self.assertEqual((T.record.flavor, T.record.client, db.client), ("retail", "forever", "forever"))
                self.assertEqual(lua.globals().H.M.ClientText(T.record), "WoW: Forever")
                # Overview removal accepts the Retail family; "project-18" was rejected.
                self.assertTrue(lua.globals().H.V.Remove(db, T.record))
                self.assertTrue(lua.globals().H.V.IsRemoved(db, T.record))

    def test_any_project_id_on_forever_stays_retail(self):
        lua, db = login(20, FOREVER, {})
        C, T = lua.globals().H.C, lua.globals().H.T
        self.assertEqual(C.Flavor(), "retail")
        self.assertFalse(C.RetailStyle())
        self.assertFalse(C.RetailProgress())
        self.assertEqual(T.key, f"{SCOPE}:retail:{GUID}")

    def test_forever_adopts_characters_filed_under_any_project(self):
        legacy = f"{SCOPE}:project-20:{GUID}"
        lua, db = login(CAMELOT, FOREVER, {legacy: record("project-20", 5000, 1800000000 - 60)})
        self.assertEqual(list(db.characters.keys()), [f"{SCOPE}:retail:{GUID}"])
        self.assertEqual(db.characters[f"{SCOPE}:retail:{GUID}"].flavor, "retail")

    def test_identity_never_stores_an_empty_name_or_realm(self):
        cases = (
            ('UnitFullName = function() return "Elarion", "" end; GetRealmName = function() return "Classic Beta PvE" end',
             "Elarion", "Classic Beta PvE"),
            ('UnitFullName = function() return "Elarion", nil end; GetRealmName = function() return "" end; '
             'GetNormalizedRealmName = function() return "ClassicBetaPvE" end', "Elarion", "ClassicBetaPvE"),
            ('UnitFullName = function() return "", nil end; GetRealmName = function() return nil end; '
             'GetNormalizedRealmName = nil', "?", "?"),
        )
        for setup, name, realm in cases:
            with self.subTest(name=name, realm=realm):
                lua, db = login(CAMELOT, FOREVER, {}, setup=setup)
                stored = db.characters[f"{SCOPE}:retail:{GUID}"]
                self.assertEqual((stored.name, stored.realm), (name, realm))

    def test_forever_adopts_characters_filed_under_project_18(self):
        legacy = f"{SCOPE}:project-18:{GUID}"
        lua, db = login(CAMELOT, FOREVER, {legacy: record("project-18", 5000, 1800000000 - 60)})
        self.assertEqual(list(db.characters.keys()), [f"{SCOPE}:retail:{GUID}"])
        char = db.characters[f"{SCOPE}:retail:{GUID}"]
        self.assertEqual((char.flavor, char.seconds), ("retail", 5000))

    def test_forever_merges_both_earlier_records(self):
        older = record("retail", 3000, 1800000000 - 86400)
        newer = record("project-18", 5000, 1800000000 - 60)
        lua, db = login(CAMELOT, FOREVER, {f"{SCOPE}:retail:{GUID}": older, f"{SCOPE}:project-18:{GUID}": newer})
        self.assertEqual(list(db.characters.keys()), [f"{SCOPE}:retail:{GUID}"])
        char = db.characters[f"{SCOPE}:retail:{GUID}"]
        self.assertEqual((char.flavor, char.seconds), ("retail", 5000))

    def test_forever_migrates_characters_not_logged_in(self):
        alt = dict(record("project-18", 7000, 1800000000 - 3600), guid="Player-1-BBB")
        lua, db = login(CAMELOT, FOREVER, {f"{SCOPE}:project-18:Player-1-BBB": alt})
        self.assertEqual(sorted(db.characters.keys()), [f"{SCOPE}:retail:{GUID}", f"{SCOPE}:retail:Player-1-BBB"])
        char = db.characters[f"{SCOPE}:retail:Player-1-BBB"]
        self.assertEqual((char.flavor, char.seconds, char.client), ("retail", 7000, "forever"))
        self.assertEqual(lua.globals().H.M.ClientText(char), lua.globals().H.L.forever)
        self.assertTrue(lua.globals().H.V.Remove(db, char))

    def test_reload_from_033_keeps_the_session(self):
        legacy = f"{SCOPE}:project-18:{GUID}"
        lua, db = login(CAMELOT, FOREVER, {legacy: record("project-18", 5000, 1800000000 - 60)},
                        runtime_state={"key": legacy, "at": 996, "session": 100}, reload=True)
        T = lua.globals().H.T
        self.assertEqual(T.key, f"{SCOPE}:retail:{GUID}")
        self.assertEqual(T.Session(T), 104)
        self.assertEqual(T.Value(T, T.key, T.record), 5004)

    def test_malformed_records_never_block_loading(self):
        # Equal playtime fields make the merge compare the non-numeric levels.
        legacy = dict(record("project-18", 5000, 1800000000 - 60), level=True)
        current = dict(record("retail", 5000, 1800000000 - 60), level=False)
        for project in ("project-18", "project-20"):
            with self.subTest(project=project):
                lua, db = login(CAMELOT, FOREVER, {f"{SCOPE}:{project}:{GUID}": dict(legacy, flavor=project), f"{SCOPE}:retail:{GUID}": current})
                self.assertIsNotNone(lua.globals().H.UI.db)
                self.assertEqual(db.characters[f"{SCOPE}:{project}:{GUID}"].flavor, project)

    def test_retail_leaves_project_18_records_alone(self):
        legacy = f"{SCOPE}:project-18:{GUID}"
        lua, db = login(1, None, {legacy: record("project-18", 5000, 1800000000 - 60)})
        self.assertEqual(sorted(db.characters.keys()), sorted([legacy, f"{SCOPE}:retail:{GUID}"]))
        self.assertEqual(db.characters[legacy].flavor, "project-18")


def alt(flavor, updated_at, guid):
    return dict(record(flavor, 4000, updated_at), guid=guid)


def source(created):
    """A source ID as C.SourceId creates it, starting with the database's creation time."""
    return f"hs-{created}-" + "0" * 32


FRESH = source(LIVE + 60)  # created in Forever after the launch, like the author's live database


def by_guid(db, guid):
    return next(char for char in db.characters.values() if char.guid == guid)


class ForeverLabel(unittest.TestCase):
    def test_a_database_created_since_the_launch_is_marked_once(self):
        unplayed = dict(alt("retail", None, "Player-1-CCC"), seconds=None)  # saved before any /played answer
        characters = {"a": alt("retail", LIVE + 60, "Player-1-BBB"), "b": unplayed, "c": alt("era", LIVE + 60, "Player-1-DDD")}
        lua, db = login(CAMELOT, FOREVER, characters, source=FRESH)
        H = lua.globals().H
        self.assertEqual(by_guid(db, "Player-1-BBB").client, "forever")
        self.assertEqual(by_guid(db, "Player-1-CCC").client, "forever")
        self.assertIsNone(by_guid(db, "Player-1-DDD").client)
        self.assertEqual(H.M.ClientText(by_guid(db, "Player-1-BBB")), H.L.forever)
        self.assertEqual(H.M.ClientText(by_guid(db, "Player-1-DDD")), H.L.era)
        self.assertEqual(db.client, "forever")

    def test_an_older_database_keeps_retail_until_each_login(self):
        # A Retail WTF folder copied into _forever_ after the launch, a database without a
        # creation time and one whose invalid source ID is replaced during loading.
        for created in (source(LIVE - 1), "local-source", "invalid source"):
            with self.subTest(source=created):
                lua, db = login(CAMELOT, FOREVER, {"a": alt("retail", LIVE + 3600, "Player-1-BBB")}, source=created)
                H = lua.globals().H
                self.assertIsNone(by_guid(db, "Player-1-BBB").client)
                self.assertEqual(H.M.ClientText(by_guid(db, "Player-1-BBB")), H.L.retail)
                self.assertEqual((H.T.record.client, db.client), ("forever", "forever"))

    def test_a_stamped_database_is_not_marked_again(self):
        # "retail" and "era": a WTF folder copied from a client running this version.
        for stamp in ("retail", "era", "forever"):
            with self.subTest(stamp=stamp):
                lua, db = login(CAMELOT, FOREVER, {"a": alt("retail", LIVE + 60, "Player-1-BBB")}, client=stamp, source=FRESH)
                self.assertIsNone(by_guid(db, "Player-1-BBB").client)
                self.assertEqual(by_guid(db, GUID).client, "forever")
                self.assertEqual(db.client, "forever")

    def test_migrated_project_entries_are_marked(self):
        beta = alt("project-18", LIVE - 30 * 86400, "Player-1-BBB")
        lua, db = login(CAMELOT, FOREVER, {f"{SCOPE}:project-18:Player-1-BBB": beta}, client="forever")
        self.assertEqual(db.characters[f"{SCOPE}:retail:Player-1-BBB"].client, "forever")

    def test_other_clients_stamp_the_database_and_mark_nothing(self):
        for project, flavor in ((1, "retail"), (19, "mists"), (5, "tbc"), (2, "era")):
            with self.subTest(flavor=flavor):
                lua, db = login(project, None, {"a": alt("retail", LIVE + 60, "Player-1-BBB")}, source=FRESH)
                H = lua.globals().H
                self.assertEqual(db.client, flavor)
                self.assertIsNone(H.T.record.client)
                self.assertIsNone(by_guid(db, "Player-1-BBB").client)
                self.assertEqual(H.M.ClientText(H.T.record), H.L[flavor])

    def test_a_login_outside_forever_clears_a_stale_marker(self):
        stale = dict(record("retail", 5000, LIVE + 60), client="forever")
        lua, db = login(1, None, {f"{SCOPE}:retail:{GUID}": stale}, client="forever")
        H = lua.globals().H
        self.assertIsNone(H.T.record.client)
        self.assertEqual(H.M.ClientText(H.T.record), H.L.retail)
        self.assertTrue(H.P.Get(H.P, H.T.record).supported)

    def test_display_labels_by_identity_and_filters_by_client(self):
        lua, db = login(CAMELOT, FOREVER, {}, setup="GetCurrentRegion = function() return 3 end")
        H = lua.globals().H
        key = f"eu:retail:{GUID}"
        self.assertEqual(H.T.key, key)
        # A newer confirmed observation from another PC wins the playtime merge.
        lua.execute(f"""H.S.received = {{
            ["{key}"] = {{sourceId="other-pc", region="eu", flavor="retail", guid="{GUID}", name="Elarion",
                realm="Blackhand", class="MAGE", level=90, seconds=9999, updatedAt=EPOCH+10, serverSeconds=9999, serverAt=EPOCH+10}},
            ["eu:retail:Player-2-ZZZ"] = {{sourceId="other-pc", region="eu", flavor="retail", guid="Player-2-ZZZ", name="Thrall",
                realm="Blackhand", class="WARRIOR", level=80, seconds=5000, updatedAt=EPOCH}},
        }}""")
        display = H.S.Display(db)
        mine = display.characters[f"sync:{key}"]
        self.assertEqual((mine.sourceId, mine.flavor, mine.client), ("other-pc", "retail", "forever"))
        self.assertIsNone(H.S.received[key].client)
        self.assertEqual(H.M.ClientText(display.characters["sync:eu:retail:Player-2-ZZZ"]), H.L.retail)

        def names(client, sort="name"):
            rows, _ = H.M.List(display, "", None, sort, False, None, client)
            return [rows[i].char.name for i in range(1, len(rows) + 1)]
        self.assertEqual(names("forever"), ["Elarion"])
        self.assertEqual(names("retail"), ["Thrall"])
        self.assertEqual(names(None, "flavor"), ["Thrall", "Elarion"])  # "Retail" before "WoW: Forever"

    def test_retail_progress_excludes_forever_characters(self):
        lua, db = login(1, None, {})
        H = lua.globals().H
        self.assertTrue(H.P.Get(H.P, H.T.record).supported)
        lua.execute('FOREVER_ROW = {flavor="retail", client="forever", guid="Player-9-AAA", region="eu", sourceId="local-source"}')
        self.assertFalse(H.P.Get(H.P, lua.globals().FOREVER_ROW).supported)

    def test_client_menu_offers_forever_on_forever_only(self):
        for project, interface, forever in ((CAMELOT, FOREVER, True), (1, FOREVER, True), (1, None, False), (2, None, False)):
            with self.subTest(project=project, interface=interface):
                lua, db = login(project, interface, {f"{SCOPE}:era:Player-1-DDD": alt("era", LIVE + 60, "Player-1-DDD")})
                lua.execute("H.UI:Create(); H.UI:Refresh()")
                U = lua.globals().H.UI
                self.assertEqual(U.clientRows.forever is not None, forever)
                self.assertEqual(U.clientMenu.height, 16 + (6 if forever else 5) * 25)
                if forever:
                    U.clientRows.forever.scripts.OnClick()
                    self.assertEqual((U.flavor, U.visibleCount), ("forever", 1))
                    self.assertEqual((U.clientButton.label.text, U.rows[1].client.text), ("WoW: Forever", "WoW: Forever"))
                    U.clientRows.retail.scripts.OnClick()
                    self.assertEqual(U.visibleCount, 0)


if __name__ == "__main__":
    unittest.main()
