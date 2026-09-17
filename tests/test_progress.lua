local P,T,S,M = H.P,H.T,H.S,H.M
local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key,item in pairs(value) do out[key] = clone(item) end; return out
end
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
if not H.C.Retail() then
    assert(not P:Get(T.record).supported and P:Get(T.record).vault.status=="unavailable")
    assert(HourstoneDB.progress==nil and not P.frame)
    P:Schedule("open"); tick(1)
    assert(HourstoneDB.progress==nil)
    -- Exercise the data contract in every scenario runtime as well as the
    -- unsupported-client early return above.
    WOW_PROJECT_ID=WOW_PROJECT_MAINLINE
end
local reads, mapRequests, rewardRequests = 0,0,0
local mapID, keyLevel, season, active = 399,12,42,false
local nextReset = EPOCH+604800
local names = {[399]="Rubinlebensbecken",[400]="Ein extrem langer lokalisierter Dungeonname | mit Zeichen"}
local runs = {
    {thisWeek=true,completed=true,season=42,level=12},
    {thisWeek=true,completed=true,season=42,level=13,durationSec=99999}, -- overtime still completed
    {thisWeek=true,completed=false,season=42,level=99},
    {thisWeek=false,completed=true,season=42,level=98},
    {thisWeek=true,completed=true,season=41,level=97},
}
local function read(value) reads=reads+1; return value end
Enum={WeeklyRewardChestThresholdType={Activities=1,Raid=3,World=6},ItemClass={Reagent=5},ItemReagentSubclass={Keystone=1}}
local function activities(progress)
    local out={}
    -- Deliberately shuffled categories and slots, with nonstandard thresholds.
    for _,category in ipairs({6,1,3}) do
        for _,index in ipairs({3,1,2}) do
            out[#out+1]={type=category,index=index,progress=progress or 4,threshold=({1,4,9})[index],
                level=({13,12,0})[index],activityTierID=100+category,rewards={}}
        end
    end
    return out
end
local vault={}
C_DateAndTime={GetSecondsUntilWeeklyReset=function() return read(nextReset-EPOCH) end}
C_MythicPlus={
    GetOwnedKeystoneChallengeMapID=function() return read(mapID) end,
    GetOwnedKeystoneLevel=function() return read(keyLevel) end,
    GetOwnedKeystoneMapID=function() error("Normal map IDs must never be used for keystones") end,
    GetCurrentSeason=function() return read(season) end,
    GetRunHistory=function(previous,incomplete,current) assert(previous==false and incomplete==false and current==true); return read(runs) end,
    RequestMapInfo=function() mapRequests=mapRequests+1 end,
    RequestRewards=function() rewardRequests=rewardRequests+1 end,
}
C_ChallengeMode={GetMapUIInfo=function(id) return read(names[id]) end,IsChallengeModeActive=function() return read(active) end}
C_WeeklyRewards={GetActivities=function() return read(vault) end,
    GetDifficultyIDForActivityTier=function(tier) return read(tier) end,
    OnUIInteract=function() error("A read-only tracker must never open/claim the vault") end}
GetDifficultyInfo=function(id) return read("Difficulty "..id) end
local bagItem, itemReady = true,true
NUM_TOTAL_EQUIPPED_BAG_SLOTS=5
C_Container={GetContainerNumSlots=function(bag) return read(bag==0 and 2 or 0) end,
    GetContainerItemID=function(bag,slot) return read(bag==0 and slot==1 and bagItem and 12345 or nil) end}
C_Item={GetItemInfoInstant=function(id) reads=reads+1; if itemReady then return id,"Reagent","Keystone","",0,5,1 end end}
local db=M.Init({sourceId="progress-source"})
GetCurrentRegion=function() return 3 end
T:Init(db); P:Init(db); T:Begin(false); H.UI.db=db
P:Schedule("login"); P:Tick(.5)
assert(mapRequests==1 and rewardRequests==1)
assert(P:Get(T.record).keystone.status=="unknown" and P:Get(T.record).weekly.status=="unknown")
assert(P:Get(T.record).vault.status=="unknown") -- an empty cache is not nine locked slots
-- Native Retail can return complete activities without sending a new vault
-- event on login/open. The valid cache is sufficient; no event gate is needed.
vault=activities()
P:Schedule("open"); P:Tick(.5)
assert(P:Get(T.record).vault.status=="known" and P:Get(T.record).vault.rows.world.slots[1].progress==4)
assert(db.version==3 and S.FORMAT==3 and db.progress.version==1)
local function update(...)
    advance(1)
    for _,event in ipairs({...}) do fire(event) end
    P:Tick(.5)
end
update("CHALLENGE_MODE_MAPS_UPDATE","WEEKLY_REWARDS_UPDATE","BAG_UPDATE_DELAYED")
local key, char = T.key,T.record
local data=P:Get(char)
assert(data.supported and data.keystone.status=="known" and data.keystone.present)
assert(data.keystone.mapID==399 and data.keystone.name==names[399] and data.keystone.level==12)
assert(data.weekly.level==13 and data.weekly.status=="known")
assert(data.vault.status=="known")
assert(not data.keystone.expired and not data.weekly.expired and not data.vault.rows.dungeon.expired)
local savedClock=P.now
P.now=nil
assert(P:Get(char).weekly.status=="stale" and not P:Get(char).weekly.expired)
assert(P:Get(char).vault.rows.dungeon.status=="stale" and not P:Get(char).vault.rows.dungeon.expired)
P.now=data.weekly.updatedAt-1
assert(P:Get(char).keystone.status=="stale" and not P:Get(char).keystone.expired)
P.now=savedClock
for _,category in ipairs({"dungeon","raid","world"}) do
    local row=data.vault.rows[category]
    assert(row.status=="known" and row.slots[1].unlocked and row.slots[2].unlocked and not row.slots[3].unlocked)
    assert(row.slots[3].threshold==9 and row.slots[3].progress==4 and row.slots[2].level==12)
    assert(row.slots[1].difficultyName~=nil)
end
-- Get is a detached, read-only projection, including when a companion import
-- won the displayed playtime observation for this same known-region identity.
local beforeReads=reads
for i=1,20 do P:Get(char) end
assert(reads==beforeReads)
data.vault.rows.dungeon.slots[1].progress=999; data.keystone.level=999
assert(P:Get(char).keystone.level==12 and P:Get(char).vault.rows.dungeon.slots[1].progress==4)
T:Receive(100)
local remote=clone(T.record); remote.sourceId="remote"; remote.seconds=999; remote.serverSeconds=999
remote.updatedAt=EPOCH+10; remote.serverAt=EPOCH+10
assert(S.Import(db,{formatVersion=3,sources={[db.sourceId]={observations={remote},visibility={}}}}))
local projected=S.Display(db).characters["sync:"..key]
assert(projected.seconds==999 and P:Get(projected).weekly.level==13)
assert(H.V.Remove(db,char) and P:Get(char).keystone.level==12)
assert(H.V.Restore(db,char) and P:Get(char).keystone.level==12)
-- Idle updates and UI reads do not query the progression APIs.
beforeReads=reads
for i=1,20 do advance(1); P:Tick(1); P:Get(char) end
assert(reads==beforeReads)
local oldRequests=mapRequests
for i=1,25 do P:Schedule("open") end
P:Tick(.1); assert(mapRequests==oldRequests)
P:Tick(.2); assert(mapRequests==oldRequests+1 and rewardRequests==mapRequests)

-- Key changes use ChallengeMap IDs; an unavailable localized name does not
-- discard a known map/level and later resolves without an addon-maintained list.
mapID,keyLevel=400,14
update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.name==names[400] and P:Get(char).keystone.level==14)
names[400]=nil; keyLevel=15; update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.level==15 and P:Get(char).keystone.name~=nil)
mapID=401; update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.mapID==401 and P:Get(char).keystone.name==nil)
names[401]="New Dungeon"; update("CHALLENGE_MODE_MAPS_UPDATE")
assert(P:Get(char).keystone.name=="New Dungeon")
mapID,keyLevel=nil,nil
update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.present) -- nil cache while a key still exists in bags
bagItem=false; active=true; update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.present) -- consumed/slotted key during a dungeon
active=false; update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.present==false and P:Get(char).keystone.status=="known")
mapID,keyLevel=399,12; bagItem=true; update("BAG_UPDATE_DELAYED")
mapID,keyLevel=nil,nil; itemReady=false; update("BAG_UPDATE_DELAYED")
assert(P:Get(char).keystone.present) -- incomplete item cache is not empty inventory
itemReady=true; mapID,keyLevel=399,12

-- Whole-family and per-field secrets, malformed and throwing APIs preserve
-- independently valid prior values; a transient zero cache cannot regress.
local secretValue={}
issecretvalue=function(value) return value==secretValue end
mapID=secretValue; runs=secretValue; vault=secretValue
update("BAG_UPDATE_DELAYED","WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).keystone.level==12 and P:Get(char).weekly.level==13 and P:Get(char).vault.rows.raid.slots[1].progress==4)
mapID=399; runs={{thisWeek=true,completed=secretValue,season=42,level=90}}; vault=activities()
vault[1].progress=secretValue
update("WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).weekly.level==13 and P:Get(char).vault.rows.world.slots[3].progress==4)
runs={}; vault=activities(0)
for _,slot in ipairs(vault) do slot.level=0 end
P:Schedule("open"); P:Tick(.5)
assert(P:Get(char).weekly.level==13 and P:Get(char).vault.rows.dungeon.slots[1].progress==4)
local originalGetter=C_MythicPlus.GetOwnedKeystoneLevel
C_MythicPlus.GetOwnedKeystoneLevel=function() error("API not available in this context") end
update("BAG_UPDATE_DELAYED"); assert(P:Get(char).keystone.level==12)
C_MythicPlus.GetOwnedKeystoneLevel=originalGetter

-- A complete category can update independently; incomplete rows, duplicates
-- and generated/claimable rewards never overwrite current progress.
vault=activities(6); vault[1].rewards={{id=123,itemDBID=123}}
update("WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).vault.rows.world.slots[1].progress==4 and P:Get(char).vault.rows.raid.slots[1].progress==6)
vault=activities(7); vault[4].claimID=100
update("WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).vault.rows.dungeon.slots[1].progress==6 and P:Get(char).vault.rows.world.slots[1].progress==7)
vault=activities(8); table.remove(vault,9)
update("WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).vault.rows.raid.slots[1].progress==7 and P:Get(char).vault.rows.dungeon.slots[1].progress==8)
vault=activities(9); vault[#vault+1]=clone(vault[1])
update("WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).vault.rows.world.slots[1].progress==8 and P:Get(char).vault.rows.raid.slots[1].progress==9)

-- Reset marks offline characters stale immediately, makes one request while
-- online, and waits for new data-ready events before accepting empty values.
local offline=clone(char); offline.guid="Player-1-OFFLINE"
db.progress.characters[S.Key(offline)]=clone(db.progress.characters[key])
db.progress.characters[S.Key(offline)].guid=offline.guid
local originalReset=nextReset
local jump=nextReset-EPOCH+1
advance(jump); nextReset=nextReset+604800
oldRequests=mapRequests; P:Tick(jump)
assert(mapRequests==oldRequests+1)
assert(P:Get(char).keystone.status=="stale" and P:Get(char).weekly.status=="stale")
assert(P:Get(char).vault.status=="stale") -- old live cache cannot be re-stamped at rollover
assert(P:Get(char).keystone.expired and P:Get(char).weekly.expired and P:Get(offline).vault.rows.dungeon.expired)
assert(P:Get(offline).vault.status=="stale")
P:Tick(10); assert(mapRequests==oldRequests+1)
-- A reload must not remove the barrier and stamp the still-cached nine old
-- activities into the new week. Derive it from this character's saved rows.
P:Init(db); P:Schedule("login"); P:Tick(.5)
assert(P:Get(char).vault.status=="stale" and P:Get(char).vault.rows.dungeon.slots[1].progress==9)
mapID,keyLevel=nil,nil; bagItem=false; runs={}; vault=activities(0)
for _,slot in ipairs(vault) do slot.level=0 end
update("CHALLENGE_MODE_MAPS_UPDATE","BAG_UPDATE_DELAYED","WEEKLY_REWARDS_UPDATE")
assert(P:Get(char).keystone.present==false and P:Get(char).weekly.level==0 and P:Get(char).weekly.status=="known")
assert(P:Get(char).vault.rows.world.slots[1].progress==0 and P:Get(char).vault.status=="known")
assert(P:Get(offline).weekly.status=="stale" and P:Get(offline).weekly.resetAt==originalReset)
-- Reverse the order: the next week's fresh event arrives before Tick has
-- noticed the reset. The later clock check must preserve that confirmation.
vault=activities(7); update("WEEKLY_REWARDS_UPDATE")
jump=nextReset-EPOCH+1
advance(jump); nextReset=nextReset+604800
vault=activities(0); for _,slot in ipairs(vault) do slot.level=0 end
fire("WEEKLY_REWARDS_UPDATE")
P:Tick(jump)
assert(P:Get(char).vault.status=="known" and P:Get(char).vault.rows.dungeon.slots[1].progress==0)
-- A new season is independent of the prior season's best, without fixed IDs.
season=43; runs={{thisWeek=true,completed=true,season=42,level=99},{thisWeek=true,completed=true,season=43,level=2}}
update("CHALLENGE_MODE_MAPS_UPDATE")
assert(P:Get(char).weekly.level==2)

-- Reload retains the local cache; no region knowledge is invented. A later
-- region correction adopts all families together with the existing identity.
P:Init(db); assert(P:Get(char).weekly.level==2 and P:Get(offline).weekly.status=="stale")
GetCurrentRegion=function() return 0 end
local unknownDB=M.Init({sourceId="unknown-source"})
T:Init(unknownDB); P:Init(unknownDB); T:Begin(false)
local unknownKey=T.key
mapID,keyLevel=399,12; bagItem=true; vault=activities()
update("CHALLENGE_MODE_MAPS_UPDATE","BAG_UPDATE_DELAYED","WEEKLY_REWARDS_UPDATE")
assert(unknownDB.progress.characters[unknownKey] and P:Get(T.record).weekly.level==2)
assert(H.V.Remove(unknownDB,T.record))
GetCurrentRegion=function() return 3 end
assert(T:UpdateIdentity())
assert(unknownDB.progress.characters[unknownKey]==nil and unknownDB.progress.characters[T.key])
assert(P:Get(T.record).keystone.level==12 and H.V.IsRemoved(unknownDB,T.record))
local wrongRegion=clone(T.record); wrongRegion.region="us"
assert(P:Get(wrongRegion).weekly.status=="unknown")
local classic=clone(T.record); classic.flavor="era"
assert(not P:Get(classic).supported and P:Get(classic).vault.rows.raid.status=="unavailable")
-- Invalid optional cache entries cannot crash projection or mutate the main
-- schema. A future cache version remains untouched for its owning version.
local corrupted=clone(unknownDB)
corrupted.progress.characters[T.key].keystone.level=-1
corrupted.progress.characters[T.key].vault.rows.world.slots[2].threshold=0
P:Init(corrupted)
assert(P:Get(T.record).keystone.status=="unknown" and P:Get(T.record).vault.rows.world.status=="unknown")
local future=M.Init({sourceId="future-progress",progress={version=99,characters={opaque="keep"}}})
P:Init(future); P:Schedule("open"); beforeReads=reads; P:Tick(10)
assert(future.version==3 and future.progress.version==99 and future.progress.characters.opaque=="keep" and reads==beforeReads)
