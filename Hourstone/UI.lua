local _, H = ...
local U, C, M, T, L = {}, H.C, H.M, H.T, H.L
H.UI = U
local ROOT = "Interface\\AddOns\\Hourstone\\Media\\"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD, MUTED = {243/255,206/255,112/255}, {169/255,170/255,162/255}
local WIDTH, ROW_HEIGHT, CAPACITY = 720, 50, 8
local NAME_WIDTH, CLIENT_WIDTH, PLAYED_WIDTH, UPDATED_WIDTH = 280, 120, 185, 115
local SEARCH_WIDTH, FILTER_WIDTH, FORMAT_WIDTH, COMBINED_WIDTH = 216, 139, 185, 111
local MINIMAP_SIZE, MINIMAP_MASK = 31, 24

local function rect(kind,parent,x,y,w,h,name)
    local f=C.Frame(kind,name,parent)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetSize(w,h)
    return f
end
local function solid(parent,layer,r,g,b,a)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND")
    t:SetColorTexture(r,g,b,a or 1); return t
end
local function line(parent,x,y,w,h,r,g,b,a)
    local t=solid(parent,"BORDER",r,g,b,a)
    t:SetPoint("TOPLEFT",x,-y); t:SetSize(w,h); return t
end
local function text(parent,value,size,x,y,width,color,height,align)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetFont(FONT,size,""); f:SetPoint("TOPLEFT",x,-y)
    -- Essential labels always have reserved space, even while the window is hidden.
    -- Never size a title or label from a font metric that may not be ready yet.
    f:SetSize(width,height or size*1.2)
    f:SetJustifyH(align or "LEFT"); f:SetJustifyV("MIDDLE"); f:SetWordWrap(false)
    f:SetTextColor(unpack(color or {238/255,233/255,218/255})); f:SetText(value or "")
    return f
end
local function artwork(parent,name,w,h,x,y,layer)
    local t=parent:CreateTexture(nil,layer or "ARTWORK")
    t:SetTexture(ROOT..name..".tga"); t:SetSize(w,h); t:SetPoint("TOPLEFT",x,-y)
    return t
end
-- Original Soundstone crops. Fixed corners prevent oversized frame ornaments.
local SKINS={
    RetailPanel={{2/512,510/512,120/512,391/512},711,379,23,7},
    ClassicPanel={{2/512,510/512,118/512,393/512},710,384,52,10},
    Toggle={{.015625,.984375,.2421875,.7578125},155,82,14,4},
    ToggleRed={{.015625,.984375,.2578125,.7421875},159,80,14,4},
}
local function skin(frame,name)
    local spec=SKINS[name]; local uv,sw,sh,sc,corner=unpack(spec)
    local du,dv=(uv[2]-uv[1])*sc/sw,(uv[4]-uv[3])*sc/sh
    local xs,ys={uv[1],uv[1]+du,uv[2]-du,uv[2]},{uv[3],uv[3]+dv,uv[4]-dv,uv[4]}
    local textures={}
    for r=1,3 do for c=1,3 do
        local t=frame:CreateTexture(nil,"BACKGROUND")
        t:SetTexture(ROOT..name..".tga"); t:SetTexCoord(xs[c],xs[c+1],ys[r],ys[r+1])
        textures[#textures+1]=t
    end end
    local function layout()
        local w,h=frame:GetWidth(),frame:GetHeight()
        local widths,heights={corner,w-2*corner,corner},{corner,h-2*corner,corner}
        local lefts,tops={0,corner,w-corner},{0,corner,h-corner}
        for i,t in ipairs(textures) do
            local r,c=math.floor((i-1)/3)+1,(i-1)%3+1
            t:ClearAllPoints(); t:SetPoint("TOPLEFT",lefts[c],-tops[r]); t:SetSize(widths[c],heights[r])
        end
    end
    layout(); return layout,textures
end
local function control(parent,label,x,y,w,h,action,style)
    local b=rect("Button",parent,x,y,w,h)
    local _,textures=skin(b,style or "ToggleRed"); b.background=textures
    b.label=text(b,label,11,8,0,w-16,GOLD,h,"CENTER")
    local glow=solid(b,"HIGHLIGHT",1,.9,.6,.12); glow:SetAllPoints()
    b:SetScript("OnClick",action); return b
end
local function selected(b,on)
    for _,t in ipairs(b.background) do
        t:SetDesaturated(not on); t:SetVertexColor(on and 1 or .65,on and 1 or .58,on and 1 or .48)
    end
    b.label:SetTextColor(unpack(on and {1,227/255,156/255} or {184/255,175/255,160/255}))
end
local function arrow(parent,x,y,w,h)
    local t=artwork(parent,"Arrow",w or 5,h or 3,x,y)
    t:SetVertexColor(197/255,191/255,171/255); return t
end
local function closeButton(parent,x,y,size,action)
    local b=rect("Button",parent,x,y,size,size)
    b:SetNormalTexture(ROOT.."HeaderClose.tga")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetScript("OnClick",action); return b
end
local function tooltip(owner,lines)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT"); GameTooltip:ClearLines()
    for _,value in ipairs(lines) do
        if type(value)=="table" then GameTooltip:AddLine(value.text,.94,.91,.84,value.wrap~=false)
        else GameTooltip:AddLine(value,.94,.91,.84,true) end
    end
    GameTooltip:Show()
end
-- Width measurements affect only spacing between adjacent labels. A zero result
-- uses the already reserved width, never a zero-width visible text region.
local function occupied(label)
    local w=label:GetUnboundedStringWidth()
    return w and w>0 and math.min(w,label:GetWidth()) or label:GetWidth()
end
function U:ApplyScale()
    local sw,sh=GetPhysicalScreenSize()
    local fitting=math.min((sw-20)/WIDTH,(sh-20)/self.frame:GetHeight())
    self.frame:SetScale(math.min(self.db.settings.scale,fitting)*(768/sh)/UIParent:GetEffectiveScale())
    self:Position()
end
function U:Position(reset)
    local f,p=self.frame,self.db.settings.position
    if reset then self.db.settings.position=nil; p=nil; self.anchorHeight=f:GetHeight() end
    local height=p and tonumber(p.height) or self.anchorHeight or 262
    if not M.Number(height) or height<248 or height>612 then height=262 end
    -- Stored center offsets remain compatible. Remember the height at placement
    -- so filtering grows downward from the same header instead of making it jump.
    local x,y=p and p.x or 0,(p and p.y or 0)+(height-f:GetHeight())/2
    local sw,sh=GetPhysicalScreenSize(); local factor=f:GetEffectiveScale()*sh/768
    local mx,my=math.max(0,(sw-20)/factor/2-WIDTH/2),math.max(0,(sh-20)/factor/2-f:GetHeight()/2)
    x,y=math.max(-mx,math.min(mx,x)),math.max(-my,math.min(my,y))
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x,y)
end
function U:SavePosition()
    local x,y=self.frame:GetCenter(); local px,py=UIParent:GetCenter()
    local ratio=self.frame:GetScale()
    self.db.settings.position={x=x-px/ratio,y=y-py/ratio,height=self.frame:GetHeight()}
end
function U:CloseMenus()
    self.menu:Hide(); self.sortMenu:Hide(); self.settings:Hide()
    if self.clientMenu then self.clientMenu:Hide() end
    if self.removeDialog then self.removeDialog:Hide(); self.pendingRemoval=nil end
end
function U:ToggleSettings()
    self:Create(); local shown=self.settings:IsShown(); self:CloseMenus()
    self.settings:SetShown(not shown); self:SettingsText()
end
function U:SettingsText()
    self.removedToggle.label:SetText(self.removedOnly and L.showTracked or L.removedCharacters)
    self.minimapBox:SetChecked(self.db.settings.minimap)
    self.scaleLabel:SetText(math.floor(self.db.settings.scale*100+.5).." %")
    self.updatingScale=true; self.scaleSlider:SetValue(self.db.settings.scale*100); self.updatingScale=false
    self.scaleFill:SetWidth(224*(self.db.settings.scale-.65)/.65)
end
function U:SetFormat(mode) self.db.settings.format=mode; self:Refresh() end
function U:SetSort(field)
    if self.sort==field then self.descending=not self.descending
    else self.sort,self.descending=field,field=="seconds" or field=="level" or field=="updatedAt" end
    self.offset=0; self:CloseMenus(); self:Refresh()
end
function U:LayoutRows(count)
    local slots=math.max(1,math.min(CAPACITY,count or self.visibleCount or 0))
    if self.slots==slots then return end
    self.slots=slots; local h=slots*ROW_HEIGHT
    self.frame:SetHeight(212+h); self.panelLayout()
    self.table:SetHeight(24+h); self.list:SetHeight(h); self.scroll:SetHeight(h-4)
    self.footerFrame:ClearAllPoints(); self.footerFrame:SetPoint("TOPLEFT",10,-(176+h))
    self:ApplyScale()
end
function U:Create()
    if self.frame then return end
    local f=C.Frame("Frame","HourstoneWindow",UIParent); self.frame=f
    f:SetSize(WIDTH,262); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true); f:Hide()
    self.panelName=C.Retail() and "RetailPanel" or "ClassicPanel"
    self.panelLayout=skin(f,self.panelName)
    self:ApplyScale(); UISpecialFrames[#UISpecialFrames+1]="HourstoneWindow"
    self.header=rect("Frame",f,10,10,700,40)
    self.header:EnableMouse(true); self.header:RegisterForDrag("LeftButton")
    self.header:SetScript("OnDragStart",function() self:CloseMenus(); f:StartMoving() end)
    self.header:SetScript("OnDragStop",function() f:StopMovingOrSizing(); self:SavePosition() end)
    for y=0,2 do for x=0,1 do
        local rivet=artwork(self.header,"Rivet",3,3,3.5+x*6,12+y*6)
        rivet:SetTexCoord(.03125,.96875,.03125,.96875); rivet:SetAlpha(.75)
    end end
    self.gear=rect("Button",self.header,20,9.5,20,20)
    self.gear:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY")
    self.gear:GetNormalTexture():SetVertexColor(.9,.8,.57)
    self.gear:SetScript("OnEnter",function(b) b:GetNormalTexture():SetVertexColor(1,1,1) end)
    self.gear:SetScript("OnLeave",function(b) b:GetNormalTexture():SetVertexColor(.9,.8,.57) end)
    self.gear:SetScript("OnClick",function() self:ToggleSettings() end)
    self.logo=artwork(self.header,"Logo",28,28,48,5.5)
    self.title=text(self.header,"Hourstone – Azeroth Hours",17,84,7.5,588,{1,213/255,116/255},24)
    self.close=closeButton(self.header,678,9.5,20,function() f:Hide() end)
    line(self.header,0,39,700,1,166/255,162/255,148/255,128/255)

    self.summary=rect("Frame",f,10,50,700,64)
    self.statLabels={}
    local starts,widths={5,280.2,432},{250.2,126.8,251}
    for i,key in ipairs({"total","characters","session"}) do
        self.statLabels[i]=text(self.summary,L[key],11,starts[i],11.5,widths[i],{196/255,192/255,178/255},15)
    end
    for _,x in ipairs({267.2,419}) do line(self.summary,x,10,1,43,146/255,137/255,120/255,66/255) end
    self.total=text(self.summary,"",20,5,26.5,250.2,GOLD,25)
    self.count=text(self.summary,"",20,280.2,26.5,50,GOLD,25)
    self.realms=text(self.summary,"",11,308.2,35.5,96,MUTED,13.2)
    self.session=text(self.summary,"",20,432,26.5,251,GOLD,25)
    self.summary:EnableMouse(true)
    self.summary:SetScript("OnEnter",function(owner)
        local stats=self.overviewStats
        if stats then tooltip(owner,{L.total,M.SumText(stats.total,stats.missing,stats.count,self.db.settings.format)}) end
    end)
    self.summary:SetScript("OnLeave",function() GameTooltip:Hide() end)
    line(self.summary,0,63,700,1,150/255,144/255,128/255,66/255)

    self.toolbar=rect("Frame",f,10,114,700,38)
    local search=rect("EditBox",self.toolbar,0,6,SEARCH_WIDTH,26); self.search=search
    skin(search,"Toggle"); search:SetFont(FONT,11,""); search:SetTextColor(231/255,225/255,206/255)
    search:SetAutoFocus(false); search:SetMaxLetters(80); search:SetTextInsets(9,25,0,0)
    search.hint=text(search,L.search,11,9,0,SEARCH_WIDTH-34,{.56,.55,.51},26)
    self.clearSearch=rect("Button",search,SEARCH_WIDTH-23,4,18,18)
    text(self.clearSearch,"×",12,0,0,18,MUTED,18,"CENTER")
    self.clearSearch:SetScript("OnClick",function() search:SetText(""); search:ClearFocus() end)
    self.clearSearch:Hide()
    search:SetScript("OnTextChanged",function(edit)
        local value=edit:GetText(); edit.hint:SetShown(value==""); self.clearSearch:SetShown(value~="")
        self.searchText,self.offset=value,0; self:Refresh()
    end)
    search:SetScript("OnEscapePressed",function(edit) edit:ClearFocus(); f:Hide() end)
    search:SetScript("OnEnterPressed",function(edit) edit:ClearFocus() end)
    search:SetScript("OnEnter",function(owner) tooltip(owner,{L.searchHelp}) end)
    search:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.realmButton=control(self.toolbar,L.allRealms,SEARCH_WIDTH+7,6,FILTER_WIDTH,26,function() self:ToggleRealms() end,"Toggle")
    self.realmButton.label:SetJustifyH("LEFT"); self.realmButton.label:SetWidth(107)
    arrow(self.realmButton,124,11,6,4)
    self.clientButton=control(self.toolbar,L.allClients,SEARCH_WIDTH+FILTER_WIDTH+14,6,FILTER_WIDTH,26,function() self:ToggleClients() end,"Toggle")
    self.clientButton.label:SetJustifyH("LEFT"); self.clientButton.label:SetWidth(107)
    arrow(self.clientButton,124,11,6,4)
    self.format=rect("Frame",self.toolbar,700-FORMAT_WIDTH,6.5,FORMAT_WIDTH,25)
    self.combined=control(self.format,L.combined,0,0,COMBINED_WIDTH,25,function() self:SetFormat("combined") end)
    self.hours=control(self.format,L.hours,COMBINED_WIDTH+3,0,FORMAT_WIDTH-COMBINED_WIDTH-3,25,function() self:SetFormat("hours") end)

    self.sort,self.descending,self.offset="seconds",true,0
    self.table=rect("Frame",f,10,152,700,24+ROW_HEIGHT); self.headers={}
    for _,spec in ipairs({{"name","character",0,NAME_WIDTH},{"flavor","client",NAME_WIDTH,CLIENT_WIDTH},
        {"seconds","played",NAME_WIDTH+CLIENT_WIDTH,PLAYED_WIDTH},{"updatedAt","updated",NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH,UPDATED_WIDTH}}) do
        local field,title,x,w=spec[1],L[spec[2]],spec[3],spec[4]
        local b=rect("Button",self.table,x,0,w,24)
        b.label=text(b,title,11,8,0,w-24,{197/255,191/255,171/255},24,field=="seconds" and "RIGHT" or "LEFT")
        if field=="seconds" then b.label:SetWidth(w-32) end
        b.arrow=arrow(b,field=="seconds" and w-19 or 80,10.5)
        b:SetScript("OnClick",function()
            if field=="name" then
                local shown=self.sortMenu:IsShown(); self:CloseMenus(); self.sortMenu:SetShown(not shown)
            else self:SetSort(field) end
        end)
        self.headers[field]={button=b,width=w,title=title}
    end
    line(self.table,0,23,700,1,169/255,160/255,139/255,101/255)
    self.list=rect("Frame",self.table,0,24,700,ROW_HEIGHT); self.list:EnableMouseWheel(true)
    self.list:SetScript("OnMouseWheel",function(_,delta) self:Scroll(-delta*3) end)
    self.rows={}
    for i=1,CAPACITY do
        local row=rect("Button",self.list,0,(i-1)*ROW_HEIGHT,700,ROW_HEIGHT); self.rows[i]=row
        row.bg=solid(row,"BACKGROUND",1,1,1,0); row.bg:SetAllPoints()
        row.active=line(row,0,0,2,ROW_HEIGHT-1,104/255,202/255,232/255)
        line(row,0,ROW_HEIGHT-1,700,1,141/255,138/255,114/255,59/255)
        row.dot=artwork(row,"LiveDot",5,5,8,8.5)
        row.name=text(row,"",13,8,3,NAME_WIDTH-77,nil,16)
        row.level=text(row,"",10,NAME_WIDTH-62,5,54,{196/255,184/255,154/255},12)
        row.realm=text(row,"",11,8,19,NAME_WIDTH-16,{168/255,170/255,165/255},13)
        row.guild=text(row,"",10,8,33,NAME_WIDTH-16,{150/255,165/255,156/255},13)
        row.client=text(row,"",11,NAME_WIDTH+8,0,CLIENT_WIDTH-16,{168/255,170/255,165/255},ROW_HEIGHT-1)
        row.played=text(row,"",12,NAME_WIDTH+CLIENT_WIDTH+5,0,PLAYED_WIDTH-19,{238/255,225/255,187/255},ROW_HEIGHT-1,"RIGHT")
        row.updated=text(row,"",11,NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH+8,0,UPDATED_WIDTH-24,{167/255,171/255,165/255},ROW_HEIGHT-1)
        local glow=solid(row,"HIGHLIGHT",203/255,184/255,130/255,12/255); glow:SetAllPoints()
        row:SetScript("OnEnter",function(owner) self:RowTooltip(owner) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row:RegisterForClicks("RightButtonUp")
        row:SetScript("OnClick",function(owner,button)
            if button ~= "RightButton" or not owner.entry then return end
            if self.removedOnly then
                if not H.V.Restore(self.db,owner.entry.char) then print(L.visibilityError) end
                GameTooltip:Hide(); self:Refresh()
            else self:ConfirmRemoval(owner.entry.char) end
        end)
    end
    self.empty=text(self.list,L.empty,11,8,0,684,MUTED,ROW_HEIGHT,"CENTER")
    self.scroll=rect("Slider",self.list,695,2,5,ROW_HEIGHT-4)
    self.scroll:SetOrientation("VERTICAL"); self.scroll:SetMinMaxValues(0,0); self.scroll:SetValueStep(1)
    if self.scroll.SetObeyStepOnDrag then self.scroll:SetObeyStepOnDrag(true) end
    self.scroll:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    self.scroll:GetThumbTexture():SetSize(4,28); self.scroll:GetThumbTexture():SetVertexColor(.55,.5,.38,.9)
    self.scroll:SetScript("OnValueChanged",function(_,v)
        if not self.refreshing then self.offset=math.floor(v+.5); self:Refresh() end
    end)
    self.footerFrame=rect("Frame",f,10,176+ROW_HEIGHT,700,26)
    self.footer=text(self.footerFrame,"",10,5,2,540,{166/255,166/255,155/255},24)
    self.footerFrame:EnableMouse(true)
    self.footerFrame:SetScript("OnEnter",function(owner) tooltip(owner,{self.footer:GetText()}) end)
    self.footerFrame:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.clientMenu=rect("Frame",self.clientButton,0,29,168,141)
    self.clientMenu:SetFrameLevel(f:GetFrameLevel()+30); skin(self.clientMenu,self.panelName)
    self.clientMenu:EnableMouse(true); self.clientMenu:Hide(); self.clientRows={}
    for i,flavor in ipairs({"all","retail","mists","tbc","era"}) do
        local b=rect("Button",self.clientMenu,8,8+(i-1)*25,152,25)
        b.label=text(b,flavor=="all" and L.allClients or L[flavor],11,7,0,140,nil,25)
        local glow=solid(b,"HIGHLIGHT",187/255,161/255,102/255,37/255); glow:SetAllPoints()
        b:SetScript("OnClick",function()
            self.flavor,self.offset=flavor~="all" and flavor or nil,0; self:CloseMenus(); self:Refresh()
        end)
        self.clientRows[flavor]=b
    end
    local creditColor={156/255,158/255,146/255,.85}
    self.creditVersion=text(self.footerFrame,"v"..C.Version(),10,555,2,36,creditColor,24,"RIGHT")
    self.creditWith=text(self.footerFrame,"with",10,596,2,24,creditColor,24)
    self.creditHeart=artwork(self.footerFrame,"Heart",9,9,625,9.5)
    self.creditAuthor=text(self.footerFrame,"by krebs3r",10,639,2,56,creditColor,24)

    self.menu=rect("Frame",self.realmButton,0,29,218,41); self.menu:SetFrameLevel(f:GetFrameLevel()+30)
    self.menuLayout=skin(self.menu,self.panelName); self.menu:EnableMouse(true); self.menu:EnableMouseWheel(true); self.menu:Hide()
    self.realmRows={}; self.realmOffset=0
    for i=1,6 do
        local b=rect("Button",self.menu,8,8+(i-1)*25,202,25)
        b.label=text(b,"",11,7,0,177,nil,25)
        local glow=solid(b,"HIGHLIGHT",187/255,161/255,102/255,37/255); glow:SetAllPoints()
        b:SetScript("OnClick",function(owner) self.realm,self.offset=owner.realm,0; self.menu:Hide(); self:Refresh() end)
        self.realmRows[i]=b
    end
    self.menu:SetScript("OnMouseWheel",function(_,delta)
        self.realmOffset=math.max(0,math.min(math.max(0,#self.realmChoices-6),self.realmOffset-delta*3)); self:RenderRealms()
    end)
    self.sortMenu=rect("Frame",f,10,177,180,91); self.sortMenu:SetFrameLevel(f:GetFrameLevel()+30)
    skin(self.sortMenu,self.panelName); self.sortMenu:EnableMouse(true); self.sortMenu:Hide(); self.sortRows={}
    for i,field in ipairs({"name","level","realm"}) do
        local b=rect("Button",self.sortMenu,8,8+(i-1)*25,164,25)
        b.label=text(b,L[field],11,7,0,140,nil,25)
        local glow=solid(b,"HIGHLIGHT",187/255,161/255,102/255,37/255); glow:SetAllPoints()
        b:SetScript("OnClick",function() self:SetSort(field) end); self.sortRows[field]=b
    end
    self.settings=rect("Frame",f,24,47,252,214); local settings=self.settings
    settings:SetFrameLevel(f:GetFrameLevel()+35); settings:EnableMouse(true); settings:Hide(); skin(settings,self.panelName)
    text(settings,L.settings,15,13,13,202,GOLD,22)
    self.settingsClose=closeButton(settings,222,15.5,17,function() settings:Hide() end)
    self.minimapToggle=rect("Button",settings,13,35,226,27)
    local toggleMinimap=function()
        self.db.settings.minimap=not self.db.settings.minimap; self:UpdateMinimap(); self:SettingsText()
    end
    -- Use the same native template as Soundstone. Its inset artwork occupies the
    -- old 16px square; the 24px control adds native checked, pressed and hover states.
    self.minimapBox=CreateFrame("CheckButton",nil,self.minimapToggle,"UICheckButtonTemplate")
    self.minimapBox:SetPoint("TOPLEFT",self.minimapToggle,"TOPLEFT",-4,-1.5)
    self.minimapBox:SetSize(24,24)
    self.minimapBox:SetScript("OnClick",function(owner)
        self.db.settings.minimap=owner:GetChecked() and true or false
        self:UpdateMinimap(); self:SettingsText()
    end)
    text(self.minimapToggle,L.minimap,11,23,0,203,nil,27)
    self.minimapToggle:SetScript("OnClick",toggleMinimap)
    text(settings,L.scale,11,13,68,177,{215/255,201/255,157/255},13.2)
    self.scaleLabel=text(settings,"",11,190,68,49,{215/255,201/255,157/255},13.2,"RIGHT")
    self.scaleSlider=rect("Slider",settings,13,87.2,226,18)
    self.scaleSlider:SetOrientation("HORIZONTAL"); self.scaleSlider:SetMinMaxValues(65,130); self.scaleSlider:SetValueStep(5)
    if self.scaleSlider.SetObeyStepOnDrag then self.scaleSlider:SetObeyStepOnDrag(true) end
    line(self.scaleSlider,0,6,226,6,131/255,119/255,89/255)
    line(self.scaleSlider,1,7,224,4,39/255,38/255,31/255)
    self.scaleFill=line(self.scaleSlider,1,7,0,4,194/255,142/255,35/255)
    self.scaleSlider:SetThumbTexture(ROOT..(C.Retail() and "GoldThumb" or "SilverThumb")..".tga")
    local thumb=self.scaleSlider:GetThumbTexture(); thumb:SetSize(10,18)
    thumb:SetTexCoord(C.Retail() and .2265625 or .2109375,C.Retail() and .765625 or .78125,.015625,.984375)
    self.scaleSlider:SetScript("OnValueChanged",function(_,value)
        if not self.updatingScale then
            self.db.settings.scale=math.max(.65,math.min(1.3,math.floor(value/5+.5)*.05))
            self:ApplyScale(); self:SettingsText()
        end
    end)
    self.reset=control(settings,L.reset,13,114.2,226,25,function() self:Position(true) end)
    self.done=control(settings,L.done,157,180.2,82,25,function() settings:Hide() end)
    self.removedToggle=control(settings,L.removedCharacters,13,147.2,226,25,function()
        self:SetRemovedView(not self.removedOnly)
    end,"Toggle")
    self.removedToggle:SetScript("OnEnter",function(owner) tooltip(owner,{L.removedCharacters,L.removalHelp}) end)
    self.removedToggle:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.removeDialog=rect("Frame",f,110,30,500,205)
    self.removeDialog:SetFrameLevel(f:GetFrameLevel()+50); self.removeDialog:EnableMouse(true)
    skin(self.removeDialog,self.panelName); self.removeDialog:Hide()
    text(self.removeDialog,L.removeTitle,14,18,14,464,GOLD,28)
    self.removeBody=text(self.removeDialog,"",12,18,49,464,nil,96)
    self.removeBody:SetWordWrap(true)
    self.removeCancel=control(self.removeDialog,L.cancel,230,162,118,27,function() self:CloseMenus() end,"Toggle")
    self.removeConfirm=control(self.removeDialog,L.remove,360,162,122,27,function()
        local identity=self.pendingRemoval
        if identity and not H.V.Remove(self.db,identity) then print(L.visibilityError) end
        self:CloseMenus(); self:Refresh()
    end)
    f:SetScript("OnHide",function() search:ClearFocus(); self:CloseMenus(); GameTooltip:Hide() end)
    f:SetScript("OnMouseDown",function() self:CloseMenus(); search:ClearFocus() end)
    self:LayoutRows(0); self:SettingsText()
end
function U:SetRemovedView(removedOnly)
    self.removedOnly=removedOnly == true
    self.realm,self.flavor,self.searchText,self.offset=nil,nil,"",0
    self:CloseMenus(); self.search:SetText(""); self:SettingsText(); self:Refresh()
end
function U:ConfirmRemoval(char)
    self:CloseMenus(); GameTooltip:Hide()
    self.pendingRemoval={sourceId=char.sourceId or self.db.sourceId,region=char.region or "unknown",flavor=char.flavor,guid=char.guid}
    self.removeBody:SetText(string.format(L.removeBody,C.Escape(char.name.." · "..char.realm)))
    self.removeDialog:Show()
end
function U:ToggleRealms()
    local shown=self.menu:IsShown(); self:CloseMenus(); if shown then return end
    self.realmChoices={{label=L.allRealms}}
    for _,name in ipairs(self.stats.realms) do self.realmChoices[#self.realmChoices+1]={label=name,realm=name} end
    self.realmOffset=0; self:RenderRealms(); self.menu:Show()
end
function U:ToggleClients()
    local shown=self.clientMenu:IsShown(); self:CloseMenus()
    self.clientMenu:SetShown(not shown)
end
function U:RenderRealms()
    for i,b in ipairs(self.realmRows) do
        local entry=self.realmChoices[i+self.realmOffset]; b:SetShown(entry~=nil)
        if entry then
            b.realm=entry.realm; b.label:SetText(entry.label)
            b.label:SetTextColor(unpack(entry.realm==self.realm and GOLD or {228/255,215/255,180/255}))
        end
    end
    self.menu:SetHeight(math.min(6,#self.realmChoices)*25+16); self.menuLayout()
end
function U:Scroll(delta)
    self.offset=math.max(0,math.min(self.maxOffset or 0,self.offset+delta)); self:Refresh()
end
function U:Refresh()
    if not self.frame then return end
    self.refreshing=true
    local mode=self.db.settings.format
    local display=H.S.Display(self.db,function(key,char) return T:Value(key,char) end)
    local _,overview=M.List(display)
    self.overviewStats=overview
    if self.removedOnly then display=H.S.Display(self.db,function(key,char) return T:Value(key,char) end,true) end
    local entries,stats=M.List(display,self.searchText,self.realm,self.sort,self.descending,nil,self.flavor)
    self.stats,self.visibleCount=stats,#entries; self:LayoutRows(#entries)
    self.total:SetText(overview.count>0 and overview.missing==overview.count and L.unavailable or M.Format(overview.total,mode))
    self.count:SetText(tostring(overview.count))
    self.realms:SetText("· "..(#overview.realms==1 and L.oneRealm or string.format(L.realms,#overview.realms)))
    self.realms:ClearAllPoints(); self.realms:SetPoint("TOPLEFT",280.2+occupied(self.count)+8,-35.5)
    self.realms:SetWidth(126.8-occupied(self.count)-8)
    self.session:SetText(M.SessionFormat(T:Session()))
    self.realmButton.label:SetText(self.realm or L.allRealms)
    self.clientButton.label:SetText(self.flavor and L[self.flavor] or L.allClients)
    selected(self.combined,mode=="combined"); selected(self.hours,mode=="hours")
    for field,header in pairs(self.headers) do
        local b=header.button
        local on=self.sort==field or (field=="name" and (self.sort=="level" or self.sort=="realm"))
        local title=field=="name" and self.removedOnly and L.removedCharacters or header.title
        b.label:SetText(title..(field=="name" and self.sort~="name" and on and " · "..L[self.sort] or ""))
        b.label:SetTextColor(unpack(on and GOLD or {197/255,191/255,171/255}))
        b.arrow:SetShown(on or field=="name")
        b.arrow:SetTexCoord(0,1,on and not self.descending and 1 or 0,on and not self.descending and 0 or 1)
        b.arrow:ClearAllPoints(); b.arrow:SetPoint("TOPLEFT",field=="seconds" and PLAYED_WIDTH-19 or 13+occupied(b.label),-10.5)
        b.arrow:SetVertexColor(unpack(on and GOLD or MUTED))
    end
    for field,b in pairs(self.sortRows) do b.label:SetTextColor(unpack(self.sort==field and GOLD or {228/255,215/255,180/255})) end
    self.maxOffset=math.max(0,#entries-CAPACITY); self.offset=math.min(self.offset,self.maxOffset)
    self.scroll:SetMinMaxValues(0,self.maxOffset); self.scroll:SetValue(self.offset); self.scroll:SetShown(self.maxOffset>0)
    for i,row in ipairs(self.rows) do
        local entry=entries[i+self.offset]; row.entry=entry; row:SetShown(entry~=nil)
        if entry then
            local char,active=entry.char,entry.key==T.key and entry.char._local
            row.active:SetShown(active); row.dot:SetShown(active)
            if active then row.bg:SetColorTexture(104/255,184/255,208/255,18/255)
            else row.bg:SetColorTexture(1,1,1,(i+self.offset)%2==0 and 3/255 or 0) end
            local x=active and 20 or 8
            row.name:ClearAllPoints(); row.name:SetPoint("TOPLEFT",x,-3); row.name:SetWidth(NAME_WIDTH-69-x)
            row.name:SetText(C.Escape(char.name)); row.name:SetTextColor(C.ClassColor(char.class))
            row.level:SetText(L.level.." "..(M.Number(char.level) and tostring(char.level) or "?"))
            row.level:ClearAllPoints(); row.level:SetPoint("TOPLEFT",x+occupied(row.name)+7,-5)
            row.realm:ClearAllPoints(); row.realm:SetPoint("TOPLEFT",x,-19); row.realm:SetWidth(NAME_WIDTH-8-x)
            row.realm:SetText(C.Escape(char.realm))
            row.client:SetText(C.Escape(M.ClientText(char)))
            row.guild:ClearAllPoints(); row.guild:SetPoint("TOPLEFT",x,-33); row.guild:SetWidth(NAME_WIDTH-8-x)
            row.guild:SetText(M.GuildText(char))
            row.played:SetText(M.Format(entry.seconds,mode))
            row.updated:SetText(active and entry.seconds and L.now or M.Age(char.updatedAt))
            row.updated:SetTextColor(unpack(active and {156/255,194/255,176/255} or {167/255,171/255,165/255}))
        end
    end
    self.empty:SetShown(#entries==0); self.empty:SetText(stats.count==0 and (self.removedOnly and L.noRemoved or L.noCharacters) or L.empty)
    local count=string.format(self.removedOnly and L.removedShown or L.shown,#entries,stats.count)
    if not self.removedOnly and (self.realm or self.flavor or (self.searchText and self.searchText~="")) then
        count=count.." · "..string.format(L.filteredTime,M.SumText(stats.visible,stats.visibleMissing,#entries,mode))
    end
    self.footer:SetText(count)
    self.refreshing=false
end
function U:Toggle()
    self:Create()
    if self.frame:IsShown() then self.frame:Hide()
    else self.frame:Show(); T:Request(); self:Refresh() end
end

function U:RowTooltip(row)
    local entry = row.entry
    if not entry then return end
    local char = entry.char
    local lines = {C.Escape(char.name.." · "..char.realm), L.level.." "..tostring(char.level or "?"), M.GuildText(char),
        string.format(L.fullTime,M.Format(entry.seconds,self.db.settings.format))}
    lines[#lines+1] = L.client..": "..C.Escape(M.ClientText(char))
    if entry.key == T.key and char._local then
        lines[#lines+1] = T.base and L.estimate or L.noSync
    elseif not M.Number(char.serverAt) or not M.Number(char.serverSeconds) then lines[#lines+1] = L.noSync
    elseif entry.seconds and entry.seconds>char.serverSeconds then lines[#lines+1] = L.estimate end
    if M.Number(char.serverAt) then
        lines[#lines+1] = {text=string.format(L.sync,date("%Y-%m-%d %H:%M",char.serverAt)),wrap=false}
    end
    lines[#lines+1] = self.removedOnly and L.restoreHint or L.removeHint
    if self.removedOnly then lines[#lines+1] = L.removalHelp end
    tooltip(row,lines)
end
function U:UpdateMinimap()
    if self.minimapBox then self.minimapBox:SetChecked(self.db.settings.minimap) end
    if not self.minimap then return end
    self.minimap:SetShown(self.db.settings.minimap)
    local angle=math.rad(self.db.settings.minimapAngle)
    local radius=Minimap:GetWidth()/2+7
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end
function U:Init(db)
    self.db=db
    if not Minimap then return end
    local b=C.Frame("Button","HourstoneMinimapButton",Minimap); self.minimap=b
    b:SetSize(MINIMAP_SIZE,MINIMAP_SIZE); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    -- Blizzard's tracking-button geometry, as used by LibDBIcon. The border's
    -- transparent padding differs between Retail and the Classic families.
    local retail=C.Retail()
    b.background=b:CreateTexture(nil,"BACKGROUND"); b.background:SetTexture(136467)
    b.background:SetSize(retail and 24 or 20,retail and 24 or 20)
    if retail then b.background:SetPoint("CENTER") else b.background:SetPoint("TOPLEFT",7,-5) end
    local iconSize=retail and 18 or 17
    b.icon=artwork(b,"Logo",iconSize,iconSize,7,6)
    if retail then b.icon:ClearAllPoints(); b.icon:SetPoint("CENTER") end
    b.mask=b:CreateMaskTexture(nil,"ARTWORK")
    b.mask:SetTexture(ROOT.."CircleMask.tga","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    b.mask:SetSize(MINIMAP_MASK,MINIMAP_MASK); b.mask:SetPoint("CENTER",b.icon,"CENTER",0,0)
    b.icon:AddMaskTexture(b.mask)
    b.border=b:CreateTexture(nil,"OVERLAY"); b.border:SetTexture(136430)
    b.border:SetSize(retail and 50 or 53,retail and 50 or 53); b.border:SetPoint("TOPLEFT",0,0)
    b:SetHighlightTexture(136477,"ADD")
    b:RegisterForClicks("LeftButtonUp"); b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function() if not b.suppressUntil or C.Now()>=b.suppressUntil then self:Toggle() end end)
    b:SetScript("OnEnter",function() tooltip(b,{"Hourstone – Azeroth Hours",L.open,L.move,L.commands,L.hint}) end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart",function()
        GameTooltip:Hide()
        b:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local mx,my=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale()
            self.db.settings.minimapAngle=math.deg(math.atan2(y/scale-my,x/scale-mx))%360; self:UpdateMinimap()
        end)
    end)
    b:SetScript("OnDragStop",function() b:SetScript("OnUpdate",nil); b.suppressUntil=C.Now()+.15 end)
    self:UpdateMinimap()
end
