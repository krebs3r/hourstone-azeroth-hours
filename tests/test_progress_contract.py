"""Protocol-4 golden cases shared verbatim with the Companion's .NET tests."""
import itertools
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tests'))
from run import runtime


def plain(value):
    if not hasattr(value,'items'):
        return value
    items=dict(value.items())
    if items and set(items)==set(range(1,len(items)+1)):
        return [plain(items[index]) for index in range(1,len(items)+1)]
    return {key:plain(item) for key,item in items.items()}


def ordered(values):
    return sorted(values,key=lambda value:json.dumps(value,ensure_ascii=False,sort_keys=True))


class ProgressContract(unittest.TestCase):
    def test_shared_projection_cases(self):
        fixture=json.loads((ROOT/'tests/fixtures/sync/progress-v4.json').read_text(encoding='utf-8'))
        for case in fixture['cases']:
            for values in itertools.permutations(case['progress']):
                with self.subTest(case=case['name'],sources=[v['sourceId'] for v in values]):
                    lua=runtime()
                    lua.globals().VALUES=lua.table_from(values,recursive=True)
                    lua.execute('''local raw=assert(H.P.MergeSources(VALUES))
                        ACTUAL={}
                        for _,rows in pairs(H.P.IndexObservations(raw)) do
                            ACTUAL[#ACTUAL+1]=assert(H.P.ProjectObservations(rows))
                        end''')
                    self.assertEqual(ordered(plain(lua.globals().ACTUAL)),ordered(case['expected']))

    def test_raw_source_merge_algebra(self):
        fixture=json.loads((ROOT/'tests/fixtures/sync/progress-v4.json').read_text(encoding='utf-8'))
        for case in fixture['cases']:
            values=case['progress']
            lua=runtime()
            lua.globals().VALUES=lua.table_from(values,recursive=True)
            lua.execute('BASE=assert(H.P.MergeSources(VALUES))')
            expected=plain(lua.globals().BASE)
            for permutation in itertools.permutations(values):
                with self.subTest(case=case['name']):
                    lua.globals().VALUES=lua.table_from(permutation,recursive=True)
                    lua.execute('''local group={}
                        for _,value in ipairs(VALUES) do
                            group[#group+1]=value
                            group=assert(H.P.MergeSources(group))
                        end
                        ACTUAL=assert(H.P.MergeSources(group))
                        for _,value in ipairs(VALUES) do group[#group+1]=value end
                        DUPLICATED=assert(H.P.MergeSources(group))''')
                    self.assertEqual(plain(lua.globals().ACTUAL),expected)
                    self.assertEqual(plain(lua.globals().DUPLICATED),expected)

    def test_complete_snapshot_as_generated_addon_scope(self):
        fixture=json.loads((ROOT/'tests/fixtures/sync/snapshot-v4.json').read_text(encoding='utf-8'))
        lua=runtime()
        lua.globals().SNAPSHOT=lua.table_from(fixture,recursive=True)
        lua.execute('''local db=H.M.Init({sourceId="contract-target"})
            assert(H.S.Import(db,{formatVersion=SNAPSHOT.formatVersion,sources={[db.sourceId]={
                observations=SNAPSHOT.observations,visibility=SNAPSHOT.visibility,
                progressObservations=SNAPSHOT.progressObservations}}}))
            H.P:Init(db)
            local character=SNAPSHOT.observations[1]
            RESULT=H.P:Get(character)
            assert(RESULT.keystone.level==10 and RESULT.weekly.level==11)
            assert(RESULT.keystone.expired and RESULT.weekly.status=="stale")
            assert(next(db.characters)==nil and next(db.progress.characters)==nil)
            local count=0
            for _,value in pairs(H.S.Display(db).characters) do count=count+1; assert(value.seconds==120) end
            assert(count==1)''')


if __name__=='__main__':
    unittest.main()
