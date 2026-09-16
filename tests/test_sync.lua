local M,S,T=H.M,H.S,H.T
local currentRegion=GetCurrentRegion
for regionId,expected in pairs({[1]="us",[3]="eu",[4]="tw",[41]="us",[43]="eu",[45]="cn",[81]="us",[83]="eu",[84]="tw",[50]="unknown",[80]="unknown"}) do
    GetCurrentRegion=function() return regionId end
    assert(H.C.Region()==expected)
end
GetCurrentRegion=function() return 2 end
C_BattleNet={GetGameAccountInfoByGUID=function() return {regionID=4} end}
assert(H.C.Region()=="tw")
C_BattleNet=nil; GetCurrentRegion=currentRegion
local function observation(fields)
    local o={sourceId="source-a",region="eu",flavor="retail",guid="Player-1-ABC",name="Synthetic",
        realm="Test Realm",class="MAGE",level=80,seconds=1050,updatedAt=1010,serverSeconds=1000,serverAt=1000}
    for k,v in pairs(fields or {}) do o[k]=v end
    return o
end
local function payload(source, rows)
    return {formatVersion=1,sources={[source]={observations=rows}}}
end
local db=M.Init({version=1,sourceId="migration-source",characters={legacy={guid="Player-1-ABC",flavor="retail",
    name="Synthetic",realm="Test Realm",seconds=1234,updatedAt=2000,syncedAt=1000,serverSeconds=99,serverAt=99}}})
assert(db.version==3 and db.sourceId=="migration-source")
assert(db.characters.legacy.seconds==1234 and db.characters.legacy.serverSeconds==nil and db.characters.legacy.serverAt==nil)
assert(db.characters.legacy.region=="unknown" and db.characters.legacy.sourceId==db.sourceId)
assert(M.Init(db).sourceId==db.sourceId)
local fresh=M.Init({version="broken",sourceId="bad:id"})
assert(fresh.version==3 and fresh.sourceId:match("^hs%-"))
assert(M.Init(fresh).sourceId==fresh.sourceId)
assert(M.Init({version=4})==nil)

local a,b=observation(),observation({sourceId="source-b",seconds=1020,serverSeconds=1020,serverAt=1020,updatedAt=1020})
assert(S.Valid(a) and S.Valid(b))
assert(S.Choose(a,b)==b) -- newer authoritative answer corrects an older high estimate downward
local estimate=observation({seconds=1100,updatedAt=1030})
assert(S.Choose(a,estimate)==estimate and S.Choose(estimate,b)==b)
local fallback=observation({seconds=999999,updatedAt=999999}); fallback.serverAt=nil; fallback.serverSeconds=nil
assert(S.Choose(fallback,a)==a)
assert(S.Key(a)==S.Key(b))
local unknown=observation({region="unknown"})
assert(S.Key(unknown)~=S.Key(observation({sourceId="source-b",region="unknown"})))
assert(S.Key(a)~=S.Key(observation({region="us"})))
assert(S.Key(a)~=S.Key(observation({flavor="era"})))
for field,value in pairs({seconds=-1,updatedAt=math.huge,level=1.5,region="moon",flavor="beta",sourceId="bad:id",name=""}) do
    assert(not S.Valid(observation({[field]=value})),field)
end
assert(not S.Valid(observation({seconds=0/0})))
assert(not S.Valid(observation({seconds=999})))
assert(not S.Valid(observation({updatedAt=999})))
assert(not S.Valid(observation({name="line\nbreak"})))
assert(not S.Valid(observation({realm=string.rep("a",129)})))
local half=observation(); half.serverAt=nil; assert(not S.Valid(half))

assert(S.Import(db,payload("another-account",{b})))
assert(next(S.received)==nil) -- dataaddon visibility is gated by the current local source
assert(S.Import(db,payload(db.sourceId,{a,b,a})))
local count=0; for _ in pairs(S.received) do count=count+1 end
assert(count==1 and S.received[S.Key(b)].seconds==1020)
assert(db.characters.legacy.seconds==1234 and db.characters[S.Key(b)]==nil)
assert(not S.Import(db,{formatVersion=4,sources={}}) and next(S.received)==nil)
assert(not S.Import(db,payload(db.sourceId,{a,{}})) and next(S.received)==nil)
assert(S.Import(db,nil) and S.status=="absent")

-- The current tracker cannot pick up a received baseline, including on reload.
if H.C.Flavor():match("^project%-") then
    assert(not S.Valid(observation({flavor=H.C.Flavor()})))
    WOW_PROJECT_ID=1
end
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
local localKey=T.key
local remote=observation({sourceId="remote",region=H.C.Region(),flavor=H.C.Flavor(),guid=IDENTITY.guid,
    name=IDENTITY.name,realm=IDENTITY.realm})
-- Unknown region deliberately does not match this source. Known regions do.
GetCurrentRegion=function() return 3 end
T:UpdateIdentity(); localKey=T.key; remote.region="eu"
assert(S.Import(T.db,payload(T.db.sourceId,{remote})))
assert(T:Value(localKey,T.record)==nil and T.record.serverSeconds==nil)
local rows,stats=M.List(S.Display(T.db,function(key,row) return T:Value(key,row) end))
assert(stats.count==1 and stats.total==1050 and rows[1].key:match("^sync:"))
assert(T.record.seconds==nil) -- projection never mutates the local observation
T:Receive(100); assert(T.record.serverSeconds==100 and T.record.serverAt==EPOCH)
advance(20); T:Save()
assert(T.record.seconds==120 and T.record.serverSeconds==100 and T.record.serverAt==EPOCH-20)
rows,stats=M.List(S.Display(T.db,function(key,row) return T:Value(key,row) end))
assert(stats.total==120 and rows[1].key==T.key)
assert(S.received[S.Key(remote)].seconds==1050)
T:Init(T.db); T:Begin(true)
assert(T:Value(T.key,T.record)==120 and T.record.serverSeconds==100)
GetServerTime=nil; time=function() return EPOCH end
T:Receive(101); assert(T.record.serverSeconds==nil and T.record.serverAt==nil)

-- Filter only changes the projection and filtered total, never saved observations.
local sample={characters={a=a,b=observation({guid="Other",flavor="era",seconds=3000})}}
rows,stats=M.List(sample,nil,nil,nil,nil,nil,"era")
assert(#rows==1 and stats.count==2 and stats.total==4050 and stats.visible==3000)
