--[[
  Azeroth Mentor — universal level milestone mentor (class/spec gated, out-of-combat).
  Modular: add keys under AzerothMentor_LevelMilestones for future classes/specs.
]]

local AM = _G.AM
local L = AM.L

--- Milestone definitions: class/spec token → [levelGate] = { milestoneKey, spellID? }.
--- Copy uses L["MILESTONE_" .. milestoneKey .. "_TITLE"] etc. (see Locales).
_G.AzerothMentor_LevelMilestones = _G.AzerothMentor_LevelMilestones or {}

local SPEC_ID_RETRIBUTION = 70

local function NormalizeSpecSlot(raw)
    local n = tonumber(raw)
    if not n or n < 1 then
        return nil
    end
    return n
end

local function GetPlayerClassSpec()
    local _, classFile = UnitClass("player")
    classFile = classFile or ""
    local slot = NormalizeSpecSlot(GetSpecialization())
    local specId
    if slot then
        specId = select(1, GetSpecializationInfo(slot, false, false, nil))
    end
    return classFile, specId
end

local function MilestoneSpellKnown(spellID)
    if not spellID or spellID == 0 then
        return true
    end
    if type(AM.IsSpellKnownSafe) == "function" then
        local ok, known = pcall(AM.IsSpellKnownSafe, AM, spellID)
        if ok and known then
            return true
        end
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known then
            return true
        end
    end
    return false
end

-- Paladin + Retribution (levels 1–15 scope); extend for other classes later.
do
    local M = AzerothMentor_LevelMilestones
    M.PALADIN = M.PALADIN or {}
    M.PALADIN_RETRIBUTION = M.PALADIN_RETRIBUTION or {}

    M.PALADIN[1] = { milestoneKey = "PALADIN_L1", spellID = nil }
    M.PALADIN[2] = { milestoneKey = "PALADIN_L2", spellID = nil }
    M.PALADIN[3] = { milestoneKey = "PALADIN_L3", spellID = nil }
    M.PALADIN[5] = { milestoneKey = "PALADIN_L5", spellID = nil }
    M.PALADIN[10] = { milestoneKey = "PALADIN_L10", spellID = nil }

    M.PALADIN_RETRIBUTION[10] = { milestoneKey = "PALADIN_RET_L10", spellID = 20271 }
    M.PALADIN_RETRIBUTION[11] = { milestoneKey = "PALADIN_RET_L11", spellID = 35395 }
    M.PALADIN_RETRIBUTION[12] = { milestoneKey = "PALADIN_RET_L12", spellID = 184575 }
    M.PALADIN_RETRIBUTION[15] = { milestoneKey = "PALADIN_RET_L15", spellID = 85256 }
end

function AM:EnsureMilestoneDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    if type(AzerothMentorDB.seenMilestones) ~= "table" then
        AzerothMentorDB.seenMilestones = {}
    end
end

function AM:MarkLevelMilestoneSeen(key)
    if type(key) ~= "string" or key == "" then
        return
    end
    self:EnsureMilestoneDB()
    AzerothMentorDB.seenMilestones[key] = true
end

function AM:ResetSeenMilestones()
    self:EnsureMilestoneDB()
    wipe(AzerothMentorDB.seenMilestones)
end

local function MilestoneSeen(key)
    AM:EnsureMilestoneDB()
    return AzerothMentorDB.seenMilestones[key] and true or false
end

local function MilestoneLoc(prefix, milestoneKey, suffix)
    return L[prefix .. milestoneKey .. suffix]
end

--- @return table|nil milestone row { milestoneKey, spellID, levelGate, scope }
function AM:GetCurrentLevelMilestone()
    if UnitAffectingCombat("player") then
        return nil
    end
    self:EnsureMilestoneDB()
    local level = UnitLevel("player") or 0
    if level < 1 then
        return nil
    end
    local gate = math.min(level, 15)
    local classFile, specId = GetPlayerClassSpec()
    local M = AzerothMentor_LevelMilestones
    if not M then
        return nil
    end

    -- Spec milestones for this level only (e.g. PALADIN_RETRIBUTION); Retribution id is global for this table layout.
    local specScope = classFile .. "_RETRIBUTION"
    local specTable = (specId == SPEC_ID_RETRIBUTION) and M[specScope] or nil
    if specTable then
        local rawSpec = specTable[gate]
        if rawSpec and not MilestoneSeen(rawSpec.milestoneKey) and MilestoneSpellKnown(rawSpec.spellID) then
            return {
                milestoneKey = rawSpec.milestoneKey,
                spellID = rawSpec.spellID,
                levelGate = gate,
                scope = specScope,
            }
        end
    end

    local classTable = M[classFile]
    if classTable then
        local classDef = classTable[gate]
        if classDef and not MilestoneSeen(classDef.milestoneKey) and MilestoneSpellKnown(classDef.spellID) then
            return {
                milestoneKey = classDef.milestoneKey,
                spellID = classDef.spellID,
                levelGate = gate,
                scope = classFile,
            }
        end
    end

    return nil
end

--- Card payload for the mentor spell card (type LEVEL_MILESTONE).
--- @return table|nil
function AM:GetCurrentLevelMilestoneCard()
    local row = self:GetCurrentLevelMilestone()
    if not row then
        return nil
    end
    local mk = row.milestoneKey
    local prefix = "MILESTONE_"
    local title = MilestoneLoc(prefix, mk, "_TITLE")
    local subtitle = MilestoneLoc(prefix, mk, "_SUBTITLE")
    local body = MilestoneLoc(prefix, mk, "_BODY")
    local instruction = MilestoneLoc(prefix, mk, "_INSTRUCTION")
    local actionText = L["MILESTONE_ACTION_GOT_IT"]

    local spellID = row.spellID
    local name, icon
    if spellID and spellID > 0 then
        name, icon = self:GetSpellDisplayInfo(spellID)
    else
        name = title
        icon = 134400
    end

    local card = {
        type = "LEVEL_MILESTONE",
        milestoneKey = mk,
        title = title,
        subtitle = subtitle,
        body = body,
        instruction = instruction,
        spellID = spellID,
        icon = icon,
        name = name,
        actionText = actionText,
        onAccept = function()
            AM:MarkLevelMilestoneSeen(mk)
            if AM.UpdateMainFrame then
                AM:UpdateMainFrame({ skipDetect = true })
            end
        end,
    }
    if AM.DEBUG_MILESTONES then
        print("Azeroth Mentor milestone available: " .. tostring(mk))
    end
    return card
end

-- Aliases requested by design doc (same API as AM:*).
_G.AzerothMentor = _G.AzerothMentor or AM
