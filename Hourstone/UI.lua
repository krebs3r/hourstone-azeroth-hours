local _, H = ...
local U, C, M, T, L = {}, H.C, H.M, H.T, H.L
H.UI = U
local ROOT = "Interface\\AddOns\\Hourstone\\Media\\"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD, MUTED = {243/255,206/255,112/255}, {169/255,170/255,162/255}
local WIDTH, ROW_HEIGHT, CAPACITY = 720, 50, 8
local PROGRESS_HEIGHT, TAB_HEIGHT, PROGRESS_NAME = 64, 32, 230
local PROGRESS_COLUMNS = {230,164,122,184}
local CATEGORIES = {"dungeon","raid","world"}
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
local function place(region,x,y,w,h)
    region:ClearAllPoints(); region:SetPoint("TOPLEFT",x,-y)
    if w then region:SetWidth(w) end
    if h then region:SetHeight(h) end
end
local function ellipsis(label,value)
    label:SetText(value)
    local width=label:GetUnboundedStringWidth()
    if width<=label:GetWidth() then return end
    local chars={}
    for c in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=c end
    repeat
        chars[#chars]=nil; label:SetText(table.concat(chars).."…")
    until #chars==0 or label:GetUnboundedStringWidth()<=label:GetWidth()
end
function U:IsProgress() return C.RetailProgress() and self.db.settings.view=="progress" end
function U:ApplyScale(layoutOnly)
    if self.windowDragging then return end
    if self.ready and not layoutOnly then self:Refresh(); return end
    local sw,sh=GetPhysicalScreenSize()
    local fitting=math.min((sw-20)/WIDTH,(sh-20)/self.frame:GetHeight())
    local requested=self.scaleDragging and self.dragScale or self.db.settings.scale
    self.frame:SetScale(math.min(requested,fitting)*(768/sh)/UIParent:GetEffectiveScale())
    self:Position()
end
function U:Position(reset)
    if self.windowDragging then return end
    local f,p=self.frame,self.db.settings.position
    if reset then self.db.settings.position=nil; p=nil; self.anchorHeight=f:GetHeight() end
    local height=p and tonumber(p.height) or self.anchorHeight or 262
    if not M.Number(height) or height<248 or height>244+CAPACITY*PROGRESS_HEIGHT then height=262 end
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
function U:FinishWindowDrag()
    if not self.windowDragging then return end
    self.frame:StopMovingOrSizing()
    self:SavePosition()
    self.windowDragging=nil
    self:Refresh()
end
function U:CloseMenus()
    self.menu:Hide(); self.sortMenu:Hide(); self.settings:Hide()
    if self.clientMenu then self.clientMenu:Hide() end
    if self.removeDialog then self.removeDialog:Hide(); self.pendingRemoval=nil end
    if self.progressTip then self.progressTip:Hide() end
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
    self.scaleFill:SetWidth(224*(self.db.settings.scale-M.SCALE_MIN)/(M.SCALE_MAX-M.SCALE_MIN))
end
function U:SetFormat(mode) self.db.settings.format=mode; self:Refresh() end
function U:SetView(view)
    if not C.RetailProgress() or (view~="played" and view~="progress") then return end
    self.viewSort=self.viewSort or {}
    self.viewSort[self.db.settings.view]={self.sort,self.descending}
    self.db.settings.view=view
    local sort=self.viewSort[view] or (view=="progress" and {"name",false} or {"seconds",true})
    self.sort,self.descending,self.offset=sort[1],sort[2],0
    self:CloseMenus(); self:Refresh()
    if view=="progress" and H.P then H.P:Schedule("open") end
end
function U:SetSort(field)
    if self.sort==field then self.descending=not self.descending
    else self.sort,self.descending=field,field=="seconds" or field=="level" or field=="updatedAt" end
    self.offset=0; self:CloseMenus(); self:Refresh()
end
function U:LayoutRows(count)
    local progress=self:IsProgress()
    local rowHeight=progress and PROGRESS_HEIGHT or ROW_HEIGHT
    local tabs=C.RetailProgress() and TAB_HEIGHT or 0
    local _,sh=GetPhysicalScreenSize()
    local base=212+tabs
    local requested=self.scaleDragging and self.dragScale or self.db.settings.scale
    local fittingRows=math.floor(((sh-20)/requested-base)/rowHeight)
    local slots=math.max(1,math.min(CAPACITY,fittingRows,count or self.visibleCount or 0))
    self.slots,self.rowHeight=slots,rowHeight; local h=slots*rowHeight
    self.frame:SetHeight(base+h); self.panelLayout()
    place(self.toolbar,10,114+tabs)
    place(self.table,10,152+tabs)
    self.table:SetHeight(24+h); self.list:SetHeight(h); self.scroll:SetHeight(h-4)
    place(self.scroll,progress and 684 or 695,progress and 18 or 2,progress and 14 or 5,progress and h-36 or h-4)
    self.scroll:GetThumbTexture():SetWidth(progress and 11 or 4)
    -- A single progress row leaves only 28 units of track. Keep travel space
    -- for dragging even at 200% on a small display.
    self.scroll:GetThumbTexture():SetHeight(math.min(28,self.scroll:GetHeight()/2))
    place(self.scrollDown,684,h-17)
    for _,divider in ipairs(self.headerDividers) do divider:SetShown(progress) end
    place(self.sortMenu,10,177+tabs)
    place(self.footerFrame,10,176+tabs+h)
    self.format:SetShown(not progress)
    if self.tabs then selected(self.playedTab,not progress); selected(self.progressTab,progress) end
    local fields={"name","flavor","seconds","updatedAt"}
    local titles={L.character,L.keystone,L.thisWeek,L.vault}
    local normal={NAME_WIDTH,CLIENT_WIDTH,PLAYED_WIDTH,UPDATED_WIDTH}
    local x=0
    for index,field in ipairs(fields) do
        local header=self.headers[field]; local width=progress and PROGRESS_COLUMNS[index] or normal[index]
        place(header.button,x,0,width,24)
        header.button.label:SetWidth(width-(not progress and field=="seconds" and 32 or 24))
        header.button.label:SetJustifyH(not progress and field=="seconds" and "RIGHT" or "LEFT")
        header.title=progress and titles[index] or L[({"character","client","played","updated"})[index]]
        x=x+width
    end
    for i,row in ipairs(self.rows) do
        place(row,0,(i-1)*rowHeight,700,rowHeight)
        row.active:SetHeight(rowHeight-1); place(row.separator,0,rowHeight-1)
        row.client:SetShown(not progress); row.played:SetShown(not progress); row.updated:SetShown(not progress)
        row.progress:SetShown(progress)
        for _,divider in ipairs(row.dividers) do divider:SetHeight(rowHeight-1); divider:SetShown(progress) end
    end
    self.empty:SetHeight(rowHeight)
    self:ApplyScale(true)
end
function U:Create()
    if self.frame then return end
    local f=C.Frame("Frame","HourstoneWindow",UIParent); self.frame=f
    f:SetSize(WIDTH,262); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true); f:Hide()
    self.panelName=C.RetailStyle() and "RetailPanel" or "ClassicPanel"
    self.panelLayout=skin(f,self.panelName)
    self:ApplyScale(); UISpecialFrames[#UISpecialFrames+1]="HourstoneWindow"
    self.header=rect("Frame",f,10,10,700,40)
    self.header:EnableMouse(true); self.header:RegisterForDrag("LeftButton")
    self.header:SetScript("OnDragStart",function()
        self:CloseMenus(); self.windowDragging=true; f:StartMoving()
    end)
    self.header:SetScript("OnDragStop",function() self:FinishWindowDrag() end)
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

    if C.RetailProgress() then
        self.tabs=rect("Frame",f,10,114,700,TAB_HEIGHT)
        self.playedTab=control(self.tabs,L.played,5,4,90,25,function() self:SetView("played") end)
        self.progressTab=control(self.tabs,L.progress,98,4,102,25,function() self:SetView("progress") end)
    end

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

    self.sort,self.descending,self.offset=self:IsProgress() and "name" or "seconds",not self:IsProgress(),0
    self.table=rect("Frame",f,10,152,700,24+ROW_HEIGHT); self.headers={}
    for _,spec in ipairs({{"name","character",0,NAME_WIDTH},{"flavor","client",NAME_WIDTH,CLIENT_WIDTH},
        {"seconds","played",NAME_WIDTH+CLIENT_WIDTH,PLAYED_WIDTH},{"updatedAt","updated",NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH,UPDATED_WIDTH}}) do
        local field,title,x,w=spec[1],L[spec[2]],spec[3],spec[4]
        local b=rect("Button",self.table,x,0,w,24)
        b.label=text(b,title,11,8,0,w-24,{197/255,191/255,171/255},24,field=="seconds" and "RIGHT" or "LEFT")
        if field=="seconds" then b.label:SetWidth(w-32) end
        b.arrow=arrow(b,field=="seconds" and w-19 or 80,10.5)
        b:SetScript("OnClick",function()
            if self:IsProgress() and field~="name" then return end
            if field=="name" then
                local shown=self.sortMenu:IsShown(); self:CloseMenus(); self.sortMenu:SetShown(not shown)
            else self:SetSort(field) end
        end)
        self.headers[field]={button=b,width=w,title=title}
    end
    line(self.table,0,23,700,1,169/255,160/255,139/255,101/255)
    self.headerDividers={}
    for _,x in ipairs({230,394,516}) do self.headerDividers[#self.headerDividers+1]=line(self.table,x,2,1,19,.43,.46,.43,.4) end
    self.list=rect("Frame",self.table,0,24,700,ROW_HEIGHT); self.list:EnableMouseWheel(true)
    self.list:SetScript("OnMouseWheel",function(_,delta) self:Scroll(-delta*3) end)
    self.rows={}
    for i=1,CAPACITY do
        local row=rect("Button",self.list,0,(i-1)*ROW_HEIGHT,700,ROW_HEIGHT); self.rows[i]=row
        row.bg=solid(row,"BACKGROUND",1,1,1,0); row.bg:SetAllPoints()
        row.active=line(row,0,0,2,ROW_HEIGHT-1,104/255,202/255,232/255)
        row.separator=line(row,0,ROW_HEIGHT-1,700,1,141/255,138/255,114/255,59/255)
        row.dividers={}
        for _,x in ipairs({230,394,516}) do row.dividers[#row.dividers+1]=line(row,x,0,1,ROW_HEIGHT-1,.43,.46,.43,.3) end
        row.dot=artwork(row,"LiveDot",5,5,8,8.5)
        row.name=text(row,"",13,8,3,NAME_WIDTH-77,nil,16)
        row.level=text(row,"",10,NAME_WIDTH-62,5,54,{196/255,184/255,154/255},12)
        row.realm=text(row,"",11,8,19,NAME_WIDTH-16,{168/255,170/255,165/255},13)
        row.guild=text(row,"",10,8,33,NAME_WIDTH-16,{150/255,165/255,156/255},13)
        row.client=text(row,"",11,NAME_WIDTH+8,0,CLIENT_WIDTH-16,{168/255,170/255,165/255},ROW_HEIGHT-1)
        row.played=text(row,"",12,NAME_WIDTH+CLIENT_WIDTH+5,0,PLAYED_WIDTH-19,{238/255,225/255,187/255},ROW_HEIGHT-1,"RIGHT")
        row.updated=text(row,"",11,NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH+8,0,UPDATED_WIDTH-24,{167/255,171/255,165/255},ROW_HEIGHT-1)
        row.progress=rect("Frame",row,PROGRESS_NAME,0,470,PROGRESS_HEIGHT)
        row.keyText=text(row.progress,"",12,12,11,140,GOLD,18)
        row.keyLevel=text(row.progress,"",12,120,11,34,GOLD,18,"RIGHT")
        row.keyNote=text(row.progress,"",10,12,31,140,MUTED,17)
        row.weekText=text(row.progress,"",15,176,11,98,GOLD,19)
        row.weekNote=text(row.progress,"",10,176,33,98,MUTED,16)
        row.keyHover=rect("Frame",row.progress,0,0,164,PROGRESS_HEIGHT)
        row.keyHover:EnableMouse(true)
        row.keyHover:SetScript("OnEnter",function() self:ProgressTooltip(row,"keystone") end)
        row.weekHover=rect("Frame",row.progress,164,0,122,PROGRESS_HEIGHT)
        row.weekHover:EnableMouse(true)
        row.weekHover:SetScript("OnEnter",function() self:ProgressTooltip(row,"weekly") end)
        row.vault={}
        for j,category in ipairs(CATEGORIES) do
            local group=rect("Frame",row.progress,286,5+(j-1)*18,174,18)
            group.label=text(group,L[category],10,12,0,62,{.78,.8,.8},18)
            group:EnableMouse(true)
            group:SetScript("OnEnter",function() self:ProgressTooltip(row,category) end)
            group:SetScript("OnLeave",function() self:HideProgressTooltip() end)
            group.slots={}
            for slot=1,3 do
                local box=rect("Frame",group,80+(slot-1)*23,1,16,16)
                box.edge=solid(box,"BACKGROUND",.5,.43,.25,1); box.edge:SetAllPoints()
                box.fill=line(box,1,1,14,14,.035,.06,.065,1)
                box.check=artwork(box,"Check",14,14,1,1,"OVERLAY")
                box.unknown=text(box,"?",11,0,0,16,MUTED,16,"CENTER")
                group.slots[slot]=box
            end
            row.vault[category]=group
        end
        row.keyHover:SetScript("OnLeave",function() self:HideProgressTooltip() end)
        row.weekHover:SetScript("OnLeave",function() self:HideProgressTooltip() end)
        local glow=solid(row,"HIGHLIGHT",203/255,184/255,130/255,12/255); glow:SetAllPoints()
        row:SetScript("OnEnter",function(owner) self:RowTooltip(owner) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide(); self:HideProgressTooltip() end)
        row:RegisterForClicks("RightButtonUp")
        local function rowClick(owner,button)
            if button ~= "RightButton" or not owner.entry then return end
            if self.removedOnly then
                if not H.V.Restore(self.db,owner.entry.char) then print(L.visibilityError) end
                GameTooltip:Hide(); self:Refresh()
            else self:ConfirmRemoval(owner.entry.char) end
        end
        row:SetScript("OnClick",rowClick)
        row.keyHover:SetScript("OnMouseUp",function(_,button) rowClick(row,button) end)
        row.weekHover:SetScript("OnMouseUp",function(_,button) rowClick(row,button) end)
        for _,group in pairs(row.vault) do group:SetScript("OnMouseUp",function(_,button) rowClick(row,button) end) end
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
    self.scrollUp=rect("Button",self.list,684,0,14,17); skin(self.scrollUp,"Toggle")
    self.scrollDown=rect("Button",self.list,684,ROW_HEIGHT-17,14,17); skin(self.scrollDown,"Toggle")
    self.scrollUp:SetScript("OnClick",function() self:Scroll(-1) end)
    self.scrollDown:SetScript("OnClick",function() self:Scroll(1) end)
    local up=arrow(self.scrollUp,3,6,8,5); up:SetTexCoord(0,1,1,0)
    arrow(self.scrollDown,3,6,8,5)
    self.footerFrame=rect("Frame",f,10,176+ROW_HEIGHT,700,26)
    self.footer=text(self.footerFrame,"",10,5,2,540,{166/255,166/255,155/255},24)
    self.footerFrame:EnableMouse(true)
    self.footerFrame:SetScript("OnEnter",function(owner) tooltip(owner,{self.footer:GetText(),self:IsProgress() and L.progressHint or L.hint}) end)
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
        self:SetMinimap(not self.db.settings.minimap); self:SettingsText()
    end
    -- Use the same native template as Soundstone. Its inset artwork occupies the
    -- old 16px square; the 24px control adds native checked, pressed and hover states.
    self.minimapBox=CreateFrame("CheckButton",nil,self.minimapToggle,"UICheckButtonTemplate")
    self.minimapBox:SetPoint("TOPLEFT",self.minimapToggle,"TOPLEFT",-4,-1.5)
    self.minimapBox:SetSize(24,24)
    self.minimapBox:SetScript("OnClick",function(owner)
        self:SetMinimap(owner:GetChecked() and true or false); self:SettingsText()
    end)
    text(self.minimapToggle,L.minimap,11,23,0,203,nil,27)
    self.minimapToggle:SetScript("OnClick",toggleMinimap)
    text(settings,L.scale,11,13,68,177,{215/255,201/255,157/255},13.2)
    self.scaleLabel=text(settings,"",11,190,68,49,{215/255,201/255,157/255},13.2,"RIGHT")
    self.scaleSlider=rect("Slider",settings,13,87.2,226,18)
    self.scaleSlider:SetOrientation("HORIZONTAL"); self.scaleSlider:SetMinMaxValues(M.SCALE_MIN*100,M.SCALE_MAX*100); self.scaleSlider:SetValueStep(M.SCALE_STEP*100)
    if self.scaleSlider.SetObeyStepOnDrag then self.scaleSlider:SetObeyStepOnDrag(true) end
    line(self.scaleSlider,0,6,226,6,131/255,119/255,89/255)
    line(self.scaleSlider,1,7,224,4,39/255,38/255,31/255)
    self.scaleFill=line(self.scaleSlider,1,7,0,4,194/255,142/255,35/255)
    self.scaleSlider:SetThumbTexture(ROOT..(C.RetailStyle() and "GoldThumb" or "SilverThumb")..".tga")
    local thumb=self.scaleSlider:GetThumbTexture(); thumb:SetSize(10,18)
    thumb:SetTexCoord(C.RetailStyle() and .2265625 or .2109375,C.RetailStyle() and .765625 or .78125,.015625,.984375)
    local function beginScaleDrag()
        if not self.scaleDragging then
            self.dragScale=self.db.settings.scale; self.scaleDragging=true
        end
    end
    self.scaleSlider:SetScript("OnValueChanged",function(_,value)
        if not self.updatingScale then
            -- Native track clicks may change the value before OnMouseDown.
            -- Capture the old scale before that first change moves the control.
            if IsMouseButtonDown and IsMouseButtonDown("LeftButton") then beginScaleDrag() end
            self.db.settings.scale=M.Scale(value/100)
            if not self.scaleDragging then self:ApplyScale() end
            self:SettingsText()
        end
    end)
    self.scaleSlider:SetScript("OnMouseDown",function(_,button)
        if button=="LeftButton" then beginScaleDrag() end
    end)
    local function finishScaleDrag()
        if not self.scaleDragging then return end
        self.scaleDragging,self.dragScale=nil,nil
        self:ApplyScale()
    end
    self.scaleSlider:SetScript("OnMouseUp",finishScaleDrag)
    settings:SetScript("OnHide",finishScaleDrag)
    self.scaleMin=text(settings,math.floor(M.SCALE_MIN*100).." %",10,13,108,70,MUTED,15)
    self.scaleMax=text(settings,math.floor(M.SCALE_MAX*100).." %",10,169,108,70,MUTED,15,"RIGHT")
    self.reset=control(settings,L.reset,13,136,137,25,function() self:Position(true) end,"Toggle")
    self.reset.label:SetFont(FONT,10,""); place(self.reset.label,5,0,127,25)
    self.done=control(settings,L.done,157,136,82,25,function() settings:Hide() end)
    self.removedToggle=control(settings,L.removedCharacters,13,177,226,25,function()
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
    self.progressTip=rect("Frame",f,WIDTH+12,26,310,180)
    self.progressTip:SetFrameLevel(f:GetFrameLevel()+45); self.progressTip:SetClampedToScreen(true)
    self.tipLayout=skin(self.progressTip,self.panelName); self.progressTip:Hide(); self.tipLines={}; self.tipMarks={}
    self.tipTitle=text(self.progressTip,"",16,16,12,278,GOLD,40); self.tipTitle:SetWordWrap(true)
    self.tipDivider=line(self.progressTip,16,57,278,1,.6,.5,.28,.7)
    self.tipFooterDivider=line(self.progressTip,16,150,278,1,.6,.5,.28,.7)
    self.ready=true
    f:SetScript("OnHide",function()
        self:FinishWindowDrag(); search:ClearFocus(); self:CloseMenus(); GameTooltip:Hide()
    end)
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
function U:RenderProgress(row)
    local info=H.P and H.P:Get(row.entry.char) or {supported=false}
    row.progressInfo=info
    local key,week,vault=info.keystone or {},info.weekly or {},info.vault or {}
    local stale=key.status=="stale"
    local hasKey=(key.status=="known" or stale) and key.present
    row.keyLevel:SetText(hasKey and ("+"..tostring(key.level)) or "")
    row.keyLevel:SetShown(hasKey)
    local levelWidth=hasKey and math.max(30,row.keyLevel:GetUnboundedStringWidth()) or 0
    place(row.keyLevel,152-levelWidth,11,levelWidth)
    row.keyText:SetWidth(140-(hasKey and levelWidth+4 or 0))
    local keyLabel=hasKey and (key.name or L.unknownDungeon) or ((key.status=="known" or stale) and L.noKeystone or L.notRecorded)
    ellipsis(row.keyText,info.supported and C.Escape(keyLabel) or L.progressUnavailable)
    row.keyNote:SetText(not info.supported and "" or (stale and L.stale or
        (key.status=="known" and (hasKey and M.Age(key.updatedAt) or L.confirmed) or L.noProgressData)))
    row.keyText:SetTextColor(unpack(stale and MUTED or (hasKey and GOLD or {.84,.86,.86})))
    row.keyLevel:SetTextColor(unpack(stale and MUTED or GOLD))
    local recorded=week.status=="known" or week.status=="stale"
    row.weekText:SetText(recorded and week.level and week.level>0 and ("+"..week.level) or "–")
    row.weekText:SetTextColor(unpack(week.status=="stale" and MUTED or GOLD))
    row.weekNote:SetText(week.status=="stale" and (week.expired and L.previousWeek or L.stale) or (recorded and week.level and week.level>0 and L.completed or ""))
    for _,category in ipairs(CATEGORIES) do
        local group=row.vault[category]
        local data=vault.rows and vault.rows[category] or {}
        for slot,box in ipairs(group.slots) do
            local value=data.slots and data.slots[slot]
            local known=value and (data.status=="known" or data.status=="stale")
            local unlocked=known and value.unlocked==true
            box.check:SetShown(unlocked)
            box.unknown:SetShown(info.supported and not known)
            box.fill:SetColorTexture(unlocked and .32 or .035,unlocked and .22 or .06,unlocked and .035 or .065,1)
            box.edge:SetColorTexture(unlocked and .95 or .5,unlocked and .7 or .43,unlocked and .25 or .25,1)
            box:SetAlpha(data.status=="stale" and .38 or (info.supported and 1 or .25))
        end
    end
end
function U:HideProgressTooltip()
    if self.progressTip then self.progressTip:Hide(); self.tipOwner=nil end
end
function U:ProgressTooltip(row,category)
    if not row.entry then return end
    GameTooltip:Hide()
    local info=H.P and H.P:Get(row.entry.char) or {supported=false}
    local titleKey=category=="weekly" and "thisWeek" or (category=="keystone" and "keystone" or "vault")
    self.tipTitle:SetText(C.Escape(row.entry.char.name).." · "..L[titleKey])
    local lines,marks={},{}
    local source=info[category]
    local function add(value) lines[#lines+1]=value end
    if not info.supported then add(L.progressUnavailable)
    elseif category=="keystone" then
        source=source or {}
        if source.present and (source.status=="known" or source.status=="stale") then
            add(C.Escape(source.name or L.unknownDungeon).." +"..tostring(source.level))
        else add((source.status=="known" or source.status=="stale") and L.noKeystone or L.notRecorded) end
        if source.status=="stale" then add(L.stale) end
    elseif category=="weekly" then
        source=source or {}
        add(source.level and source.level>0 and ("+"..source.level.." · "..L.completed) or
            ((source.status=="known" or source.status=="stale") and L.noRuns or L.notRecorded))
        if source.status=="stale" then add(source.expired and (L.stale.." · "..L.previousWeek) or L.stale) end
    else
        source=info.vault and info.vault.rows and info.vault.rows[category] or {}
        add(L[category])
        for index=1,3 do
            local slot=source.slots and source.slots[index]
            local value="?"
            if slot and (source.status=="known" or source.status=="stale") then
                marks[#lines+1]={unlocked=slot.unlocked,stale=source.status=="stale"}
                value=string.format("%s    %d / %d %s",string.format(L.slot,index),
                    math.min(slot.progress,slot.threshold),slot.threshold,L[category.."Units"])
                if slot.difficultyName then value=value.." · "..C.Escape(slot.difficultyName) end
                if slot.level and slot.level>0 and (category~="raid" or not slot.difficultyName) then
                    value=value.." · "..(category=="dungeon" and "+" or (L.level.." "))..slot.level
                end
            else value=string.format(L.slot,index).." · "..L.notRecorded end
            add(value)
        end
        if source.status=="stale" then add(L.stale) end
    end
    local footerStart=#lines+1
    local week=info.weekly or {}
    if titleKey=="vault" then
        add(string.format(L.bestThisWeek,week.status=="known" and week.level and week.level>0 and ("+"..week.level) or "–"))
    end
    add(string.format(L.recordedAt,source and source.updatedAt and M.Age(source.updatedAt) or L.notRecorded))
    -- Reserve enough wrapped lines even while native metrics are unavailable.
    -- WoW's height handles word boundaries; the conservative fallback also serves previews.
    local function wrappedHeight(label,minimum)
        local native=label.GetStringHeight and label:GetStringHeight() or 0
        local width=label:GetUnboundedStringWidth()
        return math.max(minimum,native>0 and native+4 or (math.ceil(width/label:GetWidth())+1)*15)
    end
    local titleHeight=wrappedHeight(self.tipTitle,40)
    self.tipTitle:SetHeight(titleHeight); place(self.tipDivider,16,17+titleHeight)
    local y=28+titleHeight
    for i,value in ipairs(lines) do
        if i==footerStart then place(self.tipFooterDivider,16,y+4); y=y+18 end
        local label=self.tipLines[i]
        if not label then label=text(self.progressTip,"",11,16,y,278,nil,32); label:SetWordWrap(true); self.tipLines[i]=label end
        local mark=marks[i]
        place(label,mark and 36 or 16,y,mark and 258 or 278,32); label:SetText(value); label:Show()
        local height=wrappedHeight(label,24); label:SetHeight(height)
        if mark then
            local icon=self.tipMarks[i]
            if not icon then
                icon=rect("Frame",self.progressTip,16,y+5,14,14)
                icon.edge=solid(icon,"BACKGROUND",.5,.43,.25,1); icon.edge:SetAllPoints()
                icon.fill=line(icon,1,1,12,12,.035,.06,.065,1)
                icon.check=artwork(icon,"Check",14,14,0,0,"OVERLAY")
                self.tipMarks[i]=icon
            end
            place(icon,16,y+5); icon:Show(); icon.check:SetShown(mark.unlocked==true)
            icon:SetAlpha(mark.stale and .38 or 1)
        elseif self.tipMarks[i] then self.tipMarks[i]:Hide() end
        label:SetTextColor(unpack(i>=footerStart and GOLD or {.85,.87,.89})); y=y+height+2
    end
    for i=#lines+1,#self.tipLines do self.tipLines[i]:Hide() end
    for i,mark in pairs(self.tipMarks) do if not marks[i] then mark:Hide() end end
    self.progressTip:SetHeight(y+10); self.tipLayout()
    self.progressTip:Show(); self.tipOwner=row; self.tipCategory=category; self.tipIdentity=row.entry.key
end
function U:Refresh()
    -- StartMoving owns the live anchor until release. Reapplying the saved
    -- position from a timer or display event would snap it back under the mouse.
    if not self.frame or self.windowDragging then return end
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
        local on=(not self:IsProgress() or field=="name") and (self.sort==field or (field=="name" and (self.sort=="level" or self.sort=="realm")))
        local title=field=="name" and self.removedOnly and L.removedCharacters or header.title
        b.label:SetText(title..(field=="name" and self.sort~="name" and on and " · "..L[self.sort] or ""))
        b.label:SetTextColor(unpack(on and GOLD or {197/255,191/255,171/255}))
        b.arrow:SetShown(on or field=="name")
        b.arrow:SetTexCoord(0,1,on and not self.descending and 1 or 0,on and not self.descending and 0 or 1)
        b.arrow:ClearAllPoints(); b.arrow:SetPoint("TOPLEFT",field=="seconds" and PLAYED_WIDTH-19 or 13+occupied(b.label),-10.5)
        b.arrow:SetVertexColor(unpack(on and GOLD or MUTED))
    end
    for field,b in pairs(self.sortRows) do b.label:SetTextColor(unpack(self.sort==field and GOLD or {228/255,215/255,180/255})) end
    self.maxOffset=math.max(0,#entries-self.slots); self.offset=math.min(self.offset,self.maxOffset)
    self.scroll:SetMinMaxValues(0,self.maxOffset); self.scroll:SetValue(self.offset); self.scroll:SetShown(self.maxOffset>0)
    self.scrollUp:SetShown(self:IsProgress() and self.maxOffset>0); self.scrollDown:SetShown(self:IsProgress() and self.maxOffset>0)
    for i,row in ipairs(self.rows) do
        local entry=i<=self.slots and entries[i+self.offset] or nil; row.entry=entry; row:SetShown(entry~=nil)
        if entry then
            local char,active=entry.char,entry.key==T.key and entry.char._local
            row.active:SetShown(active); row.dot:SetShown(active)
            if active then row.bg:SetColorTexture(104/255,184/255,208/255,18/255)
            else row.bg:SetColorTexture(1,1,1,(i+self.offset)%2==0 and 3/255 or 0) end
            local progress=self:IsProgress()
            local nameWidth=progress and PROGRESS_NAME or NAME_WIDTH
            local x=active and 20 or 8
            local nameY,realmY,guildY=progress and 7 or 3,progress and 25 or 19,progress and 42 or 33
            place(row.name,x,nameY,nameWidth-69-x)
            ellipsis(row.name,C.Escape(char.name)); row.name:SetTextColor(C.ClassColor(char.class))
            row.level:SetText(L.level.." "..(M.Number(char.level) and tostring(char.level) or "?"))
            place(row.level,x+occupied(row.name)+7,nameY+2)
            place(row.dot,8,nameY+5.5)
            place(row.realm,x,realmY,nameWidth-8-x)
            row.realm:SetText(C.Escape(char.realm))
            row.client:SetText(C.Escape(M.ClientText(char)))
            place(row.guild,x,guildY,nameWidth-8-x)
            row.guild:SetText(M.GuildText(char))
            row.played:SetText(M.Format(entry.seconds,mode))
            row.updated:SetText(active and entry.seconds and L.now or M.Age(char.updatedAt))
            row.updated:SetTextColor(unpack(active and {156/255,194/255,176/255} or {167/255,171/255,165/255}))
            if progress then self:RenderProgress(row) end
        end
    end
    self.empty:SetShown(#entries==0); self.empty:SetText(stats.count==0 and (self.removedOnly and L.noRemoved or L.noCharacters) or L.empty)
    local count=string.format(self.removedOnly and L.removedShown or (self:IsProgress() and L.progressLocal or L.shown),#entries,stats.count)
    if not self:IsProgress() and not self.removedOnly and (self.realm or self.flavor or (self.searchText and self.searchText~="")) then
        count=count.." · "..string.format(L.filteredTime,M.SumText(stats.visible,stats.visibleMissing,#entries,mode))
    end
    self.footer:SetText(count)
    if self.tipOwner and self.progressTip:IsShown() then
        if self.tipOwner.entry and self.tipOwner.entry.key==self.tipIdentity then self:ProgressTooltip(self.tipOwner,self.tipCategory)
        else self:HideProgressTooltip() end
    end
    self.refreshing=false
end
function U:Toggle()
    self:Create()
    if self.frame:IsShown() then self.frame:Hide()
    else self.frame:Show(); T:Request(); if H.P then H.P:Schedule("open") end; self:Refresh() end
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
function U:SetMinimap(shown)
    self.db.settings.minimap=shown==true; self:UpdateMinimap()
    if not self.db.settings.minimap then print(self.compartment and L.minimapHiddenCompartment or L.minimapHidden) end
end
function U:UpdateMinimap()
    if self.minimapBox then self.minimapBox:SetChecked(self.db.settings.minimap) end
    if not self.minimap then return end
    self.minimap:SetShown(self.db.settings.minimap)
    local angle=math.rad(self.db.settings.minimapAngle)
    local radius=Minimap:GetWidth()/2+7
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end
local function rightClick(...)
    for i=1,select("#",...) do
        local value=select(i,...)
        if value=="RightButton" or (type(value)=="table" and value.buttonName=="RightButton") then return true end
    end
    return false
end
-- Clients with the Addons menu list Hourstone there. The minimap button has no
-- right-click action, so the menu entry ignores right clicks as well.
function U:CreateCompartment()
    if not C.HasAddonCompartment() then return end
    local owner=function(frame) return type(frame)=="table" and frame or AddonCompartmentFrame end
    local ok=pcall(AddonCompartmentFrame.RegisterAddon,AddonCompartmentFrame,{
        text="Hourstone",icon=ROOT.."Logo.tga",notCheckable=true,registerForAnyClick=true,
        func=function(...) if not rightClick(...) then self:Toggle() end end,
        funcOnEnter=function(frame) tooltip(owner(frame),{"Hourstone – Azeroth Hours",L.open,L.commands}) end,
        funcOnLeave=function() GameTooltip:Hide() end,
    })
    self.compartment=ok or nil
end
function U:Init(db)
    self.db=db
    self:CreateCompartment()
    -- The minimap button becomes opt-in once the Addons menu entry exists.
    -- A later opt-in through the settings or /hourstone minimap is kept.
    if self.compartment and db.settings.compartmentMigrated~=true then
        db.settings.minimap,db.settings.compartmentMigrated=false,true
    end
    if not Minimap then return end
    local b=C.Frame("Button","HourstoneMinimapButton",Minimap); self.minimap=b
    b:SetSize(MINIMAP_SIZE,MINIMAP_SIZE); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    -- Blizzard's tracking-button geometry, as used by LibDBIcon. The border's
    -- transparent padding differs between Retail and the Classic families.
    local retail=C.RetailStyle()
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
