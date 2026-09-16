local _, H = ...
local S, M = {}, H.M
H.S = S
S.FORMAT = 3
local flavors = {retail=true, mists=true, tbc=true, era=true}
local regions = {us=true, kr=true, eu=true, tw=true, cn=true, unknown=true}
local fields = {"sourceId", "region", "flavor", "guid", "name", "realm", "class", "level",
    "seconds", "updatedAt", "serverSeconds", "serverAt", "guild", "guildUpdatedAt"}
local function number(value)
    return M.Number(value) and value <= 9007199254740991
end
local function text(value, limit)
    return type(value) == "string" and #value > 0 and #value <= limit and not value:find("[%z\1-\31\127]")
end
function S.ValidGuild(guild, updatedAt)
    if guild == nil and updatedAt == nil then return true end
    return type(guild) == "string" and #guild <= 128 and not guild:find("[%z\1-\31\127]") and number(updatedAt)
end
function S.KnownGuild(o)
    return type(o) == "table" and o.guild ~= nil and S.ValidGuild(o.guild, o.guildUpdatedAt)
end
function S.Valid(observation)
    if type(observation) ~= "table" then return false end
    local o = observation
    if not text(o.sourceId, 128) or not o.sourceId:match("^[A-Za-z0-9_-]+$")
        or not regions[o.region] or not flavors[o.flavor] or not text(o.guid, 128)
        or not text(o.name, 128) or not text(o.realm, 128) or not text(o.class, 32)
        or not number(o.level) or o.level % 1 ~= 0 or o.level > 1000
        or not number(o.seconds) or not number(o.updatedAt)
        or not S.ValidGuild(o.guild, o.guildUpdatedAt) then return false end
    if o.serverAt ~= nil or o.serverSeconds ~= nil then
        if not number(o.serverAt) or not number(o.serverSeconds)
            or o.seconds < o.serverSeconds or o.updatedAt < o.serverAt then return false end
    end
    return true
end
function S.Key(o, sourceId)
    if type(o.guid) ~= "string" or type(o.flavor) ~= "string" then return nil end
    local region = regions[o.region] and o.region or "unknown"
    local scope = region == "unknown" and (region .. ":" .. (o.sourceId or sourceId or "local")) or region
    return scope .. ":" .. o.flavor .. ":" .. o.guid
end
local function confirmed(o)
    return number(o.serverAt) and number(o.serverSeconds)
end
local function greater(a, b)
    if type(a) ~= "string" then return a > b end
    -- Lua's native string order may use the process locale. Compare bytes
    -- explicitly so localized Windows installations select the same record.
    for i = 1, math.min(#a, #b) do
        local av, bv = a:byte(i), b:byte(i)
        if av ~= bv then return av > bv end
    end
    return #a > #b
end
-- The playtime observation wins as a whole. Estimates never detach from their baseline.
-- All ties use the same ordinal ordering as the companion contract.
local function choosePlaytime(a, b)
    if not a then return b end
    if not b then return a end
    local ac, bc = confirmed(a), confirmed(b)
    if ac ~= bc then return bc and b or a end
    local order = ac and {"serverAt", "serverSeconds", "updatedAt", "seconds", "sourceId", "name", "realm", "class", "level"}
        or {"updatedAt", "seconds", "sourceId", "name", "realm", "class", "level"}
    for _, field in ipairs(order) do
        local av, bv = a[field], b[field]
        if av == nil then av = type(bv) == "string" and "" or -1 end
        if bv == nil then bv = type(av) == "string" and "" or -1 end
        if type(av) ~= type(bv) then av, bv = tostring(av), tostring(bv) end
        if av ~= bv then return greater(bv, av) and b or a end
    end
    return a
end
function S.GuildChoice(a, b)
    if not S.KnownGuild(a) then return S.KnownGuild(b) and b or nil end
    if not S.KnownGuild(b) then return a end
    if a.guildUpdatedAt ~= b.guildUpdatedAt then return a.guildUpdatedAt > b.guildUpdatedAt and a or b end
    return greater(b.guild, a.guild) and b or a
end
function S.Choose(a, b)
    local winner = choosePlaytime(a, b)
    if not winner then return nil, nil end
    local guild = S.GuildChoice(a, b)
    if not guild or (winner.guild == guild.guild and winner.guildUpdatedAt == guild.guildUpdatedAt) then return winner, winner end
    -- A display merge must not write foreign metadata into a local observation.
    -- Retain the playtime winner's provenance, including transient _local flags.
    local merged = {}
    for key, value in pairs(winner) do merged[key] = value end
    merged.guild, merged.guildUpdatedAt = guild.guild, guild.guildUpdatedAt
    return merged, winner
end
local function copy(o)
    local result = {}
    for _, key in ipairs(fields) do result[key] = o[key] end
    return result
end
function S.Import(db, payload)
    S.received, S.status = {}, "absent"
    if payload == nil then return true end
    if type(payload) ~= "table" or (payload.formatVersion ~= 1 and payload.formatVersion ~= 2 and payload.formatVersion ~= S.FORMAT) or type(payload.sources) ~= "table" then
        S.status = "incompatible"; return false
    end
    local scope = payload.sources[db.sourceId]
    if scope == nil then return true end
    if type(scope) ~= "table" or type(scope.observations) ~= "table" then S.status = "invalid"; return false end
    if (payload.formatVersion < 3 and scope.visibility ~= nil)
        or (payload.formatVersion == 3 and not H.V.ValidList(scope.visibility)) then S.status = "invalid"; return false end
    local visibility = H.V.Merge(db.visibility, payload.formatVersion == 3 and scope.visibility or {})
    if not visibility then S.status = "invalid"; return false end
    local imported, count = {}, 0
    for index, o in pairs(scope.observations) do
        count = count + 1
        if count > 20000 or type(index) ~= "number" or index < 1 or index % 1 ~= 0 or not S.Valid(o)
            or (payload.formatVersion == 1 and (o.guild ~= nil or o.guildUpdatedAt ~= nil)) then
            S.status = "invalid"; return false
        end
        local key = S.Key(o)
        imported[key] = S.Choose(imported[key], copy(o))
    end
    db.visibility = visibility
    S.received, S.status = imported, "ready"
    return true
end
function S.Display(db, valueFor, removedOnly)
    local selected, originalKeys = {}, {}
    for key, o in pairs(db.characters) do
        if type(o) == "table" then
            local row = copy(o)
            row.seconds = valueFor and valueFor(key, o) or o.seconds
            if H.T.started and key == H.T.key and row.seconds ~= nil then row.updatedAt = H.C.Epoch() end
            row._local = true
            local identity = S.Key(row, db.sourceId) or key
            local chosen, winner = S.Choose(selected[identity], row)
            if winner == row then originalKeys[identity] = key end
            selected[identity] = chosen
        end
    end
    for key, o in pairs(S.received or {}) do
        local chosen, winner = S.Choose(selected[key], o)
        if winner == o then originalKeys[key] = "sync:" .. key end
        selected[key] = chosen
    end
    local characters, hidden = {}, {}
    for _, state in ipairs(db.visibility or {}) do hidden[S.Key(state)] = H.V.Hidden(state) end
    for key, row in pairs(selected) do
        if (hidden[key] == true) == (removedOnly == true) then characters[originalKeys[key] or ("sync:" .. key)] = row end
    end
    return {characters=characters}
end
