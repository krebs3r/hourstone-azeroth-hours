local name, H = ...
local frame = H.C.Frame("Frame")
H.events = frame
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent",function(_,event,...)
    if event == "ADDON_LOADED" then
        if ... ~= name then return end
        local db, reason = H.M.Init(HourstoneDB)
        if not db then print(reason == "future" and H.L.futureDB or H.L.invalidDB); frame:UnregisterAllEvents(); return end
        HourstoneDB = db
        H.S.Import(db, HourstoneSync)
        H.T:Init(db); H.UI:Init(db)
        frame:UnregisterEvent("ADDON_LOADED")
        for _, e in ipairs({"PLAYER_ENTERING_WORLD","TIME_PLAYED_MSG","PLAYER_LEVEL_UP","PLAYER_LOGOUT","PLAYER_UPDATE_RESTING","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do frame:RegisterEvent(e) end
        SLASH_HOURSTONE1, SLASH_HOURSTONE2 = "/hourstone", "/azerothhours"
        SlashCmdList.HOURSTONE = function(message)
            message = H.C.Lower((message or ""):match("^%s*(.-)%s*$"))
            if message == "minimap" then db.settings.minimap = not db.settings.minimap; H.UI:UpdateMinimap()
            elseif message == "reset" then H.UI:Create(); H.UI:Position(true)
            else H.UI:Toggle() end
        end
        local elapsed = 0
        frame:SetScript("OnUpdate",function(_,delta)
            elapsed = elapsed + delta
            if elapsed < 1 then return end
            elapsed = 0
            H.T:TryRequest()
            if H.UI.frame and H.UI.frame:IsShown() then H.UI:Refresh() end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local initialLogin, reload = ...
        H.T:Begin(reload == true, initialLogin == true); H.T:UpdateIdentity(); H.T:UpdateGuild(false)
    elseif event == "TIME_PLAYED_MSG" then H.T:Receive(...)
    elseif event == "PLAYER_LEVEL_UP" then H.T:UpdateIdentity(...)
    elseif event == "PLAYER_UPDATE_RESTING" then H.T:UpdateIdentity()
    elseif event == "PLAYER_GUILD_UPDATE" then
        if ... == "player" then H.T:UpdateGuild(true) end
    elseif event == "GUILD_ROSTER_UPDATE" then H.T:UpdateGuild(false)
    elseif event == "PLAYER_LOGOUT" then H.T:Save()
    elseif H.UI.frame then H.UI:ApplyScale(); H.UI:UpdateMinimap() end
end)
