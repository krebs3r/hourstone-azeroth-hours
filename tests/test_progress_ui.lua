fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
fire("TIME_PLAYED_MSG",100000,100)
local U,L,db=H.UI,H.L,HourstoneDB
U:Toggle()
if not H.C.RetailProgress() then
    assert(U.tabs==nil and not U:IsProgress())
    U:SetView("progress"); assert(not U:IsProgress() and db.settings.view=="played")
    return
end

local scheduled,reads=0,0
local function slots()
    return {{progress=4,threshold=1,level=13,difficultyName="Mythic+",unlocked=true},
        {progress=4,threshold=4,level=12,unlocked=true},
        {progress=4,threshold=8,level=0,unlocked=false}}
end
local longName="Ein außerordentlich langer lokalisierter Dungeonname mit Umlauten"
local data={
    Alpha01={supported=true,keystone={status="known",present=true,name=longName,level=12,updatedAt=EPOCH},
        weekly={status="known",level=13,updatedAt=EPOCH},vault={status="known",rows={
            dungeon={status="known",updatedAt=EPOCH,slots=slots()},raid={status="unknown"},
            world={status="known",slots={{progress=0,threshold=2,level=0,unlocked=false}}}}}},
    Alpha02={supported=true,keystone={status="known",present=false,updatedAt=EPOCH},weekly={status="known",level=0},vault={rows={}}},
    Alpha03={supported=true,keystone={status="unknown"},weekly={status="unknown"},vault={rows={}}},
    Alpha04={supported=true,keystone={status="stale",present=true,name="Old dungeon",level=9,updatedAt=EPOCH-604800},
        weekly={status="stale",expired=true,level=11,updatedAt=EPOCH-604800},vault={rows={dungeon={status="stale",slots=slots()}}}},
    Alpha05={supported=false,keystone={status="unavailable"},weekly={status="unavailable"},vault={rows={}}},
    Alpha06={supported=true,keystone={status="known",present=true,level=14},weekly={status="unknown"},vault={rows={}}},
    Alpha07={supported=true,keystone={status="stale",present=false},weekly={status="stale",level=0},vault={rows={}}},
}
for i=1,12 do
    local name=string.format("Alpha%02d",i)
    db.characters["fixture:"..i]={name=name,realm="Realm",guild="Guild",guildUpdatedAt=EPOCH,seconds=i*100,
        flavor=i==5 and "era" or "retail",level=80,class="MAGE"}
end
H.P={Schedule=function(_,reason) assert(reason=="open"); scheduled=scheduled+1 end,
    Get=function(_,char) reads=reads+1; return data[char.name] or {supported=true,keystone={status="unknown"},weekly={status="unknown"},vault={rows={}}} end}
U:SetView("progress")
assert(U:IsProgress() and db.settings.view=="progress" and U.sort=="name" and not U.descending)
assert(not U.format:IsShown() and U.rowHeight==64 and U.frame:GetHeight()==756 and scheduled==1)
assert(U.rows[1].entry.char.name=="Alpha01" and not U.rows[1].client:IsShown())
assert(U.headers.flavor.button.label.text==L.keystone and U.headers.seconds.button.label.text==L.thisWeek)
assert(U.headers.updatedAt.button.label.text==L.vault and not U.headers.seconds.button.arrow:IsShown())
local first=U.rows[1]
assert(first.keyText.text:find("…",1,true) and first.keyText:GetUnboundedStringWidth()<=first.keyText:GetWidth())
assert(first.keyLevel.text=="+12" and first.keyLevel:IsShown() and first.weekText.text=="+13")
assert(first.keyText.points[1][4]+first.keyText:GetWidth()<first.keyLevel.points[1][4])
assert(first.vault.dungeon.slots[1].check:IsShown() and first.vault.dungeon.slots[2].check:IsShown())
assert(not first.vault.dungeon.slots[3].check:IsShown() and not first.vault.dungeon.slots[3].unknown:IsShown())
assert(first.vault.raid.slots[1].unknown:IsShown() and first.vault.world.slots[2].unknown:IsShown())
assert(not first.vault.world.slots[1].check:IsShown() and not first.vault.world.slots[1].unknown:IsShown())
assert(U.rows[2].keyText.text==L.noKeystone and U.rows[2].keyNote.text==L.confirmed)
assert(not U.rows[2].keyLevel:IsShown() and U.rows[2].weekText.text=="–")
assert(U.rows[3].keyText.text==L.notRecorded and U.rows[3].keyNote.text==L.noProgressData)
assert(U.rows[4].keyNote.text==L.stale and U.rows[4].weekNote.text==L.previousWeek)
assert(U.rows[4].vault.dungeon.slots[1].alpha<1 and U.rows[4].vault.dungeon.slots[1].check:IsShown())
assert(not U.rows[5].keyLevel:IsShown() and not U.rows[5].vault.dungeon.slots[1].unknown:IsShown())
assert(U.rows[6].keyLevel.text=="+14" and U.rows[6].keyLevel:IsShown())
assert(U.rows[7].keyText.text==L.noKeystone and U.rows[7].keyNote.text==L.stale)
assert(U.rows[7].weekNote.text==L.stale)
assert(U.footer.text==string.format(L.progressLocal,13,13))
local before=reads
U:Refresh(); U:Refresh(); assert(reads>before and scheduled==1)

U:ProgressTooltip(first,"dungeon")
assert(U.progressTip:IsShown() and U.tipTitle.text=="Alpha01 · "..L.vault)
assert(U.tipLines[2].text:find("1 / 1",1,true) and U.tipLines[3].text:find("4 / 4",1,true))
assert(U.tipLines[2].text:find("Mythic+",1,true) and U.tipLines[2].text:find("+13",1,true))
assert(U.tipMarks[2]:IsShown() and U.tipMarks[2].check:IsShown())
assert(U.tipMarks[2].check.texture:find("Check.tga",1,true))
assert(U.tipMarks[4]:IsShown() and not U.tipMarks[4].check:IsShown())
for _,label in ipairs(U.tipLines) do
    assert(not label.text:find("✓",1,true) and not label.text:find("○",1,true))
end
assert(U.tipLines[4].text:find("4 / 8",1,true) and U.tipLines[5].text==string.format(L.bestThisWeek,"+13"))
data.Alpha01.vault.rows.world.slots[1]={progress=1,threshold=2,level=8,difficultyName="World difficulty",unlocked=false}
U:ProgressTooltip(first,"world")
assert(U.tipLines[2].text:find("World difficulty",1,true) and U.tipLines[2].text:find(L.level.." 8",1,true))
assert(not U.tipLines[2].text:find("+8",1,true))
data.Alpha01.vault.rows.raid={status="known",slots={{progress=1,threshold=2,level=16,difficultyName="Heroic",unlocked=false}}}
U:ProgressTooltip(first,"raid")
assert(U.tipLines[2].text:find("Heroic",1,true) and not U.tipLines[2].text:find("+16",1,true))
U:ProgressTooltip(first,"keystone"); assert(U.tipLines[1].text==longName.." +12")
for _,mark in pairs(U.tipMarks) do assert(not mark:IsShown()) end
U:ProgressTooltip(U.rows[2],"weekly"); assert(U.tipLines[1].text==L.noRuns)
U:ProgressTooltip(U.rows[4],"dungeon")
assert(U.tipLines[5].text==L.stale and U.tipLines[6].text==string.format(L.bestThisWeek,"–"))
U:ProgressTooltip(U.rows[5],"keystone"); assert(U.tipLines[1].text==L.progressUnavailable)
U:ProgressTooltip(U.rows[6],"keystone"); assert(U.tipLines[1].text==L.unknownDungeon.." +14")
U:ProgressTooltip(U.rows[7],"weekly"); assert(U.tipLines[1].text==L.noRuns)
U:ProgressTooltip(first,"dungeon"); U:Scroll(3); assert(not U.progressTip:IsShown())
U:Scroll(-999)

U:SetSort("level"); assert(U.sort=="level")
U.headers.seconds.button:Click(); assert(U.sort=="level") -- Progress headers do not sort hidden playtime.
U:SetView("played"); assert(U.format:IsShown() and U.rowHeight==50 and U.sort=="seconds")
U:SetView("progress"); assert(U.sort=="level" and scheduled==2)
U:SetSort("name")
U.scaleSlider:SetValue(200)
assert(db.settings.scale==2 and U.slots==4 and U.maxOffset==9)
assert(U.rows[4]:IsShown() and not U.rows[5]:IsShown())
U.scrollDown:Click(); assert(U.offset==1)
U.scrollUp:Click(); assert(U.offset==0)
U:Scroll(999); assert(U.rows[4].entry and U.offset==9)
configure_display(800,600); U:ApplyScale()
assert(U.slots==1 and U.maxOffset==12 and U.scroll:GetHeight()==28)
assert(U.scroll:GetThumbTexture():GetHeight()==14)
assert(U.scroll:GetThumbTexture():GetHeight()<U.scroll:GetHeight())
U.scroll:SetValue(U.maxOffset); assert(U.offset==12 and U.rows[1].entry)
U.scroll:SetValue(0); assert(U.offset==0 and U.rows[1].entry.char.name=="Alpha01")
configure_display(1920,1080); U:ApplyScale()
U.search:SetText("Alpha01")
assert(U.slots==1 and U.maxOffset==0 and U.offset==0 and U.frame:GetHeight()==308)
assert(not U.scrollUp:IsShown() and not U.scrollDown:IsShown())
U:Toggle(); U:Toggle(); assert(U:IsProgress() and scheduled==3)
U.search:SetText("no match"); assert(U.empty:IsShown() and U.slots==1)
U.search:SetText(""); U:SetView("played")
