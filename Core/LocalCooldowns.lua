--[[
  Azeroth Mentor - generic local cooldown tracker (memory-only).
  Records player casts via UNIT_SPELLCAST_SUCCEEDED and tracks fallback durations.
  Does not read C_Spell.GetSpellCooldown during combat for recommendations.
]]

local AM = _G.AM

AM.localCooldowns = AM.localCooldowns or {}
AM.localCooldownDurations = AM.localCooldownDurations or {}
AM.localCooldownTrackedSpells = AM.localCooldownTrackedSpells or {}

--- @param spellID number
--- @param options table|nil `{ duration = number }` or `{ fallbackDuration = number }`
function AM:RegisterLocalCooldownSpell(spellID, options)
    spellID = tonumber(spellID)
    if not spellID then
        return
    end
    options = options or {}
    local duration = tonumber(options.duration) or tonumber(options.fallbackDuration)
    if not duration or duration <= 0 then
        return
    end
    AM.localCooldownDurations[spellID] = duration
    AM.localCooldownTrackedSpells[spellID] = true
end

--- @param spellID number
local function ClearExpiredLocalCooldownEntry(spellID)
    local entry = AM.localCooldowns[spellID]
    if not entry then
        return
    end
    local now = GetTime()
    if now >= (entry.endTime or 0) then
        AM.localCooldowns[spellID] = nil
    end
end

function AM:ClearExpiredLocalCooldowns()
    for spellID in pairs(AM.localCooldowns) do
        ClearExpiredLocalCooldownEntry(spellID)
    end
end

function AM:ClearLocalCooldowns()
    wipe(AM.localCooldowns)
end

--- @param spellID number
--- @return boolean
function AM:IsLocalCooldownActive(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    local entry = AM.localCooldowns[spellID]
    if not entry then
        return false
    end
    local now = GetTime()
    if now < (entry.endTime or 0) then
        return true
    end
    AM.localCooldowns[spellID] = nil
    return false
end

--- @param spellID number
--- @return number seconds remaining (0 when inactive or expired)
function AM:GetLocalCooldownRemaining(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return 0
    end
    local entry = AM.localCooldowns[spellID]
    if not entry then
        return 0
    end
    local now = GetTime()
    local remaining = (entry.endTime or 0) - now
    if remaining <= 0 then
        AM.localCooldowns[spellID] = nil
        return 0
    end
    return remaining
end

local function OnPlayerSpellCastSucceeded(_, unit, _, spellID)
    if unit ~= "player" then
        return
    end
    spellID = tonumber(spellID)
    if not spellID or not AM.localCooldownTrackedSpells[spellID] then
        return
    end
    local duration = AM.localCooldownDurations[spellID]
    if not duration or duration <= 0 then
        return
    end
    local now = GetTime()
    AM.localCooldowns[spellID] = {
        startTime = now,
        endTime = now + duration,
        duration = duration,
    }
end

function AM:PrintLocalCooldownStatus()
    print("|cffaaaaff[Azeroth Mentor]|r Local cooldown tracker:")
    local tracked = {}
    for spellID in pairs(AM.localCooldownTrackedSpells) do
        tracked[#tracked + 1] = spellID
    end
    table.sort(tracked)
    if #tracked == 0 then
        print("  (no spells registered)")
    else
        print("  Registered fallback durations:")
        for _, spellID in ipairs(tracked) do
            local name = nil
            if type(AM.GetSpellDisplayInfo) == "function" then
                name = select(1, AM:GetSpellDisplayInfo(spellID))
            end
            print(string.format(
                "    %d (%s): %.1fs",
                spellID,
                name or "?",
                AM.localCooldownDurations[spellID] or 0
            ))
        end
    end
    local active = {}
    for spellID in pairs(AM.localCooldowns) do
        if self:IsLocalCooldownActive(spellID) then
            active[#active + 1] = spellID
        end
    end
    table.sort(active)
    if #active == 0 then
        print("  Active timers: none")
        return
    end
    print("  Active timers:")
    for _, spellID in ipairs(active) do
        local name = nil
        if type(AM.GetSpellDisplayInfo) == "function" then
            name = select(1, AM:GetSpellDisplayInfo(spellID))
        end
        print(string.format(
            "    %d (%s): %.2fs remaining",
            spellID,
            name or "?",
            self:GetLocalCooldownRemaining(spellID)
        ))
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnPlayerSpellCastSucceeded(nil, ...)
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        AM:ClearExpiredLocalCooldowns()
    end
end)
