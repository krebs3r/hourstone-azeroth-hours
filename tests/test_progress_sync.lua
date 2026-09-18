local P,S,M,T=H.P,H.S,H.M,H.T
local function clone(value)
    if type(value)~="table" then return value end
    local out={}; for key,item in pairs(value) do out[key]=clone(item) end; return out
end
local function row(at,progress)
    local out={updatedAt=at,resetAt=EPOCH+3600,slots={}}
    for index,threshold in ipairs({1,4,8}) do
        out.slots[index]={progress=progress,threshold=threshold,level=12,difficultyName="Mythic+",unlocked=false}
    end
    return out
end
local function observation(source)
    return {sourceId=source or "source-a",region="eu",flavor="retail",guid="Player-1-SYNC",
        keystone={present=true,mapID=399,level=12,name="Synthetic Dungeon",updatedAt=EPOCH-20,resetAt=EPOCH+3600},
        weekly={level=13,seasonID=42,updatedAt=EPOCH-20,resetAt=EPOCH+3600},
        vault={rows={dungeon=row(EPOCH-20,4),raid=row(EPOCH-20,2),world=row(EPOCH-20,0)}}}
end
local function payload(db,values,version)
    return {formatVersion=version or 4,sources={[db.sourceId]={observations={},visibility={},progressObservations=values}}}
end
local a=observation()
assert(P.ValidObservation(a) and P.NormalizeObservation(a).vault.rows.dungeon.slots[1].unlocked)
assert(not a.vault.rows.dungeon.slots[1].unlocked) -- normalization is detached
local empty={sourceId="source-a",region="eu",flavor="retail",guid=a.guid,vault={rows={}}}
assert(P.NormalizeObservation(empty).vault==nil)
local absent=clone(a); absent.keystone={present=false,mapID=399,level=12,name="Old",updatedAt=EPOCH,resetAt=EPOCH+3600}
assert(P.NormalizeObservation(absent).keystone.level==nil)
for _,field in ipairs({"sourceId","region","flavor","guid"}) do
    local bad=clone(a); bad[field]=nil; assert(not P.ValidObservation(bad),field)
end
for field,value in pairs({sourceId="bad:source",region="moon",flavor="era",guid="a\nb"}) do
    local bad=clone(a); bad[field]=value; assert(not P.ValidObservation(bad),field)
end
local bad=clone(a); bad.extra=true; assert(not P.ValidObservation(bad))
bad=clone(a); bad.keystone.extra=true; assert(not P.ValidObservation(bad))
bad=clone(a); bad.weekly.seasonID=0/0; assert(not P.ValidObservation(bad))
bad=clone(a); bad.weekly.updatedAt=1.5; assert(not P.ValidObservation(bad))
bad=clone(a); bad.keystone.resetAt=bad.keystone.updatedAt; assert(not P.ValidObservation(bad))
bad=clone(a); bad.keystone.name=string.rep("ä",513); assert(not P.ValidObservation(bad))
for _,bytes in ipairs({{128},{192,175},{226,130},{237,160,128},{240,128,128,128},{244,144,128,128},{245,128,128,128}}) do
    bad=clone(a); bad.keystone.name=string.char(unpack(bytes)); assert(not P.ValidObservation(bad))
end
local unicode=clone(a); unicode.keystone.name="Ä 中文 "..string.char(240,159,142,174)
assert(P.ValidObservation(unicode))
bad=clone(a); bad.vault.rows.dungeon.slots[3]=nil; assert(not P.ValidObservation(bad))
bad=clone(a); bad.vault.rows.dungeon.slots[4]=clone(bad.vault.rows.dungeon.slots[1]); assert(not P.ValidObservation(bad))
bad=clone(a); bad.vault.rows.dungeon.slots[1].threshold=0; assert(not P.ValidObservation(bad))
bad=clone(a); bad.vault.rows.raid.slots[1].difficultyName=""; assert(not P.ValidObservation(bad))
bad=clone(a); bad.vault.rows.pvp=row(EPOCH,1); assert(not P.ValidObservation(bad))
assert(not P.MergeSources({[2]=a}) and not P.MergeSources({key=a}))
local overLimit={}; for index=1,P.SYNC_LIMIT+1 do overLimit[index]=empty end
assert(not P.MergeSources(overLimit))

-- A smaller, later key and confirmed absence are valid observations. The
-- independent weekly/raid families must not inherit the key's timestamps.
local b=observation("source-b")
b.keystone.level,b.keystone.updatedAt=2,EPOCH-10
b.weekly.level,b.weekly.updatedAt=20,EPOCH-30
b.vault.rows.raid=row(EPOCH-5,8)
local projection=P.ProjectObservations({a,b})
assert(projection.sourceId=="source-b" and projection.keystone.level==2 and projection.weekly.level==13)
assert(projection.vault.rows.raid.slots[1].progress==8 and projection.vault.rows.dungeon.slots[1].progress==4)
assert(P.ProjectObservations({b,a}).keystone.level==2)
assert(not P.ProjectObservations({a,observation("source-b"),{sourceId="source-c",region="us",flavor="retail",guid=a.guid}}))
local withAbsence=P.ProjectObservations({a,b,absent})
assert(not withAbsence.keystone.present and withAbsence.keystone.level==nil)
local low=clone(a); low.weekly.updatedAt=EPOCH; low.weekly.level=0
assert(P.ProjectObservations({a,low}).weekly.level==0) -- transport is LWW, collector guards remain local
local slightReset=clone(a); slightReset.keystone.updatedAt=EPOCH-25; slightReset.keystone.resetAt=EPOCH+3602
slightReset.keystone.level=99
assert(P.ProjectObservations({a,slightReset}).keystone.level==12)
local tied=clone(a); tied.keystone.level=14
assert(P.ProjectObservations({a,tied}).keystone.level==14 and P.ProjectObservations({tied,a}).keystone.level==14)
local sourceTie=clone(a); sourceTie.sourceId="source-z"; sourceTie.keystone.level=1
assert(P.ProjectObservations({tied,sourceTie}).keystone.level==1)

-- Only raw same-source records can be merged and transported. Cross-source
-- projections retain family provenance during the fold, never as saved data.
local aa=clone(a); aa.weekly.updatedAt=EPOCH-2; aa.weekly.level=15
local left=P.MergeSources({a,aa,b}); local right=P.MergeSources({b,aa,a,a})
assert(#left==2 and #right==2 and left[1].sourceId==right[1].sourceId)
assert(left[1].weekly.level==15 and left[1].keystone.level==12 and left[2].keystone.level==2)
local intermediate=P.MergeSources({a,b}); intermediate[#intermediate+1]=aa
local grouped=P.MergeSources(intermediate)
assert(grouped[1].weekly.level==left[1].weekly.level and grouped[2].keystone.level==left[2].keystone.level)
local prefixA,prefixB=observation("a"),observation("a-b")
assert(P.MergeSources({prefixB,prefixA})[1].sourceId=="a")

local db=M.Init({sourceId="local-target"})
assert(S.Import(db,payload(db,{a,b}))) -- exactly the Core initialization order: before P:Init
assert(S.status=="ready" and #S.receivedProgress[S.Key(a)]==2)
assert(db.progress==nil and next(db.characters)==nil)
P:Init(db)
local data=P:Get(a)
if H.C.Retail() then
    assert(data.keystone.status=="known" and data.keystone.level==2 and data.weekly.level==13)
    assert(next(db.progress.characters)==nil) -- foreign observations are never re-exportable local measurements
    data.keystone.level=100; data.vault.rows.raid.slots[1].progress=100
    assert(P:Get(a).keystone.level==2 and P:Get(a).vault.rows.raid.slots[1].progress==8)
    P.now=EPOCH+3601; assert(P:Get(a).weekly.expired and P:Get(a).vault.rows.dungeon.status=="stale")
    local future=M.Init({sourceId="local-target",progress={version=99,characters={opaque="preserved"}}})
    P:Init(future)
    assert(P:Get(a).keystone.level==2 and future.progress.characters.opaque=="preserved" and P.store==nil)
    local before=P.now; P:Tick(5); assert(P.now==before+5)
else
    assert(not data.supported and db.progress==nil)
end

local invalid=payload(db,{a,bad})
assert(not S.Import(db,invalid) and next(db.characters)==nil and #db.visibility==0)
assert(not S.Import(db,payload(db,nil)))
assert(not S.Import(db,payload(db,{a},3)))
local legacy=payload(db,nil,3); assert(S.Import(db,legacy) and next(S.receivedProgress)==nil)
for _,version in ipairs({1,2}) do
    legacy.formatVersion=version; legacy.sources[db.sourceId].visibility=nil
    assert(S.Import(db,legacy) and next(S.receivedProgress)==nil)
end
assert(S.Import(db,nil) and next(S.receivedProgress)==nil)

-- Version 4 must carry the existing visibility contract unchanged, and reject
-- an invalid progress family before adopting an otherwise valid removal.
local controlled=payload(db,{a})
local scope=controlled.sources[db.sourceId]
scope.observations={{sourceId=a.sourceId,region=a.region,flavor=a.flavor,guid=a.guid,
    name="Synthetic",realm="Test Realm",class="MAGE",level=80,seconds=100,updatedAt=EPOCH}}
scope.visibility={{sourceId=a.sourceId,region=a.region,flavor=a.flavor,guid=a.guid,
    removed={["writer-one"]=1},restored={}}}
scope.progressObservations={bad}
assert(not S.Import(db,controlled) and #db.visibility==0)
scope.progressObservations={a}
assert(S.Import(db,controlled) and H.V.IsRemoved(db,a) and next(S.Display(db).characters)==nil)
assert(next(S.Display(db,nil,true).characters)~=nil and S.receivedProgress[S.Key(a)]~=nil)
scope.visibility[1].restored["writer-one"]=1
assert(S.Import(db,controlled) and not H.V.IsRemoved(db,a) and next(S.Display(db).characters)~=nil)

if H.C.Retail() then
    -- Real collector initialization cannot adopt a received week's best as a
    -- local baseline, including before the first local progress API response.
    C_DateAndTime={GetSecondsUntilWeeklyReset=function() return 3600 end}
    GetCurrentRegion=function() return 3 end
    local localDb=M.Init({sourceId="collector-local"}); T:Init(localDb); P:Init(localDb); T:Begin(false)
    local remote=observation("collector-remote")
    remote.guid,remote.region=T.record.guid,T.record.region
    assert(S.Import(localDb,payload(localDb,{remote})))
    P:Refresh()
    assert(P:Get(T.record).weekly.level==13)
    local captured=localDb.progress.characters[S.Key(T.record)]
    assert(captured and captured.sourceId==localDb.sourceId and captured.weekly==nil and captured.keystone==nil)
    P:Init(localDb)
    assert(P:Get(T.record).weekly.level==13 and localDb.progress.characters[S.Key(T.record)].weekly==nil)
end
