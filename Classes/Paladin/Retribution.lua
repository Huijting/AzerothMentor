--[[
  Azeroth Mentor - Retribution Paladin spec module
  Spec-specific guidance and tutorial during the Spec Training mentor stage.

  Retribution is the first dedicated specialization mentoring layer (stage title, guidance, and
  Ret-only spell copy in Core/Spells.lua). Future specs—Protection, Holy, and other classes—should
  register under AM.SpecModules with the same pattern and optional spell-row gates (specIdRequired).
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
