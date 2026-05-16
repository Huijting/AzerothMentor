--[[
  Azeroth Mentor - event wiring
  Listens for lifecycle and player changes, then refreshes the main panel.
  UNIT_POWER_FREQUENT keeps the Retribution Holy Power + combat hint in sync while the mentor frame is open.
  PLAYER_ENTER_COMBAT / PLAYER_LEAVE_COMBAT refresh when combat state flips.
]]

local AM = _G.AM

local eventFrame = CreateFrame("Frame", nil, UIParent)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("SPELLS_CHANGED")

eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
eventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
eventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")

eventFrame:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 ~= AM.name then
            return
        end
        if type(AM.EnsureMilestoneDB) == "function" then
            AM:EnsureMilestoneDB()
        end
        if type(AM.EnsureLessonLogDB) == "function" then
            AM:EnsureLessonLogDB()
        end
        if type(AM.SyncLessonToastAckFromDB) == "function" then
            AM:SyncLessonToastAckFromDB()
        elseif type(AM.EnsureLessonToastAckDB) == "function" then
            AM:EnsureLessonToastAckDB()
        end
    elseif event == "UNIT_POWER_FREQUENT" then
        if arg1 == "player" and AzerothMentorFrame and AzerothMentorFrame:IsShown() then
            AM:UpdateMainFrame({ skipDetect = true })
        end
        return
    elseif event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" then
        if AzerothMentorFrame and AzerothMentorFrame:IsShown() then
            AM:UpdateMainFrame({ skipDetect = true })
        end
        return
    elseif event == "SPELLS_CHANGED" then
        -- Spellbook updates after level-ups usually land here; diff before refreshing the UI.
        local _, classFile = UnitClass("player")
        if classFile == "PALADIN" then
            AM:DetectNewSpells()
        end
        AM:UpdateMainFrame({ skipDetect = true })
        return
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = arg1
        if type(newLevel) == "number" then
            AM:SetLevelUpMessage(newLevel)
        end
        -- Do not run DetectNewSpells here: the client often has not granted new spells yet.
        AM:UpdateMainFrame({ skipDetect = true })
        return
    end

    if type(AM.SyncLessonToastAckFromDB) == "function" then
        AM:SyncLessonToastAckFromDB()
    end
    AM:UpdateMainFrame()
end)
