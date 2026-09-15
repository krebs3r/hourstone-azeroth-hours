-- Strict, deliberately small native-UI and event simulator. Missing APIs fail loudly.
NOW, EPOCH, REQUESTS = 1000, 1800000000, 0
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
function RequestTimePlayed() REQUESTS=REQUESTS+1 end
function GetAddOnMetadata() return "0.1.0" end
if WOW_PROJECT_ID==1 then C_AddOns={GetAddOnMetadata=GetAddOnMetadata} end
function GetCursorPosition() return 1500,800 end
function date(_,v) return tostring(v) end
function advance(n) NOW=NOW+n; EPOCH=EPOCH+n end
RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92},WARRIOR={r=.78,g=.61,b=.43}}
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
    assert(not template or BackdropTemplateMixin,"Unavailable backdrop template")
    return new(kind,name,parent)
end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
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
function methods:GetCenter() return self.width/2,self.height/2 end
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
function methods:SetFont(path,size,flags) self.font,self.fontSize=path,size end
function methods:SetText(s) self.text=tostring(s); if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
function methods:GetText() return rawget(self,"text") or "" end
function methods:SetTextColor(...) self.color={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetTexture(path) self.texture=path end
function methods:SetTexCoord(...) self.uv={...} end
function methods:SetNormalTexture(path) self.normal=self.normal or self:CreateTexture(nil,"ARTWORK"); self.normal:SetTexture(path); self.normal:SetAllPoints() end
function methods:GetNormalTexture() return self.normal end
function methods:SetThumbTexture(path) self.thumb=self:CreateTexture(nil,"ARTWORK"); self.thumb:SetTexture(path) end
function methods:GetThumbTexture() return self.thumb end
function methods:SetFrameLevel(v) self.frameLevel=v end
function methods:GetFrameLevel() return self.frameLevel end
function methods:SetScale(s) self.scale=s end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:SetMinMaxValues(a,b) self.minValue,self.maxValue=a,b end
function methods:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function methods:GetValue() return self.value end
function methods:SetJustifyH(v) self.align=v end
function methods:SetOwner() end
function methods:ClearLines() self.lines={} end
function methods:AddLine(line) self.lines[#self.lines+1]=line end
for _,key in ipairs({"SetFrameStrata","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetHighlightTexture","SetAutoFocus","SetMaxLetters","SetTextInsets","ClearFocus","EnableMouseWheel","SetOrientation","SetValueStep","SetObeyStepOnDrag","RegisterForClicks","SetWordWrap"}) do methods[key]=function() end end
UIParent=new("Frame","UIParent"); UIParent:SetSize(1920,1080)
Minimap=new("Frame","Minimap",UIParent); Minimap:SetSize(140,140)
GameTooltip=new("Frame","GameTooltip",UIParent)
function fire(event,...)
    for _,f in ipairs(ALL_FRAMES) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end end
end
function tick(n) advance(n); H.events.scripts.OnUpdate(H.events,n) end
