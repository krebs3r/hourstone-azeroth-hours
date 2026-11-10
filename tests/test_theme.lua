-- Looks: the client's look, WoW: Forever's own art with its fallback piece by piece, the flat
-- skin's palette and one-pixel lines, and applying a look without /reload.
local C,Th,L=H.C,H.Theme,H.L
local forever=C.IsForever()

-- Every atlas Hourstone asks for, unknown at first: the flat look on Forever.
local ART_NAMES={}
for _,group in pairs(Th.ART) do
    if type(group)=="string" then ART_NAMES[#ART_NAMES+1]=group else
        for _,v in pairs(group) do
            if type(v)=="string" and not v:find("\\",1,true) and v~="ButtonFrameTemplateNoPortrait" and v~="InsetFrameTemplate" then ART_NAMES[#ART_NAMES+1]=v
            elseif type(v)=="table" then for _,name in pairs(v) do ART_NAMES[#ART_NAMES+1]=name end end
        end
    end
end
for _,layout in pairs(NineSliceLayouts) do for _,piece in pairs(layout) do if type(piece)=="table" then ART_NAMES[#ART_NAMES+1]=piece.atlas end end end
local function unknownArt(on) ATLAS_MISSING={}; if on then for _,name in ipairs(ART_NAMES) do ATLAS_MISSING[name]=true end end end
unknownArt(true)

-- The look is applied at load, before any frame exists. A choice saved by a development build goes.
HourstoneDB={settings={theme="standard"}}
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false); fire("TIME_PLAYED_MSG",1125000,200)
local U,db=H.UI,HourstoneDB
assert(db.settings.theme==nil and Th.name==(forever and "forever" or "standard") and Th.flat==forever and U.frame==nil)
assert(Th.Built()==forever)
for _,value in ipairs({"auto","forever","standard","FOREVER",1,false}) do assert(H.M.Init({settings={theme=value}}).settings.theme==nil) end
for key,on in pairs(Th.Art()) do assert(not on,key) end
-- No command chooses a look: `theme` is an unknown word, which opens the window as in 0.3.7.
SlashCmdList.HOURSTONE("theme standard"); assert(U.frame:IsShown() and Th.name==(forever and "forever" or "standard"))
SlashCmdList.HOURSTONE("")

-- More characters than rows, so the list scrolls and Retail's progress view shows its scroll buttons.
for i=1,12 do db.characters["test:"..i]={name="Example"..i,realm="Realm "..(i%3),seconds=i*3600,level=i,class=i==2 and "WARRIOR" or "MAGE",
    flavor="retail",updatedAt=EPOCH-i*60,guild="Guild",guildUpdatedAt=EPOCH} end
SlashCmdList.HOURSTONE("")
assert(U.frame:IsShown())

-- Nothing of Forever's art exists without it, and on the other clients no flat plate either.
local function count(test) local n=0; for _,r in ipairs(ALL_FRAMES) do if test(r) then n=n+1 end end; return n end
local function noArt()
    assert(#NINE_SLICE==0 and U.frame.window==nil and U.settings.window==nil and U.inset==nil and U.frameGear==nil)
    assert(count(function(r) return r.atlas~=nil or r.template=="UIPanelButtonTemplate" end)==0)
    assert(U.realmButton.dropdown==nil and U.format.art==nil and U.search.field==nil and U.menu.art==nil and U.scaleSlider.track==nil and not U.framed)
end
noArt()
if not forever then
    for _,plate in ipairs(Th.plates) do assert(not plate.built and #plate.textures==0 and plate.tint==nil) end
    assert(U.close.glyph==nil and U.settingsClose.glyph==nil)
end

local function near(a,b) return math.abs(a-b)<1e-6 end
local function rgba(c) return c[1],c[2],c[3],c[4]==nil and 1 or c[4] end
local function same(c,r,g,b,a)
    local r2,g2,b2,a2=rgba(c); return near(r,r2) and near(g,g2) and near(b,b2) and near(a or 1,a2)
end
local function rgb(r,g,b,a) return {r/255,g/255,b/255,a or 1} end

-- The forever palette as docs/FOREVER-THEME.md gives it.
local MUTE={166,160,148}
local PINNED={surface=rgb(21,18,15,.96),ground=rgb(10,8,6),lineTop=rgb(154,128,92),lineSide=rgb(128,104,72),outline=rgb(104,80,52),
    fieldRing=rgb(166,160,148,.35),tint=rgb(240,204,140,.12),underline=rgb(240,204,140),hover=rgb(240,204,140),
    text=rgb(240,233,218),muted=rgb(unpack(MUTE)),value=rgb(240,204,140),title=rgb(255,210,0),heading=rgb(255,210,0),tipTitle=rgb(240,233,218),
    guild=rgb(166,160,148,.75),hint=rgb(166,160,148,.75),credit=rgb(166,160,148,.85),
    ruleHeader=rgb(166,160,148,.30),ruleTable=rgb(166,160,148,.30),ruleSummary=rgb(166,160,148,.18),ruleSummaryBottom=rgb(166,160,148,.18),
    tipRule=rgb(166,160,148,.18),ruleColumn=rgb(166,160,148,.12),ruleColumnHeader=rgb(166,160,148,.12),ruleRow=rgb(166,160,148,.10),
    scrollThumb=rgb(128,104,72,.9),hoverRow=rgb(240,204,140,12/255),hoverMenu=rgb(240,204,140,.12),hoverControl=rgb(240,204,140,.06),
    sliderEdge=rgb(104,80,52),sliderTrack=rgb(10,8,6),sliderFill=rgb(240,204,140),sliderThumb=rgb(240,204,140),
    buttonIcon=rgb(255,230,128),trackFill=rgb(255,176,33),insetShade=rgb(0,0,0,.55)}
for key,color in pairs(PINNED) do assert(same(Th.palettes.forever[key],rgba(color)),key) end
-- Both palettes carry the same keys.
for key in pairs(Th.palettes.forever) do assert(Th.palettes.standard[key],key) end
for key in pairs(Th.palettes.standard) do assert(Th.palettes.forever[key],key) end
local RAMP={.95,.77,.54,.32,.18}

local function visible(region,root)
    root=root or U.frame
    local alpha=1
    while region do
        if not region.shown then return false end
        alpha=alpha*(region.alpha or 1)
        if region==root then return alpha>0 end
        region=region.parent
    end
    return false
end
-- File textures the forever look may show: Blizzard's white texture, Hourstone's own icons,
-- Blizzard's gear and checkbox, and the files of Blizzard's frame, inset and push buttons.
-- Anything else (a Soundstone sprite) fails. Atlases are Forever's own art and carry their colors.
local FILES={"WHITE8X8","Arrow.tga","Logo.tga","Heart.tga","LiveDot.tga","Check.tga","GEAR_64GREY","UI-CheckBox",
    "UI-Background-Rock","UI-Panel-Button-Up","UI-Panel-Button-Highlight"}
local KNOWN={}; for _,name in ipairs(ART_NAMES) do KNOWN[name]=true end
local function file(region)
    if region.atlas then return KNOWN[region.atlas]==true end
    if type(region.texture)~="string" then return true end
    for _,name in ipairs(FILES) do if region.texture:find(name,1,true) then return true end end
    return false
end
-- Regions that carry information, by identity, with the colors they may wear.
local function information()
    local owned={}
    for _,row in ipairs(U.rows) do
        local active=row.entry and row.active.shown
        owned[row.bg]=active and {rgb(104,184,208,18/255)} or {{1,1,1,0},{1,1,1,3/255}}
        owned[row.active]={rgb(104,202,232)}
        if row.entry then local r,g,b=C.ClassColor(row.entry.char.class); owned[row.name]={{r,g,b}} end
        if active then owned[row.updated]={rgb(156,194,176)} end
        for _,group in pairs(row.vault) do
            for _,box in ipairs(group.slots) do
                owned[box.unknown]={rgb(169,170,162)}
                owned[box.edge]={{.5,.43,.25},{.95,.7,.25}}; owned[box.fill]={{.035,.06,.065},{.32,.22,.035}}
            end
        end
    end
    for _,mark in pairs(U.tipMarks) do owned[mark.edge]={{.5,.43,.25}}; owned[mark.fill]={{.035,.06,.065}} end
    local ramp={}
    for _,plate in ipairs(Th.plates) do
        for i,strip in ipairs(plate.ramp) do for _,t in pairs(strip) do ramp[t]=RAMP[i] end end
    end
    return owned,ramp
end
local function palette(color)
    for _,c in pairs(Th.colors) do if same(c,rgba(color)) then return true end end
    return false
end
-- Under forever every visible region is Forever's art, flat and painted from the palette, or
-- an information region in its own color; under standard no flat region shows.
local function check(state)
    local owned,ramp=information()
    local regions=0
    for _,r in ipairs(ALL_FRAMES) do
        if (r.kind=="Texture" or r.kind=="FontString") and visible(r) then
            regions=regions+1
            if owned[r] then
                local ok=false
                for _,c in ipairs(owned[r]) do if same(r.color,rgba(c)) then ok=true end end
                assert(ok,state..": information "..table.concat({rgba(r.color)},"/"))
            elseif Th.flat then
                assert(file(r),state..": file "..tostring(r.texture or r.atlas))
                if r.atlas then -- art of its own
                elseif ramp[r] then assert(same(r.color,0,0,0,ramp[r]),state..": ramp")
                elseif r.color then assert(palette(r.color),state..": color "..table.concat({rgba(r.color)},"/")) end
            else assert(not r.atlas,state..": atlas") end
        end
    end
    assert(regions>50,state)
    for _,plate in ipairs(Th.plates) do
        for _,t in ipairs(plate.textures) do assert(t.shown==(Th.flat and not plate.covered),state) end
        for _,t in ipairs(plate.sprites) do assert(t.shown==not Th.flat,state) end
    end
    for _,b in ipairs({U.close,U.settingsClose}) do
        assert(b:GetNormalTexture().alpha==(Th.flat and 0 or 1) and b:GetHighlightTexture().alpha==(Th.flat and 0 or 1),state)
        if b.glyph then assert(b.glyph.shown==Th.flat,state) end
    end
    if Th.flat then
        local lines=U.frame.plate.lines
        assert(same(lines.top.color,Th.Color("lineTop")),state)
        for _,side in ipairs({"left","right","bottom"}) do assert(same(lines[side].color,Th.Color("lineSide")),state) end
        for _,side in ipairs({"top","left","right","bottom"}) do assert(same(U.realmButton.plate.lines[side].color,Th.Color("outline")),state) end
        assert(same(U.frame.plate.textures[1].color,Th.Color("surface")) and same(U.realmButton.plate.textures[1].color,Th.Color("ground")),state)
    end
end
-- One physical pixel: the line's size in its frame's units times the effective scale,
-- each line anchored inside the plate's own edge.
local function point(region,name)
    for _,p in ipairs(region.points) do if p[1]==name then return p end end
end
local function at(region,anchor,name,x,y,relative)
    local p=point(region,name)
    return p and p[2]==anchor and p[3]==(relative or name) and near(p[4],x) and near(p[5],y)
end
local function lines(state)
    local _,h=GetPhysicalScreenSize()
    for _,plate in ipairs(Th.plates) do
        local f,a=plate.frame,plate.anchor
        local d=(768/h)/f:GetEffectiveScale()
        assert(near(Th.Pixel(f),d),state)
        assert(plate.built,state)
        local l=plate.lines
        if l then
            assert(near(l.top.height*f:GetEffectiveScale()*h/768,1),state)
            assert(at(l.top,a,"TOPLEFT",0,0) and at(l.top,a,"TOPRIGHT",0,0) and near(l.top.height,d),state)
            assert(at(l.bottom,a,"BOTTOMLEFT",0,0) and at(l.bottom,a,"BOTTOMRIGHT",0,0) and near(l.bottom.height,d),state)
            assert(at(l.left,a,"TOPLEFT",0,-d) and at(l.left,a,"BOTTOMLEFT",0,d) and near(l.left.width,d),state)
            assert(at(l.right,a,"TOPRIGHT",0,-d) and at(l.right,a,"BOTTOMRIGHT",0,d) and near(l.right.width,d),state)
        end
        assert(#plate.ramp==(plate.kind=="panel" and 5 or 0),state)
        for i,s in ipairs(plate.ramp) do
            local o=i*d
            assert(at(s.top,a,"TOPLEFT",o,-o) and at(s.top,a,"TOPRIGHT",-o,-o) and near(s.top.height,d),state)
            assert(at(s.bottom,a,"BOTTOMLEFT",o,o) and at(s.bottom,a,"BOTTOMRIGHT",-o,o) and near(s.bottom.height,d),state)
            assert(at(s.left,a,"TOPLEFT",o,-o-d) and at(s.left,a,"BOTTOMLEFT",o,o+d) and near(s.left.width,d),state)
            assert(at(s.right,a,"TOPRIGHT",-o,-o-d) and at(s.right,a,"BOTTOMRIGHT",-o,o+d) and near(s.right.width,d),state)
            for _,t in pairs(s) do assert(same(t.color,0,0,0,RAMP[i]),state) end
        end
        if plate.tint then assert(at(plate.tint,a,"TOPLEFT",d,-d) and at(plate.tint,a,"BOTTOMRIGHT",-d,d),state) end
        if plate.underline then
            assert(at(plate.underline,a,"BOTTOMLEFT",d,d) and at(plate.underline,a,"BOTTOMRIGHT",-d,d) and plate.underline.height==2,state)
        end
    end
    -- The slider's fill lies inside its outline.
    local inset=Th.flat and Th.Pixel(U.scaleSlider) or 1
    assert(at(U.scaleFill,U.scaleSlider,"TOPLEFT",inset,-6-inset) and near(U.scaleFill.height,6-2*inset),state)
end

-- Every state of the window, and the look `name` applied while each popover is open.
local function states(label,name)
    local function switch(state) if name then U:ApplyTheme(name) end; check(label.." "..state) end
    switch("window")
    U:ToggleSettings(); switch("settings")
    U:ToggleClients(); switch("client menu")
    U:ToggleRealms(); switch("realm menu")
    assert(same(U.realmRows[1].label.color,Th.Color("value")),label)
    U:CloseMenus(); U:SetSort("name"); U.sortMenu:Show(); switch("sort menu")
    assert(same(U.sortRows.name.label.color,Th.Color("value")) and same(U.sortRows.level.label.color,Th.Color("menuText")),label)
    U:CloseMenus(); U:SetSort("seconds")
    U:ConfirmRemoval(db.characters["test:2"]); switch("dialog")
    U:CloseMenus()
    if C.RetailProgress() then
        U:SetView("progress"); assert(U.scrollUp:IsShown() and U.scrollDown:IsShown()); switch("progress")
        U:ProgressTooltip(U.rows[1],"dungeon"); switch("progress tooltip")
        assert(same(U.tipTitle.color,Th.Color("tipTitle")),label)
        U:HideProgressTooltip(); U:SetView("played")
    end
end

-- The flat look: Forever without its art, and the fallback the tests reach on every client.
-- Applying a look builds nothing once the flat pieces exist and leaves no trace of the other look.
-- (The progress tooltip creates its lines on first use, so count after one pass through every state.)
states("first")
if not forever then states("flat","forever") end
local built=#ALL_FRAMES
for _,name in ipairs({"standard","forever","standard","forever"}) do
    states("to "..name,name)
    assert(Th.name==name and db.settings.theme==nil)
    assert(#ALL_FRAMES==built,name)
end
assert(Th.flat and not U.framed)
noArt()

-- The pixel follows the size, the UI scale and the screen, also when only the events report it.
for _,screen in ipairs({{1920,1080},{2560,1440},{3840,2160}}) do
    for _,ui in ipairs({.64,.8,1}) do
        configure_display(screen[1],screen[2],ui); fire("UI_SCALE_CHANGED"); lines(screen[2].."/"..ui.." ui event")
        for _,size in ipairs({.65,1,1.35,2}) do
            db.settings.scale=size; U:ApplyScale()
            lines(screen[2].."/"..ui.."/"..size)
        end
        configure_display(screen[2]==1080 and 2560 or 1920,screen[2]==1080 and 1440 or 1080,ui); fire("DISPLAY_SIZE_CHANGED")
        lines(screen[2].."/"..ui.." display event")
    end
end
db.settings.scale=1; configure_display(2560,1440,.8); U:ApplyScale()
assert(near(U.frame.plate.lines.top.height,1))

-- The settings are 0.3.7's again: no theme row, no clamp. The progress tooltip keeps its clamp.
assert(U.settings.height==214 and U.settings.clamped==nil and U.progressTip.clamped==true)
assert(at(U.reset,U.settings,"TOPLEFT",13,-136) and at(U.done,U.settings,"TOPLEFT",157,-136) and at(U.removedToggle,U.settings,"TOPLEFT",13,-177))

-- Chosen, primary and plain controls.
U:SetFormat("hours")
assert(same(U.hours.label.color,Th.Color("chosenLabel")) and same(U.combined.label.color,Th.Color("unchosenLabel")))
assert(U.hours.plate.tint.shown and U.hours.plate.underline.shown)
for _,b in ipairs({U.combined,U.reset,U.realmButton,U.clientButton,U.removeCancel}) do assert(not b.plate.tint.shown and not b.plate.underline.shown) end
assert(U.done.plate.underline.shown and not U.done.plate.tint.shown and same(U.done.label.color,Th.Color("primaryLabel")))
assert(same(U.headers.seconds.button.label.color,Th.Color("value")))
U.search:SetText("Example2")
local warrior
for _,row in ipairs(U.rows) do if row.entry and row.entry.char.class=="WARRIOR" then warrior=row end end
local w=RAID_CLASS_COLORS.WARRIOR
assert(warrior and same(warrior.name.color,w.r,w.g,w.b))
U.search:SetText("")

-- Window titles take NORMAL_FONT_COLOR, read when the look is applied; nothing else does.
local headings={U.title,U.settingsHeading,U.removeHeading}
local normal=NORMAL_FONT_COLOR
NORMAL_FONT_COLOR={r=.2,g=.4,b=.6,GetRGB=function(self) return self.r,self.g,self.b end}
U:ApplyTheme("forever")
for _,heading in ipairs(headings) do assert(same(heading.color,.2,.4,.6)) end
assert(not same(U.tipTitle.color,.2,.4,.6) and not same(U.total.color,.2,.4,.6))
NORMAL_FONT_COLOR=nil; U:ApplyTheme("forever")
for _,heading in ipairs(headings) do assert(same(heading.color,1,210/255,0)) end
NORMAL_FONT_COLOR=normal; U:ApplyTheme("standard")
assert(same(U.title.color,1,213/255,116/255) and same(headings[2].color,243/255,206/255,112/255))

-- Without PixelUtil the same formula stands in.
local util=PixelUtil; PixelUtil=nil
local _,h=GetPhysicalScreenSize()
assert(near(Th.Pixel(U.frame),(768/h)/U.frame:GetEffectiveScale()))
PixelUtil=util

-- A control's label turns to the accent on hover under the flat skin, also across a Refresh.
U:ApplyTheme("forever"); U:SetFormat("combined")
U.hours.scripts.OnEnter(U.hours); assert(same(U.hours.label.color,Th.Color("hover")))
tick(1); U:Refresh(); assert(same(U.hours.label.color,Th.Color("hover")))
U.hours.scripts.OnLeave(U.hours); assert(same(U.hours.label.color,Th.Color("unchosenLabel")))
U.close.scripts.OnEnter(U.close); assert(same(U.close.glyph.color,Th.Color("hover")))
U.close.scripts.OnLeave(U.close); assert(same(U.close.glyph.color,Th.Color("muted")))
U:ApplyTheme("standard")
U.hours.scripts.OnEnter(U.hours); assert(same(U.hours.label.color,Th.Color("unchosenLabel")))
U.hours.scripts.OnLeave(U.hours)
U.removedToggle.scripts.OnEnter(U.removedToggle); assert(GameTooltip.lines[1]==L.removedCharacters)
U.removedToggle.scripts.OnLeave(U.removedToggle); assert(not GameTooltip:IsShown())
noArt()

-- Retail: recorded Vault progress, so slots unlock and the tooltip draws its slot marks.
-- None of them follows the look, also when the look is applied without a Refresh.
if C.RetailProgress() then
    local char={name="ExampleVault",class="MAGE",realm="Realm",region="eu",flavor="retail",guid="Player-1-THEME-VAULT",
        sourceId=db.sourceId,level=90,seconds=9999999,updatedAt=EPOCH,guild="",guildUpdatedAt=EPOCH}
    local key=H.S.Key(char,db.sourceId); db.characters[key]=char
    local rows={}
    for _,category in ipairs({"dungeon","raid","world"}) do
        local row={updatedAt=EPOCH,resetAt=EPOCH+3600,slots={}}
        for slot=1,3 do row.slots[slot]={progress=4,threshold=({1,4,8})[slot],level=category=="dungeon" and 10 or 0} end
        rows[category]=row
    end
    H.P.store.characters[key]={guid=char.guid,region="eu",flavor="retail",sourceId=db.sourceId,vault={rows=rows}}
    H.P.now=EPOCH
    U:ApplyTheme("forever"); U:SetView("progress"); U.search:SetText("ExampleVault")
    assert(U.rows[1].entry.char.name==char.name)
    U:ProgressTooltip(U.rows[1],"dungeon")
    local marks,unlocked=0,0
    for _,mark in pairs(U.tipMarks) do if mark.shown then marks=marks+1 end end
    for _,box in ipairs(U.rows[1].vault.dungeon.slots) do if box.check.shown then unlocked=unlocked+1 end end
    assert(marks==3 and unlocked==2)
    check("vault"); Th.Apply("forever"); check("vault, repainted without a Refresh")
    U:HideProgressTooltip(); U.search:SetText(""); U:SetView("played")
    db.characters[key]=nil; H.P.store.characters[key]=nil
end

-- The client's look again; nothing chooses a look, so nothing of it is saved.
U:ApplyTheme(); assert(Th.name==(forever and "forever" or "standard"))
fire("PLAYER_LOGOUT"); assert(HourstoneDB.settings.theme==nil)
if not forever then return end

------------------------------------------------------------------------------------------------
-- WoW: Forever with its art: the window frame, as Soundstone 0.4.0 wears it.
------------------------------------------------------------------------------------------------
unknownArt(false)
U:CloseMenus(); U:ApplyTheme()
for _,key in ipairs({"window","streaks","inset","menu","dropdown","track","thumb"}) do assert(Th.art[key]==true,key) end
assert(U.framed and Th.flat)
check("framed")

-- Regions in a root's units, resolved through their anchors as the client does.
local POINTS={TOPLEFT={0,0},TOP={.5,0},TOPRIGHT={1,0},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},BOTTOMLEFT={0,1},BOTTOM={.5,1},BOTTOMRIGHT={1,1}}
local function box(region,root,cache)
    if region==root then return 0,0,root.width,root.height end
    if cache[region] then return unpack(cache[region]) end
    local result
    if region.allPoints then result={box(region.allPoints,root,cache)} else
        local axes={{},{}}
        for _,p in ipairs(region.points) do
            local rx,ry,rw,rh=box(p[2],root,cache)
            local a,b=POINTS[p[1]],POINTS[p[3]]
            axes[1][#axes[1]+1]={a[1],rx+b[1]*rw+p[4]}; axes[2][#axes[2]+1]={a[2],ry+b[2]*rh-p[5]}
        end
        local function axis(list,size)
            if #list==0 then return 0,size end
            for i=2,#list do if list[i][1]~=list[1][1] then size=(list[i][2]-list[1][2])/(list[i][1]-list[1][1]); break end end
            return list[1][2]-list[1][1]*size,size
        end
        local x,width=axis(axes[1],region.width or 0); local y,height=axis(axes[2],region.height or 0)
        result={x,y,width,height}
    end
    cache[region]=result
    return unpack(result)
end
local function under(region,set) while region do if set[region] then return true end; region=region.parent end; return false end
-- Everything inside a framed window keeps clear of the frame: at least 29.75 below its top (the
-- ground starts there), 8.3 above its bottom and 8.6 from its sides (Soundstone's measurements).
local function clearance(root,skip,label)
    local cache,n={},0
    for _,r in ipairs(ALL_FRAMES) do
        if (r.kind=="Texture" or r.kind=="FontString") and visible(r,root) and not under(r,skip) then
            local x,y,width,height=box(r,root,cache); n=n+1
            assert(x>=8.6-1e-6 and x+width<=root.width-8.6+1e-6 and y>=29.75-1e-6 and y+height<=root.height-8.3+1e-6,
                label..": "..tostring(r.text or r.texture or r.atlas).." "..table.concat({x,y,width,height},"/"))
        end
    end
    assert(n>0,label)
end
local function frameParts(frame)
    local w=frame.window
    return {[w.border]=true,[w.top]=true,[w.ground]=true,[w.streaks]=true}
end

local f,border=U.frame,U.frame.window.border
for _,frame in ipairs({f,U.settings,U.removeDialog}) do
    local win=frame.window; local b=win.border
    assert(at(b,frame,"TOPLEFT",-4.4,-3.35) and at(b,frame,"BOTTOMRIGHT",.5,.35) and b.frameLevel==frame.frameLevel+10)
    assert(win.top.frameLevel==frame.frameLevel+12 and win.top.allPoints==b)
    local applied=false
    for _,call in ipairs(NINE_SLICE) do if call.call=="apply" and call.container==b then applied=call.layout=="ButtonFrameTemplateNoPortrait" end end
    assert(applied and b.TopLeftCorner.atlas=="UI-Frame-Metal-CornerTopLeft" and b.TopLeftCorner.layer=="OVERLAY")
    local g,s=win.ground,win.streaks
    assert(g.texture=="Interface\\FrameGeneral\\UI-Background-Rock" and g.wrap[1]=="REPEAT" and g.horizTile and g.vertTile)
    assert(g.layer=="BACKGROUND" and g.sublevel==-6 and at(g,b,"TOPLEFT",7,-21) and at(g,b,"BOTTOMRIGHT",-2,2))
    assert(s.atlas=="_UI-Frame-TopTileStreaks" and s.height==43 and s.horizTile and s.layer=="BACKGROUND" and s.sublevel==-5)
    assert(at(s,b,"TOPLEFT",6,-21) and at(s,b,"TOPRIGHT",-2,-21))
    -- The flat plate under the frame is covered.
    assert(frame.plate.covered and not frame.plate.textures[1].shown)
end
-- Corners cropped with the border's height, again on every change of the window's height.
local function cropped(frame)
    local last
    for _,call in ipairs(NINE_SLICE) do if call.call=="crop" and call.container==frame.window.border then last=call.height end end
    return last
end
for _,frame in ipairs({U.settings,U.removeDialog}) do assert(near(cropped(frame),frame.height-3.7)) end
for _,rows in ipairs({1,3,8}) do
    U:LayoutRows(rows)
    assert(f.height==192+U.slots*50 and near(cropped(f),f.height-3.7))
end
local original=NineSliceUtil.UpdateCornerCropping; NineSliceUtil.UpdateCornerCropping=nil
local calls=#NINE_SLICE; U:LayoutRows(2); assert(#NINE_SLICE==calls and f.height==192+U.slots*50)
NineSliceUtil.UpdateCornerCropping=original

-- The header in the title strip: the red gear, the title and the red close button.
local gear,close=U.frameGear,U.frameClose
assert(gear.template=="UIPanelButtonTemplate" and gear.width==32 and gear.height==22 and at(gear,border,"TOPLEFT",8,1))
assert(gear.symbol.texture:find("GEAR_64GREY",1,true) and gear.symbol.width==17 and at(gear.symbol,gear,"CENTER",0,-.8))
assert(same(gear.symbol.color,1,230/255,128/255))
assert(close.width==28 and close.height==28 and at(close,border,"TOPRIGHT",0,3))
assert(close.normal.atlas=="RedButton-Exit" and close.pushed.atlas=="RedButton-exit-pressed")
assert(close.highlight.atlas=="RedButton-Highlight" and close.highlight.blend=="ADD")
assert(gear.frameLevel==f.frameLevel+12 and close.frameLevel==f.frameLevel+12 and U.header.frameLevel==f.frameLevel+12)
assert(at(U.header,border,"TOPLEFT",40,1) and near(U.header.width,720+.5+4.4-40-28) and U.header.height==22)
local title=U.frameTitle
assert(title.parent==U.header and title.fontSize==12 and title.text=="Hourstone – Azeroth Hours" and at(title,border,"TOP",0,-6))
assert(title.align=="CENTER" and same(title.color,1,210/255,0))
for _,region in ipairs({U.gear,U.logo,U.title,U.close,U.headerRule}) do assert(not visible(region)) end
for _,region in ipairs({gear,close,title}) do assert(visible(region)) end
-- Box of gear and close: the gear from 3.6 to 35.6 and 2.35 to 24.35, the close button from 692.5.
local cache={}
local gx,gy=box(gear,f,cache); local cx,cy=box(close,f,cache)
assert(near(gx,3.6) and near(gy,2.35) and near(cx,692.5) and near(cy,.35))
gear:Click(); assert(U.settings:IsShown()); gear:Click(); assert(not U.settings:IsShown())
close:Click(); assert(not f:IsShown()); U:Toggle(); assert(f:IsShown())

-- The content 20 units up; the window 20 units shorter, its top edge where it was.
assert(at(U.summary,f,"TOPLEFT",10,-30) and at(U.toolbar,f,"TOPLEFT",10,-94) and at(U.table,f,"TOPLEFT",10,-132))
assert(at(U.footerFrame,f,"TOPLEFT",10,-(156+U.slots*50)) and at(U.sortMenu,f,"TOPLEFT",10,-157))
db.settings.position={x=0,y=0,height=262}; U:Position()
assert(near(f.points[1][5]+f.height/2,131))
db.settings.position={x=0,y=0,height=242}; U:Position()
assert(near(f.points[1][5],(242-f.height)/2))
db.settings.position=nil; U:Position()
U:ToggleSettings(); assert(at(U.settings,f,"TOPLEFT",10,-28) and U.settings.height==214)
-- The format and search fields are Blizzard's dropdown art, anchored 8 units beyond their controls as
-- on the filter buttons; its visible edge lies inside that box, so the controls' own rectangles keep clear.
clearance(f,{[border]=true,[f.window.top]=true,[f.window.ground]=true,[f.window.streaks]=true,[U.header]=true,[gear]=true,[close]=true,
    [U.settings]=true,[U.removeDialog]=true,[U.menu]=true,[U.clientMenu]=true,[U.sortMenu]=true,[U.progressTip]=true,[U.format.art.field]=true,[U.search.field]=true},"window")
for rows=1,8 do U.search:SetText(rows==8 and "" or "Example"..rows); clearance(f,{[border]=true,[f.window.top]=true,[f.window.ground]=true,
    [f.window.streaks]=true,[U.header]=true,[gear]=true,[close]=true,[U.settings]=true,[U.removeDialog]=true,[U.menu]=true,
    [U.clientMenu]=true,[U.sortMenu]=true,[U.progressTip]=true,[U.format.art.field]=true,[U.search.field]=true},"window "..rows) end
for _,control in ipairs({U.format,U.search}) do local x,y,width,height=box(control,f,{}); assert(x>=8.6 and x+width<=720-8.6 and y>=29.75 and y+height<=f.height-8.3) end
U.search:SetText("")

-- The settings and the delete dialog in the frame: titles centred, a close button on the settings only.
U:CloseMenus(); U:ToggleSettings()
local s=U.settings.window
assert(U.settingsFrameTitle.parent==s.top and U.settingsFrameTitle.text==L.settings and U.settingsFrameTitle.fontSize==12)
assert(at(U.settingsFrameTitle,s.border,"TOP",0,-6) and same(U.settingsFrameTitle.color,1,210/255,0))
assert(at(U.settingsFrameClose,s.border,"TOPRIGHT",0,3) and U.settingsFrameClose.normal.atlas=="RedButton-Exit")
assert(not visible(U.settingsHeading,U.settings) and not visible(U.settingsClose,U.settings))
clearance(U.settings,frameParts(U.settings),"settings")
U.settingsFrameClose:Click(); assert(not U.settings:IsShown())
U:ConfirmRemoval(db.characters["test:2"])
local d=U.removeDialog.window
assert(U.removeFrameTitle.parent==d.top and U.removeFrameTitle.text==L.removeTitle and at(U.removeFrameTitle,d.border,"TOP",0,-6))
assert(not visible(U.removeHeading,U.removeDialog) and count(function(r) return r.kind=="Button" and r.parent==d.top end)==0)
clearance(U.removeDialog,frameParts(U.removeDialog),"dialog")
U:CloseMenus()

-- Push buttons: Blizzard's template at each control's rectangle; a click is the control's click.
for _,b in ipairs({U.reset,U.done,U.removedToggle,U.removeCancel,U.removeConfirm}) do
    local twin=b.twin
    assert(twin.template=="UIPanelButtonTemplate" and not b.shown and twin.shown)
    assert(at(twin,b.points[1][2],"TOPLEFT",b.points[1][4],b.points[1][5]) and twin.width==b.width and twin.height==b.height)
    assert(twin.text==b.label.text and twin.Text.fontSize==(b==U.reset and 10 or 11) and twin.Text.color==nil)
    local clicked
    local action=b.scripts.OnClick; b.scripts.OnClick=function() clicked=true end
    twin:Click(); b.scripts.OnClick=action
    assert(clicked)
end
U:ToggleSettings(); U.removedToggle.twin:Click()
assert(U.removedOnly and U.removedToggle.twin.text==L.showTracked)
U.removedToggle.twin.scripts.OnEnter(U.removedToggle.twin); assert(GameTooltip.lines[1]==L.removedCharacters)
U.removedToggle.twin.scripts.OnLeave(U.removedToggle.twin); assert(not GameTooltip:IsShown())
U.removedToggle.twin:Click(); assert(not U.removedOnly and U.removedToggle.twin.text==L.removedCharacters)
U:CloseMenus()

-- Filter buttons in Forever's dropdown art; the arrow follows Blizzard's states.
for _,pair in ipairs({{U.realmButton,U.menu,function() U:ToggleRealms() end},{U.clientButton,U.clientMenu,function() U:ToggleClients() end}}) do
    local b,menu,toggle=pair[1],pair[2],pair[3]
    local dd=b.dropdown
    assert(b.plate.covered and not b.plate.textures[1].shown and not visible(b.arrow) and b.glow.alpha==0)
    assert(dd.field.atlas=="common-dropdown-textholder" and at(dd.field,b,"TOPLEFT",-8,7) and at(dd.field,b,"BOTTOMRIGHT",8,-9))
    assert(at(dd.arrow,b,"RIGHT",1,-3) and dd.arrow.atlas=="common-dropdown-a-button")
    b.scripts.OnEnter(b); assert(dd.arrow.atlas=="common-dropdown-a-button-hover")
    b.scripts.OnMouseDown(b); assert(dd.arrow.atlas=="common-dropdown-a-button-pressedhover")
    b.scripts.OnMouseUp(b); assert(dd.arrow.atlas=="common-dropdown-a-button-hover")
    b.scripts.OnLeave(b); assert(dd.arrow.atlas=="common-dropdown-a-button")
    toggle(); assert(menu:IsShown() and dd.arrow.atlas=="common-dropdown-a-button-open")
    U:CloseMenus(); assert(dd.arrow.atlas=="common-dropdown-a-button")
end
-- The format toggle: one dropdown field over both halves, where the filter fields lie, with a
-- one-pixel divider in the gap; the chosen half bright, the other muted, the accent under the pointer.
local fa=U.format.art
assert(fa.field.atlas=="common-dropdown-textholder" and fa.field.layer=="BACKGROUND" and fa.field.sublevel==1 and visible(fa.field))
assert(at(fa.field,U.format,"TOPLEFT",-8,7.5) and at(fa.field,U.format,"BOTTOMRIGHT",8,-9.5))
do
    local cache={}
    local _,fy,_,fh=box(fa.field,U.toolbar,cache); local _,ry,_,rh=box(U.realmButton.dropdown.field,U.toolbar,cache)
    assert(near(fy,ry) and near(fh,rh))
end
assert(at(fa.divider,U.format,"TOP",112.5,-5,"TOPLEFT") and fa.divider.height==15 and near(fa.divider.width,Th.Pixel(U.format)))
assert(fa.divider.layer=="ARTWORK" and same(fa.divider.color,Th.Color("outline")) and visible(fa.divider))
for _,b in ipairs({U.combined,U.hours}) do
    assert(b.plate.covered and not b.plate.textures[1].shown and not b.plate.tint.shown and not b.plate.underline.shown and b.glow.alpha==0)
end
U:SetFormat("hours")
assert(same(U.hours.label.color,Th.Color("text")) and same(U.combined.label.color,Th.Color("unchosenLabel")))
assert(not U.hours.plate.tint.shown and not U.hours.plate.underline.shown)
U.combined.scripts.OnEnter(U.combined); assert(same(U.combined.label.color,Th.Color("hover")))
U.combined.scripts.OnLeave(U.combined); assert(same(U.combined.label.color,Th.Color("unchosenLabel")))
U.combined.scripts.OnClick(U.combined)
assert(db.settings.format=="combined" and same(U.combined.label.color,Th.Color("text")) and same(U.hours.label.color,Th.Color("unchosenLabel")))
for _,size in ipairs({.65,1.35,2}) do db.settings.scale=size; U:ApplyScale(); assert(near(fa.divider.width,Th.Pixel(U.format))) end
db.settings.scale=1; U:ApplyScale()
-- The search field in the same field, placed as on the filter buttons; text, hint and clear button stay.
local sf=U.search.field
assert(sf.atlas=="common-dropdown-textholder" and sf.layer=="BACKGROUND" and sf.sublevel==1 and visible(sf))
assert(at(sf,U.search,"TOPLEFT",-8,7) and at(sf,U.search,"BOTTOMRIGHT",8,-9) and U.search.height==U.realmButton.height)
assert(U.search.plate.covered and not U.search.plate.textures[1].shown and visible(U.search.hint) and same(U.search.hint.color,Th.Color("hint")))
U.search:SetText("Example2"); assert(visible(U.clearSearch) and not visible(U.search.hint) and same(U.search.color,Th.Color("searchText")))
U.search:SetText("")
-- Menus in Forever's dropdown list, with Blizzard's bottom inset of 15.
U:ToggleRealms(); U:CloseMenus(); U:ToggleClients(); U:CloseMenus()
for _,menu in ipairs({U.menu,U.clientMenu,U.sortMenu}) do
    assert(menu.art.atlas=="common-dropdown-bg" and near(menu.art.alpha,.925) and at(menu.art,menu,"TOPLEFT",-10,3) and at(menu.art,menu,"BOTTOMRIGHT",10,-3))
    assert(menu.plate.covered and not menu.plate.textures[1].shown and menu.frameLevel==f.frameLevel+30)
end
local clients=0; for _,row in pairs(U.clientRows) do if row.shown then clients=clients+1 end end
assert(U.clientMenu.height==clients*25+23 and U.sortMenu.height==98 and U.menu.height==math.min(6,#U.realmChoices)*25+23)

-- The size slider: Forever's track and diamond, the fill 4 units in, in Soundstone's gold.
local slider,track=U.scaleSlider,U.scaleSlider.track
assert(track.left.atlas=="Minimal_SliderBar_Left" and track.middle.atlas=="_Minimal_SliderBar_Middle" and track.right.atlas=="Minimal_SliderBar_Right")
assert(at(track.left,slider,"LEFT",0,0) and at(track.right,slider,"RIGHT",0,0) and at(track.middle,track.left,"TOPLEFT",0,0,"TOPRIGHT"))
assert(at(track.middle,track.right,"TOPRIGHT",0,0,"TOPLEFT") and track.left.layer=="BACKGROUND" and U.scaleFill.layer=="BORDER")
assert(slider.plate.covered and not U.scaleEdge.shown and not U.scaleTrack.shown and same(U.scaleFill.color,1,176/255,33/255))
local thumb=slider:GetThumbTexture()
assert(thumb.atlas=="Minimal_SliderBar_Button" and thumb.atlasArgs[1]==true and thumb.atlasArgs[3]==true and thumb.uv==nil)
assert(thumb.layer=="OVERLAY" and thumb.sublevel==7 and thumb.blend=="BLEND" and same(thumb.color,1,1,1))
for _,size in ipairs({.65,1,1.3,2}) do
    slider:SetValue(size*100)
    assert(at(U.scaleFill,slider,"TOPLEFT",4,-7.5) and U.scaleFill.height==3 and near(U.scaleFill.width,218*(size-.65)/1.35))
end
slider:SetValue(100)

-- The table on Blizzard's inset, at the window's own level.
local inset=U.inset
assert(inset.shown and inset.frameLevel==f.frameLevel and at(inset,U.table,"TOPLEFT",0,0) and at(inset,U.table,"BOTTOMRIGHT",0,0))
-- Not the template's marble: the window's rock runs on under the table, darkened to 45 %.
assert(inset.ground.texture==nil and same(inset.ground.color,0,0,0,.55) and inset.ground.layer=="BACKGROUND" and inset.ground.sublevel==-5)
assert(inset.ground.allPoints==inset and f.window.ground.sublevel==-6 and visible(f.window.ground))
do
    local cache={}
    local gx,gy,gw,gh=box(f.window.ground,f,cache); local tx,ty,tw,th=box(U.table,f,cache)
    assert(gx<=tx and gy<=ty and gx+gw>=tx+tw and gy+gh>=ty+th)
end
assert(inset.TopLeftCorner.atlas=="UI-Frame-InnerTopLeft" and inset.TopLeftCorner.sublevel==-5)

-- Class colors, the current character's marker and the heart keep their colors in the frame.
check("framed, all states")
U.search:SetText("Example2")
for _,row in ipairs(U.rows) do if row.entry and row.entry.char.class=="WARRIOR" then warrior=row end end
assert(warrior and same(warrior.name.color,w.r,w.g,w.b))
U.search:SetText("")

-- Each group missing alone: only its piece falls back to the flat look. Without the frame, the
-- streaks and the inset go with it and the window keeps 0.3.7's height.
local GROUPS={window={"RedButton-Exit"},streaks={"_UI-Frame-TopTileStreaks"},inset={"UI-Frame-InnerTopLeft"},
    menu={"common-dropdown-bg"},dropdown={"common-dropdown-a-button-open"},track={"_Minimal_SliderBar_Middle"},thumb={"Minimal_SliderBar_Button"}}
local built=#ALL_FRAMES
for group,names in pairs(GROUPS) do
    ATLAS_MISSING={}; for _,name in ipairs(names) do ATLAS_MISSING[name]=true end
    U:ApplyTheme()
    for key in pairs(GROUPS) do
        local expected=key~=group and not (group=="window" and (key=="streaks" or key=="inset"))
        assert(Th.art[key]==expected,group.."/"..key)
    end
    local framed=group~="window"
    assert(U.framed==framed and f.plate.covered==(framed or nil) and border.shown==framed and gear.shown==framed and U.gear.shown==not framed)
    assert(f.window.streaks.shown==(framed and group~="streaks") and inset.shown==(framed and group~="inset"))
    assert(f.height==(framed and 192 or 212)+U.slots*50 and at(U.summary,f,"TOPLEFT",10,framed and -30 or -50))
    for _,b in ipairs({U.reset,U.removeConfirm}) do assert(b.shown==not framed and b.twin.shown==framed) end
    assert(U.realmButton.dropdown.field.shown==(group~="dropdown") and U.realmButton.plate.textures[1].shown==(group=="dropdown"))
    assert(U.realmButton.arrow.shown==(group=="dropdown"))
    assert(U.search.field.shown==(group~="dropdown") and U.search.plate.textures[1].shown==(group=="dropdown"))
    assert(fa.field.shown==(group~="dropdown") and fa.divider.shown==(group~="dropdown") and U.hours.plate.textures[1].shown==(group=="dropdown"))
    assert(U.combined.glow.alpha==(group=="dropdown" and 1 or 0) and U.combined.plate.tint.shown==(group=="dropdown"))
    assert(same(U.combined.label.color,Th.Color(group=="dropdown" and "chosenLabel" or "text")) and same(U.hours.label.color,Th.Color("unchosenLabel")))
    assert(U.menu.art.shown==(group~="menu") and U.menu.plate.textures[1].shown==(group=="menu"))
    U:ToggleClients(); local shownRows=0; for _,row in pairs(U.clientRows) do if row.shown then shownRows=shownRows+1 end end
    assert(U.clientMenu.height==shownRows*25+(group=="menu" and 16 or 23)); U:CloseMenus()
    assert(track.left.shown==(group~="track") and slider.plate.textures[1].shown==(group=="track"))
    assert(at(U.scaleFill,slider,"TOPLEFT",group=="track" and Th.Pixel(slider) or 4,group=="track" and -6-Th.Pixel(slider) or -7.5))
    assert((thumb.atlas=="Minimal_SliderBar_Button")==(group~="thumb"))
    if group=="thumb" then assert(thumb.texture:find("WHITE8X8",1,true) and thumb.width==10 and thumb.height==18 and thumb.layer=="ARTWORK") end
    check("without "..group)
    assert(#ALL_FRAMES==built,group)
end
unknownArt(false)

-- Round trip: forever, standard, forever restores every region and both layouts; nothing new is
-- built, and nothing moves the saved position.
local function snapshot()
    local cache,list={},{}
    for _,r in ipairs(ALL_FRAMES) do
        if (r.kind=="Texture" or r.kind=="FontString") and visible(r) then
            local x,y,width,height=box(r,f,cache)
            list[#list+1]=table.concat({r.id,r.layer or "",tostring(r.sublevel),x,y,width,height,tostring(r.alpha),tostring(r.texture),tostring(r.atlas),
                tostring(r.text),tostring(r.fontSize),r.color and table.concat({rgba(r.color)},",") or "",r.uv and table.concat(r.uv,",") or ""},"|")
        end
    end
    return table.concat(list,"\n")
end
U:ApplyTheme(); db.settings.position={x=17,y=-43,height=f.height}; U:Position()
local before,where=snapshot(),{f.points[1][4],f.points[1][5]}
U:ApplyTheme("standard")
assert(not U.framed and f.height==212+U.slots*50 and at(U.summary,f,"TOPLEFT",10,-50) and at(U.header,f,"TOPLEFT",10,-10))
assert(U.header.width==700 and U.header.height==40 and U.header.frameLevel==U.headerLevel and at(U.settings,f,"TOPLEFT",24,-47))
assert(thumb.texture:find("SilverThumb",1,true) and thumb.atlas==nil and thumb.width==10 and thumb.layer=="ARTWORK")
assert(not visible(fa.field) and not visible(fa.divider) and U.combined.glow.alpha==1 and U.combined.chosenKey==nil)
assert(not visible(sf) and not U.search.plate.covered and U.search.plate.sprites[1].shown)
assert(same(U.combined.label.color,Th.Color("chosenLabel")) and same(U.combined.label.color,255/255,227/255,156/255))
check("standard after the frame")
U:ApplyTheme()
assert(snapshot()==before and f.points[1][4]==where[1] and f.points[1][5]==where[2] and #ALL_FRAMES==built)
assert(db.settings.position.x==17 and db.settings.position.y==-43)
db.settings.position=nil

-- Dragging: the window is on the DIALOG strata, above the action bars' MEDIUM; the frame and its
-- header controls are its children and need no BringToFront.
assert(f.strata=="DIALOG" and border.parent==f and U.header.parent==f)
U.header.scripts.OnDragStart(U.header); assert(U.windowDragging); U.header.scripts.OnDragStop(U.header); assert(not U.windowDragging)
