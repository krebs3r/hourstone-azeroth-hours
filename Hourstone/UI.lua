local _, H = ...
local U, C, M, T, L, Th = {}, H.C, H.M, H.T, H.L, H.Theme
H.UI = U
local ROOT = "Interface\\AddOns\\Hourstone\\Media\\"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
-- Interface colors come from the theme's palette (Theme.lua) by key. These colors carry
-- information and stay the same under every theme.
local INFO_MUTED = {169/255,170/255,162/255}
local WIDTH, ROW_HEIGHT, CAPACITY = 720, 50, 8
local PROGRESS_HEIGHT, TAB_HEIGHT, PROGRESS_NAME = 64, 32, 230
local PROGRESS_COLUMNS = {230,164,122,184}
local CATEGORIES = {"dungeon","raid","world"}
local NAME_WIDTH, CLIENT_WIDTH, PLAYED_WIDTH, UPDATED_WIDTH = 280, 120, 185, 115
local SEARCH_WIDTH, FILTER_WIDTH, FORMAT_WIDTH, COMBINED_WIDTH = 216, 139, 185, 111
local MINIMAP_SIZE, MINIMAP_MASK = 31, 24
-- WoW: Forever is offered only where a row can match it; see U:LayoutClients.
local CLIENT_CHOICES = {"all","retail","forever","mists","tbc","era"}

local function rect(kind,parent,x,y,w,h,name)
    local f=C.Frame(kind,name,parent)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetSize(w,h)
    return f
end
-- solid and line paint from the palette by key; a table of numbers is an information
-- color, painted as it is and never repainted by a theme.
local function solid(parent,layer,color)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND")
    if type(color)=="table" then Th.Raw(t,nil,color[1],color[2],color[3],color[4] or 1) else Th.Paint(t,color) end
    return t
end
local function line(parent,x,y,w,h,color)
    local t=solid(parent,"BORDER",color)
    t:SetPoint("TOPLEFT",x,-y); t:SetSize(w,h); return t
end
local function text(parent,value,size,x,y,width,color,height,align)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetFont(FONT,size,""); f:SetPoint("TOPLEFT",x,-y)
    -- Essential labels always have reserved space, even while the window is hidden.
    -- Never size a title or label from a font metric that may not be ready yet.
    f:SetSize(width,height or size*1.2)
    f:SetJustifyH(align or "LEFT"); f:SetJustifyV("MIDDLE"); f:SetWordWrap(false)
    if type(color)=="table" then Th.Raw(f,"text",unpack(color)) else Th.Paint(f,color or "text","text") end
    f:SetText(value or "")
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
-- The standard skin: one of Soundstone's sprites as nine regions. Th.Plate adds the flat
-- skin beside it ("panel", "control" or "field"); the theme shows one of the two.
local function skin(frame,name,kind)
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
    layout()
    Th.Plate(frame,kind or ((name=="Toggle" or name=="ToggleRed") and "control" or "panel"),textures)
    return layout,textures
end
-- A control's label rests in the color of its state; under a flat theme it turns to
-- the accent while the pointer is over it, also when a Refresh repaints its state.
-- `tip` adds a tooltip to the same hover.
local function restLabel(b) Th.Paint(b.label,(Th.flat and b.hovered) and "hover" or b.rest,"text") end
local function control(parent,label,x,y,w,h,action,style)
    local b=rect("Button",parent,x,y,w,h)
    local _,textures=skin(b,style or "ToggleRed"); b.background=textures
    b.label=text(b,label,11,8,0,w-16,"label",h,"CENTER"); b.rest="label"
    local glow=solid(b,"HIGHLIGHT","hoverControl"); glow:SetAllPoints(); b.glow=glow
    b:SetScript("OnClick",action)
    b:SetScript("OnEnter",function(owner) owner.hovered=true; restLabel(owner); if owner.tip then owner.tip(owner) end end)
    b:SetScript("OnLeave",function(owner) owner.hovered=nil; restLabel(owner); if owner.tip then GameTooltip:Hide() end end)
    return b
end
local function selected(b,on)
    b.chosen=on
    for _,t in ipairs(b.background) do
        t:SetDesaturated(not on); t:SetVertexColor(on and 1 or .65,on and 1 or .58,on and 1 or .48)
    end
    b.rest=on and (b.chosenKey or "chosenLabel") or "unchosenLabel"; restLabel(b); Th.Update(b)
end
-- The confirming button of a pair: accent label and underline under a flat theme.
local function primary(b) b.primary=true; b.rest="primaryLabel"; restLabel(b); Th.Update(b) end
local function arrow(parent,x,y,w,h)
    local t=artwork(parent,"Arrow",w or 5,h or 3,x,y)
    Th.Paint(t,"arrow","vertex"); return t
end
local function closeButton(parent,x,y,size,action)
    local b=rect("Button",parent,x,y,size,size)
    b:SetNormalTexture(ROOT.."HeaderClose.tga")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    Th.Mute(b:GetNormalTexture()); Th.Mute(b:GetHighlightTexture())
    -- Flat: a ground square with a muted cross that turns to the accent on hover. Built only
    -- where the forever look is applied.
    Th.Plate(b,"square")
    Th.Later(function() b.glyph=Th.Flat(text(b,"×",math.floor(size*.75+.5),0,0,size,"muted",size,"CENTER")) end)
    b:SetScript("OnClick",action)
    b:SetScript("OnEnter",function(owner) if owner.glyph then Th.Paint(owner.glyph,"hover","text") end end)
    b:SetScript("OnLeave",function(owner) if owner.glyph then Th.Paint(owner.glyph,"muted","text") end end)
    return b
end

-- WoW: Forever's own art, built the first time the forever look finds it (U:BuildArt), never on
-- the other clients. The window frame is Blizzard's ButtonFrameTemplateNoPortrait nine-slice over
-- the content, with the client's ground and the streaks under the title strip, as Soundstone 0.4.0
-- wears it. The border is anchored so its opaque metal ends flush with the frame (Soundstone's
-- measurement at 1.3125 pixels per unit): the art starts 4.4 units inside its box on the left and
-- 3.35 above it. Its sizes are Hourstone's units, so it scales with the Hourstone size.
local BORDER={left=-4.4,top=-3.35,right=.5,bottom=.35}
-- Inside the frame the header moves into the title strip and the content 20 units up.
local LIFT=20
-- Forever's red button art sits 0.8 units below its rectangle's centre; a symbol takes the art's centre.
local SYMBOL_DROP=.8
local function frameWindow(frame,art)
    local A,w=Th.ART.window,{}
    local border=C.Frame("Frame",nil,frame); w.border=border
    border:SetPoint("TOPLEFT",BORDER.left,BORDER.top); border:SetPoint("BOTTOMRIGHT",BORDER.right,BORDER.bottom)
    -- Above the content, as Blizzard's NineSlice is; the header controls sit above it in turn.
    border:SetFrameLevel(frame:GetFrameLevel()+10); border:EnableMouse(false)
    NineSliceUtil.ApplyLayoutByName(border,A.layout)
    w.ground=frame:CreateTexture(nil,"BACKGROUND",nil,-6); w.ground:SetTexture(A.ground,"REPEAT","REPEAT")
    w.ground:SetHorizTile(true); w.ground:SetVertTile(true)
    w.ground:SetPoint("TOPLEFT",border,"TOPLEFT",7,-21); w.ground:SetPoint("BOTTOMRIGHT",border,"BOTTOMRIGHT",-2,2)
    if art.streaks then
        w.streaks=frame:CreateTexture(nil,"BACKGROUND",nil,-5); w.streaks:SetAtlas(Th.ART.streaks); w.streaks:SetHeight(43); w.streaks:SetHorizTile(true)
        w.streaks:SetPoint("TOPLEFT",border,"TOPLEFT",6,-21); w.streaks:SetPoint("TOPRIGHT",border,"TOPRIGHT",-2,-21)
    end
    -- Titles and header controls of the popups ride above the border.
    w.top=C.Frame("Frame",nil,frame); w.top:SetAllPoints(border); w.top:SetFrameLevel(frame:GetFrameLevel()+12); w.top:EnableMouse(false)
    frame.window=w
    return w
end
-- Forever crops the bottom corners of short frames so they cannot overlap the top ones (only
-- Forever has it). Called again whenever the frame's height changes.
local function crop(frame)
    local w=frame.window
    if not w or type(NineSliceUtil)~="table" or type(NineSliceUtil.UpdateCornerCropping)~="function" then return end
    pcall(NineSliceUtil.UpdateCornerCropping,{NineSlice=w.border,layoutType=Th.ART.window.layout},frame:GetHeight()+BORDER.top-BORDER.bottom)
end
-- Blizzard's window title: size 12 in NORMAL_FONT_COLOR, centred, 6 units below the border's top.
local function frameTitle(parent,border,value,key,width)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont(FONT,12,""); t:SetPoint("TOP",border,"TOP",0,-6); t:SetWidth(width)
    t:SetJustifyH("CENTER"); t:SetJustifyV("MIDDLE"); t:SetWordWrap(false)
    Th.Paint(t,key,"text"); t:SetText(value)
    return t
end
-- Forever's close button: Blizzard's art and place (28 x 28 at the border's TOPRIGHT 0,3) with
-- Hourstone's own action; the stock OnClick would hide the frame through HideUIPanel.
local function frameClose(parent,border,action)
    local A=Th.ART.window.close
    local b=C.Frame("Button",nil,parent); b:SetSize(28,28); b:SetPoint("TOPRIGHT",border,"TOPRIGHT",0,3)
    b:SetNormalAtlas(A.normal); b:SetPushedAtlas(A.pushed); b:SetHighlightAtlas(A.highlight,"ADD")
    b:RegisterForClicks("LeftButtonUp"); b:SetScript("OnClick",action)
    return b
end
-- A header button as Baganator's and Soundstone's on Forever: UIPanelButtonTemplate at 32 x 22 with
-- a gold symbol on the art's centre.
local function frameButton(parent,border,file,size,action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(32,22); b:SetText("")
    b:SetPoint("TOPLEFT",border,"TOPLEFT",8,1)
    b.symbol=b:CreateTexture(nil,"ARTWORK"); b.symbol:SetTexture(file); b.symbol:SetSize(size,size)
    b.symbol:SetPoint("CENTER",0,-SYMBOL_DROP); Th.Paint(b.symbol,"buttonIcon","vertex")
    b:RegisterForClicks("LeftButtonUp"); b:SetScript("OnClick",action)
    return b
end
-- Forever's push button over a flat control: UIPanelButtonTemplate at the control's rectangle,
-- with its label. A click is the control's click, its tooltip the control's tooltip; the
-- template keeps its own label colors (gold, white under the pointer).
local function pushButton(parent,owner)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint(owner:GetPoint(1)); b:SetSize(owner:GetWidth(),owner:GetHeight())
    b:SetText(owner.label:GetText())
    local label=b:GetFontString(); label:ClearAllPoints(); label:SetPoint("CENTER")
    label:SetFont(FONT,owner.labelSize or 11,""); label:SetWordWrap(false)
    -- The control is hidden meanwhile, so its action is called directly.
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick",function(_,mouse) local action=owner:GetScript("OnClick"); if action then action(owner,mouse) end end)
    b:HookScript("OnEnter",function(self) if owner.tip then owner.tip(self) end end)
    b:HookScript("OnLeave",function() if owner.tip then GameTooltip:Hide() end end)
    owner.twin=b
    return b
end
local function setLabel(b,value) b.label:SetText(value); if b.twin then b.twin:SetText(value) end end
-- Forever's dropdown field and arrow (WowStyle1DropdownTemplate's art) on a filter button. The
-- arrow follows Blizzard's states: pressed, hovered, its menu open, or at rest.
local function dropArrow(b)
    local d=b.dropdown; if not d then return end
    local A=Th.ART.dropdown
    local atlas=(b.down and (b.hovered and A.pressedHover or A.pressed)) or (b.hovered and A.hover) or (d.menu:IsShown() and A.open) or A.normal
    d.arrow:SetAtlas(atlas,true)
end
local function dropdownArt(b,menu)
    local d={menu=menu}
    d.field=b:CreateTexture(nil,"BACKGROUND",nil,1); d.field:SetAtlas(Th.ART.dropdown.field,true)
    d.field:ClearAllPoints(); d.field:SetPoint("TOPLEFT",-8,7); d.field:SetPoint("BOTTOMRIGHT",8,-9)
    d.arrow=b:CreateTexture(nil,"OVERLAY"); d.arrow:SetPoint("RIGHT",b,"RIGHT",1,-3)
    b.dropdown=d
    b:HookScript("OnEnter",dropArrow); b:HookScript("OnLeave",dropArrow)
    b:HookScript("OnMouseDown",function(owner) owner.down=true; dropArrow(owner) end)
    b:HookScript("OnMouseUp",function(owner) owner.down=nil; dropArrow(owner) end)
    menu:HookScript("OnShow",function() dropArrow(b) end); menu:HookScript("OnHide",function() dropArrow(b) end)
    dropArrow(b)
end
-- The format toggle on Forever: one dropdown field (the filter buttons' art, without an arrow) over
-- both halves, where the filter fields lie in the toolbar, and a one-pixel divider in the gap
-- between the halves, 15 units high on the field's middle, in the flat look's outline color.
local function formatArt(format,split)
    local a={}
    a.field=format:CreateTexture(nil,"BACKGROUND",nil,1); a.field:SetAtlas(Th.ART.dropdown.field,true)
    a.field:ClearAllPoints(); a.field:SetPoint("TOPLEFT",-8,7.5); a.field:SetPoint("BOTTOMRIGHT",8,-9.5)
    a.divider=format:CreateTexture(nil,"ARTWORK"); Th.Paint(a.divider,"outline")
    a.divider:SetPoint("TOP",format,"TOPLEFT",split,-5); a.divider:SetHeight(15)
    format.art=a
end
-- The search field in the same field, placed as on the filter buttons (it has their height and row).
local function searchArt(search)
    local t=search:CreateTexture(nil,"BACKGROUND",nil,1); t:SetAtlas(Th.ART.dropdown.field,true)
    t:ClearAllPoints(); t:SetPoint("TOPLEFT",-8,7); t:SetPoint("BOTTOMRIGHT",8,-9)
    search.field=t
end
-- The divider is one physical pixel wide, measured again with the flat skin's lines.
local function sizeDivider(format) if format and format.art then format.art.divider:SetWidth(Th.Pixel(format)) end end
-- Forever's dropdown list (MenuStyle1Mixin's art): 10 beyond the sides, 3 above and below, alpha .925.
local function menuArt(menu)
    local t=menu:CreateTexture(nil,"BACKGROUND",nil,1); t:SetAtlas(Th.ART.menu)
    t:SetPoint("TOPLEFT",-10,3); t:SetPoint("BOTTOMRIGHT",10,-3); t:SetAlpha(.925)
    menu.art=t
end
-- Forever's settings-slider track (MinimalSliderTemplate's three pieces at their atlas size),
-- under the fill.
local function trackArt(s)
    local A,a=Th.ART.track,{}
    a.left=s:CreateTexture(nil,"BACKGROUND",nil,1); a.left:SetAtlas(A.left,true); a.left:SetPoint("LEFT")
    a.right=s:CreateTexture(nil,"BACKGROUND",nil,1); a.right:SetAtlas(A.right,true); a.right:SetPoint("RIGHT")
    a.middle=s:CreateTexture(nil,"BACKGROUND",nil,1); a.middle:SetAtlas(A.middle,true)
    a.middle:SetPoint("TOPLEFT",a.left,"TOPRIGHT"); a.middle:SetPoint("TOPRIGHT",a.right,"TOPLEFT")
    s.track=a
end
-- Blizzard's inset (InsetFrameTemplate's inner nine-slice) under the character table, at the
-- window's own level, as the template sets it. In place of the template's cool marble, the window's
-- own rock runs on under the table, darkened to 45 % by black at 0.55 where the template has its
-- ground (BACKGROUND -5, above the window's rock at -6).
local function insetArt(frame,anchor)
    local A=Th.ART.inset
    local inset=C.Frame("Frame",nil,frame); inset:SetFrameLevel(frame:GetFrameLevel()); inset:EnableMouse(false)
    inset:SetPoint("TOPLEFT",anchor,"TOPLEFT",0,0); inset:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",0,0)
    inset.ground=inset:CreateTexture(nil,"BACKGROUND",nil,-5); Th.Paint(inset.ground,"insetShade"); inset.ground:SetAllPoints(inset)
    NineSliceUtil.ApplyLayoutByName(inset,A.layout)
    return inset
end
local function tooltip(owner,lines)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT"); GameTooltip:ClearLines()
    local r,g,b=Th.Color("tooltipText")
    for _,value in ipairs(lines) do
        if type(value)=="table" then GameTooltip:AddLine(value.text,r,g,b,value.wrap~=false)
        else GameTooltip:AddLine(value,r,g,b,true) end
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
    -- One physical pixel is 1 / size here, so the flat skin's lines are measured again.
    Th.SizeAll(); sizeDivider(self.format); if self.scaleFill then self:SizeScaleFill() end
    self:Position()
end
function U:Position(reset)
    if self.windowDragging then return end
    local f,p=self.frame,self.db.settings.position
    if reset then self.db.settings.position=nil; p=nil; self.anchorHeight=f:GetHeight() end
    local height=p and tonumber(p.height) or self.anchorHeight or 262
    if not M.Number(height) or height<(self.framed and 242 or 248) or height>244+CAPACITY*PROGRESS_HEIGHT then height=262 end
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
    setLabel(self.removedToggle,self.removedOnly and L.showTracked or L.removedCharacters)
    self.minimapBox:SetChecked(self.db.settings.minimap)
    self.scaleLabel:SetText(math.floor(self.db.settings.scale*100+.5).." %")
    self.updatingScale=true; self.scaleSlider:SetValue(self.db.settings.scale*100); self.updatingScale=false
    self:SizeScaleFill()
end
-- The fill lies inside the track's outline: one unit under the sprites, one physical pixel under
-- the flat skin. On Forever's track it keeps clear of the rounded ends, 4 units in, 3 units high on
-- the track's middle, as Soundstone's.
function U:SizeScaleFill()
    local fraction=(self.db.settings.scale-M.SCALE_MIN)/(M.SCALE_MAX-M.SCALE_MIN)
    if self.trackShown then place(self.scaleFill,4,7.5,218*fraction,3); return end
    local inset=Th.flat and Th.Pixel(self.scaleSlider) or 1
    place(self.scaleFill,inset,6+inset,(226-2*inset)*fraction,6-2*inset)
end
-- The slider thumb is one texture, so a look swaps its art rather than hiding it: Forever's copper
-- diamond at its atlas size (resetTexCoords drops the sprite's sub-rectangle), the flat square, or
-- the sprite exactly as 0.3.7 set it.
function U:ApplyThumb(atlas)
    local thumb=self.scaleSlider:GetThumbTexture()
    if atlas and pcall(thumb.SetAtlas,thumb,Th.ART.thumb,true,nil,true) then
        self.thumbAtlas=true; thumb:SetDrawLayer("OVERLAY",7); thumb:SetBlendMode("BLEND"); Th.Raw(thumb,"vertex",1,1,1,1)
        return
    end
    if self.thumbAtlas then
        self.thumbAtlas=nil; thumb:SetSize(10,18); thumb:SetDrawLayer("ARTWORK"); thumb:SetBlendMode("BLEND")
    end
    Th.Paint(thumb,"sliderThumb","vertex")
    if Th.flat then thumb:SetTexture("Interface\\Buttons\\WHITE8X8"); thumb:SetTexCoord(0,1,0,1); return end
    local retail=C.RetailStyle()
    thumb:SetTexture(ROOT..(retail and "GoldThumb" or "SilverThumb")..".tga")
    thumb:SetTexCoord(retail and .2265625 or .2109375,retail and .765625 or .78125,.015625,.984375)
end
-- Builds the pieces of Forever's art the client can draw, each group once.
function U:BuildArt(art)
    local f=self.frame
    if art.window and not f.window then
        for _,frame in ipairs({f,self.settings,self.removeDialog}) do frameWindow(frame,art) end
        crop(self.settings); crop(self.removeDialog)
        local border=f.window.border
        self.frameGear=frameButton(f,border,"Interface\\WorldMap\\GEAR_64GREY",17,function() self:ToggleSettings() end)
        self.frameClose=frameClose(f,border,function() f:Hide() end)
        self.frameTitle=frameTitle(self.header,border,"Hourstone – Azeroth Hours","title",560)
        for _,b in ipairs({self.frameGear,self.frameClose}) do b:SetFrameLevel(f:GetFrameLevel()+12) end
        local s,d=self.settings.window,self.removeDialog.window
        self.settingsFrameTitle=frameTitle(s.top,s.border,L.settings,"heading",190)
        self.settingsFrameClose=frameClose(s.top,s.border,function() self.settings:Hide() end)
        self.removeFrameTitle=frameTitle(d.top,d.border,L.removeTitle,"heading",440)
        self.pushButtons={}
        for _,b in ipairs({self.reset,self.done,self.removedToggle}) do self.pushButtons[#self.pushButtons+1]=pushButton(self.settings,b) end
        for _,b in ipairs({self.removeCancel,self.removeConfirm}) do self.pushButtons[#self.pushButtons+1]=pushButton(self.removeDialog,b) end
    end
    if art.inset and not self.inset then self.inset=insetArt(f,self.table) end
    if art.dropdown and not self.realmButton.dropdown then
        dropdownArt(self.realmButton,self.menu); dropdownArt(self.clientButton,self.clientMenu)
        formatArt(self.format,COMBINED_WIDTH+1.5); searchArt(self.search)
    end
    if art.menu and not self.menu.art then for _,menu in ipairs({self.menu,self.clientMenu,self.sortMenu}) do menuArt(menu) end end
    if art.track and not self.scaleSlider.track then trackArt(self.scaleSlider) end
end
-- Applies the look in force to what is built: Forever's art where the client has it, the flat look
-- where it does not, the sprites under the standard look. Nothing moves on the other clients; inside
-- Forever's frame the header moves into the title strip and the content 20 units up.
function U:ApplyLook()
    local art,forever=Th.art,Th.flat
    if forever then self:BuildArt(art) end
    local framed=forever and art.window==true
    self.framed=framed
    for _,frame in ipairs({self.frame,self.settings,self.removeDialog}) do
        Th.Cover(frame,framed)
        if frame.window then
            for key,piece in pairs(frame.window) do piece:SetShown(framed and (key~="streaks" or art.streaks==true)) end
        end
    end
    -- The header: 0.3.7's, or the frame's title strip between gear and close button, which drags the window.
    local header=self.header
    if framed then
        header:ClearAllPoints(); header:SetPoint("TOPLEFT",self.frame.window.border,"TOPLEFT",40,1)
        header:SetSize(WIDTH+BORDER.right-BORDER.left-40-28,22); header:SetFrameLevel(self.frame:GetFrameLevel()+12)
    else place(header,10,10,700,40); header:SetFrameLevel(self.headerLevel) end
    for _,region in ipairs({self.gear,self.logo,self.title,self.close,self.headerRule}) do region:SetShown(not framed) end
    for _,region in ipairs({self.settingsHeading,self.settingsClose,self.removeHeading,
        self.reset,self.done,self.removedToggle,self.removeCancel,self.removeConfirm}) do region:SetShown(not framed) end
    if self.frameGear then
        for _,region in ipairs({self.frameGear,self.frameClose,self.frameTitle,self.settingsFrameClose}) do region:SetShown(framed) end
        for _,b in ipairs(self.pushButtons) do b:SetShown(framed) end
    end
    place(self.summary,10,framed and 50-LIFT or 50)
    place(self.settings,framed and 10 or 24,framed and 28 or 47)
    if self.inset then self.inset:SetShown(framed and art.inset==true) end
    -- Filter buttons, menus and the slider: Forever's art, each where the client has it.
    local dropdown=forever and art.dropdown==true
    for _,b in ipairs({self.realmButton,self.clientButton}) do
        Th.Cover(b,dropdown); b.arrow:SetShown(not dropdown)
        if b.dropdown then
            b.dropdown.field:SetShown(dropdown); b.dropdown.arrow:SetShown(dropdown); b.glow:SetAlpha(dropdown and 0 or 1)
        end
    end
    Th.Cover(self.search,dropdown); if self.search.field then self.search.field:SetShown(dropdown) end
    -- The format toggle in the same field: the chosen half bright, the other muted (Refresh paints them).
    if self.format.art then
        for _,t in pairs(self.format.art) do t:SetShown(dropdown) end
        for _,b in ipairs({self.combined,self.hours}) do
            Th.Cover(b,dropdown); b.glow:SetAlpha(dropdown and 0 or 1); b.chosenKey=dropdown and "text" or nil
        end
    end
    local menu=forever and art.menu==true
    self.menuBottom=menu and 15 or 8
    for _,frame in ipairs({self.menu,self.clientMenu,self.sortMenu}) do
        Th.Cover(frame,menu); if frame.art then frame.art:SetShown(menu) end
    end
    self.sortMenu:SetHeight(83+self.menuBottom)
    if self.clientForever~=nil then local shown=self.clientForever; self.clientForever=nil; self:LayoutClients(shown) end
    if self.realmChoices then self:RenderRealms() end
    self.trackShown=forever and art.track==true
    Th.Cover(self.scaleSlider,self.trackShown)
    if self.scaleSlider.track then for _,t in pairs(self.scaleSlider.track) do t:SetShown(self.trackShown) end end
    Th.Paint(self.scaleFill,self.trackShown and "trackFill" or "sliderFill")
    self:ApplyThumb(forever and art.thumb==true)
    Th.SizeAll(); sizeDivider(self.format); self:SizeScaleFill()
end
-- Applies a look where the window stands: the client's by default; the tests also apply the other
-- one and back. Nothing new is created after a look's pieces exist, and the saved position stays.
-- State colors come back through Refresh after the repaint.
function U:ApplyTheme(name)
    Th.Apply(name)
    if not self.frame then return end
    self:ApplyLook(); self:SettingsText(); self:Refresh()
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
    -- Inside Forever's frame everything below the header sits 20 units higher.
    local lift=self.framed and LIFT or 0
    local base=212+tabs-lift
    local requested=self.scaleDragging and self.dragScale or self.db.settings.scale
    local fittingRows=math.floor(((sh-20)/requested-base)/rowHeight)
    local slots=math.max(1,math.min(CAPACITY,fittingRows,count or self.visibleCount or 0))
    self.slots,self.rowHeight=slots,rowHeight; local h=slots*rowHeight
    self.frame:SetHeight(base+h); self.panelLayout(); if self.framed then crop(self.frame) end
    place(self.toolbar,10,114+tabs-lift)
    place(self.table,10,152+tabs-lift)
    self.table:SetHeight(24+h); self.list:SetHeight(h); self.scroll:SetHeight(h-4)
    place(self.scroll,progress and 684 or 695,progress and 18 or 2,progress and 14 or 5,progress and h-36 or h-4)
    self.scroll:GetThumbTexture():SetWidth(progress and 11 or 4)
    -- A single progress row leaves only 28 units of track. Keep travel space
    -- for dragging even at 200% on a small display.
    self.scroll:GetThumbTexture():SetHeight(math.min(28,self.scroll:GetHeight()/2))
    place(self.scrollDown,684,h-17)
    for _,divider in ipairs(self.headerDividers) do divider:SetShown(progress) end
    place(self.sortMenu,10,177+tabs-lift)
    place(self.footerFrame,10,176+tabs+h-lift)
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
    self.headerLevel=self.header:GetFrameLevel()
    for y=0,2 do for x=0,1 do
        local rivet=artwork(self.header,"Rivet",3,3,3.5+x*6,12+y*6)
        rivet:SetTexCoord(.03125,.96875,.03125,.96875); rivet:SetAlpha(.75); Th.Sprite(rivet)
    end end
    self.gear=rect("Button",self.header,20,9.5,20,20)
    self.gear:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY")
    Th.Paint(self.gear:GetNormalTexture(),"gear","vertex")
    self.gear:SetScript("OnEnter",function(b) Th.Paint(b:GetNormalTexture(),"gearHover","vertex") end)
    self.gear:SetScript("OnLeave",function(b) Th.Paint(b:GetNormalTexture(),"gear","vertex") end)
    self.gear:SetScript("OnClick",function() self:ToggleSettings() end)
    self.logo=artwork(self.header,"Logo",28,28,48,5.5)
    self.title=text(self.header,"Hourstone – Azeroth Hours",17,84,7.5,588,"title",24)
    self.close=closeButton(self.header,678,9.5,20,function() f:Hide() end)
    self.headerRule=line(self.header,0,39,700,1,"ruleHeader")

    self.summary=rect("Frame",f,10,50,700,64)
    self.statLabels={}
    local starts,widths={5,280.2,432},{250.2,126.8,251}
    for i,key in ipairs({"total","characters","session"}) do
        self.statLabels[i]=text(self.summary,L[key],11,starts[i],11.5,widths[i],"statLabel",15)
    end
    for _,x in ipairs({267.2,419}) do line(self.summary,x,10,1,43,"ruleSummary") end
    self.total=text(self.summary,"",20,5,26.5,250.2,"value",25)
    self.count=text(self.summary,"",20,280.2,26.5,50,"value",25)
    self.realms=text(self.summary,"",11,308.2,35.5,96,"muted",13.2)
    self.session=text(self.summary,"",20,432,26.5,251,"value",25)
    self.summary:EnableMouse(true)
    self.summary:SetScript("OnEnter",function(owner)
        local stats=self.overviewStats
        if stats then tooltip(owner,{L.total,M.SumText(stats.total,stats.missing,stats.count,self.db.settings.format)}) end
    end)
    self.summary:SetScript("OnLeave",function() GameTooltip:Hide() end)
    line(self.summary,0,63,700,1,"ruleSummaryBottom")

    if C.RetailProgress() then
        self.tabs=rect("Frame",f,10,114,700,TAB_HEIGHT)
        self.playedTab=control(self.tabs,L.played,5,4,90,25,function() self:SetView("played") end)
        self.progressTab=control(self.tabs,L.progress,98,4,102,25,function() self:SetView("progress") end)
    end

    self.toolbar=rect("Frame",f,10,114,700,38)
    local search=rect("EditBox",self.toolbar,0,6,SEARCH_WIDTH,26); self.search=search
    skin(search,"Toggle","field"); search:SetFont(FONT,11,""); Th.Paint(search,"searchText","text")
    search:SetAutoFocus(false); search:SetMaxLetters(80); search:SetTextInsets(9,25,0,0)
    search.hint=text(search,L.search,11,9,0,SEARCH_WIDTH-34,"hint",26)
    self.clearSearch=rect("Button",search,SEARCH_WIDTH-23,4,18,18)
    text(self.clearSearch,"×",12,0,0,18,"muted",18,"CENTER")
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
    self.realmButton.arrow=arrow(self.realmButton,124,11,6,4)
    self.clientButton=control(self.toolbar,L.allClients,SEARCH_WIDTH+FILTER_WIDTH+14,6,FILTER_WIDTH,26,function() self:ToggleClients() end,"Toggle")
    self.clientButton.label:SetJustifyH("LEFT"); self.clientButton.label:SetWidth(107)
    self.clientButton.arrow=arrow(self.clientButton,124,11,6,4)
    self.format=rect("Frame",self.toolbar,700-FORMAT_WIDTH,6.5,FORMAT_WIDTH,25)
    self.combined=control(self.format,L.combined,0,0,COMBINED_WIDTH,25,function() self:SetFormat("combined") end)
    self.hours=control(self.format,L.hours,COMBINED_WIDTH+3,0,FORMAT_WIDTH-COMBINED_WIDTH-3,25,function() self:SetFormat("hours") end)

    self.sort,self.descending,self.offset=self:IsProgress() and "name" or "seconds",not self:IsProgress(),0
    self.table=rect("Frame",f,10,152,700,24+ROW_HEIGHT); self.headers={}
    for _,spec in ipairs({{"name","character",0,NAME_WIDTH},{"flavor","client",NAME_WIDTH,CLIENT_WIDTH},
        {"seconds","played",NAME_WIDTH+CLIENT_WIDTH,PLAYED_WIDTH},{"updatedAt","updated",NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH,UPDATED_WIDTH}}) do
        local field,title,x,w=spec[1],L[spec[2]],spec[3],spec[4]
        local b=rect("Button",self.table,x,0,w,24)
        b.label=text(b,title,11,8,0,w-24,"header",24,field=="seconds" and "RIGHT" or "LEFT")
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
    line(self.table,0,23,700,1,"ruleTable")
    self.headerDividers={}
    for _,x in ipairs({230,394,516}) do self.headerDividers[#self.headerDividers+1]=line(self.table,x,2,1,19,"ruleColumnHeader") end
    self.list=rect("Frame",self.table,0,24,700,ROW_HEIGHT); self.list:EnableMouseWheel(true)
    self.list:SetScript("OnMouseWheel",function(_,delta) self:Scroll(-delta*3) end)
    self.rows={}
    for i=1,CAPACITY do
        local row=rect("Button",self.list,0,(i-1)*ROW_HEIGHT,700,ROW_HEIGHT); self.rows[i]=row
        row.bg=solid(row,"BACKGROUND",{1,1,1,0}); row.bg:SetAllPoints()
        row.active=line(row,0,0,2,ROW_HEIGHT-1,{104/255,202/255,232/255})
        row.separator=line(row,0,ROW_HEIGHT-1,700,1,"ruleRow")
        row.dividers={}
        for _,x in ipairs({230,394,516}) do row.dividers[#row.dividers+1]=line(row,x,0,1,ROW_HEIGHT-1,"ruleColumn") end
        row.dot=artwork(row,"LiveDot",5,5,8,8.5)
        row.name=text(row,"",13,8,3,NAME_WIDTH-77,nil,16)
        row.level=text(row,"",10,NAME_WIDTH-62,5,54,"level",12)
        row.realm=text(row,"",11,8,19,NAME_WIDTH-16,"secondary",13)
        row.guild=text(row,"",10,8,33,NAME_WIDTH-16,"guild",13)
        row.client=text(row,"",11,NAME_WIDTH+8,0,CLIENT_WIDTH-16,"secondary",ROW_HEIGHT-1)
        row.played=text(row,"",12,NAME_WIDTH+CLIENT_WIDTH+5,0,PLAYED_WIDTH-19,"played",ROW_HEIGHT-1,"RIGHT")
        row.updated=text(row,"",11,NAME_WIDTH+CLIENT_WIDTH+PLAYED_WIDTH+8,0,UPDATED_WIDTH-24,"updated",ROW_HEIGHT-1)
        row.progress=rect("Frame",row,PROGRESS_NAME,0,470,PROGRESS_HEIGHT)
        row.keyText=text(row.progress,"",12,12,11,140,"value",18)
        row.keyLevel=text(row.progress,"",12,120,11,34,"value",18,"RIGHT")
        row.keyNote=text(row.progress,"",10,12,31,140,"muted",17)
        row.weekText=text(row.progress,"",15,176,11,98,"value",19)
        row.weekNote=text(row.progress,"",10,176,33,98,"muted",16)
        row.keyHover=rect("Frame",row.progress,0,0,164,PROGRESS_HEIGHT)
        row.keyHover:EnableMouse(true)
        row.keyHover:SetScript("OnEnter",function() self:ProgressTooltip(row,"keystone") end)
        row.weekHover=rect("Frame",row.progress,164,0,122,PROGRESS_HEIGHT)
        row.weekHover:EnableMouse(true)
        row.weekHover:SetScript("OnEnter",function() self:ProgressTooltip(row,"weekly") end)
        row.vault={}
        for j,category in ipairs(CATEGORIES) do
            local group=rect("Frame",row.progress,286,5+(j-1)*18,174,18)
            group.label=text(group,L[category],10,12,0,62,"vaultLabel",18)
            group:EnableMouse(true)
            group:SetScript("OnEnter",function() self:ProgressTooltip(row,category) end)
            group:SetScript("OnLeave",function() self:HideProgressTooltip() end)
            group.slots={}
            for slot=1,3 do
                local box=rect("Frame",group,80+(slot-1)*23,1,16,16)
                box.edge=solid(box,"BACKGROUND",{.5,.43,.25,1}); box.edge:SetAllPoints()
                box.fill=line(box,1,1,14,14,{.035,.06,.065,1})
                box.check=artwork(box,"Check",14,14,1,1,"OVERLAY")
                box.unknown=text(box,"?",11,0,0,16,INFO_MUTED,16,"CENTER")
                group.slots[slot]=box
            end
            row.vault[category]=group
        end
        row.keyHover:SetScript("OnLeave",function() self:HideProgressTooltip() end)
        row.weekHover:SetScript("OnLeave",function() self:HideProgressTooltip() end)
        local glow=solid(row,"HIGHLIGHT","hoverRow"); glow:SetAllPoints()
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
    self.empty=text(self.list,L.empty,11,8,0,684,"muted",ROW_HEIGHT,"CENTER")
    self.scroll=rect("Slider",self.list,695,2,5,ROW_HEIGHT-4)
    self.scroll:SetOrientation("VERTICAL"); self.scroll:SetMinMaxValues(0,0); self.scroll:SetValueStep(1)
    if self.scroll.SetObeyStepOnDrag then self.scroll:SetObeyStepOnDrag(true) end
    self.scroll:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    self.scroll:GetThumbTexture():SetSize(4,28); Th.Paint(self.scroll:GetThumbTexture(),"scrollThumb","vertex")
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
    self.footer=text(self.footerFrame,"",10,5,2,540,"footer",24)
    self.footerFrame:EnableMouse(true)
    self.footerFrame:SetScript("OnEnter",function(owner) tooltip(owner,{self.footer:GetText(),self:IsProgress() and L.progressHint or L.hint}) end)
    self.footerFrame:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.clientMenu=rect("Frame",self.clientButton,0,29,168,16+#CLIENT_CHOICES*25)
    self.clientMenu:SetFrameLevel(f:GetFrameLevel()+30); self.clientMenuLayout=skin(self.clientMenu,self.panelName)
    self.clientMenu:EnableMouse(true); self.clientMenu:Hide(); self.clientRows={}
    for i,flavor in ipairs(CLIENT_CHOICES) do
        local b=rect("Button",self.clientMenu,8,8+(i-1)*25,152,25)
        b.label=text(b,flavor=="all" and L.allClients or L[flavor],11,7,0,140,nil,25)
        local glow=solid(b,"HIGHLIGHT","hoverMenu"); glow:SetAllPoints()
        b:SetScript("OnClick",function()
            self.flavor,self.offset=flavor~="all" and flavor or nil,0; self:CloseMenus(); self:Refresh()
        end)
        self.clientRows[flavor]=b
    end
    self:LayoutClients(C.IsForever())
    self.creditVersion=text(self.footerFrame,"v"..C.Version(),10,555,2,36,"credit",24,"RIGHT")
    self.creditWith=text(self.footerFrame,"with",10,596,2,24,"credit",24)
    self.creditHeart=artwork(self.footerFrame,"Heart",9,9,625,9.5)
    self.creditAuthor=text(self.footerFrame,"by krebs3r",10,639,2,56,"credit",24)

    self.menu=rect("Frame",self.realmButton,0,29,218,41); self.menu:SetFrameLevel(f:GetFrameLevel()+30)
    self.menuLayout=skin(self.menu,self.panelName); self.menu:EnableMouse(true); self.menu:EnableMouseWheel(true); self.menu:Hide()
    self.realmRows={}; self.realmOffset=0
    for i=1,6 do
        local b=rect("Button",self.menu,8,8+(i-1)*25,202,25)
        b.label=text(b,"",11,7,0,177,nil,25)
        local glow=solid(b,"HIGHLIGHT","hoverMenu"); glow:SetAllPoints()
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
        local glow=solid(b,"HIGHLIGHT","hoverMenu"); glow:SetAllPoints()
        b:SetScript("OnClick",function() self:SetSort(field) end); self.sortRows[field]=b
    end
    self.settings=rect("Frame",f,24,47,252,214); local settings=self.settings
    settings:SetFrameLevel(f:GetFrameLevel()+35); settings:EnableMouse(true); settings:Hide(); skin(settings,self.panelName)
    self.settingsHeading=text(settings,L.settings,15,13,13,202,"heading",22)
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
    text(settings,L.scale,11,13,68,177,"settingsLabel",13.2)
    self.scaleLabel=text(settings,"",11,190,68,49,"settingsLabel",13.2,"RIGHT")
    self.scaleSlider=rect("Slider",settings,13,87.2,226,18)
    self.scaleSlider:SetOrientation("HORIZONTAL"); self.scaleSlider:SetMinMaxValues(M.SCALE_MIN*100,M.SCALE_MAX*100); self.scaleSlider:SetValueStep(M.SCALE_STEP*100)
    if self.scaleSlider.SetObeyStepOnDrag then self.scaleSlider:SetObeyStepOnDrag(true) end
    self.scaleEdge=line(self.scaleSlider,0,6,226,6,"sliderEdge")
    self.scaleTrack=line(self.scaleSlider,1,7,224,4,"sliderTrack")
    self.scaleFill=line(self.scaleSlider,1,7,0,4,"sliderFill")
    -- Flat: the track is a control plate on the edge's rectangle, its outline one physical
    -- pixel; the fill is inset by that pixel (U:SizeScaleFill).
    Th.Plate(self.scaleSlider,"control",{self.scaleEdge,self.scaleTrack},self.scaleEdge)
    self.scaleSlider:SetThumbTexture(ROOT..(C.RetailStyle() and "GoldThumb" or "SilverThumb")..".tga")
    local thumb=self.scaleSlider:GetThumbTexture(); thumb:SetSize(10,18)
    thumb:SetTexCoord(C.RetailStyle() and .2265625 or .2109375,C.RetailStyle() and .765625 or .78125,.015625,.984375)
    Th.Paint(thumb,"sliderThumb","vertex")
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
    self.scaleMin=text(settings,math.floor(M.SCALE_MIN*100).." %",10,13,108,70,"muted",15)
    self.scaleMax=text(settings,math.floor(M.SCALE_MAX*100).." %",10,169,108,70,"muted",15,"RIGHT")
    self.reset=control(settings,L.reset,13,136,137,25,function() self:Position(true) end,"Toggle")
    self.reset.label:SetFont(FONT,10,""); place(self.reset.label,5,0,127,25); self.reset.labelSize=10
    self.done=control(settings,L.done,157,136,82,25,function() settings:Hide() end); primary(self.done)
    self.removedToggle=control(settings,L.removedCharacters,13,177,226,25,function()
        self:SetRemovedView(not self.removedOnly)
    end,"Toggle")
    self.removedToggle.tip=function(owner) tooltip(owner,{L.removedCharacters,L.removalHelp}) end
    self.removeDialog=rect("Frame",f,110,30,500,205)
    self.removeDialog:SetFrameLevel(f:GetFrameLevel()+50); self.removeDialog:EnableMouse(true)
    skin(self.removeDialog,self.panelName); self.removeDialog:Hide()
    self.removeHeading=text(self.removeDialog,L.removeTitle,14,18,14,464,"heading",28)
    self.removeBody=text(self.removeDialog,"",12,18,49,464,nil,96)
    self.removeBody:SetWordWrap(true)
    self.removeCancel=control(self.removeDialog,L.cancel,230,162,118,27,function() self:CloseMenus() end,"Toggle")
    self.removeConfirm=control(self.removeDialog,L.remove,360,162,122,27,function()
        local identity=self.pendingRemoval
        if identity and not H.V.Remove(self.db,identity) then print(L.visibilityError) end
        self:CloseMenus(); self:Refresh()
    end)
    primary(self.removeConfirm)
    self.progressTip=rect("Frame",f,WIDTH+12,26,310,180)
    self.progressTip:SetFrameLevel(f:GetFrameLevel()+45); self.progressTip:SetClampedToScreen(true)
    self.tipLayout=skin(self.progressTip,self.panelName); self.progressTip:Hide(); self.tipLines={}; self.tipMarks={}
    self.tipTitle=text(self.progressTip,"",16,16,12,278,"tipTitle",40); self.tipTitle:SetWordWrap(true)
    self.tipDivider=line(self.progressTip,16,57,278,1,"tipRule")
    self.tipFooterDivider=line(self.progressTip,16,150,278,1,"tipRule")
    self.ready=true
    f:SetScript("OnHide",function()
        self:FinishWindowDrag(); search:ClearFocus(); self:CloseMenus(); GameTooltip:Hide()
    end)
    f:SetScript("OnMouseDown",function() self:CloseMenus(); search:ClearFocus() end)
    self:ApplyLook(); self:LayoutRows(0); self:SettingsText()
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
-- The Forever client records Forever characters itself; elsewhere they arrive through the
-- Companion's Forever list. The entry also stays while it is the selected filter.
function U:LayoutClients(forever)
    forever=forever==true
    if self.clientForever==forever then return end
    self.clientForever=forever
    local y=8
    for _,client in ipairs(CLIENT_CHOICES) do
        local b,shown=self.clientRows[client],client~="forever" or forever
        b:SetShown(shown)
        if shown then place(b,8,y); y=y+25 end
    end
    self.clientMenu:SetHeight(y+(self.menuBottom or 8)); self.clientMenuLayout()
end
function U:RenderRealms()
    for i,b in ipairs(self.realmRows) do
        local entry=self.realmChoices[i+self.realmOffset]; b:SetShown(entry~=nil)
        if entry then
            b.realm=entry.realm; b.label:SetText(entry.label)
            Th.Paint(b.label,entry.realm==self.realm and "value" or "menuText","text")
        end
    end
    self.menu:SetHeight(math.min(6,#self.realmChoices)*25+8+(self.menuBottom or 8)); self.menuLayout()
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
    Th.Paint(row.keyText,stale and "muted" or (hasKey and "value" or "noKey"),"text")
    Th.Paint(row.keyLevel,stale and "muted" or "value","text")
    local recorded=week.status=="known" or week.status=="stale"
    row.weekText:SetText(recorded and week.level and week.level>0 and ("+"..week.level) or "–")
    Th.Paint(row.weekText,week.status=="stale" and "muted" or "value","text")
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
            Th.Raw(box.fill,nil,unlocked and .32 or .035,unlocked and .22 or .06,unlocked and .035 or .065,1)
            Th.Raw(box.edge,nil,unlocked and .95 or .5,unlocked and .7 or .43,unlocked and .25 or .25,1)
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
                icon.edge=solid(icon,"BACKGROUND",{.5,.43,.25,1}); icon.edge:SetAllPoints()
                icon.fill=line(icon,1,1,12,12,{.035,.06,.065,1})
                icon.check=artwork(icon,"Check",14,14,0,0,"OVERLAY")
                self.tipMarks[i]=icon
            end
            place(icon,16,y+5); icon:Show(); icon.check:SetShown(mark.unlocked==true)
            icon:SetAlpha(mark.stale and .38 or 1)
        elseif self.tipMarks[i] then self.tipMarks[i]:Hide() end
        Th.Paint(label,i>=footerStart and "value" or "tipText","text"); y=y+height+2
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
    local forever=C.IsForever() or self.flavor=="forever"
    if not forever then for _,char in pairs(display.characters) do if M.Client(char)=="forever" then forever=true; break end end end
    self:LayoutClients(forever)
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
        Th.Paint(b.label,on and "value" or "header","text")
        b.arrow:SetShown(on or field=="name")
        b.arrow:SetTexCoord(0,1,on and not self.descending and 1 or 0,on and not self.descending and 0 or 1)
        b.arrow:ClearAllPoints(); b.arrow:SetPoint("TOPLEFT",field=="seconds" and PLAYED_WIDTH-19 or 13+occupied(b.label),-10.5)
        Th.Paint(b.arrow,on and "value" or "muted","vertex")
    end
    for field,b in pairs(self.sortRows) do Th.Paint(b.label,self.sort==field and "value" or "menuText","text") end
    self.maxOffset=math.max(0,#entries-self.slots); self.offset=math.min(self.offset,self.maxOffset)
    self.scroll:SetMinMaxValues(0,self.maxOffset); self.scroll:SetValue(self.offset); self.scroll:SetShown(self.maxOffset>0)
    self.scrollUp:SetShown(self:IsProgress() and self.maxOffset>0); self.scrollDown:SetShown(self:IsProgress() and self.maxOffset>0)
    for i,row in ipairs(self.rows) do
        local entry=i<=self.slots and entries[i+self.offset] or nil; row.entry=entry; row:SetShown(entry~=nil)
        if entry then
            local char,active=entry.char,entry.key==T.key and entry.char._local
            row.active:SetShown(active); row.dot:SetShown(active)
            if active then Th.Raw(row.bg,nil,104/255,184/255,208/255,18/255)
            else Th.Raw(row.bg,nil,1,1,1,(i+self.offset)%2==0 and 3/255 or 0) end
            local progress=self:IsProgress()
            local nameWidth=progress and PROGRESS_NAME or NAME_WIDTH
            local x=active and 20 or 8
            local nameY,realmY,guildY=progress and 7 or 3,progress and 25 or 19,progress and 42 or 33
            place(row.name,x,nameY,nameWidth-69-x)
            ellipsis(row.name,C.Escape(char.name)); Th.Raw(row.name,"text",C.ClassColor(char.class))
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
            if active then Th.Raw(row.updated,"text",156/255,194/255,176/255) else Th.Paint(row.updated,"updated","text") end
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
    Th.Apply()
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
