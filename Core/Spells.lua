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

--- Lesson toast may only fire for these resolver branches (not default/first_known or combat mentor).
local TOAST_ELIGIBLE_CARD_SOURCES = {
    level_milestone = true,
    mentor_explain = true,
    unknown_untracked = true,
    latest_learned = true,
}

local TRACKED_SPELL_BULK_NEW_THRESHOLD = 3

--- Active new-spell spotlight window (mentor explain / latest learned), not a recurring default tip.
--- @param spellID number|nil
--- @return boolean
function AM:IsActiveMentorExplainSpotlight(spellID)
    if not spellID then
        return false
    end
    local explainId = self._mentorExplainSpellID
    local untilT = self._mentorExplainUntil
    if not explainId or not untilT then
        return false
    end
    return explainId == spellID and GetTime() < untilT
end

--- @param result table|nil
--- @param branch string
local function ApplyLessonToastEligibility(self, result, branch)
    if not result then
        return
    end
    result.cardSource = branch
    local eligible = TOAST_ELIGIBLE_CARD_SOURCES[branch] and true or false
    if branch == "mentor_explain" or branch == "latest_learned" then
        eligible = eligible and self:IsActiveMentorExplainSpotlight(result.spellID)
    end
    result.toastEligible = eligible
end

--- Logs GetCombatRecommendation snapshot vs branch + spell card chosen.
--- @param branch string which resolver path returned (mentor_explain, unknown_untracked, latest_learned, combat_mentor, level_milestone, first_known)
--- @param opts table|nil optional `{ skipLessonLog = true }` for callers that must not persist mentor log entries (e.g. /am status).
local function FinishSpellCardDisplay(self, result, branch, opts)
    branch = branch or "default"
    ApplyLessonToastEligibility(self, result, branch)
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
    if AM.DEBUG_CARD_SELECTION then
        local ty = result and result.type or "nil"
        local nm = result and (result.title or result.name) or "no title"
        print("Azeroth Mentor card selected: " .. tostring(ty) .. " " .. tostring(nm))
    end
    -- Mentor log: spotlight paths only (no combat, no milestone here, no rotating first_known tips).
    if result and type(self.AddLessonLogEntry) == "function" and not (opts and opts.skipLessonLog) then
        if branch ~= "combat_mentor" and branch ~= "level_milestone" and branch ~= "first_known" then
            local title = result.title or result.name
            if not title or title == "" then
                title = result.spellID and ("Spell " .. tostring(result.spellID)) or "?"
            end
            local body = ""
            if result.tutorialKey and self.L then
                body = self.L[result.tutorialKey] or ""
            end
            self:AddLessonLogEntry({
                type = tostring(branch),
                title = title,
                subtitle = "",
                body = body,
                instruction = "",
                level = UnitLevel("player") or 0,
                timestamp = time(),
                spellID = result.spellID,
            })
        end
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

--- @param spellID number
--- @return table|nil registry row from GENERAL_UNLOCK
local function GetGeneralUnlockRow(spellID)
    if not spellID then
        return nil
    end
    local db = AM.Spells and AM.Spells.GENERAL_UNLOCK
    if not db then
        return nil
    end
    for _, row in ipairs(db) do
        if row and row.spellID == spellID then
            return row
        end
    end
    return nil
end

--- Non-class spellbook learns to ignore (parked for a future Activity Unlock Lessons system).
local SUPPRESSED_UNTRACKED_SPELL_IDS = {
    [459988] = true, -- Switch Flight Style (retail)
    [436854] = true, -- Switch Flight Style (legacy PTR id)
}

--- @param spellID number
--- @return boolean
local function IsSuppressedUntrackedSpell(spellID)
    return spellID and SUPPRESSED_UNTRACKED_SPELL_IDS[spellID] or false
end

--- @param self AM
--- @param spellID number
--- @return table|nil PALADIN or GENERAL_UNLOCK row
local function FindRegistryRowForSpell(self, spellID)
    if not spellID then
        return nil
    end
    local paladin = self.Spells and self.Spells.PALADIN
    if paladin then
        for _, row in ipairs(paladin) do
            if row and row.spellID == spellID then
                return row
            end
        end
    end
    return GetGeneralUnlockRow(spellID)
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
        spellID = 462970,
        tutorialKey = "SPELL_RET_CONSECRATED_BLADE",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "utility",
        priority = 52,
    }, -- Consecrated Blade (Retribution passive; not a new action button — verify spell ID after major patches)
    {
        spellID = 85256,
        tutorialKey = "SPELL_RET_TEMPLARS_VERDICT",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "spender",
        priority = 94,
    }, -- Templar's Verdict (Retribution)
    {
        spellID = 383328,
        tutorialKey = "SPELL_RET_FINAL_VERDICT",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "spender",
        priority = 93,
    }, -- Final Verdict (replaces Templar's Verdict when talented; spellID 383328 — retail learn toast / Wowhead)
    {
        spellID = 53385,
        tutorialKey = "SPELL_RET_DIVINE_STORM",
        specIdRequired = SPEC_ID_RETRIBUTION_PALADIN,
        category = "aoe",
        priority = 72,
    }, -- Divine Storm (often from talents; optional multi-target Holy Power spender)
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
        spellID = 633,
        tutorialKey = "SPELL_PALADIN_LAY_ON_HANDS",
        category = "heal",
        priority = 79,
    }, -- Lay on Hands (class-wide emergency heal; long cooldown; not damage rotation)
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
        spellID = 190784,
        tutorialKey = "SPELL_PALADIN_DIVINE_STEED",
        category = "utility",
        priority = 63,
    }, -- Divine Steed (movement / escape; not a damage rotation button)
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
    {
        spellID = 7328,
        tutorialKey = "SPELL_PALADIN_REDEMPTION",
        category = "utility",
        priority = 62,
    }, -- Redemption (resurrect dead allies; not a combat damage button)
    {
        spellID = 391054,
        tutorialKey = "SPELL_PALADIN_INTERCESSION",
        category = "utility",
        priority = 61,
    }, -- Intercession (combat rez in group content; spellID 391054 — retail learn toast / Wowhead)
}

-- Class-neutral spellbook unlocks (riding, travel). Not part of AM.Spells.PALADIN combat mentoring.
AM.Spells.GENERAL_UNLOCK = {
    {
        spellID = 34090,
        tutorialKey = "SPELL_GENERAL_EXPERT_RIDING",
        category = "travel",
        priority = 10,
    }, -- Expert Riding (riding skill 225; spellID 34090 — retail / Wowhead)
    {
        spellID = 361584,
        tutorialKey = "SPELL_GENERAL_WHIRLING_SURGE",
        category = "travel",
        priority = 9,
    }, -- Whirling Surge (skyriding / dynamic flying; spellID 361584 — retail / Wowhead)
    {
        spellID = 447981,
        tutorialKey = "SPELL_GENERAL_WHIRLING_SURGE",
        category = "travel",
        priority = 9,
    }, -- Whirling Surge (alternate retail spellID; same ability — some clients report this id)
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

-- Retail combat can return secret cooldown numbers: type() may be "number" but >/< still errors.
-- Never compare or format cooldown values outside pcall; fail open when unreadable.
local SPELL_CD_MIN_DURATION = 1.5
local SPELL_CD_REMAINING_THRESHOLD = 0.1
local SPELL_CD_CACHE_TTL = 2.0
local SPELL_CD_TRACKED_IDS = { 184575, 20271, 35395, 383328, 85256 }

-- Shown by /am cooldowns to confirm the loaded cooldown logic revision.
AM.COOLDOWN_LOGIC_VERSION = "plain-v7"

AM._spellCooldownReadyCache = AM._spellCooldownReadyCache or {}

--- @param val any
--- @return boolean|nil true/false when plain boolean; nil when secret or non-boolean
local function SafeBoolField(val)
    if val == true then
        return true
    end
    if val == false then
        return false
    end
    return nil
end

--- Convert secret/protected cooldown numbers into plain Lua numbers (never compare raw API values).
--- @param value any
--- @return number|nil
local function SafePlainNumber(value)
    if value == nil then
        return nil
    end
    local ok, text = pcall(function()
        return string.format("%.3f", value)
    end)
    if ok and type(text) == "string" then
        local n = tonumber(text)
        if type(n) == "number" then
            return n
        end
    end
    local ok2, n2 = pcall(function()
        return tonumber(value)
    end)
    if ok2 and type(n2) == "number" then
        return n2
    end
    return nil
end

--- @param a any plain Lua number
--- @param b any plain Lua number
--- @return boolean|nil true / false, or nil if compare failed
local function SafeGreater(a, b)
    if a == nil or b == nil then
        return nil
    end
    local ok, result = pcall(function()
        return a > b
    end)
    if ok and type(result) == "boolean" then
        return result
    end
    return nil
end

--- @param val any
--- @return string
local function SafeFormatNumber(val)
    if val == nil then
        return "nil"
    end
    local ok, text = pcall(function()
        return string.format("%.2f", val)
    end)
    if ok and type(text) == "string" then
        return text
    end
    local ok2, text2 = pcall(function()
        return tostring(val)
    end)
    if ok2 and type(text2) == "string" then
        return text2
    end
    return "unreadable"
end

--- Read raw cooldown fields from game APIs (no comparisons here).
--- @param spellID number
--- @param detail table
--- @return any startRaw
--- @return any durationRaw
local function ReadCooldownRaw(spellID, detail)
    local startRaw = nil
    local durationRaw = nil

    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local cdOk, cdPack = pcall(function()
            local r1, r2, r3 = C_Spell.GetSpellCooldown(spellID)
            return { r1, r2, r3 }
        end)
        if cdOk and type(cdPack) == "table" and cdPack[1] ~= nil then
            detail.apiPath = "C_Spell.GetSpellCooldown"
            local first = cdPack[1]
            if type(first) == "table" then
                detail.apiPath = "C_Spell.GetSpellCooldown(table)"
                if first.isOnGCD == true then
                    detail.isOnGCD = true
                elseif first.isOnGCD == false then
                    detail.isOnGCD = false
                end
                durationRaw = first.duration
                startRaw = first.startTime or first.start
                if durationRaw == nil and cdPack[2] ~= nil then
                    durationRaw = cdPack[2]
                end
            else
                detail.apiPath = "C_Spell.GetSpellCooldown(returns)"
                startRaw = first
                durationRaw = cdPack[2]
            end
        end
    end

    if durationRaw == nil and type(GetSpellCooldown) == "function" then
        local legOk, a, b = pcall(GetSpellCooldown, spellID)
        if legOk then
            detail.apiPath = "GetSpellCooldown"
            startRaw = a
            durationRaw = b
        end
    end

    return startRaw, durationRaw
end

--- @param spellID number|nil clears one entry; omit to clear all tracked entries.
function AM:ClearSpellCooldownCache(spellID)
    if not self._spellCooldownReadyCache then
        return
    end
    if spellID == nil then
        self._spellCooldownReadyCache = {}
        return
    end
    self._spellCooldownReadyCache[spellID] = nil
end

--- @param spellID number
--- @return boolean|nil usable; nil = unknown (fail open)
--- @return string apiPath
local function EvaluateSpellUsable(spellID)
    if C_Spell and type(C_Spell.IsSpellUsable) == "function" then
        local ok, usable = pcall(function()
            local u = C_Spell.IsSpellUsable(spellID)
            if type(u) == "boolean" then
                return u
            end
            if type(u) == "table" then
                return SafeBoolField(u.isUsable)
            end
            return nil
        end)
        if ok and type(usable) == "boolean" then
            return usable, "C_Spell.IsSpellUsable"
        end
    end
    if type(IsUsableSpell) == "function" then
        local ok, usable = pcall(IsUsableSpell, spellID)
        if ok and type(usable) == "boolean" then
            return usable, "IsUsableSpell"
        end
    end
    return nil, "none"
end

--- Single-path cooldown evaluation for mentor hints (duration-only; no GCD/remaining branches).
--- @param spellID number
--- @param opts table|nil reserved (skipCache ignored; one evaluation only)
--- @return boolean ready
--- @return boolean conclusive
--- @return table detail
function AM:EvaluateSpellCooldownReady(spellID, opts)
    local detail = {
        apiPath = "none",
        ready = true,
        conclusive = false,
        compareDurationNum = nil,
        durationNum = nil,
        durationDisplay = nil,
        threshold = SPELL_CD_MIN_DURATION,
        startDisplay = nil,
        durationNormalized = false,
        isOnGCD = nil,
        branch = nil,
        note = nil,
    }

    local ok = pcall(function()
        local startRaw, durationRaw = ReadCooldownRaw(spellID, detail)

        if startRaw ~= nil then
            local startNum = SafePlainNumber(startRaw)
            if startNum ~= nil then
                detail.startDisplay = string.format("%.2f", startNum)
            else
                detail.startDisplay = SafeFormatNumber(startRaw)
            end
        end

        local durationNum = SafePlainNumber(durationRaw)
        if durationNum ~= nil then
            detail.compareDurationNum = durationNum
            detail.durationNum = durationNum
            detail.durationDisplay = string.format("%.2f", durationNum)
            detail.durationNormalized = true

            local durGtMin = SafeGreater(durationNum, SPELL_CD_MIN_DURATION)
            if durGtMin == true then
                detail.ready = false
                detail.conclusive = true
                detail.branch = "durationNum>threshold"
                detail.note = "duration indicates cooldown"
            elseif durGtMin == false then
                detail.ready = true
                detail.conclusive = true
                detail.branch = "durationNum<=threshold"
                detail.note = "duration<=1.5 (gcd/ready)"
            else
                detail.ready = true
                detail.conclusive = false
                detail.branch = "durationCompareFailOpen"
                detail.note = "cooldown comparison failed, fail open"
            end
        else
            detail.ready = true
            detail.conclusive = false
            detail.branch = "noDurationNumFailOpen"
            detail.note = "cooldown unreadable, fail open"
            detail.durationNormalized = false
        end

        if AM.DEBUG_COOLDOWNS then
            local assertOk, inconsistent = pcall(function()
                return detail.compareDurationNum ~= nil
                    and detail.compareDurationNum > SPELL_CD_MIN_DURATION
                    and detail.ready == true
            end)
            if assertOk and inconsistent then
                print(
                    "[Azeroth Mentor] COOLDOWN BUG: duration > threshold but ready=true",
                    spellID,
                    "branch=",
                    tostring(detail.branch)
                )
            end
        end
    end)

    if not ok then
        detail.ready = true
        detail.conclusive = false
        detail.branch = "evalErrorFailOpen"
        detail.note = "cooldown evaluation error, fail open"
    end

    return detail.ready, detail.conclusive, detail
end

--- True when the spell is known and not obviously on cooldown / unusable (beginner-facing; not rotation math).
--- Uses the same single-path EvaluateSpellCooldownReady result as /am cooldowns.
--- @param spellID number|nil
--- @param opts table|nil optional `{ skipCache = true }` (cache no longer used; kept for API compat)
--- @return boolean
function AM:IsSpellReady(spellID, opts)
    if spellID == nil then
        return false
    end

    local ok, ready = pcall(function()
        if not self:IsSpellKnownSafe(spellID) then
            return false
        end

        local cdReady, conclusive = self:EvaluateSpellCooldownReady(spellID, opts)
        if conclusive == true then
            if cdReady == false then
                return false
            end
            local usable, _ = EvaluateSpellUsable(spellID)
            if usable == false then
                return false
            end
            return true
        end

        local usable, _ = EvaluateSpellUsable(spellID)
        if usable == false then
            return false
        end
        return true
    end)

    if not ok then
        return true
    end
    return ready == true
end

local COOLDOWN_REPORT_SPELLS = {
    { 184575, "BoJ", "Blade of Justice" },
    { 20271, "Judgment", "Judgment" },
    { 35395, "CS", "Crusader Strike" },
    { 383328, "FV", "Final Verdict" },
    { 85256, "TV", "Templar's Verdict" },
}

--- @param spellID number
--- @param shortLabel string
--- @param verbose boolean
--- @return string|nil
function AM:FormatCooldownSpellLine(spellID, shortLabel, verbose)
    local lineOk, line = pcall(function()
        local name = self:GetSpellDisplayInfo(spellID)
        local known = self:IsSpellKnownSafe(spellID)
        local cdReady, conclusive, detail = self:EvaluateSpellCooldownReady(spellID, { skipCache = true })
        local isReady = cdReady == true
        if conclusive ~= true then
            isReady = true
        elseif cdReady == false then
            isReady = false
        else
            local usable, _ = EvaluateSpellUsable(spellID)
            if usable == false then
                isReady = false
            end
        end
        local usable, usePath = EvaluateSpellUsable(spellID)

        if not verbose then
            local durNorm = detail.durationNormalized == true and "true" or "false"
            local function fmtPlainNum(val)
                if val == nil then
                    return "nil"
                end
                local numOk, numText = pcall(function()
                    return string.format("%.2f", val)
                end)
                return numOk and numText or "unreadable"
            end
            local thresholdText = fmtPlainNum(detail.threshold or SPELL_CD_MIN_DURATION)
            return string.format(
                "  %-3s %-22s (%d)  ready=%-5s known=%-5s usable=%-5s  compareDurationNum=%s durationNum=%s durationDisplay=%s threshold=%s norm=%-5s rem=%-11s gcd=%-5s  branch=%s  note=%s",
                shortLabel,
                name,
                spellID,
                tostring(isReady),
                tostring(known),
                usable == nil and "unreadable" or tostring(usable),
                fmtPlainNum(detail.compareDurationNum),
                fmtPlainNum(detail.durationNum),
                tostring(detail.durationDisplay or "nil"),
                thresholdText,
                durNorm,
                tostring(detail.remainingDisplay or "unreadable"),
                tostring(detail.isOnGCD),
                tostring(detail.branch or "-"),
                tostring(detail.note or "-")
            )
        end

        local cache = self._spellCooldownReadyCache and self._spellCooldownReadyCache[spellID]
        local cacheNote = "no cache"
        if cache then
            local ageOk, ageText = pcall(function()
                return string.format("%.2f", GetTime() - (cache.at or 0))
            end)
            cacheNote = string.format(
                "cache ready=%s conclusive=%s age=%ss note=%s",
                tostring(cache.ready),
                tostring(cache.conclusive),
                ageOk and ageText or "?",
                tostring(cache.detail and cache.detail.note)
            )
        end
        return string.format(
            "[AM cooldown] %d %s (%s) | known=%s | usable=%s path=%s | start=%s dur=%s norm=%s rem=%s | gcd=%s enabled=%s | api=%s note=%s | evalReady=%s conclusive=%s | %s | IsSpellReady=%s",
            spellID,
            shortLabel,
            tostring(name),
            tostring(known),
            tostring(usable),
            tostring(usePath),
            tostring(detail.startDisplay or "unreadable"),
            tostring(detail.durationDisplay or "unreadable"),
            detail.durationNormalized == true and "true" or "false",
            tostring(detail.remainingDisplay or "unreadable"),
            tostring(detail.isOnGCD),
            tostring(detail.isEnabled),
            tostring(detail.apiPath),
            tostring(detail.note),
            tostring(cdReady),
            tostring(conclusive),
            cacheNote,
            tostring(isReady)
        )
    end)
    if lineOk and line then
        return line
    end
    return string.format("  %-3s (%d)  print failed (secret/taint)", tostring(shortLabel), spellID)
end

--- One-shot mentor + cooldown snapshot for `/am cooldowns`.
function AM:PrintCooldownStatusReport()
    local ok = pcall(function()
        if type(self.ClearSpellCooldownCache) == "function" then
            self:ClearSpellCooldownCache()
        end

        print("[Azeroth Mentor] === Cooldown status ===")
        print("  cooldown logic: " .. tostring(self.COOLDOWN_LOGIC_VERSION or "unknown"))

        local combat = self.RetributionCombat and self.RetributionCombat.GetState and self.RetributionCombat:GetState()
        local hpText = "unreadable"
        if combat and combat.holyPowerCurrent ~= nil then
            local hpOk, hpVal = pcall(function()
                return tonumber(combat.holyPowerCurrent) or combat.holyPowerCurrent
            end)
            if hpOk and hpVal ~= nil then
                hpText = tostring(hpVal) .. "/5"
            end
        end
        print("  Holy Power: " .. hpText)

        local phase = "n/a"
        local suggestedID = nil
        local suggestedName = "none"
        local suggestedReadyText = "n/a"
        local sm = self.SpecModules and self.SpecModules.PALADIN and self.SpecModules.PALADIN.RETRIBUTION
        if sm and sm.GetCombatRecommendation then
            local rec = sm.GetCombatRecommendation({ combat = combat })
            if rec then
                phase = tostring(rec.phase or "n/a")
                suggestedID = rec.suggestedSpellID
                if suggestedID then
                    suggestedName = self:GetSpellDisplayInfo(suggestedID)
                    suggestedReadyText = tostring(self:IsSpellReady(suggestedID, { skipCache = true }))
                else
                    suggestedReadyText = "n/a (wait)"
                end
            end
        end
        print("  Phase: " .. phase)
        if suggestedID then
            print(string.format(
                "  Mentor suggests: %s (%d) — ready=%s",
                tostring(suggestedName),
                suggestedID,
                suggestedReadyText
            ))
        else
            print("  Mentor suggests: none — ready=" .. suggestedReadyText)
        end

        print("  Spells:")
        for _, row in ipairs(COOLDOWN_REPORT_SPELLS) do
            print(self:FormatCooldownSpellLine(row[1], row[2], false))
        end

        print("[Azeroth Mentor] === end (one-shot; run /am cooldowns again anytime) ===")
    end)
    if not ok then
        print("[Azeroth Mentor] Cooldown status report failed (secret/taint). Try again after /reload.")
    end
end

--- Verbose report for developers when DEBUG_COOLDOWNS is enabled (optional).
function AM:PrintCooldownDebugReport()
    local ok = pcall(function()
        print("[Azeroth Mentor] --- cooldown debug (verbose) ---")
        for _, row in ipairs(COOLDOWN_REPORT_SPELLS) do
            print(self:FormatCooldownSpellLine(row[1], row[2], true))
        end
        print("[Azeroth Mentor] --- end cooldown debug ---")
    end)
    if not ok then
        print("[Azeroth Mentor] Cooldown debug report failed (secret/taint).")
    end
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
    local pickedGeneralUnlock
    for _, sid in ipairs(newList) do
        if IsSuppressedUntrackedSpell(sid) then
            -- Parked: future Activity Unlock Lessons (e.g. Switch Flight Style, battlegrounds).
        elseif GetGeneralUnlockRow(sid) then
            pickedGeneralUnlock = sid
            break
        elseif not IsSpellInPaladinRegistry(self, sid) then
            pickedUntracked = sid
            break
        end
    end

    wipe(self.spellbookIdSnapshot)
    for sid in pairs(bookSnap) do
        self.spellbookIdSnapshot[sid] = true
    end

    if pickedGeneralUnlock then
        if type(self.GetCurrentLevelMilestone) == "function" and self:GetCurrentLevelMilestone() then
            DebugSpellDetect(
                "General unlock learn skipped (current level milestone active): " .. tostring(pickedGeneralUnlock)
            )
        else
            self._newAbilityBanner = true
            self._mentorExplainSpellID = pickedGeneralUnlock
            self._mentorExplainUntil = now + MENTOR_SPELL_FOCUS_SECONDS
            self._unknownUntrackedSpellID = nil
            self._unknownUntrackedUntil = nil
            DebugSpellDetect("General unlock spellbook learn: " .. tostring(pickedGeneralUnlock))
        end
    elseif pickedUntracked then
        -- Do not queue a generic unknown card while a current-level milestone is available (better level-up UX).
        if type(self.GetCurrentLevelMilestone) == "function" and self:GetCurrentLevelMilestone() then
            DebugSpellDetect(
                "Untracked spellbook learn skipped (current level milestone active): " .. tostring(pickedUntracked)
            )
        else
            self._unknownUntrackedSpellID = pickedUntracked
            self._unknownUntrackedUntil = now + MENTOR_SPELL_FOCUS_SECONDS
            DebugSpellDetect("Untracked spellbook learn: " .. tostring(pickedUntracked))
        end
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
        if next(newSnap) == nil then
            DebugSpellDetect("DetectNewSpells: defer snapshot seed (spellbook not ready yet).")
            self:DetectUntrackedSpellbookNewSpells()
            return {}
        end
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

    if #newIds >= TRACKED_SPELL_BULK_NEW_THRESHOLD then
        DebugSpellDetect(
            "DetectNewSpells: bulk new tracked spells (" .. #newIds .. "); reseed without spotlight."
        )
        self.pendingNewSpellIds = nil
        self:DetectUntrackedSpellbookNewSpells()
        return {}
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
        local sid = rec.suggestedSpellID
        if not sid then
            return nil
        end
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

--- Spell card priority:
--- In combat: Retribution combat mentor when available.
--- Out of combat: level milestone → mentor explain → unknown untracked (also suppressed at detect-time if a milestone is active) → latest learned spotlight → default known.
--- Spec onboarding stays in MainFrame (separate panel).
--- @param opts table|nil optional `{ skipLessonLog = true }` so diagnostic callers do not append to the lesson log.
--- @return table|nil { spellID, tutorialKey, category, priority, name, icon }
function AM:GetSpellCardDisplayInfo(opts)
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

    -- 1) Retribution combat mentor card (only while in combat; OOC returns nil from resolver).
    if UnitAffectingCombat("player") then
        local combatFocus = self:GetRetributionMentorCombatSpellCard()
        if combatFocus then
            return FinishSpellCardDisplay(self, combatFocus, "combat_mentor", opts)
        end
    end

    -- 2) Level milestone (OOC only inside GetCurrentLevelMilestone); must beat latest-learned spotlight.
    if type(self.GetCurrentLevelMilestoneCard) == "function" then
        local milestone = self:GetCurrentLevelMilestoneCard()
        if milestone then
            return FinishSpellCardDisplay(self, milestone, "level_milestone", opts)
        end
    end

    local explainId = self._mentorExplainSpellID
    if explainId and self._mentorExplainUntil and now < self._mentorExplainUntil then
        if not self:IsSpellKnownSafe(explainId) then
            self._mentorExplainUntil = nil
            self._mentorExplainSpellID = nil
            self.latestLearnedSpellID = nil
        else
            local row = FindRegistryRowForSpell(self, explainId)
            if row then
                local info = BuildSpellDisplayInfo(self, row)
                if info then
                    return FinishSpellCardDisplay(self, info, "mentor_explain", opts)
                end
            end
        end
    end

    local unkId = self._unknownUntrackedSpellID
    local unkUntil = self._unknownUntrackedUntil
    if unkId and unkUntil and now < unkUntil then
        if not self:IsSpellKnownSafe(unkId)
            or IsSpellInPaladinRegistry(self, unkId)
            or GetGeneralUnlockRow(unkId)
            or IsSuppressedUntrackedSpell(unkId) then
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
            }, "unknown_untracked", opts)
        end
    end

    -- Latest tracked learn after explain/unknown windows (milestone already took priority when present).
    local latest = self.latestLearnedSpellID
    if latest and self:IsSpellKnownSafe(latest) then
        local db = self.Spells and self.Spells.PALADIN
        if db then
            for _, row in ipairs(db) do
                if row and row.spellID == latest then
                    local info = BuildSpellDisplayInfo(self, row)
                    if info then
                        return FinishSpellCardDisplay(self, info, "latest_learned", opts)
                    end
                end
            end
        end
    end

    return FinishSpellCardDisplay(self, self:GetFirstKnownClassSpell(), "first_known", opts)
end

--------------------------------------------------------------------------------
-- Default spell card (highest beginner priority among known registry spells)
--------------------------------------------------------------------------------
--- Out-of-combat Retribution: rotate among core builders so the default Mentor Tip is not always Crusader Strike.
local RET_OOC_BUILDER_TIP_ROTATION_SECONDS = 30
local RET_OOC_BUILDER_SPELL_ORDER = {
    20271, -- Judgment
    184575, -- Blade of Justice
    35395, -- Crusader Strike
}

--- @param self AM
--- @param db table
--- @return table|nil
local function GetRetributionOocRotatingBuilderCard(self, db)
    local candidates = {}
    for _, sid in ipairs(RET_OOC_BUILDER_SPELL_ORDER) do
        for _, row in ipairs(db) do
            if row and row.spellID == sid then
                local info = BuildSpellDisplayInfo(self, row)
                if info then
                    candidates[#candidates + 1] = info
                end
                break
            end
        end
    end
    if #candidates == 0 then
        return nil
    end
    if #candidates == 1 then
        return candidates[1]
    end
    local t = math.floor((GetTime() or 0) / RET_OOC_BUILDER_TIP_ROTATION_SECONDS)
    local idx = (t % #candidates) + 1
    return candidates[idx]
end

--- Returns one display-ready Paladin registry spell: the **known** spell with the highest `priority` value.
--- Ties on `priority`: the earlier row in AM.Spells.PALADIN wins (deterministic).
--- Retribution + out of combat: prefers a simple time-rotated pick among Judgment / Blade of Justice / Crusader Strike
--- when those rows are known (educational variety; not a rotation engine). In combat or other specs: priority only.
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

    if GetPlayerSpecializationId() == SPEC_ID_RETRIBUTION_PALADIN and not UnitAffectingCombat("player") then
        local rotated = GetRetributionOocRotatingBuilderCard(self, db)
        if rotated then
            return rotated
        end
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
