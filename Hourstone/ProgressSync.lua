local _, H = ...
local P, S = H.P, H.S
local categories = {"dungeon", "raid", "world"}
local regions = {us=true, kr=true, eu=true, tw=true, cn=true, unknown=true}
local LIMIT = 10000
P.SYNC_LIMIT = LIMIT

local function number(value)
    return type(value)=="number" and value==value and value>=0 and value<=9007199254740991 and value%1==0
end
local function text(value, limit)
    if type(value)~="string" or #value==0 or #value>limit or value:find("[%z\1-\31\127]") then return false end
    -- Lua 5.1 has no UTF-8 library. Reject malformed byte sequences, overlong
    -- encodings and surrogate code points before text enters the shared merge.
    local index=1
    while index<=#value do
        local first=value:byte(index)
        local count=first<128 and 1 or first>=194 and first<=223 and 2
            or first>=224 and first<=239 and 3 or first>=240 and first<=244 and 4
        if not count or index+count-1>#value then return false end
        if count>1 then
            local second=value:byte(index+1)
            if second<128 or second>191 or first==224 and second<160 or first==237 and second>159
                or first==240 and second<144 or first==244 and second>143 then return false end
            for offset=2,count-1 do
                local byte=value:byte(index+offset)
                if byte<128 or byte>191 then return false end
            end
        end
        index=index+count
    end
    return true
end
local function keys(value, allowed)
    if type(value)~="table" then return false end
    for key in pairs(value) do if not allowed[key] then return false end end
    return true
end
local function stamped(value)
    return number(value.updatedAt) and number(value.resetAt) and value.resetAt>value.updatedAt
end
local function stamp(value)
    return {updatedAt=value.updatedAt,resetAt=value.resetAt}
end
local function copyKey(value)
    if not keys(value,{present=true,mapID=true,level=true,name=true,updatedAt=true,resetAt=true})
        or not stamped(value) or type(value.present)~="boolean" then return nil end
    local out=stamp(value); out.present=value.present
    if value.present then
        if not number(value.mapID) or value.mapID==0 or not number(value.level) or value.level==0
            or value.name~=nil and not text(value.name,1024) then return nil end
        out.mapID,out.level,out.name=value.mapID,value.level,value.name
    end
    return out
end
local function copyWeek(value)
    if not keys(value,{level=true,seasonID=true,updatedAt=true,resetAt=true}) or not stamped(value)
        or not number(value.level) or not number(value.seasonID) then return nil end
    local out=stamp(value); out.level,out.seasonID=value.level,value.seasonID; return out
end
local function copyRow(value)
    if not keys(value,{slots=true,updatedAt=true,resetAt=true}) or not stamped(value)
        or not keys(value.slots,{[1]=true,[2]=true,[3]=true}) then return nil end
    local out=stamp(value); out.slots={}
    for index=1,3 do
        local slot=value.slots[index]
        if not keys(slot,{progress=true,threshold=true,level=true,difficultyName=true,unlocked=true})
            or not number(slot.progress) or not number(slot.threshold) or slot.threshold==0 or not number(slot.level)
            or slot.difficultyName~=nil and not text(slot.difficultyName,1024)
            or slot.unlocked~=nil and type(slot.unlocked)~="boolean" then return nil end
        out.slots[index]={progress=slot.progress,threshold=slot.threshold,level=slot.level,
            difficultyName=slot.difficultyName,unlocked=slot.progress>=slot.threshold}
    end
    return out
end
local function normalize(value)
    if not keys(value,{sourceId=true,region=true,flavor=true,guid=true,keystone=true,weekly=true,vault=true})
        or not text(value.sourceId,128) or not value.sourceId:match("^[A-Za-z0-9_-]+$")
        or not regions[value.region] or value.flavor~="retail" or not text(value.guid,128) then return nil end
    local out={sourceId=value.sourceId,region=value.region,flavor="retail",guid=value.guid}
    if value.keystone~=nil then out.keystone=copyKey(value.keystone); if not out.keystone then return nil end end
    if value.weekly~=nil then out.weekly=copyWeek(value.weekly); if not out.weekly then return nil end end
    if value.vault~=nil then
        if not keys(value.vault,{rows=true}) or not keys(value.vault.rows,{dungeon=true,raid=true,world=true}) then return nil end
        local rows={}
        for _,category in ipairs(categories) do
            local row=value.vault.rows[category]
            if row~=nil then rows[category]=copyRow(row); if not rows[category] then return nil end end
        end
        if next(rows) then out.vault={rows=rows} end
    end
    return out
end
P.NormalizeObservation=normalize
function P.ValidObservation(value) return normalize(value)~=nil end

-- Every comparison is a total order. Never compare resetAt as a week ID or
-- use an epsilon: separate server API reads can differ by a second and an
-- approximate equivalence would make merging depend on arrival/grouping order.
local function compare(a,b)
    if a==b then return 0 end
    if type(a)=="string" then
        for index=1,math.min(#a,#b) do
            local av,bv=a:byte(index),b:byte(index)
            if av~=bv then return av>bv and 1 or -1 end
        end
        return #a>#b and 1 or -1
    end
    return a>b and 1 or -1
end
local function tuple(value,kind)
    local result={value.resetAt}
    if kind=="keystone" then
        result[2],result[3],result[4],result[5]=value.present and 1 or 0,value.mapID or 0,value.level or 0,value.name or ""
    elseif kind=="weekly" then result[2],result[3]=value.level,value.seasonID
    else
        for index=1,3 do
            local slot=value.slots[index]
            result[#result+1]=slot.progress; result[#result+1]=slot.threshold
            result[#result+1]=slot.level; result[#result+1]=slot.difficultyName or ""
        end
    end
    return result
end
local function choose(a,aSource,b,bSource,kind)
    if not a then return b,bSource end
    if not b then return a,aSource end
    local order=compare(a.updatedAt,b.updatedAt)
    if order==0 then order=compare(aSource,bSource) end
    if order==0 then
        local av,bv=tuple(a,kind),tuple(b,kind)
        for index=1,#av do order=compare(av[index],bv[index]); if order~=0 then break end end
    end
    if order<0 then return b,bSource end
    return a,aSource
end
P.ChooseProgressFamily=choose
local function row(record,category) return record.vault and record.vault.rows[category] end
local function mergeSameSource(a,b)
    if not a then return b end
    a.keystone=choose(a.keystone,a.sourceId,b.keystone,b.sourceId,"keystone")
    a.weekly=choose(a.weekly,a.sourceId,b.weekly,b.sourceId,"weekly")
    local rows={}
    for _,category in ipairs(categories) do rows[category]=choose(row(a,category),a.sourceId,row(b,category),b.sourceId,category) end
    a.vault=next(rows) and {rows=rows} or nil
    return a
end
-- This is the only merge that may be persisted/transported: all families in
-- each result still belong to one original source. Display projections below
-- can mix sources and must never be fed back into this function or exported.
function P.MergeSources(values)
    if type(values)~="table" then return nil end
    local count,largest,selected=0,0,{}
    for index,value in pairs(values) do
        count=count+1
        if count>LIMIT or not number(index) or index==0 then return nil end
        largest=math.max(largest,index)
        local record=normalize(value)
        if not record then return nil end
        local key=record.sourceId..":"..S.Key(record)
        selected[key]=mergeSameSource(selected[key],record)
    end
    if count~=largest then return nil end
    local sorted={}; for key in pairs(selected) do sorted[#sorted+1]=key end
    table.sort(sorted,function(a,b)
        local av,bv=selected[a],selected[b]
        local sourceOrder=compare(av.sourceId,bv.sourceId)
        return sourceOrder~=0 and sourceOrder<0 or sourceOrder==0 and compare(S.Key(av),S.Key(bv))<0
    end)
    local result={}; for _,key in ipairs(sorted) do result[#result+1]=selected[key] end
    return result
end
function P.IndexObservations(values)
    local result={}
    for _,value in ipairs(values) do
        local key=S.Key(value); result[key]=result[key] or {}; result[key][#result[key]+1]=value
    end
    return result
end
function P.ProjectObservations(values)
    local result,sources=nil,{}
    for _,raw in ipairs(values) do
        local value=normalize(raw)
        if value then
            if not result then result={sourceId=value.sourceId,region=value.region,flavor=value.flavor,guid=value.guid,vault={rows={}}} end
            if S.Key(value)~=S.Key(result) then return nil end
            if compare(value.sourceId,result.sourceId)>0 then result.sourceId=value.sourceId end
            result.keystone,sources.keystone=choose(result.keystone,sources.keystone,value.keystone,value.sourceId,"keystone")
            result.weekly,sources.weekly=choose(result.weekly,sources.weekly,value.weekly,value.sourceId,"weekly")
            for _,category in ipairs(categories) do
                result.vault.rows[category],sources[category]=choose(result.vault.rows[category],sources[category],row(value,category),value.sourceId,category)
            end
        end
    end
    if result and not next(result.vault.rows) then result.vault=nil end
    return result
end
function P:Projection(char)
    local key=S.Key(char,self.db.sourceId)
    if not key then return nil end
    local values={}
    local localRecord=self.store and self.store.characters[key]
    if localRecord then values[1]=localRecord end
    for _,value in ipairs(S.receivedProgress and S.receivedProgress[key] or {}) do values[#values+1]=value end
    local result=P.ProjectObservations(values)
    if result then result.vault=result.vault or {rows={}} end
    return result
end
