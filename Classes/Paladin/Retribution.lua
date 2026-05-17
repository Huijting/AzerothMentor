--[[
  Azeroth Mentor - Retribution Paladin spec module
  Spec-specific guidance and tutorial during the Spec Training mentor stage.

  Retribution is the first dedicated specialization mentoring layer (stage title, guidance, and
  Ret-only spell copy in Core/Spells.lua). Future specs—Protection, Holy, and other classes—should
  register under AM.SpecModules with the same pattern and optional spell-row gates (specIdRequired).

  GetCombatRecommendation is beginner-facing only: Holy Power + in/out of combat. No cooldown math,
  no action bar scanning, no rotation sequencing.
]]

local AM = _G.AM
local L = AM.L

AM.SpecModules = AM.SpecModules or {}

--- Mentor combat hint phases (stable strings for UI / debugging).
local PHASE_OUT_OF_COMBAT = "OUT_OF_COMBAT"
local PHASE_BUILD = "BUILD"
local PHASE_SPEND = "SPEND"

-- Spell IDs aligned with Core/Spells.lua + RetributionCombat.lua (retail).
local SPELL_BLADE_OF_JUSTICE = 184575
local SPELL_CRUSADER_STRIKE = 35395
local SPELL_JUDGMENT = 20271
local SPELL_TEMPLARS_VERDICT = 85256
local SPELL_FINAL_VERDICT = 383328

local BUILD_SPELL_ORDER = {
    SPELL_BLADE_OF_JUSTICE,
    SPELL_JUDGMENT,
    SPELL_CRUSADER_STRIKE,
}

--- @class PaladinRetributionModule
local module = {}

--- Active single-target Holy Power spender for beginner combat guidance (not rotation math).
--- Retail: Final Verdict (talent) replaces Templar's Verdict on the action bar when talented.
--- @return number|nil spellID
function module.GetRetributionSingleTargetSpenderSpellID()
    if AM:IsSpellKnownSafe(SPELL_FINAL_VERDICT) then
        return SPELL_FINAL_VERDICT
    end
    if AM:IsSpellKnownSafe(SPELL_TEMPLARS_VERDICT) then
        return SPELL_TEMPLARS_VERDICT
    end
    return nil
end

--- First known builder in priority order (no cooldown filtering).
--- @return number|nil spellID
local function PickKnownBuilderSpellID()
    for _, sid in ipairs(BUILD_SPELL_ORDER) do
        if AM:IsSpellKnownSafe(sid) then
            return sid
        end
    end
    return nil
end

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

--- Spell ID order for the BUILD mentor spell card (must match GetCombatRecommendation builder priority).
--- @return number[]
function module.GetBuildMentorSpellOrder()
    return BUILD_SPELL_ORDER
end

--- @param state table|nil optional `{ combat = table }` from AM.RetributionCombat:GetState(); if omitted, reads live state.
--- @return table { phase = string, displayLineKey = string, suggestedSpellID = number|nil }
function module.GetCombatRecommendation(state)
    state = state or {}
    local combat = state.combat
    if not combat and AM.RetributionCombat and AM.RetributionCombat.GetState then
        combat = AM.RetributionCombat:GetState()
    end
    combat = combat or {}

    local hp = tonumber(combat.holyPowerCurrent) or 0
    local inCombat = combat.inCombat and true or false

    if not inCombat then
        return {
            phase = PHASE_OUT_OF_COMBAT,
            displayLineKey = "RET_COMBAT_LINE_OOC",
            suggestedSpellID = nil,
        }
    end

    if hp < 3 then
        return {
            phase = PHASE_BUILD,
            displayLineKey = "RET_COMBAT_LINE_BUILD",
            suggestedSpellID = PickKnownBuilderSpellID(),
        }
    end

    return {
        phase = PHASE_SPEND,
        displayLineKey = "RET_COMBAT_LINE_SPEND",
        suggestedSpellID = module.GetRetributionSingleTargetSpenderSpellID(),
    }
end

AM.SpecModules["PALADIN_RETRIBUTION"] = module

-- Nested alias for callers that prefer AM.SpecModules.PALADIN.RETRIBUTION (same table as PALADIN_RETRIBUTION).
AM.SpecModules.PALADIN = AM.SpecModules.PALADIN or {}
AM.SpecModules.PALADIN.RETRIBUTION = module
