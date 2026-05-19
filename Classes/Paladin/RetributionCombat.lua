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

-- Beginner AoE: at least this many engaged enemies (target + extras) while player is in combat.
local HOSTILE_NAMEPLATE_AOE_MIN = 3
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

--- @return boolean
function AM.RetributionCombat:HasValidHostileTarget()
    if not SafeCall(UnitExists, "target") then
        return false
    end
    if SafeCall(UnitIsDead, "target") == true then
        return false
    end
    return SafeCall(UnitCanAttack, "player", "target") == true
end

--- Conservative: unit is part of the player's pull (targets player or has threat), not merely visible.
--- @param unit string
--- @return boolean engaged
--- @return string reason
local function IsUnitEngagedWithPlayer(unit)
    if not unit or type(unit) ~= "string" then
        return false, "invalid unit"
    end
    local unitTarget = unit .. "target"
    if SafeCall(UnitExists, unitTarget) and SafeCall(UnitIsUnit, unitTarget, "player") then
        return true, "targeting player"
    end
    if type(UnitThreatSituation) == "function" then
        local status = SafeCall(UnitThreatSituation, "player", unit)
        if type(status) == "number" and status > 0 then
            return true, "threat on player"
        end
    end
    if SafeCall(UnitAffectingCombat, unit) == true and SafeCall(UnitIsUnit, unit, "target") then
        return true, "current target in combat"
    end
    return false, "not engaged with player (conservative)"
end

--- Evaluate one unit for conservative AoE counting.
--- @param unit string
--- @param opts table|nil { isCurrentTarget, skipCount }
--- @return table row
function AM.RetributionCombat:EvaluateNameplateUnit(unit, opts)
    opts = opts or {}
    local row = {
        token = unit,
        isTarget = opts.isCurrentTarget and true or false,
        exists = false,
        canAttack = nil,
        isDead = nil,
        unitInCombat = nil,
        targetsPlayer = nil,
        threatOnPlayer = nil,
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
    local unitTarget = unit .. "target"
    row.targetsPlayer = SafeCall(UnitExists, unitTarget) and SafeCall(UnitIsUnit, unitTarget, "player") or false
    if type(UnitThreatSituation) == "function" then
        row.threatOnPlayer = SafeCall(UnitThreatSituation, "player", unit)
    end

    if opts.isCurrentTarget then
        row.counted = not opts.skipCount
        row.reason = opts.skipCount and "current target (counted separately)" or "counted (current target)"
        return row
    end

    if SafeCall(UnitIsUnit, unit, "target") then
        row.reason = "skipped (same as current target)"
        return row
    end

    local engaged, engageReason = IsUnitEngagedWithPlayer(unit)
    if engaged then
        row.counted = true
        row.reason = "counted (" .. engageReason .. ")"
    else
        row.reason = engageReason
    end
    return row
end

--- Conservative AoE count: valid hostile target + engaged extras (not distant visible nameplates).
--- @param playerInCombat boolean|nil
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
    local seenGuids = {}

    if not playerInCombat then
        return rows, 0, scanNote .. " | player not in combat"
    end

    if not self:HasValidHostileTarget() then
        return rows, 0, scanNote .. " | no valid hostile target"
    end

    local targetGuid = SafeCall(UnitGUID, "target")
    if targetGuid then
        seenGuids[targetGuid] = true
    end
    rows[#rows + 1] = self:EvaluateNameplateUnit("target", { isCurrentTarget = true })
    counted = 1

    for _, unit in ipairs(tokens) do
        local skipAsTargetDup = SafeCall(UnitIsUnit, unit, "target")
        local row = self:EvaluateNameplateUnit(unit, {
            isCurrentTarget = false,
            skipCount = skipAsTargetDup,
        })
        rows[#rows + 1] = row
        if row.counted then
            local guid = SafeCall(UnitGUID, unit)
            if guid and seenGuids[guid] then
                row.counted = false
                row.reason = "not counted (duplicate of already-counted unit)"
            elseif guid then
                seenGuids[guid] = true
                counted = counted + 1
            else
                counted = counted + 1
            end
        end
    end

    return rows, counted, scanNote
end

--- Engaged enemy count for beginner AoE (target + extras engaged with player).
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

    print("|cffaaaaff[Azeroth Mentor]|r Nameplate AoE debug (conservative):")
    print("  Player UnitAffectingCombat: " .. YesNo(playerInCombat))
    print("  Valid hostile target: " .. YesNo(self:HasValidHostileTarget()))
    print("  Scan: " .. tostring(scanNote))
    print(string.format(
        "  Units listed: %d  |  Final AoE count: %d  |  Divine Storm at >= %d",
        #rows,
        counted,
        HOSTILE_NAMEPLATE_AOE_MIN
    ))

    if #rows == 0 then
        print("  (no units to evaluate — need a hostile target and/or nameplates)")
        return
    end

    for _, row in ipairs(rows) do
        local threatStr = row.threatOnPlayer == nil and "?" or tostring(row.threatOnPlayer)
        print(string.format(
            "  %s | target=%s | exists=%s attack=%s dead=%s combat=%s tgtPlayer=%s threat=%s | counted=%s | %s",
            tostring(row.token),
            YesNo(row.isTarget),
            YesNo(row.exists),
            row.canAttack == nil and "?" or YesNo(row.canAttack),
            row.isDead == nil and "?" or YesNo(row.isDead),
            row.unitInCombat == nil and "?" or YesNo(row.unitInCombat),
            row.targetsPlayer == nil and "?" or YesNo(row.targetsPlayer),
            threatStr,
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
        "  AoE enemy count (conservative, target + engaged): %d (Divine Storm at >= %d)",
        s.nearbyHostileInCombatCount or 0,
        s.hostileNameplateAoEMin or HOSTILE_NAMEPLATE_AOE_MIN
    ))
    print("  Valid hostile target: " .. YesNo(self:HasValidHostileTarget()))
    print("  ShouldUseRetributionAoESpender: " .. YesNo(useAoE))
    print("  Single-target spender spellID: " .. tostring(stSpender or "nil"))
    print("  AoE spender spellID: " .. tostring(aoeSpender or "nil"))
    print("  Combat recommendation spellID: " .. tostring(rec and rec.suggestedSpellID or "nil"))
    print("  In combat: " .. YesNo(s.inCombat))
    print("  Tip: run /am nameplates while fighting for per-token details.")
end
