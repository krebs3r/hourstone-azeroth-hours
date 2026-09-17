local _, H = ...
local T, C, M = {}, H.C, H.M
H.T = T
function T:Init(db)
    self.db, self.started, self.wantSync, self.pendingInitialLogin, self.pendingReload = db, false, false, false, false
end
function T:UpdateIdentity(level)
    local identity = C.Identity(self.db.sourceId)
    if not identity then return false end
    self.key = identity.key
    local record = self.db.characters[self.key]
    -- Adopt only an existing local observation when its previously unknown region
    -- becomes available. Imported observations are never in db.characters.
    if type(record) ~= "table" then record = nil end
    for key, candidate in pairs(self.db.characters) do
        if key ~= self.key and type(candidate) == "table" and candidate.guid == identity.guid and candidate.flavor == identity.flavor
            and (candidate.region == nil or candidate.region == "unknown" or candidate.region == identity.region) then
            if not H.V.AdoptRegion(self.db, candidate, identity) then return false end
            if H.P and H.P.db == self.db then H.P:Adopt(candidate, identity) end
            record = H.S.Choose(record, candidate); self.db.characters[key] = nil
            if type(self.db.runtime) == "table" and self.db.runtime.key == key then self.db.runtime.key = self.key end
        end
    end
    if type(record) ~= "table" then record = {} end
    self.db.characters[self.key] = record
    for k, v in pairs(identity) do if k ~= "key" then record[k] = v end end
    if M.Number(level) then record.level = level end
    self.record = record
    return true
end
function T:Begin(isReload, isInitialLogin)
    if self.started then return end
    if isInitialLogin == true then self.pendingInitialLogin = true end
    if isReload == true then self.pendingReload = true end
    if not self:UpdateIdentity() then return end
    local now, saved = C.Now(), self.db.runtime
    local carry, gap = 0, 0
    -- Only the client's explicit reload flag may restore a session. Never use wall-clock
    -- time to infer that a new login is a continuation of the previous session.
    if self.pendingReload and type(saved) == "table" and saved.key == self.key and M.Number(saved.at)
        and now >= saved.at and M.Number(saved.session) then
        carry, gap = saved.session, now - saved.at
    end
    self.sessionBase, self.sessionAt = carry + gap, now
    self.base = M.Number(self.record.seconds) and (self.record.seconds + gap) or nil
    self.baseAt, self.started = now, true
    self.db.runtime = nil
    if self.pendingInitialLogin then H.V.Restore(self.db, self.record) end
    self.pendingInitialLogin, self.pendingReload = false, false
    self:UpdateGuild(false)
    self:Request()
end
function T:UpdateGuild(allowAbsent)
    if not self.started or not self.record then return false end
    local guild, stamp = C.Guild(allowAbsent), C.ServerEpoch()
    if guild == nil or not H.S.ValidGuild(guild, stamp) then return false end
    -- A fresh local API result can replace an earlier sample in the same server
    -- second. Ordinal guild ties apply only when merging independent observations.
    if H.S.KnownGuild(self.record) and stamp < self.record.guildUpdatedAt then return false end
    local changed = self.record.guild ~= guild or self.record.guildUpdatedAt ~= stamp
    self.record.guild, self.record.guildUpdatedAt = guild, stamp
    return changed
end
function T:Value(key, record)
    if self.started and key == self.key then
        if self.base == nil then return nil end
        return self.base + math.max(0, C.Now() - self.baseAt)
    end
    return M.Number(record.seconds) and record.seconds or nil
end
function T:Session()
    if not self.started then return 0 end
    return self.sessionBase + math.max(0, C.Now() - self.sessionAt)
end
function T:Request()
    self.wantSync = true
    return self:TryRequest()
end
function T:TryRequest()
    if not self.started or not self.wantSync then return false end
    local now = C.Epoch()
    if M.Number(self.db.lastRequest) and now - self.db.lastRequest < 60 then return false end
    self.db.lastRequest = now
    RequestTimePlayed()
    return true
end
function T:Receive(total)
    if not self.started or not M.Number(total) then return false end
    -- A server answer is a replacement baseline, including answers to manual /played.
    self.base, self.baseAt, self.wantSync = total, C.Now(), false
    local serverAt = C.ServerEpoch()
    if not M.Number(serverAt) then serverAt = nil end
    self.record.seconds, self.record.updatedAt = total, C.Epoch()
    self.record.serverSeconds, self.record.serverAt = M.Number(serverAt) and total or nil, serverAt
    self.record.syncedAt = nil
    return true
end
function T:Save()
    if not self.started then return end
    self:UpdateIdentity()
    self:UpdateGuild(true)
    local total = self:Value(self.key, self.record)
    if total then self.record.seconds, self.record.updatedAt = total, C.Epoch() end
    self.db.runtime = { key = self.key, at = C.Now(), session = self:Session() }
end
