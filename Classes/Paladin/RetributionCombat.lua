--[[
  Azeroth Mentor - Retribution Paladin combat readiness (read-only snapshot).
  Used for diagnostics and future mentor logic; not for rotation recommendations or action bar scanning.
]]

local AM = _G.AM

AM.RetributionCombat = AM.RetributionCombat or {}

-- Retail spell IDs (same as Core/Spells.lua registry).
local SPELL_CRUSADER_STRIKE = 35395
local SPELL_JUDGMENT = 20271
local SPELL_TEMPLARS_VERDICT = 85256

local function GetHolyPowerPowerType()
    if Enum and Enum.PowerType and Enum.PowerType.HolyPower ~= nil then
        return Enum.PowerType.HolyPower
    end
    -- Legacy HOLY_POWER index (still valid on some API paths).
    return 9
end

local function YesNo(v)
    return v and "yes" or "no"
end

--- Snapshot of a few combat-readiness facts for Retribution Paladins (safe on any class).
--- @return table
function AM.RetributionCombat:GetState()
    local powerType = GetHolyPowerPowerType()
    local current = UnitPower("player", powerType) or 0
    local max = UnitPowerMax("player", powerType) or 0

    return {
        holyPowerCurrent = current,
        holyPowerMax = max,
        crusaderStrikeKnown = AM:IsSpellKnownSafe(SPELL_CRUSADER_STRIKE),
        judgmentKnown = AM:IsSpellKnownSafe(SPELL_JUDGMENT),
        templarsVerdictKnown = AM:IsSpellKnownSafe(SPELL_TEMPLARS_VERDICT),
        inCombat = UnitAffectingCombat("player") and true or false,
    }
end

function AM.RetributionCombat:PrintStateToChat()
    local s = self:GetState()
    print("|cffaaaaff[Azeroth Mentor]|r Retribution combat state:")
    print(string.format("  Holy Power: %d / %d", s.holyPowerCurrent, s.holyPowerMax))
    print("  Crusader Strike known: " .. YesNo(s.crusaderStrikeKnown))
    print("  Judgment known: " .. YesNo(s.judgmentKnown))
    print("  Templar's Verdict known: " .. YesNo(s.templarsVerdictKnown))
    print("  In combat: " .. YesNo(s.inCombat))
end
