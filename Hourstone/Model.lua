local _, H = ...
local M, L = {}, H.L
H.M = M
M.SCHEMA = 2
function M.Number(value)
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end
function M.Init(db)
    if type(db) ~= "table" then db = {} end
    if M.Number(db.version) and db.version > M.SCHEMA then return nil, "future" end
    local previous = M.Number(db.version) and db.version or 1
    db.version = M.SCHEMA
    if type(db.sourceId) ~= "string" or not db.sourceId:match("^[A-Za-z0-9_-]+$") or #db.sourceId > 128 then
        db.sourceId = H.C.SourceId()
    end
    if type(db.characters) ~= "table" then db.characters = {} end
    for _, char in pairs(db.characters) do
        if type(char) == "table" then
            char.sourceId = db.sourceId
            if type(char.region) ~= "string" then char.region = "unknown" end
            if previous < 2 then
                -- Schema 1 seconds may include a saved local estimate. syncedAt
                -- cannot recover its original server value, so never invent one.
                char.serverSeconds, char.serverAt, char.syncedAt = nil, nil, nil
            end
        end
    end
    if type(db.settings) ~= "table" then db.settings = {} end
    local s = db.settings
    if s.format ~= "hours" then s.format = "combined" end
    s.scale = M.Number(s.scale) and math.max(.65, math.min(1.3, s.scale)) or 1
    s.minimap = s.minimap ~= false
    s.minimapAngle = M.Number(s.minimapAngle) and s.minimapAngle % 360 or 225
    if type(s.position) ~= "table" or not M.Number(math.abs(tonumber(s.position.x) or math.huge))
        or not M.Number(math.abs(tonumber(s.position.y) or math.huge)) then s.position = nil
    else s.position.x, s.position.y = tonumber(s.position.x), tonumber(s.position.y) end
    return db
end
function M.Format(seconds, mode)
    if not M.Number(seconds) then return L.unavailable end
    if mode == "hours" then
        local value = string.format("%.1f", seconds / 3600)
        local whole,fraction=value:match("^(%d+)%.(%d)$")
        local grouped=whole:reverse():gsub("(%d%d%d)","%1"..(H.de and "." or ",")):reverse():gsub("^[.,]","")
        value=grouped..(H.de and "," or ".")..fraction
        return value .. " " .. L.hoursUnit
    end
    local minutes = math.floor(seconds / 60)
    if not H.de then return string.format("%dd %dh %dm",math.floor(minutes/1440),math.floor(minutes/60)%24,minutes%60) end
    return string.format("%d %s %d %s %d %s", math.floor(minutes / 1440), L.daysUnit,
        math.floor(minutes / 60) % 24, L.hoursUnit, minutes % 60, L.minutesUnit)
end
function M.SessionFormat(seconds)
    if not M.Number(seconds) then return L.unavailable end
    if seconds >= 86400 then return M.Format(seconds,"combined") end
    local minutes=math.floor(seconds/60)
    if not H.de then return string.format("%dh %dm",math.floor(minutes/60),minutes%60) end
    return string.format("%d %s %d %s",math.floor(minutes/60),L.hoursUnit,minutes%60,L.minutesUnit)
end
function M.Age(epoch, now)
    if not M.Number(epoch) then return L.unavailable end
    local age = math.max(0, (now or H.C.Epoch()) - epoch)
    if age < 60 then return L.now end
    if age < 3600 then return string.format(L.minuteAgo, math.floor(age / 60)) end
    if age < 86400 then return string.format(L.hourAgo, math.floor(age / 3600)) end
    if age < 172800 then return L.yesterday end
    return string.format(L.dayAgo, math.floor(age / 86400))
end
function M.List(db, search, realm, sort, descending, valueFor, flavor)
    local rows, total, visible, missing, visibleMissing, count, realms = {}, 0, 0, 0, 0, 0, {}
    search, sort = H.C.Lower(search or ""), sort or "seconds"
    if descending == nil then descending = true end
    for key, char in pairs(db.characters) do
        if type(key) == "string" and type(char) == "table" and type(char.name) == "string" and type(char.realm) == "string" then
            count = count + 1
            realms[char.realm] = true
            local seconds = valueFor and valueFor(key, char) or char.seconds
            if not M.Number(seconds) then seconds = nil; missing = missing + 1 else total = total + seconds end
            if (not realm or char.realm == realm) and (not flavor or char.flavor == flavor)
                and H.C.Lower(char.name):find(search, 1, true) then
                rows[#rows + 1] = { key = key, char = char, seconds = seconds }
                if seconds then visible = visible + seconds else visibleMissing = visibleMissing + 1 end
            end
        end
    end
    local function field(row)
        if sort == "seconds" then return row.seconds end
        if sort == "level" or sort == "updatedAt" then
            return M.Number(row.char[sort]) and row.char[sort] or nil
        end
        return H.C.Lower(tostring(row.char[sort] or ""))
    end
    table.sort(rows, function(a, b)
        local av, bv = field(a), field(b)
        -- Unknown numeric values stay at the bottom in both sort directions.
        if av == nil and bv ~= nil then return false end
        if bv == nil and av ~= nil then return true end
        if av ~= bv then
            if descending then return av > bv end
            return av < bv
        end
        local an, bn = H.C.Lower(a.char.name), H.C.Lower(b.char.name)
        if an ~= bn then return an < bn end
        if a.char.realm ~= b.char.realm then return a.char.realm < b.char.realm end
        return a.key < b.key
    end)
    local realmList = {}
    for name in pairs(realms) do realmList[#realmList + 1] = name end
    table.sort(realmList)
    return rows, { total = total, visible = visible, missing = missing, visibleMissing = visibleMissing,
        count = count, realms = realmList }
end
function M.SumText(seconds, missing, count, mode)
    if count > 0 and missing == count then return L.unavailable end
    return M.Format(seconds, mode) .. (missing > 0 and string.format(L.partial, missing) or "")
end
