"""Run shared synthetic synchronization contracts against actual Lua 5.1."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import CAMELOT, FOREVER, runtime


def ordered(values):
    return sorted(values, key=lambda value: (value is not None, value if value is not None else ""))


class SyncContract(unittest.TestCase):
    def test_shared_visibility_cases(self):
        fixture = json.loads((ROOT / "tests/fixtures/sync/visibility-v3.json").read_text(encoding="utf-8"))
        for case in fixture["cases"]:
            for reverse in (False, True):
                with self.subTest(case=case["name"], reverse=reverse):
                    lua = runtime()
                    lua.globals().STATES = lua.table_from(case["states"][::-1] if reverse else case["states"], recursive=True)
                    lua.execute('RESULT=assert(H.V.Merge(STATES, {})); HIDDEN=H.V.Hidden(RESULT[1])')
                    actual = lua.globals().RESULT[1]
                    for field in ("sourceId", "region", "flavor", "guid"):
                        self.assertEqual(actual[field], case["expected"][field])
                    for field in ("removed", "restored"):
                        self.assertEqual(dict(actual[field].items()), case["expected"][field])
                    self.assertEqual(lua.globals().HIDDEN, case["hidden"])
        for case in fixture["invalid"]:
            with self.subTest(invalid=case["name"]):
                lua = runtime()
                lua.globals().STATE = lua.table_from(case["state"], recursive=True)
                lua.execute('assert(not H.V.Valid(STATE))')

    def test_shared_merge_cases(self):
        for version in (1, 2, 3):
            fixture = json.loads((ROOT / f"tests/fixtures/sync/contract-v{version}.json").read_text(encoding="utf-8"))
            self.assertEqual(fixture["formatVersion"], version)
            for case in fixture["cases"]:
                for reverse in (False, True):
                    with self.subTest(version=version, case=case["name"], reverse=reverse):
                        lua = runtime()
                        observations = case["observations"][::-1] if reverse else case["observations"]
                        lua.globals().OBSERVATIONS = lua.table_from(observations, recursive=True)
                        lua.globals().FORMAT_VERSION = version
                        lua.execute('''local db=H.M.Init({sourceId="contract-target"})
                            assert(H.S.Import(db,{formatVersion=FORMAT_VERSION,sources={[db.sourceId]={observations=OBSERVATIONS, visibility=FORMAT_VERSION == 3 and {} or nil}}}))
                            SELECTED=H.S.Display(db).characters''')
                        selected = list(lua.globals().SELECTED.values())
                        self.assertEqual(len(selected), case["expectedCount"])
                        self.assertEqual(sorted(row.seconds for row in selected), case["expectedSeconds"])
                        if "expectedNames" in case:
                            self.assertEqual(sorted(row.name for row in selected), case["expectedNames"])
                        if "expectedGuilds" in case:
                            self.assertEqual(ordered(row.guild for row in selected), case["expectedGuilds"])
                            self.assertEqual(ordered(row.guildUpdatedAt for row in selected), case["expectedGuildUpdatedAts"])

    def test_shared_forever_cases(self):
        fixture = json.loads((ROOT / "tests/fixtures/sync/forever-v4.json").read_text(encoding="utf-8"))
        self.assertEqual((fixture["formatVersion"], fixture["field"]), (4, "foreverSources"))

        def labelled(case, listed, project, interface):
            lua = runtime(project, "enUS", interface=interface)
            local = {f"{o['region']}:{o['flavor']}:{o['guid']}": o for o in case["local"]}
            lua.globals().SOURCE = case["localSourceId"]
            lua.globals().LOCAL = lua.table_from(local, recursive=True)
            lua.globals().OBSERVATIONS = lua.table_from(case["observations"], recursive=True)
            lua.globals().LIST = lua.table_from(listed) if listed else None
            lua.execute('''local db=H.M.Init({sourceId=SOURCE,characters=LOCAL})
                assert(H.S.Import(db,{formatVersion=4,sources={[SOURCE]={observations=OBSERVATIONS,visibility={},progressObservations={},foreverSources=LIST}}}))
                assert(H.S.status=="ready"); FOREVER={}
                for _,row in pairs(H.S.Display(db).characters) do
                    if H.M.Client(row)=="forever" then FOREVER[#FOREVER+1]=H.S.Key(row,SOURCE) end
                end''')
            return sorted(lua.globals().FOREVER.values())

        for case in fixture["cases"]:
            self.assertEqual(case["expectedList"], sorted(set(case["expectedList"])))
            # The canonical list and the Companion's whole input set label the same rows.
            for listed in (case["expectedList"], sorted(set(case["foreverSources"]))):
                for client, project, interface in (("Retail", 1, None), ("Forever", CAMELOT, FOREVER)):
                    with self.subTest(case=case["name"], client=client, listed=listed):
                        self.assertEqual(labelled(case, listed, project, interface), case["expectedForever"])

        # forever-data-v4.lua is the Companion's generated data for the first case.
        golden = (ROOT / "tests/fixtures/sync/forever-data-v4.lua").read_text(encoding="utf-8")
        first = fixture["cases"][0]
        for client, project, interface in (("Retail", 1, None), ("Forever", CAMELOT, FOREVER)):
            with self.subTest(golden=client):
                lua = runtime(project, "enUS", interface=interface)
                lua.execute(golden)
                lua.globals().SOURCE = first["localSourceId"]
                lua.execute('''local db=H.M.Init({sourceId=SOURCE})
                    assert(H.S.Import(db,HourstoneSync) and H.S.status=="ready"); FOREVER={}
                    for _,row in pairs(H.S.Display(db).characters) do
                        if H.M.Client(row)=="forever" then FOREVER[#FOREVER+1]=H.S.Key(row,SOURCE) end
                    end''')
                self.assertEqual(sorted(lua.globals().FOREVER.values()), first["expectedForever"])

        invalid = [(repr(value), [value]) for value in fixture["invalidSourceIds"]]
        invalid += [(case["name"], case["value"]) for case in fixture["invalidLists"]]
        for name, value in invalid:
            with self.subTest(invalid=name):
                lua = runtime()
                lua.globals().LIST = lua.table_from(value, recursive=True) if isinstance(value, (list, dict)) else value
                lua.execute('''local db=H.M.Init({sourceId="contract-target"})
                    local valid={sourceId="contract-target",region="eu",flavor="retail",guid="Player-1-A",name="A",realm="R",class="MAGE",level=1,seconds=1,updatedAt=1}
                    assert(not H.S.Import(db,{formatVersion=4,sources={[db.sourceId]={observations={valid},visibility={},progressObservations={},foreverSources=LIST}}}))
                    assert(H.S.status=="invalid" and next(H.S.received)==nil and next(H.S.receivedForever)==nil)''')

    def test_shared_invalid_guild_cases(self):
        fixture = json.loads((ROOT / "tests/fixtures/sync/contract-v2.json").read_text(encoding="utf-8"))
        for case in fixture["invalidCases"]:
            with self.subTest(case=case["name"]):
                lua = runtime()
                lua.globals().OBSERVATION = lua.table_from(case["observation"], recursive=True)
                lua.execute('''local db=H.M.Init({sourceId="contract-target"})
                    assert(not H.S.Valid(OBSERVATION))
                    assert(not H.S.Import(db,{formatVersion=2,sources={[db.sourceId]={observations={OBSERVATION}}}}))
                    assert(next(H.S.received)==nil)''')


if __name__ == "__main__":
    unittest.main()
