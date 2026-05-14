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
local function ComputeMentorStage(level, specIndex)
    if level < 10 then
        return STAGE_CLASS_BASICS
    end
    if not specIndex then
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

    -- Normalize: no active spec slot (nil/false) or invalid index (0) = no specialization.
    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then
        specIndex = nil
    end

    local specLine
    local specId

    if not specIndex then
        specLine = L["SPEC_NOT_SELECTED"]
        specId = nil
    else
        specId, specLine = GetSpecializationInfo(specIndex, false, false, nil)
        -- Empty string is truthy in Lua; low-level / loading states can return "" — show localized placeholder.
        local trimmed = specLine and strtrim(specLine) or ""
        if trimmed == "" then
            specLine = L["SPEC_NOT_SELECTED"]
        else
            specLine = trimmed
        end
    end

    local stageKey = ComputeMentorStage(level, specIndex)
    local stageTitle = GetStageTitle(stageKey)

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
    }

    local guidance = ResolveGuidance(baseState)
    local tutorial = ResolveTutorial(baseState)

    baseState.guidance = guidance
    baseState.tutorial = tutorial

    return baseState
end
