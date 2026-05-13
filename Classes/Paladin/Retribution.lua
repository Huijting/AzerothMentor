--[[
  Azeroth Mentor - Retribution Paladin spec module
  Spec-specific guidance and tutorial during the Spec Training mentor stage.
  Register additional specs under AM.SpecModules using the same pattern.
]]

local AM = _G.AM
local L = AM.L

AM.SpecModules = AM.SpecModules or {}

--- @class PaladinRetributionModule
local module = {}

--- @param playerState table snapshot from AM:GetPlayerState (without guidance/tutorial yet)
--- @return string
function module.GetGuidance(playerState)
    return L["RET_GUIDANCE"]
end

--- @param playerState table
--- @return string
function module.GetTutorial(playerState)
    return L["RET_TUTORIAL"]
end

AM.SpecModules["PALADIN_RETRIBUTION"] = module
