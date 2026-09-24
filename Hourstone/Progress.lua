local _, H = ...
local P, C = {}, H.C
H.P = P
P.VERSION = 1
local categories = {"dungeon", "raid", "world"}

-- API values can be unavailable (or secret during restricted gameplay). Check
-- before comparing, indexing or persisting them; one bad family must not erase
-- the other families' last trustworthy observations.
local function secret(value)
    if not issecretvalue then return false end
    local ok, result = pcall(issecretvalue, value)
    return not ok or result == true
end
local function number(value)
    return not secret(value) and type(value) == "number" and value == value
        and value >= 0 and value <= 9007199254740991 and value % 1 == 0
end
local function text(value)
    return not secret(value) and type(value) == "string" and #value > 0 and #value <= 1024
        and not value:find("[%z\1-\31\127]")
end
local function object(value) return not secret(value) and type(value) == "table" end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or secret(value) then return nil, false end
    return value, true
end
local function stamped(value)
    return object(value) and number(value.updatedAt) and number(value.resetAt) and value.resetAt > value.updatedAt
end
local function stamp(value, now, resetAt)
    value.updatedAt, value.resetAt = now, resetAt
    return value
end
local function copyKey(value)
    if not stamped(value) or secret(value.present) or type(value.present) ~= "boolean" then return nil end
    local out = {present=value.present, updatedAt=value.updatedAt, resetAt=value.resetAt}
    if value.present then
        if not number(value.mapID) or value.mapID == 0 or not number(value.level) or value.level == 0 then return nil end
        out.mapID, out.level = value.mapID, value.level
        if text(value.name) then out.name = value.name end
    end
    return out
end
local function copyWeek(value)
    if not stamped(value) or not number(value.level) or not number(value.seasonID) then return nil end
    return {level=value.level, seasonID=value.seasonID, updatedAt=value.updatedAt, resetAt=value.resetAt}
end
local function copyRow(value)
    if not stamped(value) or not object(value.slots) then return nil end
    local out = {updatedAt=value.updatedAt, resetAt=value.resetAt, slots={}}
    for index = 1, 3 do
        local slot = value.slots[index]
        if not object(slot) or not number(slot.progress) or not number(slot.threshold) or slot.threshold == 0
            or not number(slot.level) then return nil end
        local item = {progress=slot.progress, threshold=slot.threshold, level=slot.level, unlocked=slot.progress >= slot.threshold}
        if text(slot.difficultyName) then item.difficultyName = slot.difficultyName end
        out.slots[index] = item
    end
    return out
end
local function latest(a, b)
    if not b then return a end
    if not a or b.updatedAt > a.updatedAt then return b end
    return a
end
local function sanitizeRecord(value, sourceId)
    if not object(value) or not text(value.guid) or value.flavor ~= "retail" then return nil end
    local out = {guid=value.guid, region=value.region, flavor="retail", sourceId=sourceId,
        keystone=copyKey(value.keystone), weekly=copyWeek(value.weekly), vault={rows={}}}
    if type(out.region) ~= "string" then out.region = "unknown" end
    for _, category in ipairs(categories) do
        if object(value.vault) and object(value.vault.rows) then out.vault.rows[category] = copyRow(value.vault.rows[category]) end
    end
    return out
end

function P:Init(db)
    self.db, self.enabled = db, C.RetailProgress()
    self.ready, self.pending, self.wantRequest, self.delay = {}, false, false, 0
    self.vaultAfterReset = false
    self.vaultReadyAt, self.vaultResetAt = nil, nil
    self.now, self.resetAt, self.store = nil, nil, nil
    if self.frame then self.frame:UnregisterAllEvents() end
    if not self.enabled then return end
    self:ReadClock()
    if type(db.progress) ~= "table" then db.progress = {version=self.VERSION, characters={}} end
    -- A future optional cache never blocks the rest of Hourstone or gets replaced.
    if db.progress.version ~= self.VERSION then return end
    local cleaned = {}
    if type(db.progress.characters) == "table" then
        for _, value in pairs(db.progress.characters) do
            local row = sanitizeRecord(value, db.sourceId)
            if row then cleaned[H.S.Key(row, db.sourceId)] = row end
        end
    end
    db.progress.characters, self.store = cleaned, db.progress
    self.frame = self.frame or C.Frame("Frame")
    self.frame:SetScript("OnEvent", function(_, event) self:Schedule(event) end)
    for _, event in ipairs({"BAG_UPDATE_DELAYED", "CHALLENGE_MODE_MAPS_UPDATE", "CHALLENGE_MODE_COMPLETED",
        "CHALLENGE_MODE_START", "CHALLENGE_MODE_RESET", "MYTHIC_PLUS_NEW_WEEKLY_RECORD",
        "WEEKLY_REWARDS_UPDATE", "WEEKLY_REWARDS_ITEM_CHANGED"}) do
        -- Older clients/builds can lack an event even when a namespace exists.
        pcall(self.frame.RegisterEvent, self.frame, event)
    end
end

function P:RequireVaultUpdate(resetAt)
    self.vaultResetAt = math.max(self.vaultResetAt or 0, resetAt)
    self.vaultAfterReset = self.vaultReadyAt == nil or self.vaultReadyAt < self.vaultResetAt
end

function P:ReadClock()
    local now = call(GetServerTime)
    local remaining = call(C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset)
    if not number(now) then return nil end
    self.now = now
    if not number(remaining) or remaining == 0 then return nil end
    local resetAt = now + remaining
    if not number(resetAt) then return nil end
    -- Tolerate a one-second boundary between the two server-time calls.
    if self.resetAt and math.abs(resetAt - self.resetAt) <= 2 then resetAt = self.resetAt end
    if self.resetAt and resetAt > self.resetAt + 2 then
        self.ready = {}
        self:RequireVaultUpdate(self.resetAt)
    end
    self.resetAt = resetAt
    return now, resetAt
end

function P:Adopt(previous, identity)
    if not self.store or previous.region ~= nil and previous.region ~= "unknown" then return end
    if identity.region == "unknown" then return end
    local oldKey, newKey = H.S.Key(previous, self.db.sourceId), H.S.Key(identity, self.db.sourceId)
    local old, current = self.store.characters[oldKey], self.store.characters[newKey]
    if not old or oldKey == newKey then return end
    if not current then current = {vault={rows={}}}; self.store.characters[newKey] = current end
    current.guid, current.region, current.flavor, current.sourceId = identity.guid, identity.region, identity.flavor, self.db.sourceId
    current.keystone = latest(copyKey(current.keystone), copyKey(old.keystone))
    current.weekly = latest(copyWeek(current.weekly), copyWeek(old.weekly))
    current.vault = current.vault or {rows={}}
    current.vault.rows = current.vault.rows or {}
    for _, category in ipairs(categories) do
        local value = old.vault and old.vault.rows and copyRow(old.vault.rows[category])
        current.vault.rows[category] = latest(copyRow(current.vault.rows[category]), value)
    end
    self.store.characters[oldKey] = nil
end

function P:Schedule(reason)
    if not self.enabled or not self.store then return end
    if reason == "CHALLENGE_MODE_MAPS_UPDATE" then self.ready.maps = true
    elseif reason == "BAG_UPDATE_DELAYED" then self.ready.bags = true
    elseif reason == "WEEKLY_REWARDS_UPDATE" then
        -- The server event can arrive before the first frame update notices
        -- the rollover. Its timestamp must survive the later boundary check.
        local observedAt = call(GetServerTime)
        if number(observedAt) then self.vaultReadyAt = math.max(self.vaultReadyAt or 0, observedAt) end
        self.vaultAfterReset = self.vaultResetAt ~= nil
            and (self.vaultReadyAt == nil or self.vaultReadyAt < self.vaultResetAt)
    elseif reason ~= "WEEKLY_REWARDS_UPDATE" and reason ~= "WEEKLY_REWARDS_ITEM_CHANGED" then
        self.wantRequest = true
        if reason == "CHALLENGE_MODE_COMPLETED" or reason == "MYTHIC_PLUS_NEW_WEEKLY_RECORD" then
            self.ready.maps = nil
        end
    end
    if not self.pending then self.pending, self.delay = true, .25 end
end

-- Called by Core's existing update callback. An idle tick advances only the
-- cached clock; WoW progress APIs run once for a pending event burst, never on
-- the one-second UI refresh. A week boundary requests one fresh server answer.
function P:Tick(delta)
    if not self.enabled then return end
    if self.now then self.now = self.now + delta end
    if not self.store then return end
    if self.resetAt and self.now and self.now >= self.resetAt then
        self:RequireVaultUpdate(self.resetAt)
        self.resetAt, self.ready = nil, {}
        self:Schedule("reset")
    end
    if not self.pending then return end
    self.delay = self.delay - delta
    if self.delay > 0 then return end
    local request = self.wantRequest
    self.pending, self.wantRequest = false, false
    if request then
        call(C_MythicPlus and C_MythicPlus.RequestMapInfo)
        call(C_MythicPlus and C_MythicPlus.RequestRewards)
    end
    self:Refresh()
end

local function noKeystoneInBags()
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    local class = Enum and Enum.ItemClass and Enum.ItemClass.Reagent
    local subclass = Enum and Enum.ItemReagentSubclass and Enum.ItemReagentSubclass.Keystone
    if not C_Container or not C_Item or type(C_Item.GetItemInfoInstant) ~= "function"
        or not number(lastBag) or not number(class) or not number(subclass) then return false end
    for bag = 0, lastBag do
        local slots = call(C_Container.GetContainerNumSlots, bag)
        if not number(slots) or bag == 0 and slots == 0 then return false end
        for slot = 1, slots do
            local itemID, ok = call(C_Container.GetContainerItemID, bag, slot)
            if not ok then return false end
            if itemID ~= nil then
                if not number(itemID) or itemID == 0 then return false end
                local success, _, _, _, _, _, itemClass, itemSubclass = pcall(C_Item.GetItemInfoInstant, itemID)
                if not success or not number(itemClass) or not number(itemSubclass) then return false end
                if itemClass == class and itemSubclass == subclass then return false end
            end
        end
    end
    return true
end
local function readKey(self, now, resetAt)
    if not C_MythicPlus or not self.ready.maps or not self.ready.bags then return nil end
    local mapID, mapOK = call(C_MythicPlus.GetOwnedKeystoneChallengeMapID)
    local level, levelOK = call(C_MythicPlus.GetOwnedKeystoneLevel)
    if not mapOK or not levelOK then return nil end
    if number(mapID) and mapID > 0 and number(level) and level > 0 then
        local name = call(C_ChallengeMode and C_ChallengeMode.GetMapUIInfo, mapID)
        return stamp({present=true, mapID=mapID, level=level, name=text(name) and name or nil}, now, resetAt)
    end
    -- Both documented nullable getters must agree, after a map response and
    -- settled inventory. Confirm absence independently from fully readable
    -- bags, so a delayed or nil API cache cannot erase a still-owned key.
    if (mapID == nil and level == nil) or (mapID == 0 and level == 0) then
        local active, activeOK = call(C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive)
        if not activeOK or active ~= false then return nil end
        if noKeystoneInBags() then return stamp({present=false}, now, resetAt) end
    end
end
local function readWeek(self, now, resetAt)
    if not C_MythicPlus or not self.ready.maps then return nil end
    local season = call(C_MythicPlus.GetCurrentSeason)
    local runs = call(C_MythicPlus.GetRunHistory, false, false, true)
    if not number(season) or not object(runs) then return nil end
    local best, count, largest = 0, 0, 0
    for index, run in pairs(runs) do
        if not number(index) or index == 0 or not object(run) then return nil end
        count, largest = count + 1, math.max(largest, index)
        if secret(run.thisWeek) or secret(run.completed) or type(run.thisWeek) ~= "boolean"
            or type(run.completed) ~= "boolean" or not number(run.season) then return nil end
        if run.thisWeek and run.completed and run.season == season then
            if not number(run.level) or run.level == 0 then return nil end
            best = math.max(best, run.level)
        end
    end
    if count ~= largest then return nil end
    return stamp({level=best, seasonID=season}, now, resetAt)
end
local function readVault(self, now, resetAt)
    if not C_WeeklyRewards or self.vaultAfterReset then return nil end
    -- Retail can populate GetActivities before addon login without sending a
    -- subsequent WEEKLY_REWARDS_UPDATE. A complete, valid reward-free row is
    -- usable on login/open itself; empty/partial rows remain unknown, and the
    -- same-week monotonicity guard below preserves data against cache resets.
    -- An online week rollover is different: wait for the server's update so
    -- the previous week's still-cached activities cannot be re-stamped as new.
    local enum = Enum and Enum.WeeklyRewardChestThresholdType
    if not object(enum) then return nil end
    local mapping = {}
    for category, key in pairs({dungeon="Activities", raid="Raid", world="World"}) do
        if number(enum[key]) then mapping[enum[key]] = category end
    end
    local activities = call(C_WeeklyRewards.GetActivities)
    if not object(activities) then return nil end
    local rows, invalid = {}, {}
    for _, activity in pairs(activities) do
        if not object(activity) or not number(activity.type) then return nil end
        local category = mapping[activity.type]
        if category then
            local index = activity.index
            rows[category] = rows[category] or stamp({slots={}}, now, resetAt)
            -- GetActivities may mix last week's generated rewards with this
            -- week's progress. Only reward-free, unclaimed activity slots are
            -- unambiguously current. Never open or claim the Blizzard vault.
            local valid = number(index) and index >= 1 and index <= 3
                and number(activity.progress) and number(activity.threshold) and activity.threshold > 0
                and number(activity.level) and not secret(activity.claimID) and activity.claimID == nil
                and object(activity.rewards) and next(activity.rewards) == nil
            if not valid or rows[category].slots[index] then invalid[category] = true
            else
                local slot = {progress=activity.progress, threshold=activity.threshold, level=activity.level,
                    unlocked=activity.progress >= activity.threshold}
                if number(activity.activityTierID) then
                    local difficulty = call(C_WeeklyRewards.GetDifficultyIDForActivityTier, activity.activityTierID)
                    local name = number(difficulty) and call(GetDifficultyInfo, difficulty) or nil
                    if text(name) then slot.difficultyName = name end
                end
                rows[category].slots[index] = slot
            end
        end
    end
    for _, category in ipairs(categories) do
        if invalid[category] then rows[category] = nil else rows[category] = copyRow(rows[category]) end
    end
    return rows
end
local function collect(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok and result or nil
end
function P:Refresh()
    if not self.enabled or not self.store or not H.T or H.T.db ~= self.db or not H.T.started then return end
    local now, resetAt = self:ReadClock()
    if not now or not resetAt then return end
    if not H.T:UpdateIdentity() then return end
    local identity = H.T.record
    local key = H.S.Key(identity, self.db.sourceId)
    if not key or identity.flavor ~= "retail" then return end
    local record = self.store.characters[key]
    if not record then
        record = {guid=identity.guid, region=identity.region, flavor=identity.flavor, sourceId=self.db.sourceId, vault={rows={}}}
        self.store.characters[key] = record
    end
    local keystone = collect(readKey, self, now, resetAt)
    if keystone and (not record.keystone or now >= record.keystone.updatedAt) then
        if keystone.present and not keystone.name and record.keystone and record.keystone.mapID == keystone.mapID then
            keystone.name = record.keystone.name
        end
        record.keystone = keystone
    end
    local weekly = collect(readWeek, self, now, resetAt)
    if weekly and (not record.weekly or now >= record.weekly.updatedAt) then
        local previous = record.weekly
        -- Server caches can briefly regress during a refresh. A completed run
        -- cannot disappear within the same week and season.
        if not previous or previous.resetAt <= now or previous.seasonID ~= weekly.seasonID or weekly.level >= previous.level then
            record.weekly = weekly
        end
    end
    -- Derive the barrier from the saved character observations as well. This
    -- survives /reload (and offline resets) without adding a global flag that
    -- could incorrectly suppress a different character's first observation.
    for _, category in ipairs(categories) do
        local previous = record.vault.rows[category]
        if previous and previous.resetAt <= now then self:RequireVaultUpdate(previous.resetAt) end
    end
    local vault = collect(readVault, self, now, resetAt)
    if vault then
        for _, category in ipairs(categories) do
            local row, previous = vault[category], record.vault.rows[category]
            if row and (not previous or now >= previous.updatedAt) then
                local regressed = false
                if previous and previous.resetAt > now then
                    for index = 1, 3 do
                        local old, new = previous.slots[index], row.slots[index]
                        if old.threshold == new.threshold and (new.progress < old.progress or new.level < old.level) then regressed = true end
                    end
                end
                if not regressed then record.vault.rows[category] = row end
            end
        end
    end
end

local function status(value, now)
    if not value then return "unknown" end
    if not now or now < value.updatedAt or now >= value.resetAt then return "stale" end
    return "known"
end
function P:Get(char)
    local supported = self.enabled == true and type(char) == "table" and char.flavor == "retail"
    local empty = supported and "unknown" or "unavailable"
    local result = {supported=supported, keystone={status=empty, expired=false}, weekly={status=empty, expired=false}, vault={status=empty, rows={}}}
    local key = supported and H.S.Key(char, self.db.sourceId) or nil
    local record = key and self:Projection(char)
    if record then
        result.keystone = copyKey(record.keystone) or result.keystone
        result.weekly = copyWeek(record.weekly) or result.weekly
        result.keystone.status = status(record.keystone, self.now)
        result.weekly.status = status(record.weekly, self.now)
        result.keystone.expired = record.keystone ~= nil and self.now ~= nil and self.now >= record.keystone.resetAt
        result.weekly.expired = record.weekly ~= nil and self.now ~= nil and self.now >= record.weekly.resetAt
    end
    local known, stale = 0, false
    for _, category in ipairs(categories) do
        local row = record and copyRow(record.vault.rows[category])
        local group = row or {slots={}}
        group.status = row and status(row, self.now) or empty
        group.expired = row ~= nil and self.now ~= nil and self.now >= row.resetAt
        result.vault.rows[category] = group
        if row then
            result.vault.updatedAt = math.max(result.vault.updatedAt or 0, row.updatedAt)
            result.vault.resetAt = math.min(result.vault.resetAt or math.huge, row.resetAt)
            if group.status == "known" then known = known + 1 else stale = true end
        end
    end
    if stale then result.vault.status = "stale" elseif known == 3 then result.vault.status = "known" end
    return result
end
