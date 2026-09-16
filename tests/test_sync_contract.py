"""Run the shared synthetic synchronization contract against actual Lua 5.1."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import runtime


class SyncContract(unittest.TestCase):
    def test_shared_merge_cases(self):
        fixture = json.loads((ROOT / "tests/fixtures/sync/contract-v1.json").read_text(encoding="utf-8"))
        self.assertEqual(fixture["formatVersion"], 1)
        for case in fixture["cases"]:
            with self.subTest(case=case["name"]):
                lua = runtime()
                observations = lua.table_from(case["observations"], recursive=True)
                lua.globals().OBSERVATIONS = observations
                lua.execute('''local db=H.M.Init({sourceId="contract-target"})
                    assert(H.S.Import(db,{formatVersion=1,sources={[db.sourceId]={observations=OBSERVATIONS}}}))
                    SELECTED=H.S.Display(db).characters''')
                selected = list(lua.globals().SELECTED.values())
                self.assertEqual(len(selected), case["expectedCount"])
                self.assertEqual(sorted(row.seconds for row in selected), case["expectedSeconds"])
                if "expectedNames" in case:
                    self.assertEqual(sorted(row.name for row in selected), case["expectedNames"])


if __name__ == "__main__":
    unittest.main()
