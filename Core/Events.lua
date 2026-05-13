--[[
  Azeroth Mentor - event wiring
  Listens for lifecycle and player changes, then refreshes the main panel.
]]

local AM = _G.AM

local eventFrame = CreateFrame("Frame", nil, UIParent)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("SPELLS_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 ~= AM.name then
            return
        end
    elseif event == "SPELLS_CHANGED" then
        local _, classFile = UnitClass("player")
        if classFile ~= "PALADIN" then
            return
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = arg1
        if type(newLevel) == "number" then
            AM:SetLevelUpMessage(newLevel)
        end
    end

    AM:UpdateMainFrame()
end)
