local V,S,M,T = H.V,H.S,H.M,H.T
local function clone(value)
    if type(value) ~= "table" then return value end
    local result={}; for key,item in pairs(value) do result[key]=clone(item) end; return result
end
local function state(source, region, removed, restored)
    return {sourceId=source or "source-a",region=region or "eu",flavor="retail",guid="Player-1-VIS",removed=removed or {},restored=restored or {}}
end
local function hidden(db,identity) return V.IsRemoved(db,identity) end
local a=state(nil,nil,{actorA=1})
local restored=state("source-z",nil,{actorA=1},{actorA=1})
local concurrent=state(nil,nil,{actorB=1})
assert(V.Valid(a) and V.Hidden(a) and not V.Hidden(restored))
local merged=V.Merge({a},{restored,concurrent})
assert(#merged==1 and merged[1].sourceId=="source-z" and V.Hidden(merged[1]))
assert(a.restored.actorA==nil and restored.removed.actorB==nil) -- immutable input
local again=V.Merge(merged,merged)
assert(again[1].removed.actorA==1 and again[1].removed.actorB==1 and again[1].restored.actorA==1)
assert(not V.Hidden(V.Merge({restored},{a})[1])) -- stale removal cannot undo restore
assert(#V.Merge({state("a","unknown")},{state("b","unknown")})==2)
assert(not V.Valid(state(nil,nil,{}, {actorA=1})))
assert(not V.Valid(state(nil,nil,{actorA=1}, {actorA=0})))
assert(not V.Valid(state(nil,nil,{actorA=1}, {actorA=2})))
for _,bad in ipairs({0,-1,.5,math.huge,9007199254740992}) do assert(not V.Valid(state(nil,nil,{actorA=bad}))) end
assert(not V.Valid(state(nil,nil,{actorA=0/0})))
assert(not V.Valid(state(nil,nil,{["bad:actor"]=1})))
assert(not V.ValidList({[2]=a}) and not V.ValidList({x=a}))
local capped=state()
for i=1,V.MAX_ACTORS do capped.removed["actor"..i]=1 end
assert(V.Valid(capped)); capped.removed.overflow=1; assert(not V.Valid(capped))
capped.removed.overflow=nil
assert(V.Merge({capped},{state(nil,nil,{newActor=1})})==nil)
local db=M.Init({version=2,sourceId="cloned-source",characters={legacy={seconds=123,guild="Guild",guildUpdatedAt=1}}})
assert(db.version==3 and #db.visibility==0 and db.characters.legacy.seconds==123 and db.characters.legacy.guild=="Guild")
assert(M.Init({version=2,visibility={}})==nil and M.Init({version=3})==nil)
assert(M.Init({version=3,visibility={a}}))
V.actor="first-runtime"; assert(V.Remove(db,a)); assert(hidden(db,a))
assert(V.Restore(db,a)); assert(not hidden(db,a)); assert(V.Find(db,a).restored[V.actor]==1)
assert(V.Remove(db,a)); assert(V.Find(db,a).removed[V.actor]==2 and hidden(db,a))
assert(V.Restore(db,a)); V.actor="second-runtime" -- copied sourceId cannot reuse an acknowledged operation
assert(V.Remove(db,a)); assert(V.Find(db,a).removed["second-runtime"]==1 and hidden(db,a))
assert(V.Find(db,a).restored["first-runtime"]==2)
V.actor="limit-actor"; local limit=state(nil,nil,{[V.actor]=V.MAX_REVISION})
db.visibility={limit}; assert(not V.Remove(db,a) and db.visibility[1]==limit)

-- Controls merge atomically with the complete selected payload, while observations stay local.
local obs={sourceId=db.sourceId,region="eu",flavor="retail",guid=a.guid,name="Example",realm="Realm",class="MAGE",level=1,seconds=123,updatedAt=2}
db.characters={[S.Key(obs)]=obs}; db.visibility={}
local function payload(format, controls, observations)
    return {formatVersion=format,sources={[db.sourceId]={observations=observations or {},visibility=controls}}}
end
assert(not S.Import(db,payload(1,{a})) and #db.visibility==0)
assert(not S.Import(db,payload(2,{a})) and #db.visibility==0)
assert(not S.Import(db,payload(3,nil)))
assert(not S.Import(db,payload(3,{a},{{name="invalid"}})) and #db.visibility==0)
assert(S.Import(db,payload(3,{a},{obs})))
assert(next(S.Display(db).characters)==nil and next(S.Display(db,nil,true).characters)~=nil)
assert(db.characters[S.Key(obs)]==obs and obs.seconds==123)
assert(V.Restore(db,obs)); assert(S.Import(db,payload(3,{a})))
assert(next(S.Display(db).characters)~=nil) -- old full snapshot cannot remove again
assert(S.Import(db,payload(2,nil,{obs}))) -- legacy readers remain supported

-- Only an explicitly confirmed actual login restores; delayed GUID keeps that exact intent.
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
fire("TIME_PLAYED_MSG",10000,0); db=T.db
-- Test project 999 is intentionally unsupported by the synchronization identity contract.
if T.record.flavor ~= "project-999" then
    V.actor="login-test"; assert(V.Remove(db,T.record)); local key=T.key
    local before=T:Value(key,T.record); advance(4); T:Save()
    assert(hidden(db,T.record) and db.characters[key].seconds==before+4)
    fire("TIME_PLAYED_MSG",12000,0); fire("PLAYER_ENTERING_WORLD",false,false)
    assert(hidden(db,T.record))
    T:Init(db); fire("PLAYER_ENTERING_WORLD",false,true); assert(hidden(db,T.record))
    T:Init(db); fire("PLAYER_ENTERING_WORLD",true,false); assert(not hidden(db,T.record))
    assert(T.record.seconds==12000)
    assert(V.Remove(db,T.record)); T:Save()
    local guid=IDENTITY.guid; IDENTITY.guid=nil; T:Init(db)
    fire("PLAYER_ENTERING_WORLD",false,true); assert(not T.started)
    IDENTITY.guid=guid; fire("PLAYER_ENTERING_WORLD",false,false)
    assert(T.started and hidden(db,T.record))
    IDENTITY.guid=nil; T:Init(db); fire("PLAYER_ENTERING_WORLD",true,false)
    IDENTITY.guid=guid; fire("PLAYER_ENTERING_WORLD",false,false)
    assert(T.started and not hidden(db,T.record))
    -- A removal not observed at that login remains hidden until a subsequent actual login.
    local remote=clone(V.Find(db,T.record)); remote.removed.offlineActor=1
    assert(S.Import(db,payload(3,{remote})))
    fire("PLAYER_ENTERING_WORLD",false,false); assert(hidden(db,T.record))
    T:Init(db); fire("PLAYER_ENTERING_WORLD",true,false); assert(not hidden(db,T.record))

    -- Unknown region adoption carries controls without an implicit restore on reload.
    local previous=clone(T.record); previous.region="unknown"; previous.sourceId=db.sourceId
    db.characters={[S.Key(previous)]=previous}; db.visibility={}
    assert(V.Remove(db,previous)); local oldRegion=H.C.Region; H.C.Region=function() return "eu" end
    T:Init(db); fire("PLAYER_ENTERING_WORLD",false,true)
    assert(T.record.region=="eu" and hidden(db,T.record) and hidden(db,previous))

    -- Right click requires confirmation. Removed view never contributes to overview cards.
    T:Init(db); fire("PLAYER_ENTERING_WORLD",true,false)
    local ui=H.UI; ui:Toggle(); ui:Refresh()
    assert(ui.rows[1].entry and ui.count.text=="1")
    local data=T.record; local seconds=data.seconds
    ui.rows[1]:Click("RightButton"); assert(ui.removeDialog:IsShown() and not hidden(db,data))
    ui.removeCancel:Click(); assert(not hidden(db,data))
    ui.rows[1]:Click("RightButton"); ui.removeConfirm:Click()
    assert(hidden(db,data) and ui.count.text=="0" and next(S.Display(db).characters)==nil)
    ui:ToggleSettings(); ui.removedToggle:Click()
    assert(ui.removedOnly and ui.rows[1].entry and ui.count.text=="0")
    assert(ui.realms.text=="· "..string.format(H.L.realms,0) and ui.overviewStats.total==0)
    assert(ui.headers.name.button.label.text:find(H.L.removedCharacters,1,true))
    ui.rows[1]:Click("RightButton")
    assert(not hidden(db,data) and ui.count.text=="1" and not ui.rows[1]:IsShown())
    assert(data.seconds==seconds)
    H.C.Region=oldRegion
end
