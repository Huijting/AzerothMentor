--[[
  Azeroth Mentor - small "lesson available" toast when the main frame is closed.
  Notifies for level milestones, new spell spotlight / mentor explain, and unknown abilities.
]]

local AM = _G.AM
local L = AM.L

AM._lessonToastAcknowledgedKeys = AM._lessonToastAcknowledgedKeys or {}
AM._lessonToastPending = AM._lessonToastPending or false
AM._lessonToastActiveKey = AM._lessonToastActiveKey or nil

--- @return table AzerothMentorDB.lessonToastAcknowledgedKeys
function AM:EnsureLessonToastAckDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    if type(AzerothMentorDB.lessonToastAcknowledgedKeys) ~= "table" then
        AzerothMentorDB.lessonToastAcknowledgedKeys = {}
    end
    self._lessonToastAcknowledgedKeys = self._lessonToastAcknowledgedKeys or {}
    return AzerothMentorDB.lessonToastAcknowledgedKeys
end

function AM:AcknowledgeLessonToast(key)
    if not key or key == "" then
        return
    end
    local db = self:EnsureLessonToastAckDB()
    self._lessonToastAcknowledgedKeys[key] = true
    db[key] = true
end

function AM:IsLessonToastAcknowledged(key)
    if not key or key == "" then
        return false
    end
    local db = self:EnsureLessonToastAckDB()
    if self._lessonToastAcknowledgedKeys[key] or db[key] then
        return true
    end
    return false
end

function AM:ResetLessonToastAcknowledgements()
    self:EnsureLessonToastAckDB()
    wipe(self._lessonToastAcknowledgedKeys)
    wipe(AzerothMentorDB.lessonToastAcknowledgedKeys)
end

function AM:PrintLessonToastStatus()
    local active = self._lessonToastActiveKey or "(none)"
    local cardKey
    if type(self.GetSpellCardDisplayInfo) == "function" and type(self.BuildLessonToastKey) == "function" then
        local ok, card = pcall(self.GetSpellCardDisplayInfo, self, { skipLessonLog = true })
        if ok then
            cardKey = self:BuildLessonToastKey(card) or "(none)"
        else
            cardKey = "(error)"
        end
    else
        cardKey = "(n/a)"
    end
    local checkKey = self._lessonToastActiveKey or (cardKey ~= "(none)" and cardKey ~= "(error)" and cardKey ~= "(n/a)" and cardKey)
    local ackStr = "n/a"
    if checkKey then
        ackStr = tostring(self:IsLessonToastAcknowledged(checkKey))
    end
    print(
        string.format(
            "[Azeroth Mentor] toast active=%s cardKey=%s acknowledged=%s",
            tostring(active),
            tostring(cardKey),
            ackStr
        )
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

--- @param cardInfo table|nil from GetSpellCardDisplayInfo
--- @return string|nil toast dedupe key
function AM:BuildLessonToastKey(cardInfo)
    if not cardInfo or cardInfo.isRetCombatMentorFocus then
        return nil
    end
    if cardInfo.type == "LEVEL_MILESTONE" and cardInfo.milestoneKey then
        return "milestone:" .. tostring(cardInfo.milestoneKey)
    end
    if cardInfo.isUnknownUntracked and cardInfo.spellID then
        return "unknown:" .. tostring(cardInfo.spellID)
    end
    local now = GetTime()
    local explainId = self._mentorExplainSpellID
    if explainId and self._mentorExplainUntil and now < self._mentorExplainUntil and cardInfo.spellID == explainId then
        return "spell:" .. tostring(cardInfo.spellID)
    end
    local latest = self.latestLearnedSpellID
    if latest and cardInfo.spellID == latest then
        return "spell:" .. tostring(cardInfo.spellID)
    end
    return nil
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
    if not key or key == "" then
        self:HideLessonToast()
        return
    end
    if self:IsLessonToastAcknowledged(key) then
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
end

--- @param cardInfo table|nil optional; if omitted, resolves via GetSpellCardDisplayInfo (no lesson log).
function AM:MaybeShowLessonToastForCurrentCard(cardInfo)
    if self:IsMainFrameShown() then
        self:HideLessonToast()
        self._lessonToastPending = false
        return
    end

    if UnitAffectingCombat("player") then
        self._lessonToastPending = true
        self:HideLessonToast()
        return
    end

    self._lessonToastPending = false

    if not cardInfo and type(self.GetSpellCardDisplayInfo) == "function" then
        local ok, info = pcall(self.GetSpellCardDisplayInfo, self, { skipLessonLog = true })
        if ok then
            cardInfo = info
        end
    end

    local key = self:BuildLessonToastKey(cardInfo)
    if not key then
        self:HideLessonToast()
        return
    end

    if self:IsLessonToastAcknowledged(key) then
        return
    end

    self:ShowLessonToast(key, L["LESSON_TOAST_TITLE"], L["LESSON_TOAST_SUBTITLE"])
end

local toastEventFrame = CreateFrame("Frame", nil, UIParent)
toastEventFrame:RegisterEvent("ADDON_LOADED")
toastEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
toastEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == AM.name and type(AM.EnsureLessonToastAckDB) == "function" then
            AM:EnsureLessonToastAckDB()
        end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and AM._lessonToastPending then
        AM:MaybeShowLessonToastForCurrentCard()
    end
end)
