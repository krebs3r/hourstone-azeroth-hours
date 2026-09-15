local _, H = ...
local C = {}
H.C = C
function C.Now() return GetTime() end
function C.Epoch() return GetServerTime and GetServerTime() or time() end
function C.Retail() return WOW_PROJECT_ID == (WOW_PROJECT_MAINLINE or 1) end
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
    return getter and getter("Hourstone", "Version") or "0.1.1"
end
function C.Frame(kind, name, parent, backdrop)
    return CreateFrame(kind or "Frame", name, parent, backdrop and BackdropTemplateMixin and "BackdropTemplate" or nil)
end
function C.Lower(s) return (strlower or string.lower)(s) end
function C.Identity()
    local guid = UnitGUID("player")
    if not guid then return nil end
    local name, realm = UnitFullName("player")
    local _, class = UnitClass("player")
    return { key = C.Flavor() .. ":" .. guid, guid = guid, flavor = C.Flavor(), name = name or "?",
        realm = realm and realm ~= "" and realm or GetRealmName(), class = class or "",
        level = UnitLevel("player") }
end
function C.ClassColor(class)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return .94, .9, .8
end
