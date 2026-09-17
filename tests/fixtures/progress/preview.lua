-- Fictional data for the real Lua UI renderer, not live game observations.
local db = HourstoneDB
db.characters = {}
H.P.store.characters = {}
H.P.now = EPOCH
local examples = {
    {"Ardoran","WARRIOR","Example Realm A","Dawnwatch",12,13,{4,2,0}},
    {"Elarion","MAGE","Example Realm B","Dawnwatch",8,10,{1,0,4}},
    {"Elyndra","DRUID","Example Realm A","Evening Watch",10,12,{8,4,2}},
    {"Solira","PRIEST","Example Realm C","",0,0,{0,2,8}},
    {"Thalorin","PALADIN","Example Realm B","Evening Watch",nil,nil,nil},
    {"Vaelith","DEMONHUNTER","Example Realm D","Dawnwatch",9,11,{4,0,0},true},
    {"Zareon","HUNTER","Example Realm D","Dawnwatch",6,8,{1,0,2}},
    {"Zorath","ROGUE","Example Realm B","Evening Watch",7,9,{4,0,0}},
}
for i, example in ipairs(examples) do
    local char = {name=example[1],class=example[2],realm=example[3],guild=example[4],guildUpdatedAt=EPOCH,
        region="eu",flavor="retail",guid="Player-1-SYNTHETIC-"..i,sourceId=db.sourceId,
        level=90,seconds=500000-i*10000,updatedAt=EPOCH}
    local key=H.S.Key(char,db.sourceId)
    db.characters[key]=char
    if i==1 then H.T.key=key; H.T.record=char; H.T.base=char.seconds end
    local updatedAt, resetAt = EPOCH, EPOCH+3600
    if example[8] then updatedAt,resetAt=EPOCH-7200,EPOCH-3600 end
    local progress={guid=char.guid,region=char.region,flavor=char.flavor,sourceId=db.sourceId,vault={rows={}}}
    if example[5] then
        progress.keystone={present=example[5]>0,mapID=399,
            name=H.de and "Rubinlebensbecken" or "Ruby Life Pools",level=example[5],updatedAt=updatedAt,resetAt=resetAt}
        progress.weekly={level=example[6],seasonID=1,updatedAt=updatedAt,resetAt=resetAt}
        for j,category in ipairs({"dungeon","raid","world"}) do
            local thresholds=category=="dungeon" and {1,4,8} or {2,4,8}
            local row={updatedAt=updatedAt,resetAt=resetAt,slots={}}
            for slot=1,3 do
                row.slots[slot]={progress=example[7][j],threshold=thresholds[slot],
                    level=category=="dungeon" and example[6] or 0}
            end
            progress.vault.rows[category]=row
        end
    end
    H.P.store.characters[key]=progress
end
H.UI.flavor="retail"
