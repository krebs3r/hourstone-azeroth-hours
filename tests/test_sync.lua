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
assert(not S.Import(db,{formatVersion=5,sources={}}) and next(S.received)==nil)
assert(not S.Import(db,payload(db.sourceId,{a,{}})) and next(S.received)==nil)
assert(S.Import(db,nil) and S.status=="absent")

-- Protocol 4 addendum: the Companion lists the sources whose observations come from WoW: Forever.
local function scoped(list,rows)
    return {formatVersion=4,sources={[db.sourceId]={observations=rows,visibility={},progressObservations={},foreverSources=list}}}
end
local forever=observation({sourceId="forever-source",guid="Player-1-FOR"})
local function listed() return S.Import(db,scoped({"forever-source","unused-source"},{b,forever})) and S.status=="ready" end
assert(listed() and S.receivedForever["forever-source"] and S.receivedForever["unused-source"])
local shown=S.Display(db).characters
assert(M.Client(shown["sync:"..S.Key(forever)])=="forever" and M.Client(shown["sync:"..S.Key(b)])=="retail")
assert(M.ClientText(shown["sync:"..S.Key(forever)])==H.L.forever and shown["sync:"..S.Key(forever)].flavor=="retail")
assert(S.received[S.Key(forever)].client==nil) -- the label never enters received observations
local classic=observation({sourceId="forever-source",guid="Player-1-ERA",flavor="era"})
assert(S.Import(db,scoped({"forever-source"},{classic})) and S.Display(db).characters["sync:"..S.Key(classic)].client==nil)
-- An absent list is empty, and so is an empty one.
for _,list in ipairs({false,{}}) do
    assert(S.Import(db,scoped(list or nil,{b,forever})) and S.status=="ready" and next(S.receivedForever)==nil)
    assert(M.Client(S.Display(db).characters["sync:"..S.Key(forever)])=="retail")
end
-- A malformed list rejects the payload like any other invalid field and clears earlier data.
local limit=S.FOREVER_LIMIT
for name,list in pairs({text="forever-source",number=1,keyed={["forever-source"]=true},entry={1},nested={{"forever-source"}},
    duplicate={"forever-source","forever-source"},gap={[1]="forever-source",[3]="unused-source"},zero={[0]="forever-source"},
    fraction={[1.5]="forever-source"},invalid={"bad id"},empty={""},long={string.rep("a",129)},control={"a\0b"},
    limit={"forever-source","unused-source","third-source"}}) do
    assert(listed(),name); S.FOREVER_LIMIT=name=="limit" and 2 or limit
    assert(not S.Import(db,scoped(list,{b,forever})) and S.status=="invalid",name)
    assert(next(S.received)==nil and next(S.receivedForever)==nil,name)
    S.FOREVER_LIMIT=limit
end
assert(listed() and S.Import(db,scoped({string.rep("a",128)},{b})))
-- Formats 1–3 have no list; a rejected, incompatible, foreign or absent payload resets it.
assert(listed() and not S.Import(db,{formatVersion=3,sources={[db.sourceId]={observations={b},visibility={},foreverSources={}}}}))
assert(S.status=="invalid" and next(S.receivedForever)==nil)
assert(listed() and not S.Import(db,{formatVersion=5,sources={}}) and next(S.receivedForever)==nil)
assert(listed() and S.Import(db,scoped({"forever-source"},{b,{}})) == false and next(S.receivedForever)==nil)
assert(listed() and S.Import(db,payload("another-account",{b})) and next(S.receivedForever)==nil)
assert(listed() and S.Import(db,nil) and S.status=="absent" and next(S.receivedForever)==nil)
-- This database's own record of a character decides; the list labels only characters it has not recorded.
local copy=M.Init({sourceId="copy-source",characters={own={sourceId="copy-source",region="eu",flavor="retail",guid="Player-1-FOR",
    name="Synthetic",realm="Test Realm",class="MAGE",level=80,seconds=900,updatedAt=900}}})
assert(S.Import(copy,{formatVersion=4,sources={["copy-source"]={observations={forever},visibility={},progressObservations={},foreverSources={"forever-source"}}}}))
local function client(target) local _,row=next(S.Display(target).characters); return M.Client(row) end
assert(client(copy)=="retail")
copy.characters.own.client="forever"; assert(client(copy)=="forever")
assert(S.Import(db,nil))

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
