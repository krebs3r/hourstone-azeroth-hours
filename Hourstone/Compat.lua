local _, H = ...
local C = {}
H.C = C
function C.Now() return GetTime() end
function C.Epoch() return GetServerTime and GetServerTime() or time() end
-- Server timestamps alone may establish an authoritative /played baseline.
function C.ServerEpoch() return GetServerTime and GetServerTime() or nil end
-- Guild data can lag behind login. Only an explicit membership result can
-- establish absence; a missing name for a known member remains unknown.
function C.Guild(allowAbsent)
    if not IsInGuild or not GetGuildInfo then return nil end
    local member, guild = IsInGuild(), GetGuildInfo("player")
    if issecretvalue and (issecretvalue(member) or issecretvalue(guild)) then return nil end
    if member == true and type(guild) == "string" and guild ~= "" then return guild end
    if allowAbsent and member == false and (guild == nil or guild == "") then return "" end
    return nil
end
function C.Escape(value) return (tostring(value):gsub("|", "||")) end
function C.Region()
    local regions = {"us", "kr", "eu", "tw", "cn"}
    local guid = UnitGUID("player")
    local info = guid and C_BattleNet and C_BattleNet.GetGameAccountInfoByGUID and C_BattleNet.GetGameAccountInfoByGUID(guid)
    local id = type(info) == "table" and info.regionID or nil
    if not regions[id] then id = GetCurrentRegion and GetCurrentRegion() or 0 end
    -- Live Classic families have their own Cfg_Regions IDs. Test/arena regions
    -- deliberately remain unknown instead of being mistaken for a live region.
    if type(id) == "number" and id >= 41 and id <= 45 then id = id - 40 end
    if type(id) == "number" and id >= 81 and id <= 85 then id = id - 80 end
    return regions[id] or "unknown"
end
function C.SourceId()
    local parts = {}
    for i = 1, 8 do parts[i] = string.format("%04x", math.random(0, 65535)) end
    -- Include the server epoch without changing WoW's shared random seed.
    return "hs-" .. tostring(C.Epoch()) .. "-" .. table.concat(parts)
end
function C.Retail() return WOW_PROJECT_ID == (WOW_PROJECT_MAINLINE or 1) end
-- WoW: Forever runs the Retail API (project MAINLINE) under interface 16xxx.
function C.IsForever()
    if type(GetBuildInfo) ~= "function" then return false end
    local ok, _, _, _, interface = pcall(GetBuildInfo)
    return ok and type(interface) == "number" and interface >= 16000 and interface < 17000
end
-- Retail artwork only for modern Retail; Forever keeps the Classic look.
function C.RetailStyle() return C.Retail() and not C.IsForever() end
-- Keystones and the Great Vault exist only in modern Retail, not in Forever.
function C.RetailProgress() return C.Retail() and not C.IsForever() end
function C.HasAddonCompartment()
    return type(AddonCompartmentFrame) == "table" and type(AddonCompartmentFrame.RegisterAddon) == "function"
end
function C.Flavor()
    local id = WOW_PROJECT_ID
    if C.Retail() then return "retail" end
    if id == (WOW_PROJECT_CLASSIC or 2) then return "era" end
    if id == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) then return "tbc" end
    if id == (WOW_PROJECT_MISTS_CLASSIC or 19) then return "mists" end
    return "project-" .. tostring(id or "unknown")
end
function C.Version()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getter and getter("Hourstone", "Version") or "0.3.3"
end
function C.Frame(kind, name, parent, backdrop)
    return CreateFrame(kind or "Frame", name, parent, backdrop and BackdropTemplateMixin and "BackdropTemplate" or nil)
end
function C.Lower(s) return (strlower or string.lower)(s) end
function C.Identity(sourceId)
    local guid = UnitGUID("player")
    if not guid then return nil end
    local name, realm = UnitFullName("player")
    local _, class = UnitClass("player")
    local region, flavor = C.Region(), C.Flavor()
    local scope = region == "unknown" and (region .. ":" .. (sourceId or "local")) or region
    return { key = scope .. ":" .. flavor .. ":" .. guid, guid = guid, flavor = flavor, region = region,
        sourceId = sourceId, name = name or "?",
        realm = realm and realm ~= "" and realm or GetRealmName(), class = class or "",
        level = UnitLevel("player") }
end
function C.ClassColor(class)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return .94, .9, .8
end
