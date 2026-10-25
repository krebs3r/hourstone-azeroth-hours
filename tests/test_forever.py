"""WoW: Forever stays in the Retail client family across its project ID change."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import CAMELOT, FOREVER, runtime

GUID = "Player-1-AAA"  # IDENTITY.guid in wow_mock.lua
SCOPE = "unknown:local-source"  # the simulator has no region API


def record(flavor, seconds, updated_at):
    return {"guid": GUID, "flavor": flavor, "region": "unknown", "sourceId": "local-source", "name": "Elarion",
            "realm": "Blackhand", "class": "MAGE", "level": 90, "seconds": seconds, "updatedAt": updated_at}


def login(project, interface, characters, runtime_state=None, reload=False):
    lua = runtime(project, "enUS", interface=interface)
    saved = {"version": 3, "visibility": {}, "sourceId": "local-source", "characters": characters}
    if runtime_state:
        saved["runtime"] = runtime_state
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
                self.assertEqual(lua.globals().H.M.ClientText(T.record), lua.globals().H.L.retail)
                # Overview removal accepts the Retail family; "project-18" was rejected.
                self.assertTrue(lua.globals().H.V.Remove(db, T.record))
                self.assertTrue(lua.globals().H.V.IsRemoved(db, T.record))

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
        self.assertEqual((char.flavor, char.seconds), ("retail", 7000))
        self.assertEqual(lua.globals().H.M.ClientText(char), lua.globals().H.L.retail)
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
        lua, db = login(CAMELOT, FOREVER, {f"{SCOPE}:project-18:{GUID}": legacy, f"{SCOPE}:retail:{GUID}": current})
        self.assertIsNotNone(lua.globals().H.UI.db)
        self.assertEqual(db.characters[f"{SCOPE}:project-18:{GUID}"].flavor, "project-18")

    def test_retail_leaves_project_18_records_alone(self):
        legacy = f"{SCOPE}:project-18:{GUID}"
        lua, db = login(1, None, {legacy: record("project-18", 5000, 1800000000 - 60)})
        self.assertEqual(sorted(db.characters.keys()), sorted([legacy, f"{SCOPE}:retail:{GUID}"]))
        self.assertEqual(db.characters[legacy].flavor, "project-18")


if __name__ == "__main__":
    unittest.main()
