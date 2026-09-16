"""Run shared synthetic synchronization contracts against actual Lua 5.1."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import runtime


def ordered(values):
    return sorted(values, key=lambda value: (value is not None, value if value is not None else ""))


class SyncContract(unittest.TestCase):
    def test_shared_merge_cases(self):
        for version in (1, 2):
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
                            assert(H.S.Import(db,{formatVersion=FORMAT_VERSION,sources={[db.sourceId]={observations=OBSERVATIONS}}}))
                            SELECTED=H.S.Display(db).characters''')
                        selected = list(lua.globals().SELECTED.values())
                        self.assertEqual(len(selected), case["expectedCount"])
                        self.assertEqual(sorted(row.seconds for row in selected), case["expectedSeconds"])
                        if "expectedNames" in case:
                            self.assertEqual(sorted(row.name for row in selected), case["expectedNames"])
                        if "expectedGuilds" in case:
                            self.assertEqual(ordered(row.guild for row in selected), case["expectedGuilds"])
                            self.assertEqual(ordered(row.guildUpdatedAt for row in selected), case["expectedGuildUpdatedAts"])

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
