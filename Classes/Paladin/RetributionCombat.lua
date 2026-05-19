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
local SPELL_FINAL_VERDICT = 383328

-- Beginner AoE: at least this many hostile visible nameplates while player is in combat.
local HOSTILE_NAMEPLATE_AOE_MIN = 2
local MAX_NAMEPLATE_SCAN = 40

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

--- @param fn function|nil
--- @return any|nil
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, val = pcall(fn, ...)
    if ok then
        return val
    end
    return nil
end

--- Collect unique nameplate unit tokens from C_NamePlate and nameplateN indices.
--- @return string[] tokens
--- @return string scanNote
local function CollectNameplateTokens()
    local tokens = {}
    local seen = {}
    local notes = {}

    local function addToken(unit, source)
        if not unit or type(unit) ~= "string" or seen[unit] then
            return
        end
        seen[unit] = source or true
        tokens[#tokens + 1] = unit
    end

    if C_NamePlate and type(C_NamePlate.GetNamePlates) == "function" then
        local ok, plates = pcall(C_NamePlate.GetNamePlates)
        if ok and type(plates) == "table" then
            notes[#notes + 1] = string.format("C_NamePlate.GetNamePlates: %d frame(s)", #plates)
            for _, plate in ipairs(plates) do
                if plate then
                    addToken(plate.namePlateUnitToken, "C_NamePlate.namePlateUnitToken")
                    local unitFrame = plate.UnitFrame or plate.unitFrame
                    if unitFrame then
                        addToken(unitFrame.unit, "C_NamePlate.UnitFrame.unit")
                        addToken(unitFrame.namePlateUnitToken, "C_NamePlate.UnitFrame.namePlateUnitToken")
                    end
                end
            end
        else
            notes[#notes + 1] = "C_NamePlate.GetNamePlates: failed or empty"
        end
    else
        notes[#notes + 1] = "C_NamePlate.GetNamePlates: unavailable"
    end

    local indexHits = 0
    for i = 1, MAX_NAMEPLATE_SCAN do
        local unit = "nameplate" .. i
        if SafeCall(UnitExists, unit) then
            indexHits = indexHits + 1
            addToken(unit, "nameplate index")
        end
    end
    notes[#notes + 1] = string.format("nameplate1..%d exists: %d", MAX_NAMEPLATE_SCAN, indexHits)

    return tokens, table.concat(notes, "; ")
end

--- Evaluate one nameplate token for AoE counting (v1: no per-unit UnitAffectingCombat requirement).
--- @param unit string
--- @param playerInCombat boolean
--- @return table row { token, exists, canAttack, isDead, unitInCombat, counted, reason }
function AM.RetributionCombat:EvaluateNameplateUnit(unit, playerInCombat)
    local row = {
        token = unit,
        exists = false,
        canAttack = nil,
        isDead = nil,
        unitInCombat = nil,
        counted = false,
        reason = "unknown",
    }

    if not unit or type(unit) ~= "string" then
        row.reason = "invalid token"
        return row
    end

    row.exists = SafeCall(UnitExists, unit) and true or false
    if not row.exists then
        row.reason = "UnitExists=false"
        return row
    end

    row.isDead = SafeCall(UnitIsDead, unit)
    if row.isDead == true then
        row.reason = "UnitIsDead=true"
        return row
    end

    row.canAttack = SafeCall(UnitCanAttack, "player", unit)
    if row.canAttack ~= true then
        row.reason = "UnitCanAttack=false"
        return row
    end

    row.unitInCombat = SafeCall(UnitAffectingCombat, unit)

    if not playerInCombat then
        row.reason = "player not in combat"
        return row
    end

    row.counted = true
    row.reason = "counted (hostile visible nameplate)"
    return row
end

--- @param playerInCombat boolean|nil default: current player combat state
--- @return table[] rows
--- @return number counted
--- @return string scanNote
function AM.RetributionCombat:GetHostileNameplateEvaluation(playerInCombat)
    if playerInCombat == nil then
        playerInCombat = UnitAffectingCombat("player") and true or false
    end
    local tokens, scanNote = CollectNameplateTokens()
    local rows = {}
    local counted = 0
    for _, unit in ipairs(tokens) do
        local row = self:EvaluateNameplateUnit(unit, playerInCombat)
        rows[#rows + 1] = row
        if row.counted then
            counted = counted + 1
        end
    end
    return rows, counted, scanNote
end

--- Count hostile visible nameplates while the player is in combat (beginner AoE signal).
--- @return number
function AM.RetributionCombat:CountHostileNameplatesInCombat()
    if not UnitAffectingCombat("player") then
        return 0
    end
    local _, counted = self:GetHostileNameplateEvaluation(true)
    return counted
end

function AM.RetributionCombat:PrintNameplateDebug()
    local playerInCombat = UnitAffectingCombat("player") and true or false
    local rows, counted, scanNote = self:GetHostileNameplateEvaluation(playerInCombat)

    print("|cffaaaaff[Azeroth Mentor]|r Nameplate AoE debug:")
    print("  Player UnitAffectingCombat: " .. YesNo(playerInCombat))
    print("  Scan: " .. tostring(scanNote))
    print(string.format("  Tokens scanned: %d  |  Counted (hostile visible): %d  |  AoE threshold: >= %d", #rows, counted, HOSTILE_NAMEPLATE_AOE_MIN))

    if #rows == 0 then
        print("  (no nameplate tokens found — enable enemy nameplates and fight near mobs)")
        return
    end

    for _, row in ipairs(rows) do
        print(string.format(
            "  %s | exists=%s attack=%s dead=%s unitCombat=%s | counted=%s | %s",
            tostring(row.token),
            YesNo(row.exists),
            row.canAttack == nil and "?" or YesNo(row.canAttack),
            row.isDead == nil and "?" or YesNo(row.isDead),
            row.unitInCombat == nil and "?" or YesNo(row.unitInCombat),
            YesNo(row.counted),
            tostring(row.reason)
        ))
    end
end

--- Snapshot of a few combat-readiness facts for Retribution Paladins (safe on any class).
--- @return table
function AM.RetributionCombat:GetState()
    local powerType = GetHolyPowerPowerType()
    local current = UnitPower("player", powerType) or 0
    local max = UnitPowerMax("player", powerType) or 0
    local inCombat = UnitAffectingCombat("player") and true or false
    local nearbyHostileInCombatCount = 0
    if inCombat then
        nearbyHostileInCombatCount = self:CountHostileNameplatesInCombat()
    end

    return {
        holyPowerCurrent = current,
        holyPowerMax = max,
        crusaderStrikeKnown = AM:IsSpellKnownSafe(SPELL_CRUSADER_STRIKE),
        judgmentKnown = AM:IsSpellKnownSafe(SPELL_JUDGMENT),
        templarsVerdictKnown = AM:IsSpellKnownSafe(SPELL_TEMPLARS_VERDICT),
        finalVerdictKnown = AM:IsSpellKnownSafe(SPELL_FINAL_VERDICT),
        inCombat = inCombat,
        nearbyHostileInCombatCount = nearbyHostileInCombatCount,
        hostileNameplateAoEMin = HOSTILE_NAMEPLATE_AOE_MIN,
    }
end

function AM.RetributionCombat:PrintStateToChat()
    local s = self:GetState()
    local sm = AM.SpecModules and AM.SpecModules.PALADIN and AM.SpecModules.PALADIN.RETRIBUTION
    local stSpender = sm and sm.GetRetributionSingleTargetSpenderSpellID and sm.GetRetributionSingleTargetSpenderSpellID()
    local aoeSpender = sm and sm.GetRetributionAoESpenderSpellID and sm.GetRetributionAoESpenderSpellID(s)
    local useAoE = sm and sm.ShouldUseRetributionAoESpender and sm.ShouldUseRetributionAoESpender(s)
    local rec = sm and sm.GetCombatRecommendation and sm.GetCombatRecommendation({ combat = s })
    print("|cffaaaaff[Azeroth Mentor]|r Retribution combat state:")
    print(string.format("  Holy Power: %d / %d", s.holyPowerCurrent, s.holyPowerMax))
    print("  Crusader Strike known: " .. YesNo(s.crusaderStrikeKnown))
    print("  Judgment known: " .. YesNo(s.judgmentKnown))
    print("  Templar's Verdict known: " .. YesNo(s.templarsVerdictKnown))
    print("  Final Verdict known: " .. YesNo(s.finalVerdictKnown))
    print(string.format(
        "  Hostile visible nameplates (player in combat): %d (AoE hint at >= %d)",
        s.nearbyHostileInCombatCount or 0,
        s.hostileNameplateAoEMin or HOSTILE_NAMEPLATE_AOE_MIN
    ))
    print("  ShouldUseRetributionAoESpender: " .. YesNo(useAoE))
    print("  Single-target spender spellID: " .. tostring(stSpender or "nil"))
    print("  AoE spender spellID: " .. tostring(aoeSpender or "nil"))
    print("  Combat recommendation spellID: " .. tostring(rec and rec.suggestedSpellID or "nil"))
    print("  In combat: " .. YesNo(s.inCombat))
    print("  Tip: run /am nameplates while fighting for per-token details.")
end
