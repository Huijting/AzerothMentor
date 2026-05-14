--[[
  Azeroth Mentor - spell awareness (beginner-facing, non-combat-rotation)
  Tracks important Paladin spells the player knows and surfaces a short tip when one is newly learned.
  Future: GameTooltip:SetHyperlink("spell:"..spellID) / SetSpellByID on hover regions in the UI layer.
]]

local AM = _G.AM

AM.Spells = AM.Spells or {}

-- In-memory snapshot of tracked spellIDs the player knew after the last diff (see DetectNewSpells).
AM.knownSpellSnapshot = AM.knownSpellSnapshot or {}
-- After first successful DetectNewSpells seeding pass, diffs run against this snapshot.
AM._knownSpellSnapshotReady = AM._knownSpellSnapshotReady or false
-- AM.latestLearnedSpellID — set by DetectNewSpells when new tracked spells appear.
-- AM.pendingNewSpellIds — array of new spellIDs for the current UI refresh (consumed in UpdateMainFrame).
-- One-shot: UI shows NEW_ABILITY_LEARNED label for the refresh right after a detection.
AM._newAbilityBanner = AM._newAbilityBanner or false

-- Crusader Strike — prioritized in AM:GetFirstKnownClassSpell when actually known.
local CRUSADER_STRIKE_SPELL_ID = 35395

-- Temporary: set false to silence snapshot / detection chat spam.
local SPELL_DETECT_DEBUG = true

local function DebugSpellDetect(msg)
    if SPELL_DETECT_DEBUG then
        print("|cffaaaaff[Azeroth Mentor]|r " .. tostring(msg))
    end
end

local function SortedSpellIdList(snap)
    local ids = {}
    for sid in pairs(snap or {}) do
        ids[#ids + 1] = sid
    end
    table.sort(ids)
    local parts = {}
    for i = 1, #ids do
        parts[i] = tostring(ids[i])
    end
    return table.concat(parts, ", ")
end

--[[
  Paladin spell registry (retail spell IDs — verify after major patches).
  tutorialKey = key into AM.L for beginner copy.
  category   = builder | spender | heal | utility (for future filtering, not shown in UI yet).
  Only spells that pass IsSpellKnownSafe are treated as known (nothing “future” from this list).
]]
AM.Spells.PALADIN = {
    { spellID = 35395, tutorialKey = "SPELL_PALADIN_CRUSADER_STRIKE", category = "builder" }, -- Crusader Strike
    -- Player-learned Judgment uses the base spell id (e.g. level 3); 214222 is not the book entry on retail.
    { spellID = 20271, tutorialKey = "SPELL_PALADIN_JUDGMENT", category = "builder" }, -- Judgment
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
-- Spell name + icon for UI (modern C_Spell first, then legacy GetSpellInfo)
--------------------------------------------------------------------------------
local UNKNOWN_SPELL_NAME = "Unknown Spell"
local FALLBACK_SPELL_ICON = 134400

--- @param spellID number|nil
--- @return string spellName
--- @return number|string spellIcon fileID or texture path for SetTexture
function AM:GetSpellDisplayInfo(spellID)
    if spellID == nil then
        return UNKNOWN_SPELL_NAME, FALLBACK_SPELL_ICON
    end

    local spellName = UNKNOWN_SPELL_NAME
    local spellIcon = FALLBACK_SPELL_ICON

    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info and type(info) == "table" then
            if info.name and info.name ~= "" then
                spellName = info.name
            end
            local iconCandidate = info.iconID or info.originalIconID or info.iconFileID or info.icon
            if iconCandidate then
                spellIcon = iconCandidate
            end
        end
    end

    if type(GetSpellInfo) == "function" then
        local ok, pack = pcall(function()
            return { GetSpellInfo(spellID) }
        end)
        if ok and pack then
            if spellName == UNKNOWN_SPELL_NAME and pack[1] and pack[1] ~= "" then
                spellName = pack[1]
            end
            if spellIcon == FALLBACK_SPELL_ICON and pack[3] and pack[3] ~= "" and pack[3] ~= nil then
                spellIcon = pack[3]
            end
        end
    end

    if spellName == nil or spellName == "" then
        spellName = UNKNOWN_SPELL_NAME
    end

    if spellIcon == nil or spellIcon == "" then
        spellIcon = FALLBACK_SPELL_ICON
    end

    return spellName, spellIcon
end

--------------------------------------------------------------------------------
-- Shared spell row → display info (only when the spell is actually known)
--------------------------------------------------------------------------------
--- @return table|nil { spellID, tutorialKey, category, name, icon }
local function BuildSpellDisplayInfo(self, row)
    if not row or row.spellID == nil or not row.tutorialKey then
        return nil
    end
    if not self:IsSpellKnownSafe(row.spellID) then
        return nil
    end

    local spellID = row.spellID
    local spellName, spellIcon = self:GetSpellDisplayInfo(spellID)

    return {
        spellID = spellID,
        tutorialKey = row.tutorialKey,
        category = row.category or "utility",
        name = spellName,
        icon = spellIcon,
    }
end

--------------------------------------------------------------------------------
-- Known spell scan
--------------------------------------------------------------------------------
--- @return table[] list of { spellID, tutorialKey, category, name, icon } for tracked spells the player currently knows.
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
-- Known spell snapshot (diff-based “newly learned” detection)
--------------------------------------------------------------------------------
--- @return table<number, boolean> spellID -> true for every tracked spell the player currently knows.
function AM:BuildKnownSpellSnapshot()
    local snap = {}
    for _, info in ipairs(self:GetKnownSpells()) do
        snap[info.spellID] = true
    end
    DebugSpellDetect("BuildKnownSpellSnapshot → {" .. SortedSpellIdList(snap) .. "}")
    return snap
end

--- Compares the previous snapshot to the current one, updates the saved snapshot, sets latestLearnedSpellID
--- when at least one new spell appears (first new in PALADIN registry order if several), and stages UI data.
--- First run seeds the snapshot without reporting anything as new (avoids login spam).
--- @return number[] newSpellIDs in registry order
function AM:DetectNewSpells()
    self.knownSpellSnapshot = self.knownSpellSnapshot or {}

    -- Build the current spellbook view first; keep a shallow copy of the previous snapshot until diff completes.
    local newSnap = self:BuildKnownSpellSnapshot()

    if not self._knownSpellSnapshotReady then
        wipe(self.knownSpellSnapshot)
        for sid in pairs(newSnap) do
            self.knownSpellSnapshot[sid] = true
        end
        self._knownSpellSnapshotReady = true
        self.pendingNewSpellIds = nil
        DebugSpellDetect("DetectNewSpells: initial snapshot seeded (no new spells reported).")
        return {}
    end

    local oldSnap = {}
    for sid, v in pairs(self.knownSpellSnapshot) do
        oldSnap[sid] = v
    end
    DebugSpellDetect("DetectNewSpells: comparing old={" .. SortedSpellIdList(oldSnap) .. "} vs new={" .. SortedSpellIdList(newSnap) .. "}")

    local newIds = {}

    local db = self.Spells and self.Spells.PALADIN
    if db then
        for _, row in ipairs(db) do
            if row and row.spellID and newSnap[row.spellID] and not oldSnap[row.spellID] then
                newIds[#newIds + 1] = row.spellID
            end
        end
    end

    -- Only after diff: replace stored snapshot with the newest spellbook state.
    wipe(self.knownSpellSnapshot)
    for sid in pairs(newSnap) do
        self.knownSpellSnapshot[sid] = true
    end

    if #newIds >= 1 then
        self.latestLearnedSpellID = newIds[1]
        self._newAbilityBanner = true
        local pending = {}
        for i, sid in ipairs(newIds) do
            pending[i] = sid
        end
        self.pendingNewSpellIds = pending
        local idParts = {}
        for i = 1, #newIds do
            idParts[i] = tostring(newIds[i])
        end
        DebugSpellDetect(
            "DetectNewSpells: NEW tracked spell ID(s): "
                .. table.concat(idParts, ", ")
                .. " (first="
                .. tostring(newIds[1])
                .. ")"
        )
    else
        self.pendingNewSpellIds = nil
        DebugSpellDetect("DetectNewSpells: no new tracked spells this pass.")
    end

    return newIds
end

--- Spell card: prefer the latest detected new spell while it is still known; otherwise Crusader-first fallback.
--- @return table|nil { spellID, tutorialKey, category, name, icon }
function AM:GetSpellCardDisplayInfo()
    local latest = self.latestLearnedSpellID
    if latest and self:IsSpellKnownSafe(latest) then
        local db = self.Spells and self.Spells.PALADIN
        if db then
            for _, row in ipairs(db) do
                if row and row.spellID == latest then
                    local info = BuildSpellDisplayInfo(self, row)
                    if info then
                        return info
                    end
                end
            end
        end
    end
    return self:GetFirstKnownClassSpell()
end

--------------------------------------------------------------------------------
-- First known class spell (for spell card UI)
--------------------------------------------------------------------------------
--- Returns one display-ready Paladin registry spell: Crusader Strike if known, else the first known row in DB order.
--- @return table|nil { spellID, tutorialKey, category, name, icon }
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
