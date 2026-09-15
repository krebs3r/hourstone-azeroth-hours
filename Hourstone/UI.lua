local _, H = ...
local U, C, M, T, L = {}, H.C, H.M, H.T, H.L
H.UI = U
local ROOT = "Interface\\AddOns\\Hourstone\\Media\\"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD, MUTED = { .91, .77, .43 }, { .64, .68, .68 }

local function text(parent, value, size, x, y, width, color)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont(FONT, size or 12, "")
    f:SetPoint("TOPLEFT", x or 0, y or 0)
    if width then f:SetWidth(width) end
    f:SetJustifyH("LEFT"); f:SetWordWrap(false)
    f:SetTextColor(unpack(color or { .94, .91, .84 }))
    f:SetText(value or "")
    return f
end
local function solid(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetColorTexture(r, g, b, a or 1)
    return texture
end
local function box(parent, r, g, b, a)
    local bg = solid(parent, "BACKGROUND", r or .07, g or .085, b or .09, a or .97)
    bg:SetAllPoints()
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = solid(parent, "BORDER", .34, .32, .25, .9)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetHeight(1); line:SetPoint(edge .. "LEFT"); line:SetPoint(edge .. "RIGHT")
        else
            line:SetWidth(1); line:SetPoint("TOP" .. edge); line:SetPoint("BOTTOM" .. edge)
        end
    end
end
local function button(parent, label, x, y, width, action)
    local b = C.Frame("Button", nil, parent)
    b:SetPoint("TOPLEFT", x, y); b:SetSize(width, 26)
    box(b)
    b.label = text(b, label, 12, 7, -7, width - 14)
    b.label:SetJustifyH("CENTER")
    local highlight = solid(b, "HIGHLIGHT", .8, .65, .25, .14); highlight:SetAllPoints()
    b:SetScript("OnClick", action)
    return b
end
local function artButton(parent, art, x, action)
    local b = C.Frame("Button", nil, parent)
    b:SetPoint("TOPRIGHT", x, -17); b:SetSize(28, 28)
    b:SetNormalTexture(ROOT .. art .. ".tga")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", action)
    return b
end
local function panel(frame)
    local retail = C.Retail()
    local uv = retail and { 2/512, 510/512, 120/512, 391/512 } or { 2/512, 510/512, 118/512, 393/512 }
    local sourceW, sourceH = retail and 711 or 710, retail and 379 or 384
    local sourceCorner, corner = retail and 23 or 52, retail and 10 or 14
    local du, dv = (uv[2]-uv[1])*sourceCorner/sourceW, (uv[4]-uv[3])*sourceCorner/sourceH
    local xs, ys = { uv[1], uv[1]+du, uv[2]-du, uv[2] }, { uv[3], uv[3]+dv, uv[4]-dv, uv[4] }
    local widths, heights = {corner, frame:GetWidth()-2*corner, corner}, {corner, frame:GetHeight()-2*corner, corner}
    local lefts, tops = {0, corner, frame:GetWidth()-corner}, {0, corner, frame:GetHeight()-corner}
    for row = 1, 3 do for col = 1, 3 do
        local t = frame:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(ROOT .. (retail and "RetailPanel" or "ClassicPanel") .. ".tga")
        t:SetTexCoord(xs[col], xs[col+1], ys[row], ys[row+1])
        t:SetSize(widths[col], heights[row]); t:SetPoint("TOPLEFT",lefts[col],-tops[row])
    end end
end
local function tooltip(owner, lines)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    for _, line in ipairs(lines) do GameTooltip:AddLine(line, .94, .91, .84, true) end
    GameTooltip:Show()
end
function U:ApplyScale()
    local screenLimit = math.min(UIParent:GetWidth()/960, UIParent:GetHeight()/640)
    self.frame:SetScale(math.max(.4, math.min(self.db.settings.scale, screenLimit)))
end
function U:Position(reset)
    local f, p = self.frame, self.db.settings.position
    f:ClearAllPoints()
    if not reset and p then f:SetPoint("CENTER", UIParent, "CENTER", p.x, p.y)
    else f:SetPoint("CENTER"); self.db.settings.position = nil end
end
function U:SavePosition()
    local x, y = self.frame:GetCenter()
    local px, py = UIParent:GetCenter()
    local ratio = self.frame:GetScale()
    self.db.settings.position = { x = x - px / ratio, y = y - py / ratio }
end
function U:ToggleSettings()
    self:Create()
    self.menu:Hide()
    if self.settings:IsShown() then self.settings:Hide() else self.settings:Show(); self:SettingsText() end
end
function U:SettingsText()
    local s = self.db.settings
    self.minimapToggle.label:SetText(L.minimap .. ": " .. (s.minimap and L.on or L.off))
    self.densityToggle.label:SetText(L.density .. ": " .. (s.compact and L.compact or L.comfortable))
    self.scaleLabel:SetText(L.scale .. ": " .. math.floor(s.scale * 100 + .5) .. "%")
end
function U:SetFormat(mode)
    self.db.settings.format = mode
    self:Refresh()
end
function U:Create()
    if self.frame then return end
    local f = C.Frame("Frame", "HourstoneWindow", UIParent)
    self.frame = f
    f:SetSize(940, 620); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true); f:Hide()
    panel(f)
    self:ApplyScale(); self:Position()
    UISpecialFrames[#UISpecialFrames+1] = "HourstoneWindow"
    local drag = C.Frame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 14, -10); drag:SetSize(795, 60); drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing(); self:SavePosition() end)
    local logo = drag:CreateTexture(nil, "ARTWORK"); logo:SetTexture(ROOT.."Logo.tga"); logo:SetSize(48,48); logo:SetPoint("LEFT", 6, 0)
    text(drag, "Hourstone", 23, 66, -7, 168, GOLD)
    text(drag, "– Azeroth Hours", 18, 238, -11, 310, GOLD)
    text(drag, L.tagline, 11, 67, -36, 470, MUTED)
    artButton(f, "HeaderClose", -16, function() f:Hide() end)
    artButton(f, "HeaderHide", -47, function() f:Hide() end)
    local gear = artButton(f, "HeaderClose", -82, function() self:ToggleSettings() end)
    gear:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY")
    gear:GetNormalTexture():SetVertexColor(unpack(GOLD))
    local line = solid(f, "BORDER", .55,.53,.43,.65); line:SetPoint("TOPLEFT",18,-75); line:SetSize(904,1)
    text(f, L.total, 11, 25, -94, 400, MUTED)
    self.total = text(f, "", 22, 25, -113, 404, GOLD)
    self.totalNote = text(f, L.allTracked, 10, 25, -143, 410, MUTED)
    text(f, L.characters, 11, 463, -94, 160, MUTED)
    self.count = text(f, "0", 24, 463, -113, 130, GOLD)
    self.realms = text(f, "", 10, 463, -143, 165, MUTED)
    text(f, L.session, 11, 668, -94, 236, MUTED)
    self.session = text(f, "", 19, 668, -116, 238, GOLD)
    self.current = text(f, "", 10, 668, -143, 238, MUTED)

    local search = C.Frame("EditBox", nil, f); self.search = search
    search:SetPoint("TOPLEFT", 22, -172); search:SetSize(306, 28); search:SetFont(FONT,12,"")
    search:SetAutoFocus(false); search:SetMaxLetters(80); search:SetTextInsets(9,9,0,0); box(search)
    search.hint = text(search,L.search,12,9,-8,284,MUTED)
    search:SetScript("OnTextChanged", function(edit)
        edit.hint:SetShown(edit:GetText() == "")
        self.searchText, self.offset = edit:GetText(), 0; self:Refresh()
    end)
    search:SetScript("OnEscapePressed", function(edit) edit:ClearFocus(); f:Hide() end)
    search:SetScript("OnEnterPressed", function(edit) edit:ClearFocus() end)
    self.realmButton = button(f, L.allRealms .. "  v", 338, -173, 230, function() self:ToggleRealms() end)
    self.combined = button(f, L.combined, 644, -173, 143, function() self:SetFormat("combined") end)
    self.hours = button(f, L.hours, 794, -173, 123, function() self:SetFormat("hours") end)

    self.sort, self.descending, self.offset = "seconds", true, 0
    self.headers = {}
    local columns = { {"name",L.character,22,228}, {"level",L.level,250,64}, {"realm",L.realm,318,176},
        {"seconds",L.played,502,228}, {"updatedAt",L.updated,738,162} }
    for _, col in ipairs(columns) do
        local field, title = col[1], col[2]
        local b = button(f,title,col[3],-211,col[4],function()
            if self.sort == field then self.descending = not self.descending
            else self.sort, self.descending = field, field == "seconds" or field == "level" or field == "updatedAt" end
            self.offset = 0; self:Refresh()
        end)
        b.label:SetJustifyH("LEFT"); self.headers[field] = {button=b,title=title}
    end
    local list = C.Frame("Frame", nil, f); self.list = list
    list:SetPoint("TOPLEFT",22,-241); list:SetSize(878,312); list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel",function(_,delta) self:Scroll(-delta*3) end)
    self.rows = {}
    for i=1,10 do
        local row = C.Frame("Button",nil,list); self.rows[i] = row
        row:SetWidth(878)
        row.bg = solid(row,"BACKGROUND",.06,.09,.1,.35); row.bg:SetAllPoints()
        row.active = solid(row,"ARTWORK",.28,.78,.96,1); row.active:SetWidth(2); row.active:SetPoint("TOPLEFT"); row.active:SetPoint("BOTTOMLEFT")
        row.name = text(row,"",13,9,-12,214)
        row.level = text(row,"",12,239,-12,45)
        row.realm = text(row,"",12,304,-12,169,MUTED)
        row.played = text(row,"",12,489,-12,220)
        row.updated = text(row,"",11,725,-12,146,MUTED)
        row:SetScript("OnEnter",function(owner) self:RowTooltip(owner) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    self.empty = text(list,L.empty,13,10,-40,850,MUTED); self.empty:SetJustifyH("CENTER")
    self.scroll = C.Frame("Slider",nil,f)
    self.scroll:SetPoint("TOPRIGHT",-18,-243); self.scroll:SetSize(12,308)
    self.scroll:SetOrientation("VERTICAL"); self.scroll:SetMinMaxValues(0,0); self.scroll:SetValueStep(1)
    if self.scroll.SetObeyStepOnDrag then self.scroll:SetObeyStepOnDrag(true) end
    box(self.scroll)
    self.scroll:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    self.scroll:GetThumbTexture():SetSize(8,28); self.scroll:GetThumbTexture():SetVertexColor(.58,.5,.31,.8)
    self.scroll:SetScript("OnValueChanged",function(_,v)
        if not self.refreshing then self.offset = math.floor(v+.5); self:Refresh() end
    end)
    self.footer = text(f,"",11,25,-568,670,MUTED)
    text(f,"v"..C.Version().."  |  by krebs3r",10,740,-569,177,MUTED):SetJustifyH("RIGHT")
    text(f,L.hint,10,25,-595,875,MUTED)

    local menu = C.Frame("Frame",nil,f); self.menu = menu
    menu:SetPoint("TOPLEFT",338,-202); menu:SetSize(230,260); menu:SetFrameLevel(f:GetFrameLevel()+30); box(menu); menu:Hide()
    menu:EnableMouse(true); menu:EnableMouseWheel(true); self.realmOffset = 0; self.realmRows = {}
    for i=1,8 do
        local b = button(menu,"",5,-5-(i-1)*31,220,function(owner)
            self.realm, self.offset = owner.realm, 0; menu:Hide(); self:Refresh()
        end)
        self.realmRows[i] = b
    end
    menu:SetScript("OnMouseWheel",function(_,delta)
        self.realmOffset = math.max(0,math.min(math.max(0,#self.realmChoices-8),self.realmOffset-delta*3)); self:RenderRealms()
    end)
    local settings = C.Frame("Frame",nil,f); self.settings = settings
    settings:SetPoint("TOPRIGHT",-18,-56); settings:SetSize(302,255); settings:SetFrameLevel(f:GetFrameLevel()+35); box(settings); settings:EnableMouse(true); settings:Hide()
    text(settings,L.settings,16,16,-16,267,GOLD)
    self.minimapToggle = button(settings,"",16,-50,270,function()
        self.db.settings.minimap = not self.db.settings.minimap; self:UpdateMinimap(); self:SettingsText()
    end)
    self.densityToggle = button(settings,"",16,-84,270,function()
        self.db.settings.compact = not self.db.settings.compact; self.offset = 0; self:Refresh(); self:SettingsText()
    end)
    self.scaleLabel = text(settings,"",12,16,-126,206)
    button(settings,"−",208,-117,35,function() self.db.settings.scale = math.max(.65,self.db.settings.scale-.05); self:ApplyScale(); self:SettingsText() end)
    button(settings,"+",250,-117,35,function() self.db.settings.scale = math.min(1.3,self.db.settings.scale+.05); self:ApplyScale(); self:SettingsText() end)
    button(settings,L.reset,16,-158,270,function() self:Position(true) end)
    button(settings,L.done,164,-212,122,function() settings:Hide() end)
    f:SetScript("OnHide",function() search:ClearFocus(); menu:Hide(); settings:Hide(); GameTooltip:Hide() end)
end
function U:ToggleRealms()
    self.settings:Hide()
    if self.menu:IsShown() then self.menu:Hide(); return end
    self.realmChoices = {{label=L.allRealms}}
    for _, name in ipairs(self.stats.realms) do self.realmChoices[#self.realmChoices+1] = {label=name,realm=name} end
    self.realmOffset = 0; self:RenderRealms(); self.menu:Show()
end
function U:RenderRealms()
    for i,b in ipairs(self.realmRows) do
        local entry = self.realmChoices[i+self.realmOffset]
        b:SetShown(entry ~= nil)
        if entry then b.realm = entry.realm; b.label:SetText(entry.label) end
    end
    self.menu:SetHeight(math.min(8,#self.realmChoices)*31+8)
end
function U:Scroll(delta)
    self.offset = math.max(0,math.min(self.maxOffset or 0,self.offset+delta)); self:Refresh()
end
function U:RowTooltip(row)
    local entry = row.entry
    if not entry then return end
    local char = entry.char
    local lines = {char.name.." · "..char.realm, L.level.." "..tostring(char.level or "?"),
        string.format(L.fullTime,M.Format(T:Value(entry.key,char),self.db.settings.format))}
    if entry.key == T.key then
        lines[#lines+1] = L.active
        lines[#lines+1] = T.base and L.estimate or L.noSync
    else lines[#lines+1] = L.known end
    if M.Number(char.syncedAt) then lines[#lines+1] = string.format(L.sync,date("%Y-%m-%d %H:%M",char.syncedAt)) end
    tooltip(row,lines)
end
function U:Refresh()
    if not self.frame then return end
    self.refreshing = true
    local mode, compact = self.db.settings.format, self.db.settings.compact
    local entries, stats = M.List(self.db,self.searchText,self.realm,self.sort,self.descending,function(key,char) return T:Value(key,char) end)
    self.stats = stats
    self.total:SetText(stats.count > 0 and stats.missing == stats.count and L.unavailable or M.Format(stats.total,mode))
    self.totalNote:SetText(L.allTracked .. (stats.missing > 0 and string.format(L.partial,stats.missing) or ""))
    self.count:SetText(tostring(stats.count)); self.realms:SetText(string.format(L.realms,#stats.realms))
    self.session:SetText(M.Format(T:Session(),"combined"))
    self.current:SetText(T.record and T.record.name.." · "..T.record.realm or "")
    self.realmButton.label:SetText((self.realm or L.allRealms).."  v")
    self.combined.label:SetTextColor(unpack(mode == "combined" and GOLD or MUTED))
    self.hours.label:SetTextColor(unpack(mode == "hours" and GOLD or MUTED))
    for field, header in pairs(self.headers) do
        header.button.label:SetText(header.title .. (self.sort == field and (self.descending and "  v" or "  ^") or ""))
        header.button.label:SetTextColor(unpack(self.sort == field and GOLD or MUTED))
    end
    local capacity, height = compact and 10 or 8, compact and 31 or 39
    self.maxOffset = math.max(0,#entries-capacity); self.offset = math.min(self.offset,self.maxOffset)
    self.scroll:SetMinMaxValues(0,self.maxOffset); self.scroll:SetValue(self.offset); self.scroll:SetShown(self.maxOffset > 0)
    for i,row in ipairs(self.rows) do
        local entry = i <= capacity and entries[i+self.offset] or nil
        row.entry = entry; row:SetShown(entry ~= nil)
        if entry then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*height); row:SetHeight(height-1)
            local char, active = entry.char, entry.key == T.key
            row.active:SetShown(active)
            row.bg:SetColorTexture(active and .1 or .06, active and .2 or .09, active and .25 or .1,active and .7 or (i%2==0 and .6 or .28))
            row.name:SetText(char.name); row.name:SetTextColor(C.ClassColor(char.class))
            row.level:SetText(M.Number(char.level) and tostring(char.level) or "?")
            row.realm:SetText(char.realm); row.played:SetText(M.Format(entry.seconds,mode))
            row.updated:SetText(active and entry.seconds and L.now or M.Age(char.updatedAt))
            for _, field in ipairs({"name","level","realm","played","updated"}) do
                local label = row[field]; local _,_,_,x = label:GetPoint(1)
                label:ClearAllPoints(); label:SetPoint("TOPLEFT",x,compact and -8 or -12)
            end
        end
    end
    self.empty:SetShown(#entries==0)
    if self.realm or (self.searchText and self.searchText ~= "") then
        self.footer:SetText(string.format(L.visible,#entries,stats.count,M.SumText(stats.visible,stats.visibleMissing,#entries,mode)))
    else self.footer:SetText(L.commands) end
    self.refreshing = false
end
function U:Toggle()
    self:Create()
    if self.frame:IsShown() then self.frame:Hide()
    else self.frame:Show(); T:Request(); self:Refresh() end
end
function U:UpdateMinimap()
    if not self.minimap then return end
    self.minimap:SetShown(self.db.settings.minimap)
    local angle = math.rad(self.db.settings.minimapAngle)
    local radius = Minimap:GetWidth()/2 + 7
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end
function U:Init(db)
    self.db = db
    if not Minimap then return end
    local b = C.Frame("Button","HourstoneMinimapButton",Minimap); self.minimap = b
    b:SetSize(32,32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    local bg = b:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); bg:SetAllPoints()
    local icon = b:CreateTexture(nil,"ARTWORK"); icon:SetTexture(ROOT.."Logo.tga"); icon:SetSize(29,29); icon:SetPoint("CENTER")
    local border = b:CreateTexture(nil,"OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(54,54); border:SetPoint("TOPLEFT",-1,1)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp"); b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function() if not b.suppressUntil or C.Now() >= b.suppressUntil then self:Toggle() end end)
    b:SetScript("OnEnter",function() tooltip(b,{"Hourstone – Azeroth Hours",L.open,L.move,L.commands}) end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart",function()
        GameTooltip:Hide()
        b:SetScript("OnUpdate",function()
            local x,y = GetCursorPosition(); local mx,my = Minimap:GetCenter(); local scale = Minimap:GetEffectiveScale()
            self.db.settings.minimapAngle = math.deg(math.atan2(y/scale-my,x/scale-mx))%360
            self:UpdateMinimap()
        end)
    end)
    b:SetScript("OnDragStop",function() b:SetScript("OnUpdate",nil); b.suppressUntil = C.Now()+.15 end)
    self:UpdateMinimap()
end
