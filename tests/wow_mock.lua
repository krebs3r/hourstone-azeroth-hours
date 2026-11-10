-- Strict, deliberately small native-UI and event simulator. Missing APIs fail loudly.
NOW, EPOCH, REQUESTS = 1000, 1800000000, 0
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
IDENTITY = {guid="Player-1-AAA",name="Elarion",realm="Blackhand",class="MAGE",level=90}
WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_MISTS_CLASSIC = 1,2,5,19
-- Only WoW: Forever (Camelot) defines its own project constant; Retail does not.
if WOW_PROJECT_ID==18 then WOW_PROJECT_CAMELOT=18 end
function GetTime() return NOW end
function GetServerTime() return EPOCH end
function GetLocale() return TEST_LOCALE end
function GetRealmName() return IDENTITY.realm end
function UnitGUID() return IDENTITY.guid end
-- WoW: Forever (interface 16xxx) reports the character's surname in the realm slot.
function UnitFullName()
    if TEST_INTERFACE and TEST_INTERFACE >= 16000 and TEST_INTERFACE < 17000 then return IDENTITY.name, IDENTITY.surname end
    return IDENTITY.name, IDENTITY.realm
end
function UnitClass() return IDENTITY.class, IDENTITY.class end
function UnitLevel() return IDENTITY.level end
GUILD_READS = 0
function IsInGuild() return IN_GUILD end
function GetGuildInfo(unit) assert(unit == "player"); GUILD_READS=GUILD_READS+1; return GUILD_NAME end
function RequestTimePlayed() REQUESTS=REQUESTS+1 end
function GetAddOnMetadata() return TEST_VERSION end
function GetBuildInfo() return "test", "0", "Jan 1 2026", TEST_INTERFACE end
PRINTED = {}
function print(...) PRINTED[#PRINTED+1] = table.concat({tostringall(...)}, " ") end
function tostringall(...)
    local out = {}
    for i = 1, select("#", ...) do out[i] = tostring((select(i, ...))) end
    return unpack(out)
end
-- Retail's Addons menu. run.py removes it for clients without that menu.
COMPARTMENT = {}
AddonCompartmentFrame = {RegisterAddon=function(frame, info)
    assert(frame == AddonCompartmentFrame and type(info) == "table")
    COMPARTMENT[#COMPARTMENT+1] = info
end}
function GetPhysicalScreenSize() return SCREEN_WIDTH or 1920,SCREEN_HEIGHT or 1080 end
-- Blizzard_SharedXML/PixelUtil.lua on every client: UI units per physical pixel at scale 1.
PixelUtil={GetPixelToUIUnitFactor=function() local _,h=GetPhysicalScreenSize(); return 768/h end}
-- A client database color (Blizzard_SharedXMLBase/Color.lua); WoW: Forever measures #FFD200.
NORMAL_FONT_COLOR={r=1,g=210/255,b=0,a=1,GetRGB=function(self) return self.r,self.g,self.b end}
if WOW_PROJECT_ID==1 or WOW_PROJECT_ID==18 then C_AddOns={GetAddOnMetadata=GetAddOnMetadata} end
-- Atlases (C_Texture.GetAtlasInfo). The names are those Hourstone asks for; the sizes are stand-ins,
-- not the client's. A test removes names through ATLAS_MISSING to see a piece fall back.
ATLAS_MISSING = {}
local ATLAS_SIZES = {
    ["UI-Frame-Metal-CornerTopLeft"]={75,74}, ["UI-Frame-Metal-CornerTopRight"]={75,74},
    ["UI-Frame-Metal-CornerBottomLeft"]={75,74}, ["UI-Frame-Metal-CornerBottomRight"]={75,74},
    ["_UI-Frame-Metal-EdgeTop"]={32,74}, ["_UI-Frame-Metal-EdgeBottom"]={32,74},
    ["!UI-Frame-Metal-EdgeLeft"]={75,32}, ["!UI-Frame-Metal-EdgeRight"]={75,32},
    ["RedButton-Exit"]={33,34}, ["RedButton-exit-pressed"]={33,34}, ["RedButton-Highlight"]={33,34},
    ["_UI-Frame-TopTileStreaks"]={256,43},
    ["UI-Frame-InnerTopLeft"]={6,6}, ["UI-Frame-InnerTopRight"]={6,6}, ["UI-Frame-InnerBotLeftCorner"]={6,6},
    ["UI-Frame-InnerBotRight"]={6,6}, ["_UI-Frame-InnerTopTile"]={32,6}, ["_UI-Frame-InnerBotTile"]={32,6},
    ["!UI-Frame-InnerLeftTile"]={6,32}, ["!UI-Frame-InnerRightTile"]={6,32},
    ["common-dropdown-bg"]={60,60}, ["common-dropdown-textholder"]={135,41},
    ["common-dropdown-a-button"]={27,26}, ["common-dropdown-a-button-hover"]={27,26}, ["common-dropdown-a-button-pressed"]={27,26},
    ["common-dropdown-a-button-pressedhover"]={27,26}, ["common-dropdown-a-button-open"]={27,26},
    ["Minimal_SliderBar_Left"]={11,8}, ["_Minimal_SliderBar_Middle"]={64,8}, ["Minimal_SliderBar_Right"]={11,8},
    ["Minimal_SliderBar_Button"]={20,19},
}
C_Texture = {GetAtlasInfo=function(name)
    local size=not ATLAS_MISSING[name] and ATLAS_SIZES[name]
    if size then return {width=size[1],height=size[2],file=1} end
end}
-- NineSliceUtil and the two layouts Hourstone uses, as Blizzard_SharedXML defines them; on WoW:
-- Forever with Camelot's offset overrides and UpdateCornerCropping, which only Forever has.
-- NINE_SLICE records every call.
NINE_SLICE = {}
local forever_ui = TEST_INTERFACE and TEST_INTERFACE >= 16000 and TEST_INTERFACE < 17000
NineSliceLayouts = {
    ButtonFrameTemplateNoPortrait = {disableSharpening=true,
        TopLeftCorner={layer="OVERLAY",atlas="UI-Frame-Metal-CornerTopLeft",x=-8,y=16},
        TopRightCorner={layer="OVERLAY",atlas="UI-Frame-Metal-CornerTopRight",x=forever_ui and 2 or 4,y=16},
        BottomLeftCorner={layer="OVERLAY",atlas="UI-Frame-Metal-CornerBottomLeft",x=-8,y=forever_ui and -8 or -3},
        BottomRightCorner={layer="OVERLAY",atlas="UI-Frame-Metal-CornerBottomRight",x=forever_ui and 2 or 4,y=forever_ui and -8 or -3},
        TopEdge={layer="OVERLAY",atlas="_UI-Frame-Metal-EdgeTop"}, BottomEdge={layer="OVERLAY",atlas="_UI-Frame-Metal-EdgeBottom"},
        LeftEdge={layer="OVERLAY",atlas="!UI-Frame-Metal-EdgeLeft"}, RightEdge={layer="OVERLAY",atlas="!UI-Frame-Metal-EdgeRight"}},
    InsetFrameTemplate = {
        TopLeftCorner={layer="BORDER",subLevel=-5,atlas="UI-Frame-InnerTopLeft"}, TopRightCorner={layer="BORDER",subLevel=-5,atlas="UI-Frame-InnerTopRight"},
        BottomLeftCorner={layer="BORDER",subLevel=-5,atlas="UI-Frame-InnerBotLeftCorner",x=0,y=-1},
        BottomRightCorner={layer="BORDER",subLevel=-5,atlas="UI-Frame-InnerBotRight",x=0,y=-1},
        TopEdge={layer="BORDER",subLevel=-5,atlas="_UI-Frame-InnerTopTile"}, BottomEdge={layer="BORDER",subLevel=-5,atlas="_UI-Frame-InnerBotTile"},
        LeftEdge={layer="BORDER",subLevel=-5,atlas="!UI-Frame-InnerLeftTile"}, RightEdge={layer="BORDER",subLevel=-5,atlas="!UI-Frame-InnerRightTile"}},
}
local PIECES = {{"TopLeftCorner","TOPLEFT"},{"TopRightCorner","TOPRIGHT"},{"BottomLeftCorner","BOTTOMLEFT"},{"BottomRightCorner","BOTTOMRIGHT"},
    {"TopEdge"},{"BottomEdge"},{"LeftEdge"},{"RightEdge"}}
NineSliceUtil = {
    GetLayout=function(name) return NineSliceLayouts[name] end,
    ApplyLayoutByName=function(container,name)
        local layout=assert(NineSliceLayouts[name],"Unknown nine-slice layout")
        NINE_SLICE[#NINE_SLICE+1]={call="apply",container=container,layout=name}
        for _,spec in ipairs(PIECES) do
            local key,corner,piece=spec[1],spec[2],layout[spec[1]]
            local t=rawget(container,key) or container:CreateTexture(nil,piece.layer or "BORDER",nil,piece.subLevel)
            container[key]=t; t:SetAtlas(piece.atlas,true); t:ClearAllPoints()
            if corner then t:SetPoint(corner,container,corner,piece.x or 0,piece.y or 0) end
        end
        local c=container
        c.TopEdge:SetPoint("TOPLEFT",c.TopLeftCorner,"TOPRIGHT"); c.TopEdge:SetPoint("TOPRIGHT",c.TopRightCorner,"TOPLEFT")
        c.BottomEdge:SetPoint("BOTTOMLEFT",c.BottomLeftCorner,"BOTTOMRIGHT"); c.BottomEdge:SetPoint("BOTTOMRIGHT",c.BottomRightCorner,"BOTTOMLEFT")
        c.LeftEdge:SetPoint("TOPLEFT",c.TopLeftCorner,"BOTTOMLEFT"); c.LeftEdge:SetPoint("BOTTOMLEFT",c.BottomLeftCorner,"TOPLEFT")
        c.RightEdge:SetPoint("TOPRIGHT",c.TopRightCorner,"BOTTOMRIGHT"); c.RightEdge:SetPoint("BOTTOMRIGHT",c.BottomRightCorner,"TOPRIGHT")
    end,
}
if forever_ui then
    NineSliceUtil.UpdateCornerCropping=function(container,height)
        assert(type(container)=="table" and container.NineSlice and NineSliceLayouts[container.layoutType] and type(height)=="number")
        NINE_SLICE[#NINE_SLICE+1]={call="crop",container=container.NineSlice,height=height}
    end
end
function GetCursorPosition() return 1500,800 end
function IsMouseButtonDown(button) return button == "LeftButton" and MOUSE_LEFT_DOWN == true end
function date(_,v) return tostring(v) end
function advance(n) NOW=NOW+n; EPOCH=EPOCH+n end
RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92},WARRIOR={r=.78,g=.61,b=.43},DRUID={r=1,g=.49,b=.04},PRIEST={r=1,g=1,b=1},HUNTER={r=.67,g=.83,b=.45},DEMONHUNTER={r=.77,g=.64,b=1},ROGUE={r=1,g=.95,b=.48},PALADIN={r=.96,g=.55,b=.73}}
SlashCmdList, UISpecialFrames, ALL_FRAMES = {}, {}, {}
local methods = {}
local function new(kind,name,parent)
    local f=setmetatable({kind=kind,name=name,parent=parent,points={},scripts={},events={},shown=true,width=0,height=0,scale=1,frameLevel=1}, {__index=function(_,k)
        if type(k)=="string" and k:match("^[A-Z]") then assert(methods[k],"Unsupported mock API: "..tostring(k)) end
        return methods[k]
    end})
    ALL_FRAMES[#ALL_FRAMES+1]=f
    f.id=#ALL_FRAMES
    if name then _G[name]=f end
    return f
end
function CreateFrame(kind,name,parent,template)
    assert(not template or template=="UICheckButtonTemplate" or template=="UIPanelButtonTemplate" or BackdropTemplateMixin,"Unavailable backdrop template")
    local f=new(kind,name,parent); f.template=template
    if template=="UIPanelButtonTemplate" then
        -- SecureUIPanelTemplates.xml: three pieces of UI-Panel-Button-Up and a label; Retail's
        -- red art on Retail and WoW: Forever.
        assert(kind=="Button")
        for _,key in ipairs({"Left","Middle","Right"}) do
            f[key]=f:CreateTexture(nil,"BACKGROUND"); f[key]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        end
        f.Left:SetPoint("TOPLEFT"); f.Left:SetPoint("BOTTOMLEFT"); f.Left:SetWidth(12)
        f.Right:SetPoint("TOPRIGHT"); f.Right:SetPoint("BOTTOMRIGHT"); f.Right:SetWidth(12)
        f.Middle:SetPoint("TOPLEFT",f.Left,"TOPRIGHT"); f.Middle:SetPoint("BOTTOMRIGHT",f.Right,"BOTTOMLEFT")
        f.Text=f:CreateFontString(); f.Text:SetPoint("CENTER")
        f:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    end
    if template=="UICheckButtonTemplate" then
        assert(kind=="CheckButton")
        f:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        f:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        f:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        f:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check"); f:SetChecked(false)
    end
    return f
end
function methods:SetSize(w,h) assert(w>=0 and h>=0,"Negative region size"); self.width,self.height=w,h end
function methods:SetWidth(w) assert(w>=0,"Negative region width"); self.width=w end
function methods:SetHeight(h) assert(h>=0,"Negative region height"); self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(p,a,b,x,y)
    if type(a)=="number" then x,y,a,b=a,b,self.parent,p end
    if a==nil then a,b,x,y=self.parent,p,0,0 end
    b=b or p
    for i,pt in ipairs(self.points) do if pt[1]==p then table.remove(self.points,i); break end end
    self.points[#self.points+1]={p,a,b,x or 0,y or 0}
end
function methods:GetPoint(i) return unpack(self.points[i or 1]) end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints(relative) self.allPoints=relative or self.parent end
function methods:GetCenter()
    if not self.parent then return self.width/2,self.height/2 end
    local p=self.points[1]
    if p and p[1]=="CENTER" and p[3]=="CENTER" then
        local x,y=p[2]:GetCenter(); local ratio=p[2]:GetEffectiveScale()/self:GetEffectiveScale()
        return x*ratio+p[4],y*ratio+p[5]
    end
    return self.width/2,self.height/2
end
function methods:SetScript(e,fn) self.scripts[e]=fn end
function methods:GetScript(e) return self.scripts[e] end
function methods:HookScript(e,fn)
    local old=self.scripts[e]
    self.scripts[e]=old and function(...) old(...); fn(...) end or fn
end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:IsShown() return self.shown end
function methods:Show() local old=self.shown; self.shown=true; if not old and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local old=self.shown; self.shown=false; if old and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:CreateFontString() return new("FontString",nil,self) end
function methods:CreateTexture(_,layer,_,sublevel) local t=new("Texture",nil,self); t.layer=layer; t.sublevel=sublevel; return t end
function methods:CreateMaskTexture(_,layer) local t=new("MaskTexture",nil,self); t.layer=layer; return t end
function methods:AddMaskTexture(mask) self.mask=mask end
function methods:GetUnboundedStringWidth()
    if ZERO_FONT_METRICS then return 0 end
    if ZERO_HIDDEN_FONT_METRICS then
        local p=self
        while p do if not p.shown then return 0 end; p=p.parent end
    end
    return MEASURE_TEXT(self.font,self.fontSize,self.text or "")
end
-- A bounded FontString may already be truncated; this is not its intrinsic width.
function methods:GetStringWidth() return math.min(self:GetUnboundedStringWidth(),self.width) end
function methods:GetStringHeight()
    local lines=self.wordWrap and math.max(1,math.ceil(self:GetUnboundedStringWidth()/math.max(1,self.width))) or 1
    return lines*(self.fontSize or 12)*1.2
end
function methods:SetWordWrap(value) self.wordWrap=value end
function methods:SetFont(path,size,flags) self.font,self.fontSize=path,size end
function methods:SetText(s)
    self.text=tostring(s)
    local label=rawget(self,"Text"); if label then label:SetText(s) end
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetFontString() return rawget(self,"Text") end
function methods:GetText() return rawget(self,"text") or "" end
function methods:SetTextColor(...) self.color={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetDesaturated(v) self.desaturated=v end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetTexture(path,wrapH,wrapV) self.texture=path; self.atlas=nil; self.wrap=wrapH and {wrapH,wrapV} or nil end
-- Texture:SetAtlas(atlas, useAtlasSize, filterMode, resetTexCoords). Earlier texture coordinates
-- stay unless the last argument resets them, as in the client.
function methods:SetAtlas(name,useSize,filter,reset)
    local info=C_Texture.GetAtlasInfo(name)
    self.atlas,self.atlasArgs,self.texture=name,{useSize,filter,reset},nil
    if reset then self.uv=nil end
    if useSize and info then self:SetSize(info.width,info.height) end
end
function methods:SetHorizTile(v) self.horizTile=v end
function methods:SetVertTile(v) self.vertTile=v end
function methods:SetDrawLayer(layer,sublevel) self.layer,self.sublevel=layer,sublevel end
function methods:SetBlendMode(mode) self.blend=mode end
function methods:SetTexCoord(...) self.uv={...} end
function methods:SetNormalTexture(path) self.normal=self.normal or self:CreateTexture(nil,"ARTWORK"); self.normal:SetTexture(path); self.normal:SetAllPoints() end
function methods:GetNormalTexture() return self.normal end
function methods:SetPushedTexture(path)
    self.pushed=self:CreateTexture(nil,"ARTWORK"); self.pushed:SetTexture(path); self.pushed:SetAllPoints(); self.pushed:Hide()
end
function methods:SetCheckedTexture(path)
    self.checkedTexture=self:CreateTexture(nil,"OVERLAY"); self.checkedTexture:SetTexture(path); self.checkedTexture:SetAllPoints()
end
function methods:GetCheckedTexture() return self.checkedTexture end
function methods:SetChecked(v) self.checked=not not v; if self.checkedTexture then self.checkedTexture:SetShown(self.checked) end end
function methods:GetChecked() return self.checked end
function methods:Click(mouse)
    if self.kind=="CheckButton" then self:SetChecked(not self:GetChecked()) end
    if self.scripts.OnClick then self.scripts.OnClick(self,mouse or "LeftButton") end
end
function methods:SetHighlightTexture(path)
    self.highlight=self.highlight or self:CreateTexture(nil,"HIGHLIGHT")
    self.highlight:SetTexture(path); self.highlight:SetAllPoints()
end
function methods:GetHighlightTexture() return self.highlight end
function methods:SetNormalAtlas(name) self.normal=self.normal or self:CreateTexture(nil,"ARTWORK"); self.normal:SetAtlas(name); self.normal:SetAllPoints() end
function methods:SetPushedAtlas(name)
    self.pushed=self.pushed or self:CreateTexture(nil,"ARTWORK"); self.pushed:SetAtlas(name); self.pushed:SetAllPoints(); self.pushed:Hide()
end
function methods:SetHighlightAtlas(name,blend)
    self.highlight=self.highlight or self:CreateTexture(nil,"HIGHLIGHT"); self.highlight:SetAtlas(name); self.highlight:SetAllPoints(); self.highlight.blend=blend
end
function methods:SetThumbTexture(path) self.thumb=self:CreateTexture(nil,"ARTWORK"); self.thumb:SetTexture(path) end
function methods:GetThumbTexture() return self.thumb end
function methods:SetOrientation(v) self.orientation=v end
function methods:SetFrameLevel(v) self.frameLevel=v end
function methods:GetFrameLevel() return self.frameLevel end
function methods:SetScale(s)
    self.scale=s
    if self==UIParent then
        local w,h=GetPhysicalScreenSize()
        self:SetSize(w*768/h/s,768/s)
    end
end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetMinMaxValues(a,b) self.minValue,self.maxValue=a,b end
function methods:SetValue(v)
    self.value=v
    if self.thumb then
        local range=self.maxValue-self.minValue
        local progress=range>0 and (v-self.minValue)/range or 0
        self.thumb:ClearAllPoints()
        if self.orientation=="HORIZONTAL" then
            self.thumb:SetPoint("TOPLEFT",self,"TOPLEFT",progress*(self.width-self.thumb.width),-(self.height-self.thumb.height)/2)
        else
            self.thumb:SetPoint("TOPLEFT",self,"TOPLEFT",(self.width-self.thumb.width)/2,-progress*(self.height-self.thumb.height))
        end
    end
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
end
function methods:GetValue() return self.value end
function methods:SetJustifyH(v) self.align=v end
function methods:SetJustifyV(v) self.valign=v end
function methods:SetOwner(owner) self.owner=owner end
function methods:ClearLines() self.lines={}; self.lineWrap={} end
function methods:AddLine(line,_,_,_,wrap) self.lines[#self.lines+1]=line; self.lineWrap[#self.lines]=wrap end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:SetFrameStrata(v) self.strata=v end
for _,key in ipairs({"SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetMaxLetters","SetTextInsets","ClearFocus","EnableMouseWheel","SetValueStep","SetObeyStepOnDrag","RegisterForClicks"}) do methods[key]=function() end end
UIParent=new("Frame","UIParent"); UIParent:SetScale(1)
function configure_display(w,h,scale)
    SCREEN_WIDTH,SCREEN_HEIGHT=w,h
    UIParent:SetScale(scale or UIParent:GetScale())
end
Minimap=new("Frame","Minimap",UIParent); Minimap:SetSize(140,140)
GameTooltip=new("Frame","GameTooltip",UIParent)
function fire(event,...)
    for _,f in ipairs(ALL_FRAMES) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end end
end
function tick(n) advance(n); H.events.scripts.OnUpdate(H.events,n) end
