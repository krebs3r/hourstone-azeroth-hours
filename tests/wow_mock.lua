-- Strict, deliberately small native-UI and event simulator. Missing APIs fail loudly.
NOW, EPOCH, REQUESTS = 1000, 1800000000, 0
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
IDENTITY = {guid="Player-1-AAA",name="Elarion",realm="Blackhand",class="MAGE",level=90}
WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_MISTS_CLASSIC = 1,2,5,19
function GetTime() return NOW end
function GetServerTime() return EPOCH end
function GetLocale() return TEST_LOCALE end
function GetRealmName() return IDENTITY.realm end
function UnitGUID() return IDENTITY.guid end
function UnitFullName() return IDENTITY.name, IDENTITY.realm end
function UnitClass() return IDENTITY.class, IDENTITY.class end
function UnitLevel() return IDENTITY.level end
GUILD_READS = 0
function IsInGuild() return IN_GUILD end
function GetGuildInfo(unit) assert(unit == "player"); GUILD_READS=GUILD_READS+1; return GUILD_NAME end
function RequestTimePlayed() REQUESTS=REQUESTS+1 end
function GetAddOnMetadata() return TEST_VERSION end
function GetPhysicalScreenSize() return SCREEN_WIDTH or 1920,SCREEN_HEIGHT or 1080 end
if WOW_PROJECT_ID==1 then C_AddOns={GetAddOnMetadata=GetAddOnMetadata} end
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
    assert(not template or template=="UICheckButtonTemplate" or BackdropTemplateMixin,"Unavailable backdrop template")
    local f=new(kind,name,parent); f.template=template
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
function methods:RegisterEvent(e) self.events[e]=true end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:IsShown() return self.shown end
function methods:Show() local old=self.shown; self.shown=true; if not old and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local old=self.shown; self.shown=false; if old and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:CreateFontString() return new("FontString",nil,self) end
function methods:CreateTexture(_,layer) local t=new("Texture",nil,self); t.layer=layer; return t end
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
function methods:SetText(s) self.text=tostring(s); if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
function methods:GetText() return rawget(self,"text") or "" end
function methods:SetTextColor(...) self.color={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetDesaturated(v) self.desaturated=v end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetTexture(path) self.texture=path end
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
function methods:SetOwner() end
function methods:ClearLines() self.lines={}; self.lineWrap={} end
function methods:AddLine(line,_,_,_,wrap) self.lines[#self.lines+1]=line; self.lineWrap[#self.lines]=wrap end
for _,key in ipairs({"SetFrameStrata","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetMaxLetters","SetTextInsets","ClearFocus","EnableMouseWheel","SetValueStep","SetObeyStepOnDrag","RegisterForClicks"}) do methods[key]=function() end end
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
