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
-- AM.latestLearnedSpellID — set on new tracked learns; cleared when mentor spotlight ends (see GetSpellCardDisplayInfo).
-- AM.pendingNewSpellIds — array of new spellIDs for the current UI refresh (consumed in UpdateMainFrame).
-- AM._mentorExplainSpellID / AM._mentorExplainUntil — keep the spell card on the new spell while the player reads the mentor copy (complements Blizzard’s unlock toast; does not replace it).
-- AM.spellbookIdSnapshot / AM._spellbookSpellSnapshotReady — full player spellbook spellIDs for detecting learns not yet in AM.Spells.PALADIN.
-- AM._unknownUntrackedSpellID / AM._unknownUntrackedUntil — show UNKNOWN_SPELL_NOTICE card for off-registry learns.
AM._newAbilityBanner = AM._newAbilityBanner or false

-- Set true to print snapshot / detection details to chat (for development only).
local SPELL_DETECT_DEBUG = false

local function DebugSpellDetect(msg)
    if SPELL_DETECT_DEBUG then
        print("|cffaaaaff[Azeroth Mentor]|r " .. tostring(msg))
    end
end

-- Set true temporarily to trace spell card branch + GetCombatRecommendation vs final pick (chat can be noisy).
local DEBUG_COMBAT_SPELL_CARD = false

--- Logs GetCombatRecommendation snapshot vs branch + spell card chosen.
--- @param branch string which resolver path returned (mentor_explain, unknown_untracked, latest_learned, combat_mentor, first_known)
local function FinishSpellCardDisplay(self, result, branch)
    branch = branch or "default"
    if DEBUG_COMBAT_SPELL_CARD then
        local phase = "n/a"
        local suggested = "nil"
        local sm = self.SpecModules and self.SpecModules.PALADIN and self.SpecModules.PALADIN.RETRIBUTION
        if sm and sm.GetCombatRecommendation and self.RetributionCombat and self.RetributionCombat.GetState then
            local rec = sm.GetCombatRecommendation({ combat = self.RetributionCombat:GetState() })
            if rec then
                phase = tostring(rec.phase)
                suggested = tostring(rec.suggestedSpellID)
            end
        end
        local final = result and result.spellID or "nil"
        print(
            string.format(
                "[Azeroth Mentor][SpellCard] branch=%s phase=%s suggestedSpellID=%s finalSpellID=%s",
                tostring(branch),
                phase,
                suggested,
                tostring(final)
            )
        )
    end
    return result
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

--- @param self AM
--- @param spellID number
--- @return boolean
local function IsSpellInPaladinRegistry(self, spellID)
    if not spellID then
        return false
    end
    local db = self.Spells and self.Spells.PALADIN
    if not db then
        return false
    end
    for _, row in ipairs(db) do
        if row and row.spellID == spellID then
            return true
        end
    end
    return false
end

--- Collect spellIDs listed in the player spellbook (General + spec tabs). Used only for Paladin untracked-learn detection.
--- @return table<number, boolean>
local function CollectSpellbookSpellIds()
    local set = {}
    local bank = 0
    if Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player ~= nil then
        bank = Enum.SpellBookSpellBank.Player
    end

    if C_SpellBook and type(C_SpellBook.GetSpellBookItemInfo) == "function" then
        local flyEnum = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.SpellFlyout
        local futureEnum = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell

        local miss = 0
        for slot = 1, 1500 do
            local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, bank)
            if ok and info and type(info) == "table" and info.spellID and info.spellID > 0 then
                local it = info.itemType
                if flyEnum and it == flyEnum then
                    miss = 0
                elseif futureEnum and it == futureEnum then
                    miss = 0
                else
                    set[info.spellID] = true
                    miss = 0
                end
            else
                miss = miss + 1
                if miss > 100 then
                    break
                end
            end
        end
        return set
    end

    local book = _G.BOOKTYPE_SPELL
    if type(GetSpellBookItemInfo) == "function" and book ~= nil then
        for slot = 1, 600 do
            local ok, _, _, _, _, _, spellID = pcall(GetSpellBookItemInfo, slot, book)
            if ok and spellID and spellID > 0 then
                set[spellID] = true
            elseif ok and (not spellID or spellID == 0) then
                -- keep scanning; legacy API may have gaps
            end
        end
    end

    return set
end

-- Retribution specialization id (matches Core/Player.lua SPEC_ID_RETRIBUTION_PALADIN).
local SPEC_ID_RETRIBUTION_PALADIN = 70

--- Active specialization id for the local player, or nil (used to gate Ret-only spell rows).
local function GetPlayerSpecializationId()
    local n = tonumber(GetSpecialization())
    if not n or n < 1 then
        return nil
    end
    local ok, sid = pcall(function()
        return select(1, GetSpecializationInfo(n, false, false, nil))
    end)
    if ok and type(sid) == "number" and sid > 0 then
        return sid
    end
    return nil
end

--- Picks Retribution-specific copy when tutorialKeyRet is set and the player is Retribution.
local function ResolveRowTutorialKey(row)
    if not row then
        return nil
    end
    if row.tutorialKeyRet and GetPlayerSpecializationId() == SPEC_ID_RETRIBUTION_PALADIN then
        return row.tutorialKeyRet
    end
    return row.tutorialKey
end

--[[
  Paladin spell registry (retail spell IDs — verify after major patches).

  Each row:
    spellID          — book / player spell id used with IsSpellKnownSafe
    tutorialKey      — AM.L beginner tip when this spell is highlighted
    tutorialKeyRet   — optional; when set and the player is Retribution, overrides tutorialKey (one spellID, two tones)
    specIdRequired   — optional; when set (e.g. 70), row is ignored unless the player's specialization id matches
                       (spells the player has not learned yet are still hidden via IsSpellKnownSafe)
    category         — builder | spender | heal | utility | crowdcontrol | defensive | aoe
                  (future: filter tips, stage gates, “what to learn next” without combat rotation math)
    priority    — integer; higher = more important for beginners when picking a default spell card
                  (future: mentor pacing — which concept to explain first; rotation guidance will layer on top)

  Registry order is descending priority so DetectNewSpells(), when several spells appear in one refresh,
  picks latestLearnedSpellID as the first new row — i.e. the highest-priority among newly learned.

  Only spells that pass IsSpellKnownSafe are treated as known (nothing “future” from this list).

  Blizzard’s level-up / spell unlock UI handles celebration and “you unlocked X”.
  Azeroth Mentor uses the same registry for HOW/WHY copy on the spell card (mentor pacing, not rotation math).
]]
local MENTOR_SPELL_FOCUS_SECONDS = 55

AM.Spells.PALADIN = {
    {
        spellID = 35395,
        tutorialKey = "SPELL_PALADIN_CRUSADER_STRIKE",
        category = "builder",
        priority = 100,
    }, -- Crusader Strike
    {
        spellID = 20271,
        tutorialKey = "SPELL_PALADIN_JUDGMENT",
        tutorialKeyRet = "SPELL_RET_JUDGMENT",
        category = "builder",
        priority = 96,
    }, -- Judgment (shared; Ret uses SPELL_RET_JUDGMENT when specialized)
    {
        spellID = 184575,
        tutorialKey = "SPELL_RET_BLADE_OF_JUSTICE",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "builder",
        priority = 98,
    }, -- Blade of Justice (Retribution)
    {
        spellID = 85256,
        tutorialKey = "SPELL_RET_TEMPLARS_VERDICT",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "spender",
        priority = 94,
    }, -- Templar's Verdict (Retribution)
    {
        spellID = 255937,
        tutorialKey = "SPELL_RET_WAKE_OF_ASHES",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "aoe",
        priority = 88,
    }, -- Wake of Ashes (Retribution; talent or baseline depending on patch—hidden until known)
    {
        spellID = 85673,
        tutorialKey = "SPELL_PALADIN_WORD_OF_GLORY",
        category = "heal",
        priority = 90,
    }, -- Word of Glory
    {
        spellID = 53600,
        tutorialKey = "SPELL_PALADIN_SHIELD_OF_THE_RIGHTEOUS",
        category = "defensive",
        priority = 87,
    }, -- Shield of the Righteous
    {
        spellID = 26573,
        tutorialKey = "SPELL_PALADIN_CONSECRATION",
        category = "aoe",
        priority = 82,
    }, -- Consecration
    {
        spellID = 19750,
        tutorialKey = "SPELL_PALADIN_FLASH_OF_LIGHT",
        category = "heal",
        priority = 78,
    }, -- Flash of Light
    {
        spellID = 853,
        tutorialKey = "SPELL_PALADIN_HAMMER_OF_JUSTICE",
        category = "crowdcontrol",
        priority = 70,
    }, -- Hammer of Justice
    {
        spellID = 62124,
        tutorialKey = "SPELL_PALADIN_HAND_OF_RECKONING",
        category = "utility",
        priority = 65,
    }, -- Hand of Reckoning
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
--- @return table|nil { spellID, tutorialKey, category, priority, name, icon }
local function BuildSpellDisplayInfo(self, row)
    if not row or row.spellID == nil then
        return nil
    end
    local tKey = ResolveRowTutorialKey(row)
    if not tKey then
        return nil
    end
    if row.specIdRequired and GetPlayerSpecializationId() ~= row.specIdRequired then
        return nil
    end
    if not self:IsSpellKnownSafe(row.spellID) then
        return nil
    end

    local spellID = row.spellID
    local spellName, spellIcon = self:GetSpellDisplayInfo(spellID)
    local priority = tonumber(row.priority) or 0

    return {
        spellID = spellID,
        tutorialKey = tKey,
        category = row.category or "utility",
        priority = priority,
        name = spellName,
        icon = spellIcon,
    }
end

--------------------------------------------------------------------------------
-- Known spell scan
--------------------------------------------------------------------------------
--- @return table[] list of { spellID, tutorialKey, category, priority, name, icon } for tracked spells the player currently knows.
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

local SPELLBOOK_BULK_NEW_THRESHOLD = 18

--- Diff the player spellbook against the last scan to find spellIDs that appeared but are not in AM.Spells.PALADIN.
--- Throttled and bulk-guarded so spellbook load spikes do not flood the UI.
function AM:DetectUntrackedSpellbookNewSpells()
    local _, classFile = UnitClass("player")
    if classFile ~= "PALADIN" then
        return
    end

    local now = GetTime()

    self.spellbookIdSnapshot = self.spellbookIdSnapshot or {}
    local bookSnap = CollectSpellbookSpellIds()

    if not self._spellbookSpellSnapshotReady then
        wipe(self.spellbookIdSnapshot)
        for sid in pairs(bookSnap) do
            self.spellbookIdSnapshot[sid] = true
        end
        self._spellbookSpellSnapshotReady = true
        DebugSpellDetect("Spellbook snapshot seeded (untracked-learn detection ready).")
        return
    end

    local oldB = {}
    for sid, v in pairs(self.spellbookIdSnapshot) do
        oldB[sid] = v
    end

    local newList = {}
    for sid in pairs(bookSnap) do
        if not oldB[sid] then
            newList[#newList + 1] = sid
        end
    end

    if #newList > SPELLBOOK_BULK_NEW_THRESHOLD then
        wipe(self.spellbookIdSnapshot)
        for sid in pairs(bookSnap) do
            self.spellbookIdSnapshot[sid] = true
        end
        DebugSpellDetect("Spellbook bulk change (" .. #newList .. " new); reseed without untracked notice.")
        return
    end

    table.sort(newList)

    local pickedUntracked
    for _, sid in ipairs(newList) do
        if not IsSpellInPaladinRegistry(self, sid) then
            pickedUntracked = sid
            break
        end
    end

    wipe(self.spellbookIdSnapshot)
    for sid in pairs(bookSnap) do
        self.spellbookIdSnapshot[sid] = true
    end

    if pickedUntracked then
        self._unknownUntrackedSpellID = pickedUntracked
        self._unknownUntrackedUntil = now + MENTOR_SPELL_FOCUS_SECONDS
        DebugSpellDetect("Untracked spellbook learn: " .. tostring(pickedUntracked))
    end
end

--- Compares the previous snapshot to the current one, updates the saved snapshot, sets latestLearnedSpellID
--- when at least one new spell appears (first new in PALADIN registry order — highest beginner priority first
--- in the table — if several), and stages UI data. latestLearnedSpellID is cleared when mentor spotlight ends.
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
        self:DetectUntrackedSpellbookNewSpells()
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
        self._mentorExplainSpellID = newIds[1]
        self._mentorExplainUntil = GetTime() + MENTOR_SPELL_FOCUS_SECONDS
        self._unknownUntrackedSpellID = nil
        self._unknownUntrackedUntil = nil
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

    self:DetectUntrackedSpellbookNewSpells()
    return newIds
end

--- Retribution in combat: spell card follows BUILD (walk builder list) or SPEND (Templar's Verdict when known).
--- Does not replace mentor_explain / unknown / latest spotlight (handled in GetSpellCardDisplayInfo).
--- @return table|nil
function AM:GetRetributionMentorCombatSpellCard()
    local _, classFile = UnitClass("player")
    if classFile ~= "PALADIN" then
        return nil
    end
    if GetPlayerSpecializationId() ~= SPEC_ID_RETRIBUTION_PALADIN then
        return nil
    end
    local sm = self.SpecModules and self.SpecModules.PALADIN and self.SpecModules.PALADIN.RETRIBUTION
    if not sm or not sm.GetCombatRecommendation then
        return nil
    end
    local combat = self.RetributionCombat and self.RetributionCombat.GetState and self.RetributionCombat:GetState()
    if not combat then
        return nil
    end
    local rec = sm.GetCombatRecommendation({ combat = combat })
    if not rec or rec.phase == "OUT_OF_COMBAT" then
        return nil
    end

    local db = self.Spells and self.Spells.PALADIN
    if not db then
        return nil
    end

    if rec.phase == "BUILD" then
        -- Never gate BUILD on rec.suggestedSpellID alone: display can be BUILD while suggested was nil,
        -- which previously skipped this path and let GetFirstKnownClassSpell pick a spender (e.g. TV).
        local order = (sm.GetBuildMentorSpellOrder and sm.GetBuildMentorSpellOrder()) or { 184575, 35395, 20271 }
        for _, sid in ipairs(order) do
            for _, row in ipairs(db) do
                if row and row.spellID == sid then
                    local info = BuildSpellDisplayInfo(self, row)
                    if info then
                        info.isRetCombatMentorFocus = true
                        return info
                    end
                    break
                end
            end
        end
        return nil
    end

    if rec.phase == "SPEND" then
        if not rec.suggestedSpellID then
            return nil
        end
        for _, row in ipairs(db) do
            if row and row.spellID == rec.suggestedSpellID then
                local info = BuildSpellDisplayInfo(self, row)
                if info then
                    info.isRetCombatMentorFocus = true
                    return info
                end
                break
            end
        end
        return nil
    end

    return nil
end

--- Spell card: mentor focus on a tracked new spell, then an off-registry spellbook learn (UNKNOWN_SPELL_NOTICE),
--- then latest tracked learn, then Retribution BUILD/SPEND mentor focus, else highest-priority known.
--- @return table|nil { spellID, tutorialKey, category, priority, name, icon }
function AM:GetSpellCardDisplayInfo()
    local now = GetTime()
    if self._mentorExplainUntil and now >= self._mentorExplainUntil then
        self._mentorExplainUntil = nil
        self._mentorExplainSpellID = nil
        -- End "new spell" spotlight; otherwise latestLearnedSpellID would win forever and block combat mentor card.
        self.latestLearnedSpellID = nil
    end

    if self._unknownUntrackedUntil and now >= self._unknownUntrackedUntil then
        self._unknownUntrackedUntil = nil
        self._unknownUntrackedSpellID = nil
    end

    local explainId = self._mentorExplainSpellID
    if explainId and self._mentorExplainUntil and now < self._mentorExplainUntil then
        if not self:IsSpellKnownSafe(explainId) then
            self._mentorExplainUntil = nil
            self._mentorExplainSpellID = nil
            self.latestLearnedSpellID = nil
        else
            local db = self.Spells and self.Spells.PALADIN
            if db then
                for _, row in ipairs(db) do
                    if row and row.spellID == explainId then
                        local info = BuildSpellDisplayInfo(self, row)
                        if info then
                            return FinishSpellCardDisplay(self, info, "mentor_explain")
                        end
                        break
                    end
                end
            end
        end
    end

    local unkId = self._unknownUntrackedSpellID
    local unkUntil = self._unknownUntrackedUntil
    if unkId and unkUntil and now < unkUntil then
        if not self:IsSpellKnownSafe(unkId) or IsSpellInPaladinRegistry(self, unkId) then
            self._unknownUntrackedSpellID = nil
            self._unknownUntrackedUntil = nil
        else
            local nm, ic = self:GetSpellDisplayInfo(unkId)
            return FinishSpellCardDisplay(self, {
                spellID = unkId,
                tutorialKey = "UNKNOWN_SPELL_NOTICE",
                category = "unknown",
                priority = -2,
                name = nm,
                icon = ic,
                isUnknownUntracked = true,
            }, "unknown_untracked")
        end
    end

    -- While mentor spotlight is active, explain branch above returns first. After it ends, latestLearnedSpellID is nil.
    local latest = self.latestLearnedSpellID
    if latest and self:IsSpellKnownSafe(latest) then
        local db = self.Spells and self.Spells.PALADIN
        if db then
            for _, row in ipairs(db) do
                if row and row.spellID == latest then
                    local info = BuildSpellDisplayInfo(self, row)
                    if info then
                        return FinishSpellCardDisplay(self, info, "latest_learned")
                    end
                end
            end
        end
    end

    -- Retribution: replaces default fallback only (not explain / unknown / latest spotlight).
    local combatFocus = self:GetRetributionMentorCombatSpellCard()
    if combatFocus then
        return FinishSpellCardDisplay(self, combatFocus, "combat_mentor")
    end

    return FinishSpellCardDisplay(self, self:GetFirstKnownClassSpell(), "first_known")
end

--------------------------------------------------------------------------------
-- Default spell card (highest beginner priority among known registry spells)
--------------------------------------------------------------------------------
--- Returns one display-ready Paladin registry spell: the **known** spell with the highest `priority` value.
--- Ties on `priority`: the earlier row in AM.Spells.PALADIN wins (deterministic).
--- Future: rotation and mentor pacing will use category + priority together; this is the non-“new spell” default card.
--- @return table|nil { spellID, tutorialKey, category, priority, name, icon }
function AM:GetFirstKnownClassSpell()
    local _, classFile = UnitClass("player")
    if classFile ~= "PALADIN" then
        return nil
    end

    local db = self.Spells and self.Spells.PALADIN
    if not db then
        return nil
    end

    local bestInfo
    local bestPriority = -math.huge
    local bestIndex = math.huge

    for index, row in ipairs(db) do
        local info = BuildSpellDisplayInfo(self, row)
        if info then
            local pr = info.priority or 0
            if pr > bestPriority or (pr == bestPriority and index < bestIndex) then
                bestPriority = pr
                bestIndex = index
                bestInfo = info
            end
        end
    end

    return bestInfo
end
