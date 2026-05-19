--[[
  Azeroth Mentor - Talent Help v1 (beginner guidance only).
  Detects unspent talent points via C_ClassTalents when available; no build recommendations.
]]

local AM = _G.AM
local L = AM.L

--- @class TalentPointInfo
--- @field available boolean whether the player has unspent talent points to spend
--- @field total number combined unspent class + spec points (0 when unknown)
--- @field classPoints number
--- @field specPoints number
--- @field hasUnspent boolean raw API flag when readable
--- @field apiPath string|nil
--- @field unavailable boolean true when detection could not run safely

--- Safe read of retail talent point availability (no Icy Veins / node parsing).
--- @return TalentPointInfo
function AM:GetUnspentTalentPointInfo()
    local unavailable = {
        available = false,
        total = 0,
        classPoints = 0,
        specPoints = 0,
        hasUnspent = false,
        apiPath = nil,
        unavailable = true,
    }

    if not (C_ClassTalents and type(C_ClassTalents.HasUnspentTalentPoints) == "function") then
        return unavailable
    end

    local ok, hasUnspent, classPts, specPts = pcall(C_ClassTalents.HasUnspentTalentPoints)
    if not ok then
        return unavailable
    end

    local classPoints = tonumber(classPts) or 0
    local specPoints = tonumber(specPts) or 0
    local total = classPoints + specPoints
    local flag = hasUnspent == true
    local available = flag or total > 0

    return {
        available = available,
        total = total,
        classPoints = classPoints,
        specPoints = specPoints,
        hasUnspent = flag,
        apiPath = "C_ClassTalents.HasUnspentTalentPoints",
        unavailable = false,
    }
end

--- @return boolean
function AM:HasUnspentTalentPoints()
    local info = self:GetUnspentTalentPointInfo()
    return info.available and true or false
end

--- Spell-card payload when no higher-priority lesson is active (see GetSpellCardDisplayInfo).
--- @return table|nil
function AM:GetTalentHelpCard()
    if not self:HasUnspentTalentPoints() then
        return nil
    end
    return {
        type = "TALENT_HELP",
        title = L["TALENT_HELP_TITLE"],
        body = L["TALENT_HELP_BODY"],
        instruction = L["TALENT_HELP_INSTRUCTION"],
        icon = 134400,
    }
end

function AM:PrintTalentHelpStatus()
    local info = self:GetUnspentTalentPointInfo()
    print("|cffaaaaff[Azeroth Mentor]|r Talent Help v1:")
    if info.unavailable then
        print("  Detection: unavailable (C_ClassTalents.HasUnspentTalentPoints missing or errored)")
        print("  Talent Help UI: hidden until API is readable")
        return
    end
    print("  API: " .. tostring(info.apiPath))
    print(string.format(
        "  hasUnspent=%s  class=%d  spec=%d  total=%d",
        tostring(info.hasUnspent),
        info.classPoints,
        info.specPoints,
        info.total
    ))
    print("  HasUnspentTalentPoints: " .. tostring(self:HasUnspentTalentPoints()))
    local card = self:GetTalentHelpCard()
    print("  Talent Help spell card: " .. (card and "yes" or "no (higher-priority card may still show)"))
    print("  Inline reminder: " .. (self:HasUnspentTalentPoints() and "yes when main frame refreshes" or "no"))
end
