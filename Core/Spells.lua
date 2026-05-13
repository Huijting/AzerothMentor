--[[
  Azeroth Mentor - spell awareness (beginner-facing, non-combat-rotation)
  Tracks important Paladin spells the player knows and surfaces a short tip when one is newly learned.
  Future: GameTooltip:SetHyperlink("spell:"..spellID) / SetSpellByID on hover regions in the UI layer.
]]

local AM = _G.AM

AM.Spells = AM.Spells or {}

-- Crusader Strike — prioritized in AM:GetFirstKnownClassSpell when actually known.
local CRUSADER_STRIKE_SPELL_ID = 35395

--[[
  Paladin spell registry (retail spell IDs — verify after major patches).
  tutorialKey = key into AM.L for beginner copy.
  category   = builder | spender | heal | utility (for future filtering, not shown in UI yet).
  Only spells that pass IsSpellKnownSafe are treated as known (nothing “future” from this list).
]]
AM.Spells.PALADIN = {
    { spellID = 35395, tutorialKey = "SPELL_PALADIN_CRUSADER_STRIKE", category = "builder" }, -- Crusader Strike
    { spellID = 214222, tutorialKey = "SPELL_PALADIN_JUDGMENT", category = "builder" }, -- Judgment
    { spellID = 19750, tutorialKey = "SPELL_PALADIN_FLASH_OF_LIGHT", category = "heal" }, -- Flash of Light
}

--------------------------------------------------------------------------------
-- Spell known detection (APIs differ by client; never assume globals exist)
--------------------------------------------------------------------------------
--- @param spellID number|nil
--- @return boolean
function AM:IsSpellKnownSafe(spellID)
    if spellID == nil then
        return false
    end

    local spellBook = C_SpellBook
    if spellBook and type(spellBook.IsSpellKnown) == "function" then
        local ok, known = pcall(spellBook.IsSpellKnown, spellBook, spellID)
        if ok and known then
            return true
        end
        -- Some builds expose a static-style call instead of a method.
        ok, known = pcall(function()
            return spellBook.IsSpellKnown(spellID)
        end)
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

    if type(IsPlayerSpell) == "function" then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known then
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- Shared spell row → display info (only when the spell is actually known)
--------------------------------------------------------------------------------
--- @return table|nil { spellID, tutorialKey, category, name }
local function BuildSpellDisplayInfo(self, row)
    if not row or row.spellID == nil or not row.tutorialKey then
        return nil
    end
    if not self:IsSpellKnownSafe(row.spellID) then
        return nil
    end

    local spellID = row.spellID
    local name = UNKNOWN

    if type(GetSpellInfo) == "function" then
        local ok, spellName = pcall(function()
            return select(1, GetSpellInfo(spellID))
        end)
        if ok and spellName and spellName ~= "" then
            name = spellName
        end
    end

    return {
        spellID = spellID,
        tutorialKey = row.tutorialKey,
        category = row.category or "utility",
        name = name,
    }
end

--------------------------------------------------------------------------------
-- Known spell scan
--------------------------------------------------------------------------------
--- @return table[] list of { spellID, tutorialKey, category, name } for tracked spells the player currently knows.
function AM:GetKnownSpells()
    local _, classFile = UnitClass("player")
    local list = {}

    if classFile ~= "PALADIN" then
        return list
    end

    local db = self.Spells and self.Spells.PALADIN
    if not db then
        return list
    end

    for _, row in ipairs(db) do
        local info = BuildSpellDisplayInfo(self, row)
        if info then
            list[#list + 1] = info
        end
    end

    return list
end

--------------------------------------------------------------------------------
-- First known class spell (for spell card UI)
--------------------------------------------------------------------------------
--- Returns one display-ready Paladin registry spell: Crusader Strike if known, else the first known row in DB order.
--- @return table|nil { spellID, tutorialKey, category, name }
function AM:GetFirstKnownClassSpell()
    local _, classFile = UnitClass("player")
    if classFile ~= "PALADIN" then
        return nil
    end

    local db = self.Spells and self.Spells.PALADIN
    if not db then
        return nil
    end

    for _, row in ipairs(db) do
        if row and row.spellID == CRUSADER_STRIKE_SPELL_ID then
            local info = BuildSpellDisplayInfo(self, row)
            if info then
                return info
            end
        end
    end

    for _, row in ipairs(db) do
        local info = BuildSpellDisplayInfo(self, row)
        if info then
            return info
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Newest learned spell (one-shot announcement per spellID)
--------------------------------------------------------------------------------
--- Detects a tracked spell that just became known and has not been announced yet.
--- Uses a one-time snapshot init on first run to avoid spamming every known spell at login.
--- @return table|nil info { spellID, tutorialKey, category, name }
function AM:GetNewestKnownSpell()
    self.db.spellTipsSeen = self.db.spellTipsSeen or {}

    local knownList = self:GetKnownSpells()
    local cur = {}
    for _, info in ipairs(knownList) do
        cur[info.spellID] = true
    end

    if not self._spellAwareInit then
        self._spellPrevKnown = cur
        self._spellAwareInit = true
        return nil
    end

    local prev = self._spellPrevKnown or {}
    local candidate

    -- Later rows in PALADIN table are treated as "newer" for tie-breaking.
    for _, info in ipairs(knownList) do
        if
            cur[info.spellID]
            and not prev[info.spellID]
            and not self.db.spellTipsSeen[info.spellID]
        then
            candidate = info
        end
    end

    self._spellPrevKnown = cur
    return candidate
end
