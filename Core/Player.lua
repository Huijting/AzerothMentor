--[[
  Azeroth Mentor - player snapshot and mentor content
  Unit queries, mentor stage, guidance, and tutorial message selection.
  Spec Training overrides are delegated to AM.SpecModules when a key matches.
  Visible copy comes from AM.L (see Locales/*.lua).
]]

local AM = _G.AM
local L = AM.L

--------------------------------------------------------------------------------
-- Mentor stage keys (stable identifiers for logic and tables)
--------------------------------------------------------------------------------
local STAGE_CLASS_BASICS = "CLASS_BASICS"
local STAGE_CHOOSE_PATH = "CHOOSE_PATH"
local STAGE_SPEC_TRAINING = "SPEC_TRAINING"

-- Retribution Paladin specialization ID (GetSpecializationInfo first return).
local SPEC_ID_RETRIBUTION_PALADIN = 70

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

--- Coerce GetSpecialization() to a positive integer slot, or nil if none.
--- Blizzard may return 0 (or nil) before a specialization is selected. In Lua, 0 is truthy,
--- so callers must not rely on `if not GetSpecialization()` alone to mean "no spec".
--- @param raw number|string|nil|false
--- @return number|nil specIndex 1-based slot, or nil
local function NormalizeSpecializationSlot(raw)
    local n = tonumber(raw)
    if not n or n < 1 or n ~= math.floor(n) then
        return nil
    end
    return n
end

--- True when the player has both a valid spec slot and a non-empty display name from the API.
--- @param specIndex number|nil normalized slot (>= 1) or nil
--- @param trimmedDisplayName string
--- @return boolean
local function HasSelectedSpecialization(specIndex, trimmedDisplayName)
    if not specIndex or specIndex < 1 then
        return false
    end
    if not trimmedDisplayName or trimmedDisplayName == "" then
        return false
    end
    return true
end

--- specIndex is nil until HasSelectedSpecialization is true (see GetPlayerState).
local function ComputeMentorStage(level, specIndex)
    -- Level 10 is the retail specialization unlock: mentor stage moves to CHOOSE_PATH until a spec is picked.
    -- That choice switches guidance/tutorial and (with spec modules) later combat mentoring tone.
    if level < 10 then
        return STAGE_CLASS_BASICS
    end
    -- specIndex should already be nil or >= 1 from GetPlayerState; reject < 1 defensively (0 is truthy in Lua).
    if not specIndex or specIndex < 1 then
        return STAGE_CHOOSE_PATH
    end
    return STAGE_SPEC_TRAINING
end

--- Localized mentor stage title for display.
--- @param stageKey string
--- @return string
local function GetStageTitle(stageKey)
    if stageKey == STAGE_CLASS_BASICS then
        return L["CLASS_BASICS"]
    end
    if stageKey == STAGE_CHOOSE_PATH then
        return L["CHOOSE_YOUR_PATH"]
    end
    if stageKey == STAGE_SPEC_TRAINING then
        return L["SPEC_TRAINING"]
    end
    return UNKNOWN
end

--- Spec Training title override (e.g. Retribution Training). Falls back to GetStageTitle when no match.
--- @param stageKey string
--- @param classFile string
--- @param specId number|nil
--- @return string
local function GetSpecTrainingStageTitle(stageKey, classFile, specId)
    if stageKey ~= STAGE_SPEC_TRAINING then
        return GetStageTitle(stageKey)
    end
    -- First spec-specific title: Retribution. Other specs keep SPEC_TRAINING until a module adds its own label.
    if classFile == "PALADIN" and specId == SPEC_ID_RETRIBUTION_PALADIN then
        return L["RET_STAGE_TITLE"]
    end
    return L["SPEC_TRAINING"]
end

--- Default guidance for a mentor stage (no spec module).
--- @param stageKey string
--- @return string
local function GetDefaultGuidance(stageKey)
    if stageKey == STAGE_CLASS_BASICS then
        return L["GUIDANCE_CLASS_BASICS"]
    end
    if stageKey == STAGE_CHOOSE_PATH then
        return L["GUIDANCE_CHOOSE_PATH"]
    end
    if stageKey == STAGE_SPEC_TRAINING then
        return L["GUIDANCE_SPEC_TRAINING"]
    end
    return UNKNOWN
end

--- Default tutorial for a mentor stage (no spec module).
--- @param stageKey string
--- @return string
local function GetDefaultTutorial(stageKey)
    if stageKey == STAGE_CLASS_BASICS then
        return L["TUTORIAL_CLASS_BASICS"]
    end
    if stageKey == STAGE_CHOOSE_PATH then
        return L["TUTORIAL_CHOOSE_PATH"]
    end
    if stageKey == STAGE_SPEC_TRAINING then
        return L["TUTORIAL_SPEC_TRAINING"]
    end
    return UNKNOWN
end

--- Maps class token + spec id to a registry key under AM.SpecModules (locale-safe).
--- @return string|nil moduleKey
local function GetSpecModuleKey(classFile, specId)
    if classFile == "PALADIN" and specId == SPEC_ID_RETRIBUTION_PALADIN then
        return "PALADIN_RETRIBUTION"
    end
    return nil
end

--- During Spec Training, use a registered spec module when present.
--- @param state table partial player snapshot (no guidance/tutorial fields yet)
--- @return string
local function ResolveGuidance(state)
    local stageKey = state.stageKey
    if stageKey == STAGE_SPEC_TRAINING then
        local moduleKey = GetSpecModuleKey(state.classFile, state.specId)
        if moduleKey and AM.SpecModules then
            local mod = AM.SpecModules[moduleKey]
            if mod and mod.GetGuidance then
                return mod.GetGuidance(state)
            end
        end
    end
    return GetDefaultGuidance(stageKey)
end

--- Same resolution rules as guidance; falls back to stage-based defaults.
--- @param state table partial player snapshot
--- @return string
local function ResolveTutorial(state)
    local stageKey = state.stageKey
    if stageKey == STAGE_SPEC_TRAINING then
        local moduleKey = GetSpecModuleKey(state.classFile, state.specId)
        if moduleKey and AM.SpecModules then
            local mod = AM.SpecModules[moduleKey]
            if mod and mod.GetTutorial then
                return mod.GetTutorial(state)
            end
        end
    end
    return GetDefaultTutorial(stageKey)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
--- Builds a read-only snapshot of the local player and derived mentor strings.
--- @return table state
function AM:GetPlayerState()
    local charName = UnitName("player") or UNKNOWN
    local level = UnitLevel("player") or 0
    local className, classFile = UnitClass("player")
    className = className or UNKNOWN
    classFile = classFile or ""

    -- Specialization: normalize slot (nil / 0 / string "0" / invalid) and require a real display name.
    -- Blizzard may return 0 before a specialization is selected; 0 is truthy in Lua, so never branch on `if not GetSpecialization()` alone.
    -- The client can also report a positive slot index while the localized name is still empty (not committed / loading).
    local rawSlot = GetSpecialization()
    local specSlot = NormalizeSpecializationSlot(rawSlot)

    local specIndex
    local specLine
    local specId

    if not specSlot then
        specIndex = nil
        specLine = L["SPEC_NOT_SELECTED"]
        specId = nil
    else
        specId, specLine = GetSpecializationInfo(specSlot, false, false, nil)
        local trimmed = specLine and strtrim(specLine) or ""
        if HasSelectedSpecialization(specSlot, trimmed) then
            specIndex = specSlot
            specLine = trimmed
        else
            specIndex = nil
            specLine = L["SPEC_NOT_SELECTED"]
            specId = nil
        end
    end

    local stageKey = ComputeMentorStage(level, specIndex)
    local stageTitle = GetSpecTrainingStageTitle(stageKey, classFile, specId)

    -- Paladin at level 10+ without a specialization: UI shows the "Choose Your Path" onboarding card (MainFrame).
    local specOnboardingActive = (classFile == "PALADIN" and level >= 10 and not specIndex)

    -- Snapshot passed into spec modules (guidance/tutorial filled next).
    local baseState = {
        charName = charName,
        className = className,
        classFile = classFile,
        level = level,
        specIndex = specIndex,
        specLine = specLine,
        specId = specId,
        stageKey = stageKey,
        stageTitle = stageTitle,
        specOnboardingActive = specOnboardingActive,
    }

    local guidance = ResolveGuidance(baseState)
    local tutorial = ResolveTutorial(baseState)

    baseState.guidance = guidance
    baseState.tutorial = tutorial

    return baseState
end

--- True when the player has a valid specialization slot and a non-empty display name from the API.
--- Uses the same rules as GetPlayerState (slot normalized; empty name means not committed yet).
--- @return boolean
function AM.HasSelectedSpecialization()
    local slot = NormalizeSpecializationSlot(GetSpecialization())
    if not slot then
        return false
    end
    local _, name = GetSpecializationInfo(slot, false, false, nil)
    local trimmed = name and strtrim(name) or ""
    return HasSelectedSpecialization(slot, trimmed)
end
