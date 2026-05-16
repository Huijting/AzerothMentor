--[[
  Azeroth Mentor - small "lesson available" toast when the main frame is closed.
  Notifies for level milestones, new spell spotlight / mentor explain, and unknown abilities.
]]

local AM = _G.AM
local L = AM.L

AM._lessonToastAcknowledgedKeys = AM._lessonToastAcknowledgedKeys or {}
AM._lessonToastPending = AM._lessonToastPending or false
AM._lessonToastActiveKey = AM._lessonToastActiveKey or nil
AM._suppressNextLessonToastCheck = AM._suppressNextLessonToastCheck or false

local function ToastDebug(msg)
    if AM.DEBUG_LESSON_TOAST then
        print("|cffaaaaff[Azeroth Mentor][Toast]|r " .. tostring(msg))
    end
end

--- Stable toast key string (milestone:/spell:/unknown:).
--- @param key string|nil
--- @return string|nil
function AM:NormalizeLessonToastKey(key)
    if key == nil then
        return nil
    end
    key = tostring(key)
    if key == "" then
        return nil
    end
    return key
end

--- Never replace the SavedVariables root table; only ensure subtables exist.
--- @return table AzerothMentorDB.lessonToastAcknowledgedKeys
function AM:EnsureLessonToastAckDB()
    if AzerothMentorDB == nil then
        AzerothMentorDB = {}
    end
    _G.AzerothMentorDB = AzerothMentorDB

    if type(AzerothMentorDB.lessonToastAcknowledgedKeys) ~= "table" then
        AzerothMentorDB.lessonToastAcknowledgedKeys = {}
    end

    self._lessonToastAcknowledgedKeys = self._lessonToastAcknowledgedKeys or {}
    return AzerothMentorDB.lessonToastAcknowledgedKeys
end

--- Copy persisted acknowledgements into the session cache (after /reload).
function AM:SyncLessonToastAckFromDB()
    local db = self:EnsureLessonToastAckDB()
    local n = 0
    for k, v in pairs(db) do
        if v then
            self._lessonToastAcknowledgedKeys[k] = true
            n = n + 1
        end
    end
    ToastDebug(string.format("SyncLessonToastAckFromDB: %d key(s) loaded from SavedVariables", n))
end

function AM:AcknowledgeLessonToast(key)
    key = self:NormalizeLessonToastKey(key)
    if not key then
        return
    end
    local db = self:EnsureLessonToastAckDB()
    self._lessonToastAcknowledgedKeys[key] = true
    db[key] = true
    ToastDebug(
        string.format(
            "AcknowledgeLessonToast key=%s session=%s db=%s",
            key,
            tostring(self._lessonToastAcknowledgedKeys[key]),
            tostring(db[key])
        )
    )
end

function AM:IsLessonToastAcknowledged(key)
    key = self:NormalizeLessonToastKey(key)
    if not key then
        return false
    end
    local db = self:EnsureLessonToastAckDB()
    local sessionAck = self._lessonToastAcknowledgedKeys[key] and true or false
    local dbAck = db[key] and true or false
    return sessionAck or dbAck
end

function AM:ResetLessonToastAcknowledgements()
    self:EnsureLessonToastAckDB()
    wipe(self._lessonToastAcknowledgedKeys)
    wipe(AzerothMentorDB.lessonToastAcknowledgedKeys)
    self._suppressNextLessonToastCheck = false
    AzerothMentorDB.suppressNextLessonToastOnLoad = nil
    ToastDebug("ResetLessonToastAcknowledgements: session + DB cleared")
end

--- After LEVEL_MILESTONE Got it, skip one toast check so fallback spell cards do not toast immediately.
--- @param persistForReload boolean|nil when true, survives /reload (one consume on next check)
function AM:SuppressNextLessonToastCheck(persistForReload)
    self._suppressNextLessonToastCheck = true
    if persistForReload then
        self:EnsureLessonToastAckDB()
        AzerothMentorDB.suppressNextLessonToastOnLoad = true
    end
    ToastDebug(
        "SuppressNextLessonToastCheck set"
            .. (persistForReload and " (persist for reload)" or " (session only)")
    )
end

--- @return boolean true if a suppress flag was consumed (caller should skip showing toast)
function AM:ConsumeLessonToastSuppress()
    if self._suppressNextLessonToastCheck then
        self._suppressNextLessonToastCheck = false
        ToastDebug("ConsumeLessonToastSuppress: session flag consumed")
        return true
    end
    self:EnsureLessonToastAckDB()
    if AzerothMentorDB.suppressNextLessonToastOnLoad then
        AzerothMentorDB.suppressNextLessonToastOnLoad = nil
        ToastDebug("ConsumeLessonToastSuppress: reload flag consumed")
        return true
    end
    return false
end

function AM:PrintLessonToastStatus()
    self:EnsureLessonToastAckDB()
    local db = AzerothMentorDB.lessonToastAcknowledgedKeys

    local active = self._lessonToastActiveKey or "(none)"
    local cardKey = "(none)"
    local cardSource = "(none)"
    local toastEligible = false
    if type(self.GetSpellCardDisplayInfo) == "function" and type(self.BuildLessonToastKey) == "function" then
        local ok, card = pcall(self.GetSpellCardDisplayInfo, self, { skipLessonLog = true })
        if ok and card then
            cardSource = tostring(card.cardSource or card.type or "?")
            toastEligible = self:IsLessonToastEligibleCard(card)
            cardKey = self:BuildLessonToastKey(card) or "(none)"
        elseif not ok then
            cardKey = "(error)"
        end
    end

    local checkKey = self._lessonToastActiveKey
    if not checkKey or checkKey == "" then
        checkKey = (cardKey ~= "(none)" and cardKey ~= "(error)") and cardKey or nil
    end

    print("[Azeroth Mentor] Lesson toast status:")
    print("  active toast key: " .. tostring(active))
    print("  current card source: " .. tostring(cardSource))
    print("  current card toast eligible: " .. tostring(toastEligible))
    print("  current card key: " .. tostring(cardKey))
    local explainId = self._mentorExplainSpellID
    local explainUntil = self._mentorExplainUntil
    local spotlightActive = false
    if explainId and explainUntil and type(self.IsActiveMentorExplainSpotlight) == "function" then
        spotlightActive = self:IsActiveMentorExplainSpotlight(explainId)
    end
    print(
        string.format(
            "  explain spotlight: spellID=%s active=%s until=%s",
            tostring(explainId or "nil"),
            tostring(spotlightActive),
            tostring(explainUntil or "nil")
        )
    )
    if checkKey then
        local sessionAck = self._lessonToastAcknowledgedKeys[checkKey] and true or false
        local dbAck = db[checkKey] and true or false
        print("  check key: " .. tostring(checkKey))
        print("  session acknowledged: " .. tostring(sessionAck))
        print("  DB acknowledged: " .. tostring(dbAck))
        print("  IsLessonToastAcknowledged: " .. tostring(self:IsLessonToastAcknowledged(checkKey)))
    else
        print("  check key: (none)")
    end

    local dbCount = 0
    for k, v in pairs(db) do
        if v then
            dbCount = dbCount + 1
        end
    end
    print("  DB ack count: " .. tostring(dbCount))
    print("  session suppress next check: " .. tostring(self._suppressNextLessonToastCheck and true or false))
    print(
        "  DB suppress on load: "
            .. tostring(AzerothMentorDB.suppressNextLessonToastOnLoad and true or false)
    )
end

local TOAST_WIDTH = 220
local TOAST_MIN_HEIGHT = 52

local toastFrame
local toastClickBtn
local toastTitle
local toastSubtitle
local toastCloseBtn

local function GetMainFrame()
    return AM.mainFrame or _G.AzerothMentorFrame
end

function AM:IsMainFrameShown()
    local f = GetMainFrame()
    return f and f:IsShown() or false
end

function AM:OpenMentorFromLessonToast()
    if self._lessonToastActiveKey then
        self:AcknowledgeLessonToast(self._lessonToastActiveKey)
    end
    self:HideLessonToast()
    local f = GetMainFrame()
    if f then
        f:Show()
    end
    if type(self.UpdateMainFrame) == "function" then
        self:UpdateMainFrame({ skipDetect = true })
    end
end

--- @param cardInfo table|nil from GetSpellCardDisplayInfo (uses cardSource / toastEligible from Spells.lua)
--- @return string|nil toast dedupe key
function AM:BuildLessonToastKey(cardInfo)
    if not cardInfo or cardInfo.isRetCombatMentorFocus or not cardInfo.toastEligible then
        return nil
    end
    local source = cardInfo.cardSource
    if source == "level_milestone" and cardInfo.type == "LEVEL_MILESTONE" and cardInfo.milestoneKey then
        return self:NormalizeLessonToastKey("milestone:" .. tostring(cardInfo.milestoneKey))
    end
    if source == "unknown_untracked" and cardInfo.isUnknownUntracked and cardInfo.spellID then
        return self:NormalizeLessonToastKey("unknown:" .. tostring(cardInfo.spellID))
    end
    if (source == "mentor_explain" or source == "latest_learned") and cardInfo.spellID then
        if type(self.IsActiveMentorExplainSpotlight) == "function" and not self:IsActiveMentorExplainSpotlight(cardInfo.spellID) then
            return nil
        end
        return self:NormalizeLessonToastKey("spell:" .. tostring(cardInfo.spellID))
    end
    return nil
end

function AM:IsLessonToastEligibleCard(cardInfo)
    if not cardInfo or cardInfo.isRetCombatMentorFocus then
        return false
    end
    if cardInfo.toastEligible == true then
        return true
    end
    return self:BuildLessonToastKey(cardInfo) ~= nil
end

function AM:HideLessonToast()
    AM._lessonToastActiveKey = nil
    if toastFrame then
        toastFrame:Hide()
    end
end

--- @param key string dedupe key (milestone:/spell:/unknown:)
--- @param title string|nil
--- @param subtitle string|nil
function AM:ShowLessonToast(key, title, subtitle)
    key = self:NormalizeLessonToastKey(key)
    if not key then
        self:HideLessonToast()
        return
    end
    if self:IsLessonToastAcknowledged(key) then
        ToastDebug("ShowLessonToast skipped (acknowledged): " .. key)
        return
    end

    if not toastFrame then
        toastFrame = CreateFrame("Frame", "AzerothMentorLessonToast", UIParent, "BackdropTemplate")
        toastFrame:SetSize(TOAST_WIDTH, TOAST_MIN_HEIGHT)
        toastFrame:ClearAllPoints()
        toastFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
        toastFrame:SetFrameStrata("TOOLTIP")
        toastFrame:SetFrameLevel(100)
        toastFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        toastFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
        toastFrame:SetBackdropBorderColor(0.75, 0.65, 0.25, 0.9)

        toastClickBtn = CreateFrame("Button", nil, toastFrame)
        toastClickBtn:SetAllPoints()
        toastClickBtn:RegisterForClicks("LeftButtonUp")
        toastClickBtn:SetScript("OnClick", function()
            AM:OpenMentorFromLessonToast()
        end)
        toastClickBtn:SetScript("OnEnter", function()
            if toastFrame then
                toastFrame:SetBackdropBorderColor(0.95, 0.82, 0.35, 1)
            end
        end)
        toastClickBtn:SetScript("OnLeave", function()
            if toastFrame then
                toastFrame:SetBackdropBorderColor(0.75, 0.65, 0.25, 0.9)
            end
        end)

        toastTitle = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        toastTitle:SetPoint("TOPLEFT", toastFrame, "TOPLEFT", 10, -10)
        toastTitle:SetPoint("TOPRIGHT", toastFrame, "TOPRIGHT", -28, -10)
        toastTitle:SetJustifyH("LEFT")
        toastTitle:SetWordWrap(true)

        toastSubtitle = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        toastSubtitle:SetPoint("TOPLEFT", toastTitle, "BOTTOMLEFT", 0, -4)
        toastSubtitle:SetPoint("RIGHT", toastTitle, "RIGHT", 0, 0)
        toastSubtitle:SetJustifyH("LEFT")
        toastSubtitle:SetWordWrap(true)
        toastSubtitle:SetTextColor(0.72, 0.78, 0.9)

        toastCloseBtn = CreateFrame("Button", nil, toastFrame)
        toastCloseBtn:SetSize(18, 18)
        toastCloseBtn:SetPoint("TOPRIGHT", toastFrame, "TOPRIGHT", -6, -6)
        toastCloseBtn:SetFrameLevel(toastFrame:GetFrameLevel() + 4)
        toastCloseBtn:SetNormalFontObject("GameFontHighlightSmall")
        toastCloseBtn:SetHighlightFontObject("GameFontHighlightSmall")
        toastCloseBtn:SetText("X")
        toastCloseBtn:SetScript("OnClick", function()
            if AM._lessonToastActiveKey then
                AM:AcknowledgeLessonToast(AM._lessonToastActiveKey)
            end
            AM:HideLessonToast()
        end)
    end

    title = title or L["LESSON_TOAST_TITLE"] or "New lesson available"
    subtitle = subtitle or L["LESSON_TOAST_SUBTITLE"] or "Click to open Azeroth Mentor"

    toastTitle:SetText(title)
    toastSubtitle:SetText(subtitle)

    local titleH = toastTitle:GetStringHeight() or 12
    local subH = toastSubtitle:GetStringHeight() or 12
    local h = math.max(TOAST_MIN_HEIGHT, 10 + titleH + 4 + subH + 10)
    toastFrame:SetHeight(h)

    AM._lessonToastActiveKey = key
    toastFrame:Show()
    ToastDebug("ShowLessonToast shown: " .. key)
end

--- @param cardInfo table|nil optional; if omitted, resolves via GetSpellCardDisplayInfo (no lesson log).
function AM:MaybeShowLessonToastForCurrentCard(cardInfo)
    self:EnsureLessonToastAckDB()

    if not cardInfo and type(self.GetSpellCardDisplayInfo) == "function" then
        local ok, info = pcall(self.GetSpellCardDisplayInfo, self, { skipLessonLog = true })
        if ok then
            cardInfo = info
        end
    end

    if self:ConsumeLessonToastSuppress() then
        self:HideLessonToast()
        local wouldKey = self:BuildLessonToastKey(cardInfo)
        ToastDebug(
            "MaybeShowLessonToast skipped (post-milestone suppress)"
                .. (wouldKey and ("; fallback key would be " .. wouldKey) or "")
        )
        return
    end

    if self:IsMainFrameShown() then
        self:HideLessonToast()
        self._lessonToastPending = false
        ToastDebug("MaybeShowLessonToast skipped (main frame open)")
        return
    end

    if UnitAffectingCombat("player") then
        self._lessonToastPending = true
        self:HideLessonToast()
        ToastDebug("MaybeShowLessonToast deferred (combat)")
        return
    end

    self._lessonToastPending = false

    if not self:IsLessonToastEligibleCard(cardInfo) then
        self:HideLessonToast()
        ToastDebug(
            string.format(
                "MaybeShowLessonToast skipped (card not toast-eligible; source=%s)",
                tostring(cardInfo and cardInfo.cardSource or "?")
            )
        )
        return
    end

    local key = self:BuildLessonToastKey(cardInfo)
    if not key then
        self:HideLessonToast()
        ToastDebug("MaybeShowLessonToast skipped (no toast key for current card)")
        return
    end

    local db = AzerothMentorDB.lessonToastAcknowledgedKeys
    local sessionAck = self._lessonToastAcknowledgedKeys[key] and true or false
    local dbAck = db[key] and true or false

    if self:IsLessonToastAcknowledged(key) then
        ToastDebug(
            string.format(
                "MaybeShowLessonToast skipped key=%s sessionAck=%s dbAck=%s",
                key,
                tostring(sessionAck),
                tostring(dbAck)
            )
        )
        return
    end

    ToastDebug(
        string.format(
            "MaybeShowLessonToast showing key=%s sessionAck=%s dbAck=%s",
            key,
            tostring(sessionAck),
            tostring(dbAck)
        )
    )
    self:ShowLessonToast(key, L["LESSON_TOAST_TITLE"], L["LESSON_TOAST_SUBTITLE"])
end

local toastEventFrame = CreateFrame("Frame", nil, UIParent)
toastEventFrame:RegisterEvent("ADDON_LOADED")
toastEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
toastEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == AM.name then
            if type(AM.SyncLessonToastAckFromDB) == "function" then
                AM:SyncLessonToastAckFromDB()
            elseif type(AM.EnsureLessonToastAckDB) == "function" then
                AM:EnsureLessonToastAckDB()
            end
        end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and AM._lessonToastPending then
        AM:MaybeShowLessonToastForCurrentCard()
    end
end)
