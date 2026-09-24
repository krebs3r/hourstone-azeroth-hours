-- Addons menu entry, one-time minimap migration and WoW: Forever detection.
local C,L=H.C,H.L
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
local U,db=H.UI,HourstoneDB
local forever=TEST_INTERFACE==16001
assert(C.IsForever()==forever)
assert(C.RetailStyle()==(WOW_PROJECT_ID==1 and not forever) and C.RetailProgress()==C.RetailStyle())
if forever then
    -- Retail API, but Classic artwork and no keystone/Great Vault view.
    assert(C.Retail() and C.Flavor()=="retail" and not H.P.enabled)
    U:Toggle(); assert(U.panelName=="ClassicPanel" and U.tabs==nil and not U:IsProgress())
    assert(U.scaleSlider:GetThumbTexture().texture:find("SilverThumb",1,true))
    assert(U.minimap.border.width==53)
    U:SetView("progress"); assert(not U:IsProgress() and db.settings.view=="played")
    U:Toggle()
end

if not AddonCompartmentFrame then
    assert(U.compartment==nil and #COMPARTMENT==0)
    assert(db.settings.minimap and db.settings.compartmentMigrated==nil and U.minimap:IsShown())
    SlashCmdList.HOURSTONE("minimap")
    assert(not db.settings.minimap and not U.minimap:IsShown() and PRINTED[#PRINTED]==L.minimapHidden)
    SlashCmdList.HOURSTONE("minimap"); assert(db.settings.minimap and U.minimap:IsShown())
    return
end

-- Registered once, with the TOC logo and the shared tooltip helper.
assert(U.compartment==true and #COMPARTMENT==1)
local info=COMPARTMENT[1]
assert(info.text=="Hourstone" and info.icon=="Interface\\AddOns\\Hourstone\\Media\\Logo.tga")
assert(info.notCheckable==true and info.registerForAnyClick==true)
local button=CreateFrame("Button",nil,UIParent)
info.funcOnEnter(button)
assert(GameTooltip:IsShown() and GameTooltip.owner==button)
assert(GameTooltip.lines[1]=="Hourstone – Azeroth Hours" and GameTooltip.lines[2]==L.open and GameTooltip.lines[3]==L.commands)
info.funcOnLeave(button); assert(not GameTooltip:IsShown())
info.funcOnEnter(nil); assert(GameTooltip.owner==AddonCompartmentFrame); info.funcOnLeave()
assert(not GameTooltip:IsShown())

-- One-time migration: the Addons menu replaces the default minimap button.
assert(db.settings.compartmentMigrated==true and db.settings.minimap==false and not U.minimap:IsShown())

-- Left click opens and closes like the minimap button, in both argument forms.
-- The minimap button has no right-click action; neither does the menu entry.
assert(U.frame==nil or not U.frame:IsShown())
for _,input in ipairs({{buttonName="LeftButton"},"LeftButton"}) do
    info.func(button,input); assert(U.frame:IsShown())
    info.func(button,input); assert(not U.frame:IsShown())
end
info.func("Hourstone","LeftButton"); assert(U.frame:IsShown())
info.func(button,{buttonName="RightButton"}); assert(U.frame:IsShown())
info.func("Hourstone","RightButton"); assert(U.frame:IsShown())
info.func(button,{buttonName="MiddleButton"}); assert(not U.frame:IsShown())

-- The minimap option keeps working next to the Addons menu.
local before=#PRINTED
SlashCmdList.HOURSTONE("minimap"); assert(db.settings.minimap and U.minimap:IsShown() and #PRINTED==before)
U:ToggleSettings(); assert(U.minimapBox:GetChecked())
U.minimapBox:Click()
assert(not db.settings.minimap and not U.minimap:IsShown() and PRINTED[#PRINTED]==L.minimapHiddenCompartment)
U.minimapToggle.scripts.OnClick(); assert(db.settings.minimap and U.minimap:IsShown() and U.minimapBox:GetChecked())
assert(db.settings.compartmentMigrated==true)

-- A failing registration never breaks loading and never hides the button.
AddonCompartmentFrame.RegisterAddon=function() error("unavailable") end
local saved=db.settings.minimap
U.compartment=nil; U:CreateCompartment(); assert(U.compartment==nil and db.settings.minimap==saved)
