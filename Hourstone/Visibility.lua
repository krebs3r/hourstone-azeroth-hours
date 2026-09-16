local _, H = ...
local V, S = {}, H.S
H.V = V
V.MAX_STATES, V.MAX_ACTORS, V.MAX_REVISION = 10000, 1024, 9007199254740991
local regions = {us=true, kr=true, eu=true, tw=true, cn=true, unknown=true}
local flavors = {retail=true, mists=true, tbc=true, era=true}
local function identifier(value)
    return type(value) == "string" and #value > 0 and #value <= 128 and value:match("^[A-Za-z0-9_-]+$") ~= nil
end
local function greater(a, b)
    for i = 1, math.min(#a, #b) do
        if a:byte(i) ~= b:byte(i) then return a:byte(i) > b:byte(i) end
    end
    return #a > #b
end
local function revision(value)
    return H.M.Number(value) and value >= 1 and value <= V.MAX_REVISION and value % 1 == 0
end
function V.Valid(state)
    if type(state) ~= "table" or not identifier(state.sourceId) or not regions[state.region] or not flavors[state.flavor]
        or type(state.guid) ~= "string" or #state.guid == 0 or #state.guid > 128 or state.guid:find("[%z\1-\31\127]")
        or type(state.removed) ~= "table" or type(state.restored) ~= "table" then return false end
    local count = 0
    for actor, value in pairs(state.removed) do
        count = count + 1
        if count > V.MAX_ACTORS or not identifier(actor) or not revision(value) then return false end
    end
    for actor, value in pairs(state.restored) do
        if not identifier(actor) or not revision(value) or state.removed[actor] == nil or value > state.removed[actor] then return false end
    end
    return true
end
function V.ValidList(states)
    if type(states) ~= "table" then return false end
    local count, largest = 0, 0
    for index, state in pairs(states) do
        count = count + 1
        if count > V.MAX_STATES or type(index) ~= "number" or index < 1 or index % 1 ~= 0 or not V.Valid(state) then return false end
        largest = math.max(largest, index)
    end
    return count == largest
end
local function copy(state)
    local result = {sourceId=state.sourceId, region=state.region, flavor=state.flavor, guid=state.guid, removed={}, restored={}}
    for actor, value in pairs(state.removed) do result.removed[actor] = value end
    for actor, value in pairs(state.restored) do result.restored[actor] = value end
    return result
end
function V.Merge(a, b)
    if not V.ValidList(a) or not V.ValidList(b) then return nil end
    local keyed, keys = {}, {}
    for _, list in ipairs({a, b}) do
        for _, state in ipairs(list) do
            local key = S.Key(state)
            local result = keyed[key]
            if not result then
                result = copy(state); keyed[key] = result; keys[#keys + 1] = key
                if #keys > V.MAX_STATES then return nil end
            else
                if greater(state.sourceId, result.sourceId) then result.sourceId = state.sourceId end
                for actor, value in pairs(state.removed) do result.removed[actor] = math.max(result.removed[actor] or 0, value) end
                for actor, value in pairs(state.restored) do result.restored[actor] = math.max(result.restored[actor] or 0, value) end
                if not V.Valid(result) then return nil end
            end
        end
    end
    table.sort(keys, function(aKey, bKey) return greater(bKey, aKey) end)
    local result = {}
    for _, key in ipairs(keys) do result[#result + 1] = keyed[key] end
    return result
end
function V.Hidden(state)
    for actor, value in pairs(state.removed) do if value > (state.restored[actor] or 0) then return true end end
    return false
end
function V.Find(db, identity)
    local key = type(identity) == "string" and identity or S.Key(identity, db.sourceId)
    for _, state in ipairs(db.visibility or {}) do if S.Key(state) == key then return state end end
end
function V.IsRemoved(db, identity)
    local state = V.Find(db, identity)
    return state ~= nil and V.Hidden(state)
end
function V.Remove(db, identity)
    local existing = V.Find(db, identity)
    local state = existing and copy(existing) or {sourceId=identity.sourceId or db.sourceId, region=identity.region or "unknown",
        flavor=identity.flavor, guid=identity.guid, removed={}, restored={}}
    -- Actors are intentionally volatile. Reusing an actor from copied SavedVariables
    -- could turn a genuinely new removal into an already acknowledged operation.
    V.actor = V.actor or H.C.SourceId()
    local counter = math.max(state.removed[V.actor] or 0, state.restored[V.actor] or 0)
    if counter >= V.MAX_REVISION then return false end
    state.removed[V.actor] = counter + 1
    local merged = V.Merge(db.visibility, {state})
    if not merged then return false end
    db.visibility = merged
    return true
end
function V.Restore(db, identity)
    local existing = V.Find(db, identity)
    if not existing or not V.Hidden(existing) then return true end
    local state = copy(existing)
    for actor, value in pairs(state.removed) do state.restored[actor] = math.max(state.restored[actor] or 0, value) end
    local merged = V.Merge(db.visibility, {state})
    if not merged then return false end
    db.visibility = merged
    return true
end
function V.AdoptRegion(db, previous, identity)
    if identity.region == "unknown" or (previous.region ~= nil and previous.region ~= "unknown") then return true end
    local existing = V.Find(db, previous)
    if not existing then return true end
    local state = copy(existing)
    state.region, state.sourceId = identity.region, identity.sourceId
    -- Keep the unknown-scope control too: an older offline copy must remain hidden
    -- until that identity can also be associated with a known region.
    local merged = V.Merge(db.visibility, {state})
    if not merged then return false end
    db.visibility = merged
    return true
end
