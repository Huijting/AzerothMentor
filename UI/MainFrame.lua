--[[
  Azeroth Mentor - main panel UI
  Frame chrome, text regions, slash toggle, and ESC (UISpecialFrames) wiring.
]]

local AM = _G.AM
local L = AM.L

--------------------------------------------------------------------------------
-- UI scale (Ctrl + mousewheel on the main frame; /am scale reset)
--------------------------------------------------------------------------------
local SCALE_MIN = 0.75
local SCALE_MAX = 1.75
local SCALE_STEP = 0.05

--- Snap to the nearest 0.05 step to avoid float drift after repeated adjustments.
local function QuantizeScale(value)
    return math.floor(value / SCALE_STEP + 0.5) * SCALE_STEP
end

local function ClampScale(value)
    return math.max(SCALE_MIN, math.min(SCALE_MAX, QuantizeScale(value)))
end

local function PrintUIScale(scale)
    print(string.format("[Azeroth Mentor] UI Scale: %.2f", scale))
end

--------------------------------------------------------------------------------
-- Main panel frame (global name for UISpecialFrames and /run access)
--------------------------------------------------------------------------------
local AzerothMentorFrame = CreateFrame("Frame", "AzerothMentorFrame", UIParent, "BackdropTemplate")

AzerothMentorFrame:SetSize(360, 498)
AzerothMentorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
AzerothMentorFrame:SetFrameStrata("MEDIUM")
AzerothMentorFrame:SetClampedToScreen(true)

-- Initial scale (CENTER anchor keeps the panel visually centered as scale changes).
AM.db.uiScale = ClampScale(AM.db.uiScale or 1.0)
AzerothMentorFrame:SetScale(AM.db.uiScale)

-- ESC closes this panel when visible (uses global frame name "AzerothMentorFrame").
tinsert(UISpecialFrames, "AzerothMentorFrame")

-- Dark, semi-transparent fill and a 1px gold outline (thin border).
AzerothMentorFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true,
    tileSize = 8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
AzerothMentorFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.78)
AzerothMentorFrame:SetBackdropBorderColor(0.9, 0.75, 0.25, 1)

--------------------------------------------------------------------------------
-- Drag to move
--------------------------------------------------------------------------------
AzerothMentorFrame:EnableMouse(true)
AzerothMentorFrame:SetMovable(true)
AzerothMentorFrame:RegisterForDrag("LeftButton")
AzerothMentorFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
AzerothMentorFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Ctrl + mousewheel adjusts uiScale in steps (wheel alone does nothing — avoids stealing zoom).
AzerothMentorFrame:EnableMouseWheel(true)
AzerothMentorFrame:SetScript("OnMouseWheel", function(self, delta)
    if not IsControlKeyDown() then
        return
    end

    local current = ClampScale(AM.db.uiScale or 1.0)
    AM.db.uiScale = current

    local nextScale = ClampScale(current + (delta > 0 and SCALE_STEP or -SCALE_STEP))

    if nextScale ~= current then
        AM.db.uiScale = nextScale
        self:SetScale(nextScale)
        PrintUIScale(nextScale)
    end
end)

--------------------------------------------------------------------------------
-- Layout: title → player info → mentor stage → guidance → tutorial (top to bottom)
-- Content width leaves room for the close button and frame padding.
--------------------------------------------------------------------------------
local CONTENT_WIDTH = 318

local titleText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", AzerothMentorFrame, "TOP", 0, -18)
titleText:SetText(L["ADDON_TITLE"])
titleText:SetTextColor(1, 0.85, 0.45)
titleText:EnableMouse(false)

-- Top-right close: sits above the draggable parent so it receives the click first.
local closeButton = CreateFrame("Button", nil, AzerothMentorFrame)
closeButton:SetSize(26, 22)
closeButton:SetPoint("TOPRIGHT", AzerothMentorFrame, "TOPRIGHT", -6, -6)
closeButton:SetFrameLevel(AzerothMentorFrame:GetFrameLevel() + 20)
closeButton:SetNormalFontObject("GameFontHighlightSmall")
closeButton:SetHighlightFontObject("GameFontHighlightSmall")
closeButton:SetText("X")
closeButton:SetScript("OnClick", function()
    AzerothMentorFrame:Hide()
end)

-- Player summary (name, class, spec, level).
-- Future tooltips: wrap lines in clickable regions or add icon frames, then call
-- GameTooltip:SetOwner / SetText / SetUnit / SetHyperlink for talents (talent ID),
-- spells (spell:123), or items (item:123) as needed.
local playerInfoText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
playerInfoText:SetPoint("TOP", titleText, "BOTTOM", 0, -22)
playerInfoText:SetWidth(CONTENT_WIDTH)
playerInfoText:SetJustifyH("CENTER")
playerInfoText:SetJustifyV("TOP")
playerInfoText:SetWordWrap(true)
playerInfoText:SetSpacing(4)
playerInfoText:EnableMouse(false)

-- Mentor stage label (distinct from body copy below).
-- Future tooltips: if this line links to UI (e.g. Specialization UI), anchor
-- GameTooltip to a transparent button here and use SetText with shortcut hints.
local mentorStageText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mentorStageText:SetPoint("TOP", playerInfoText, "BOTTOM", 0, -22)
mentorStageText:SetWidth(CONTENT_WIDTH)
mentorStageText:SetJustifyH("CENTER")
mentorStageText:SetJustifyV("TOP")
mentorStageText:SetTextColor(1, 0.82, 0.35)
mentorStageText:EnableMouse(false)

-- Stage guidance (primary mentoring sentence).
-- Future tooltips: spell names in this string could become |cff link hooks; on Enter,
-- GameTooltip:SetSpellByID / Show() — same pattern for item links (itemID) or talent rows.
local guidanceText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
guidanceText:SetPoint("TOP", mentorStageText, "BOTTOM", 0, -14)
guidanceText:SetWidth(CONTENT_WIDTH)
guidanceText:SetJustifyH("CENTER")
guidanceText:SetJustifyV("TOP")
guidanceText:SetWordWrap(true)
guidanceText:SetSpacing(3)
guidanceText:EnableMouse(false)

-- Tutorial tips (short actionable line at the bottom of the stack).
-- Future tooltips: ideal place for “see also” spell/talent/item refs — e.g. invisible
-- overlay buttons per token, OnEnter → GameTooltip:SetSpellByID / SetItemByID / SetTalent.
local tutorialText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Small")
tutorialText:SetPoint("TOP", guidanceText, "BOTTOM", 0, -18)
tutorialText:SetWidth(CONTENT_WIDTH)
tutorialText:SetJustifyH("CENTER")
tutorialText:SetJustifyV("TOP")
tutorialText:SetWordWrap(true)
tutorialText:SetSpacing(2)
tutorialText:SetTextColor(0.55, 0.58, 0.62)
tutorialText:EnableMouse(false)

-- Level-up banner (PLAYER_LEVEL_UP). Sits above the spell card; not cleared by normal refreshes.
local levelUpText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelUpText:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
levelUpText:SetWidth(CONTENT_WIDTH)
levelUpText:SetJustifyH("CENTER")
levelUpText:SetJustifyV("TOP")
levelUpText:SetWordWrap(true)
levelUpText:SetSpacing(4)
levelUpText:SetTextColor(0.45, 0.95, 0.55)
levelUpText:SetText("")
levelUpText:EnableMouse(false)

-- Headline when DetectNewSpells reports a new tracked ability (one refresh; see Core/Spells.lua).
local spellCardLabel = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
spellCardLabel:SetWidth(CONTENT_WIDTH)
spellCardLabel:SetJustifyH("CENTER")
spellCardLabel:SetJustifyV("TOP")
spellCardLabel:SetTextColor(0.45, 0.95, 0.55)
spellCardLabel:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
spellCardLabel:Hide()
spellCardLabel:EnableMouse(false)

-- Spell card: latest learned tracked spell when available, else first known (Crusader Strike preferred).
-- Icon uses WoW spell art; hover shows the real GameTooltip for the spell ID.
local spellCard = CreateFrame("Frame", nil, AzerothMentorFrame)
spellCard:SetSize(CONTENT_WIDTH, 54)
spellCard:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
spellCard:SetFrameLevel(AzerothMentorFrame:GetFrameLevel() + 3)
spellCard:Hide()

local spellIconBtn = CreateFrame("Button", nil, spellCard)
spellIconBtn:SetSize(32, 32)
spellIconBtn:SetPoint("LEFT", spellCard, "LEFT", 0, 2)
spellIconBtn:SetFrameLevel(spellCard:GetFrameLevel() + 2)

local spellIconTex = spellIconBtn:CreateTexture(nil, "ARTWORK")
spellIconTex:SetAllPoints()

spellIconBtn:SetScript("OnEnter", function(self)
    if not self.spellID then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 8)
    local ok = pcall(function()
        GameTooltip:SetSpellByID(self.spellID)
    end)
    if ok then
        GameTooltip:Show()
    end
end)
spellIconBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local spellCardName = spellCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
spellCardName:SetPoint("TOPLEFT", spellIconBtn, "TOPRIGHT", 10, -2)
spellCardName:SetWidth(CONTENT_WIDTH - 46)
spellCardName:SetJustifyH("LEFT")
spellCardName:SetJustifyV("TOP")
spellCardName:SetWordWrap(true)
spellCardName:EnableMouse(false)

local spellCardTip = spellCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
spellCardTip:SetPoint("TOPLEFT", spellCardName, "BOTTOMLEFT", 0, -4)
spellCardTip:SetWidth(CONTENT_WIDTH - 46)
spellCardTip:SetJustifyH("LEFT")
spellCardTip:SetJustifyV("TOP")
spellCardTip:SetWordWrap(true)
spellCardTip:SetSpacing(2)
spellCardTip:SetTextColor(0.72, 0.78, 0.9)
spellCardTip:EnableMouse(false)

-- Newly learned tracked spell (Paladin starter kit). Shown only when a registry spell becomes known.
-- Future tooltips: wrap spell name in a Button, OnEnter → GameTooltip:SetSpellByID(spellID); OnLeave Hide().
local learnedSpellText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
learnedSpellText:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
learnedSpellText:SetWidth(CONTENT_WIDTH)
learnedSpellText:SetJustifyH("CENTER")
learnedSpellText:SetJustifyV("TOP")
learnedSpellText:SetWordWrap(true)
learnedSpellText:SetSpacing(3)
learnedSpellText:SetTextColor(0.75, 0.88, 1)
learnedSpellText:EnableMouse(false)
AM.mainFrame = AzerothMentorFrame

--------------------------------------------------------------------------------
-- Level-up banner (set from Core/Events.lua on PLAYER_LEVEL_UP)
--------------------------------------------------------------------------------
--- @param level number new player level from PLAYER_LEVEL_UP
function AM:SetLevelUpMessage(level)
    if type(level) ~= "number" or not levelUpText then
        return
    end

    local loc = AM.L
    local headline = string.format("%s %s", loc["LEVEL_UP"], string.format(loc["LEVEL_REACHED"], level))
    levelUpText:SetText(headline .. "\n\n" .. loc["NEW_TRAINING_AVAILABLE"])
end

--------------------------------------------------------------------------------
-- Main frame visibility (slash + minimap button)
--------------------------------------------------------------------------------
function AM:ToggleMainFrame()
    local f = self.mainFrame or _G.AzerothMentorFrame
    if not f then
        return
    end
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

--------------------------------------------------------------------------------
-- Slash command: /am toggles visibility; /am scale reset restores default scale
--------------------------------------------------------------------------------
SLASH_AZEROTHMENTOR1 = "/am"

SlashCmdList["AZEROTHMENTOR"] = function(msg)
    local trimmed = strtrim(msg or "")
    local lower = string.lower(trimmed)

    if lower == "scale reset" then
        AM.db.uiScale = ClampScale(1.0)
        AzerothMentorFrame:SetScale(AM.db.uiScale)
        PrintUIScale(AM.db.uiScale)
        return
    end

    AM:ToggleMainFrame()
end

--------------------------------------------------------------------------------
-- Refresh all text from AM:GetPlayerState()
--------------------------------------------------------------------------------
--- @param opts table|nil optional `{ skipDetect = true }` to refresh UI without re-running spell diff (e.g. after SPELLS_CHANGED already called DetectNewSpells).
function AM:UpdateMainFrame(opts)
    opts = opts or {}
    if not opts.skipDetect then
        self:DetectNewSpells()
    end

    local s = self:GetPlayerState()

    playerInfoText:SetText(string.format(
        "%s: %s\n%s: %s\n%s: %s\n%s: %d",
        L["LABEL_CHARACTER"],
        s.charName,
        L["LABEL_CLASS"],
        s.className,
        L["LABEL_SPEC"],
        s.specLine,
        L["LABEL_LEVEL"],
        s.level
    ))

    mentorStageText:SetText(string.format("%s: %s", L["LABEL_MENTOR_STAGE"], s.stageTitle))
    guidanceText:SetText(s.guidance)
    tutorialText:SetText(s.tutorial or "")

    local showBanner = self._newAbilityBanner
    if showBanner then
        spellCardLabel:SetText(L["NEW_ABILITY_LEARNED"])
        spellCardLabel:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
        spellCardLabel:Show()
        spellCard:ClearAllPoints()
        spellCard:SetPoint("TOP", spellCardLabel, "BOTTOM", 0, -6)
        self._newAbilityBanner = false
    else
        spellCardLabel:Hide()
        spellCard:ClearAllPoints()
        spellCard:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
    end

    local cardInfo = self:GetSpellCardDisplayInfo()
    if cardInfo then
        spellCard:Show()
        spellIconBtn.spellID = cardInfo.spellID
        local dispName, dispIcon = self:GetSpellDisplayInfo(cardInfo.spellID)
        spellIconTex:SetTexture(dispIcon)
        spellCardName:SetText(dispName)
        spellCardTip:SetText(L[cardInfo.tutorialKey])
    else
        spellCard:Hide()
        spellIconBtn.spellID = nil
    end

    learnedSpellText:ClearAllPoints()
    if cardInfo then
        learnedSpellText:SetPoint("TOP", spellCard, "BOTTOM", 0, -10)
    elseif spellCardLabel:IsShown() then
        learnedSpellText:SetPoint("TOP", spellCardLabel, "BOTTOM", 0, -6)
    else
        learnedSpellText:SetPoint("TOP", levelUpText, "BOTTOM", 0, -10)
    end

    learnedSpellText:SetText("")
    local pending = self.pendingNewSpellIds
    self.pendingNewSpellIds = nil
    if pending and #pending > 0 then
        local sid = pending[1]
        local spellName = select(1, self:GetSpellDisplayInfo(sid))
        local tutorialKey
        local db = self.Spells and self.Spells.PALADIN
        if db then
            for _, row in ipairs(db) do
                if row and row.spellID == sid then
                    tutorialKey = row.tutorialKey
                    break
                end
            end
        end
        if tutorialKey then
            learnedSpellText:SetText(string.format(
                "%s\n%s\n\n%s",
                L["SPELL_NEW_ABILITY"],
                spellName,
                L[tutorialKey]
            ))
        end
    end
end

--------------------------------------------------------------------------------
-- Visible on load (same as pre-refactor: show panel and first paint)
--------------------------------------------------------------------------------
AzerothMentorFrame:Show()
AM:UpdateMainFrame()
