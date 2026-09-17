fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
fire("TIME_PLAYED_MSG",1125000,200)
local U,db=H.UI,HourstoneDB
SlashCmdList.HOURSTONE("")
assert(U.frame:IsShown() and UISpecialFrames[1]=="HourstoneWindow")
assert(U.total:GetText()==H.M.Format(1125000,"combined"))
U:SetFormat("hours"); assert(db.settings.format=="hours")
assert(U.rows[1].name:GetText()==IDENTITY.name and U.rows[1].active:IsShown())
U:RowTooltip(U.rows[1]); assert(#GameTooltip.lines>=4)
assert(U.rows[1].client.text==H.M.ClientText(H.T.record))
assert(U.rows[1].realm.text==IDENTITY.realm)
assert(U.creditWith.text=="with")
assert(U.search.parent==U.realmButton.parent and U.realmButton.parent==U.clientButton.parent)
U.search.scripts.OnEnter(U.search); assert(GameTooltip.lines[1]==H.L.searchHelp)
U.search.scripts.OnLeave(); assert(not GameTooltip:IsShown())
U.headers.flavor.button:Click(); assert(U.sort=="flavor" and not U.descending)
U.headers.flavor.button:Click(); assert(U.sort=="flavor" and U.descending)
U:SetSort("seconds")
local timestamp="2026-09-16 19:21"
local originalDate=date; date=function(format) assert(format=="%Y-%m-%d %H:%M"); return timestamp end
local function checkTooltip(entry,expectedNotice)
    U:RowTooltip({entry=entry})
    local foundStamp,foundNotice=false,false
    for i,line in ipairs(GameTooltip.lines) do
        assert(not line:lower():find("offline",1,true) and not line:lower():find("online",1,true))
        assert(line~="Current character" and line~="Aktueller Charakter")
        if line==string.format(H.L.sync,timestamp) then assert(GameTooltip.lineWrap[i]==false); foundStamp=true end
        if line==expectedNotice then foundNotice=true end
    end
    assert(foundStamp==(entry.char.serverAt~=nil))
    if expectedNotice then assert(foundNotice) end
end
checkTooltip(U.rows[1].entry,H.L.estimate)
checkTooltip({key="remote",seconds=200,char={name="Remote",realm="Realm",level=10,flavor="era",serverSeconds=100,serverAt=EPOCH}},H.L.estimate)
checkTooltip({key="remote",seconds=100,char={name="Remote",realm="Realm",level=10,flavor="era",serverSeconds=100,serverAt=EPOCH}})
checkTooltip({key="legacy",seconds=100,char={name="Legacy",realm="Realm",level=10}},H.L.noSync)
date=originalDate
for i=1,140 do
    db.characters["other:"..i]={name=string.rep("Long",8)..i,realm="Realm "..(i%15),level=i%91,seconds=i*1000,class="WARRIOR",updatedAt=EPOCH-i}
end
U:Refresh(); assert(U.maxOffset==133)
U:ToggleClients(); assert(U.clientMenu:IsShown())
U:ToggleRealms(); assert(U.menu:IsShown() and not U.clientMenu:IsShown())
U:ToggleClients(); assert(U.clientMenu:IsShown() and not U.menu:IsShown())
U.clientRows.era.scripts.OnClick()
assert(U.flavor=="era" and not U.clientMenu:IsShown() and U.offset==0)
assert(U.visibleCount==0 or H.C.Flavor()=="era")
U:ToggleClients(); U.clientRows.all.scripts.OnClick()
assert(U.flavor==nil and U.visibleCount==141 and U.maxOffset==133)
U:Scroll(999); assert(U.offset==133 and U.rows[8].entry)
U:ToggleRealms(); assert(#U.realmChoices==17 and U.menu:IsShown())
U.menu.scripts.OnMouseWheel(U.menu,-8); assert(U.realmOffset==11)
local realm=U.realmRows[6].realm; U.realmRows[6].scripts.OnClick(U.realmRows[6])
assert(U.realm==realm and not U.menu:IsShown() and U.offset==0)
U.search:SetText("no match []"); assert(U.empty:IsShown() and not U.rows[1]:IsShown())
U.search:SetText(""); U.realm=nil; U:Refresh()
U.headers.name.button.scripts.OnClick(); assert(U.sortMenu:IsShown())
U.sortRows.name.scripts.OnClick(); assert(U.sort=="name" and not U.descending)
U.sortRows.name.scripts.OnClick(); assert(U.descending)
U.sortRows.level.scripts.OnClick(); assert(U.sort=="level" and U.descending)
U.sortRows.realm.scripts.OnClick(); assert(U.sort=="realm" and not U.descending)
U.headers.updatedAt.button.scripts.OnClick(); assert(U.sort=="updatedAt" and U.descending)
U.headers.seconds.button.scripts.OnClick(); assert(U.sort=="seconds" and U.descending)
U:ToggleSettings(); assert(U.settings:IsShown())
assert(U.minimapBox.kind=="CheckButton" and U.minimapBox.template=="UICheckButtonTemplate")
assert(U.minimapBox:GetChecked())
U.minimapBox:Click(); assert(not db.settings.minimap and not U.minimap:IsShown() and not U.minimapBox:GetChecked())
U.minimapBox:Click(); assert(db.settings.minimap and U.minimap:IsShown() and U.minimapBox:GetChecked())
U.minimapToggle.scripts.OnClick(); assert(not db.settings.minimap and not U.minimap:IsShown())
assert(not U.minimapBox:GetChecked())
SlashCmdList.HOURSTONE("minimap"); assert(U.minimap:IsShown() and U.minimapBox:GetChecked())
assert(U.densityToggle==nil and U.densityMenu==nil and #U.rows==8)
for _,legacy in ipairs({false,true}) do
    db.settings.compact=legacy; U:LayoutRows()
    assert(U.frame:GetHeight()==(H.C.Retail() and 644 or 612) and U.rows[1]:GetHeight()==50 and db.settings.compact==legacy)
end
assert(U.frame:GetHeight()==(H.C.Retail() and 644 or 612) and U.rows[1]:GetHeight()==50)
local before=db.characters
U.scaleSlider:SetValue(90); assert(math.abs(db.settings.scale-.9)<.001)
U.scaleSlider:SetValue(130); assert(db.settings.scale==1.3 and db.characters==before)
U.scaleSlider:SetValue(200); assert(db.settings.scale==2 and db.characters==before and U.scaleFill:GetWidth()==224)
assert(U.slots<8 and U.maxOffset==U.visibleCount-U.slots)
U:Scroll(999); assert(U.rows[U.slots].entry and not U.rows[U.slots+1]:IsShown())
U.scaleSlider:SetValue(65); assert(db.settings.scale==.65 and U.scaleFill:GetWidth()==0)
assert(U.scaleMin.text=="65 %" and U.scaleMax.text=="200 %")
local stableScale,stableHeight=U.frame:GetScale(),U.frame:GetHeight()
local originalMouseButtonDown=IsMouseButtonDown
IsMouseButtonDown=function(button) return button=="LeftButton" end
U.scaleSlider:SetValue(130) -- Native track clicks can change the value before OnMouseDown.
assert(U.frame:GetScale()==stableScale and U.dragScale==.65)
U.scaleSlider.scripts.OnMouseDown(U.scaleSlider,"LeftButton")
assert(U.dragScale==.65) -- Do not replace the captured scale with the new requested value.
U.scaleSlider:SetValue(130)
assert(db.settings.scale==1.3 and U.scaleLabel.text=="130 %" and U.frame:GetScale()==stableScale)
U:Refresh() -- The regular refresh must also keep the slider under the mouse.
assert(U.frame:GetScale()==stableScale and U.frame:GetHeight()==stableHeight)
U.scaleSlider:SetValue(150)
assert(db.settings.scale==1.5 and U.scaleLabel.text=="150 %" and U.frame:GetScale()==stableScale)
IsMouseButtonDown=originalMouseButtonDown
U.scaleSlider.scripts.OnMouseUp(U.scaleSlider,"LeftButton")
assert(not U.scaleDragging and U.dragScale==nil and U.frame:GetScale()>stableScale)
U.settings:Show()
U.scaleSlider.scripts.OnMouseDown(U.scaleSlider,"LeftButton")
U.scaleSlider:SetValue(175); U.settings:Hide()
assert(not U.scaleDragging and U.dragScale==nil)
assert(math.abs(U.frame:GetEffectiveScale()*1080/768-1.75)<.0001)
U.scaleSlider:SetValue(200)
configure_display(800,600); U:ApplyScale(); assert(U.frame:GetEffectiveScale()*600/768<=780/720+.0001)
U.search.scripts.OnEscapePressed(U.search); assert(not U.frame:IsShown())
SlashCmdList.HOURSTONE(""); assert(U.frame:IsShown())
fire("UI_SCALE_CHANGED"); fire("DISPLAY_SIZE_CHANGED")
U.frame.scripts.OnHide(); assert(not U.settings:IsShown())
assert(SLASH_HOURSTONE1=="/hourstone" and SLASH_HOURSTONE2=="/azerothhours")
U.minimap.scripts.OnClick(); assert(not U.frame:IsShown())
U.minimap.scripts.OnDragStart(); U.minimap.scripts.OnUpdate()
U.minimap.scripts.OnDragStop(); assert(db.settings.minimapAngle>=0 and db.settings.minimapAngle<360)
U.minimap.scripts.OnClick(); assert(not U.frame:IsShown())
advance(1); U.minimap.scripts.OnClick(); assert(U.frame:IsShown())

-- A live drag must retain WoW's moving anchor across the real one-second
-- refresh and display events, then persist the released position before layout.
configure_display(2560,1440,.8)
U.scaleSlider:SetValue(130)
local views=H.C.Retail() and {"played","progress"} or {"played"}
for _,view in ipairs(views) do
    U:SetView(view)
    for _,parentScale in ipairs({.65,.8,1}) do
        configure_display(2560,1440,parentScale); U:ApplyScale()
        U.header.scripts.OnDragStart()
        local saved=db.settings.position
        U.frame:ClearAllPoints(); U.frame:SetPoint("CENTER",UIParent,"CENTER",90,-50)
        local movingScale,movingHeight=U.frame:GetScale(),U.frame:GetHeight()
        tick(1.1)
        fire("UI_SCALE_CHANGED"); fire("DISPLAY_SIZE_CHANGED")
        local _,_,_,x,y=U.frame:GetPoint()
        assert(x==90 and y==-50,"Periodic refresh moved the dragged window")
        assert(U.frame:GetScale()==movingScale and U.frame:GetHeight()==movingHeight)
        assert(db.settings.position==saved,"A live drag must not persist an intermediate anchor")
        U.header.scripts.OnDragStop()
        assert(math.abs(db.settings.position.x-90)<.0001 and math.abs(db.settings.position.y+50)<.0001)
        tick(1.1)
        local _,_,_,releasedX,releasedY=U.frame:GetPoint()
        assert(math.abs(releasedX-90)<.0001 and math.abs(releasedY+50)<.0001)
    end
end
U.header.scripts.OnDragStart()
U.frame:ClearAllPoints(); U.frame:SetPoint("CENTER",UIParent,"CENTER",60,20)
U.frame:Hide()
assert(math.abs(db.settings.position.x-60)<.0001 and math.abs(db.settings.position.y-20)<.0001)
local hiddenPosition=db.settings.position
U.header.scripts.OnDragStop() -- WoW can deliver the drag stop after hiding.
assert(db.settings.position==hiddenPosition)
U:Toggle(); tick(1.1)
local _,_,_,reopenedX,reopenedY=U.frame:GetPoint()
assert(math.abs(reopenedX-60)<.0001 and math.abs(reopenedY-20)<.0001)
