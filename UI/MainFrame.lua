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

AzerothMentorFrame:SetSize(360, 620)
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
-- Layout: title → … → tutorial → (optional Ret Holy Power hint) → (optional spec onboarding) → level-up → spell card
-- Content width leaves room for the close button and frame padding.
--------------------------------------------------------------------------------
local CONTENT_WIDTH = 318
-- Spell card internal layout (icon + title + tip stay inside the backdrop).
local SPELL_CARD_PAD_LEFT = 12
local SPELL_CARD_PAD_TOP = 10
local SPELL_CARD_PAD_RIGHT = 10
local SPELL_CARD_PAD_BOTTOM = 12
local SPELL_CARD_ICON_SIZE = 32
local SPELL_CARD_ICON_GAP = 10
local SPELL_CARD_TEXT_LEFT = SPELL_CARD_PAD_LEFT + SPELL_CARD_ICON_SIZE + SPELL_CARD_ICON_GAP
local SPELL_CARD_GAP_NAME_TIP = 8
local SPELL_CARD_MIN_NORMAL = 58
local SPELL_CARD_MIN_MILESTONE = 104
local SPELL_CARD_MILESTONE_TIP_RESERVE = 104
local SPELL_CARD_MILESTONE_BTN_H = 22
local SPELL_CARD_MILESTONE_BTN_INSET = 8
-- Retribution specialization id (matches Core/Player.lua).
local SPEC_ID_RETRIBUTION_PALADIN = 70

local function SpellCardTextWidth(hasMilestoneBtn)
    local w = CONTENT_WIDTH - SPELL_CARD_TEXT_LEFT - SPELL_CARD_PAD_RIGHT
    if hasMilestoneBtn then
        w = w - SPELL_CARD_MILESTONE_TIP_RESERVE
    end
    return math.max(w, 120)
end

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

-- Retribution only: Holy Power count + beginner line (AM.RetributionCombat:GetState). Not rotation advice; threshold copy only.
local holyPowerTrainingText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
holyPowerTrainingText:SetPoint("TOP", tutorialText, "BOTTOM", 0, -10)
holyPowerTrainingText:SetWidth(CONTENT_WIDTH)
holyPowerTrainingText:SetJustifyH("CENTER")
holyPowerTrainingText:SetJustifyV("TOP")
holyPowerTrainingText:SetWordWrap(true)
holyPowerTrainingText:SetSpacing(4)
holyPowerTrainingText:SetTextColor(0.7, 0.78, 0.92)
holyPowerTrainingText:EnableMouse(false)
holyPowerTrainingText:Hide()

-- Level 10+ Paladin spec onboarding: "Choose Your Path" card (hidden once a specialization is active).
-- Level 10 is a major beginner milestone in Retail; picking a spec changes mentor stage and later module hooks.
local specOnboardFrame = CreateFrame("Frame", nil, AzerothMentorFrame, "BackdropTemplate")
specOnboardFrame:SetSize(CONTENT_WIDTH, 108)
specOnboardFrame:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
specOnboardFrame:SetFrameLevel(AzerothMentorFrame:GetFrameLevel() + 2)
specOnboardFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true,
    tileSize = 8,
    edgeSize = 1,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
specOnboardFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.75)
specOnboardFrame:SetBackdropBorderColor(0.35, 0.32, 0.22, 0.75)
specOnboardFrame:Hide()

local specOnboardTitle = specOnboardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
specOnboardTitle:SetPoint("TOPLEFT", specOnboardFrame, "TOPLEFT", 8, -8)
specOnboardTitle:SetPoint("TOPRIGHT", specOnboardFrame, "TOPRIGHT", -8, -8)
specOnboardTitle:SetJustifyH("CENTER")
specOnboardTitle:SetJustifyV("TOP")
specOnboardTitle:SetTextColor(1, 0.82, 0.35)
specOnboardTitle:EnableMouse(false)

local specOnboardBody = specOnboardFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
specOnboardBody:SetPoint("TOPLEFT", specOnboardTitle, "BOTTOMLEFT", 0, -8)
specOnboardBody:SetPoint("TOPRIGHT", specOnboardTitle, "BOTTOMRIGHT", 0, -8)
specOnboardBody:SetWidth(CONTENT_WIDTH - 20)
specOnboardBody:SetJustifyH("LEFT")
specOnboardBody:SetJustifyV("TOP")
specOnboardBody:SetWordWrap(true)
specOnboardBody:SetSpacing(4)
specOnboardBody:SetTextColor(0.78, 0.82, 0.9)
specOnboardBody:EnableMouse(false)

-- Level-up banner (PLAYER_LEVEL_UP): short in-frame echo only. Blizzard already shows the main level-up / unlock celebration;
-- this line fades quickly so we do not compete with the default UI (see SetLevelUpMessage).
local levelUpText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelUpText:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
levelUpText:SetWidth(CONTENT_WIDTH)
levelUpText:SetJustifyH("CENTER")
levelUpText:SetJustifyV("TOP")
levelUpText:SetWordWrap(true)
levelUpText:SetSpacing(4)
levelUpText:SetTextColor(0.45, 0.95, 0.55)
levelUpText:SetText("")
levelUpText:Hide()
levelUpText:EnableMouse(false)

-- Subtle label above the spell card: Azeroth Mentor explains HOW/WHY here; Blizzard handles “you learned X”.
local spellCardLabel = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Small")
spellCardLabel:SetWidth(CONTENT_WIDTH)
spellCardLabel:SetJustifyH("CENTER")
spellCardLabel:SetJustifyV("TOP")
spellCardLabel:SetTextColor(0.72, 0.76, 0.84)
spellCardLabel:SetAlpha(0.92)
spellCardLabel:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
spellCardLabel:Hide()
spellCardLabel:EnableMouse(false)

-- Spell card: mentor copy + icon (tooltip on icon). Blizzard announces unlocks; this panel teaches usage.
local spellCard = CreateFrame("Frame", nil, AzerothMentorFrame, "BackdropTemplate")
spellCard:SetSize(CONTENT_WIDTH, SPELL_CARD_MIN_NORMAL)
spellCard:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
spellCard:SetFrameLevel(AzerothMentorFrame:GetFrameLevel() + 3)
spellCard:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true,
    tileSize = 8,
    edgeSize = 1,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
spellCard:SetBackdropColor(0.04, 0.04, 0.06, 0.72)
spellCard:SetBackdropBorderColor(0.22, 0.2, 0.18, 0.65)
spellCard:Hide()

local spellIconBtn = CreateFrame("Button", nil, spellCard)
spellIconBtn:SetSize(SPELL_CARD_ICON_SIZE, SPELL_CARD_ICON_SIZE)
spellIconBtn:SetPoint("TOPLEFT", spellCard, "TOPLEFT", SPELL_CARD_PAD_LEFT, -SPELL_CARD_PAD_TOP)
spellIconBtn:SetFrameLevel(spellCard:GetFrameLevel() + 2)
spellIconBtn:EnableMouse(true)

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
spellCardName:SetPoint("TOPLEFT", spellIconBtn, "TOPRIGHT", SPELL_CARD_ICON_GAP, 0)
spellCardName:SetWidth(SpellCardTextWidth(false))
spellCardName:SetJustifyH("LEFT")
spellCardName:SetJustifyV("TOP")
spellCardName:SetWordWrap(true)
spellCardName:EnableMouse(false)

local spellCardTip = spellCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
spellCardTip:SetPoint("TOPLEFT", spellCardName, "BOTTOMLEFT", 0, -SPELL_CARD_GAP_NAME_TIP)
spellCardTip:SetWidth(SpellCardTextWidth(false))
spellCardTip:SetJustifyH("LEFT")
spellCardTip:SetJustifyV("TOP")
spellCardTip:SetWordWrap(true)
spellCardTip:SetSpacing(2)
spellCardTip:SetTextColor(0.72, 0.78, 0.9)
spellCardTip:EnableMouse(false)

local milestoneAcceptBtn = CreateFrame("Button", nil, spellCard, "UIPanelButtonTemplate")
milestoneAcceptBtn:SetSize(96, SPELL_CARD_MILESTONE_BTN_H)
milestoneAcceptBtn:SetPoint(
    "BOTTOMRIGHT",
    spellCard,
    "BOTTOMRIGHT",
    -SPELL_CARD_MILESTONE_BTN_INSET,
    SPELL_CARD_MILESTONE_BTN_INSET
)
milestoneAcceptBtn:SetFrameLevel(spellCard:GetFrameLevel() + 4)
milestoneAcceptBtn:Hide()

--- Size spell card from measured title + tip text (call after SetText / SetWidth).
local function ApplySpellCardLayout(isMilestone)
    local hasBtn = milestoneAcceptBtn:IsShown()
    local textW = SpellCardTextWidth(hasBtn)

    spellIconBtn:ClearAllPoints()
    spellIconBtn:SetPoint("TOPLEFT", spellCard, "TOPLEFT", SPELL_CARD_PAD_LEFT, -SPELL_CARD_PAD_TOP)

    spellCardName:SetWidth(textW)
    spellCardName:ClearAllPoints()
    spellCardName:SetPoint("TOPLEFT", spellIconBtn, "TOPRIGHT", SPELL_CARD_ICON_GAP, 0)

    spellCardTip:SetWidth(textW)
    spellCardTip:ClearAllPoints()
    spellCardTip:SetPoint("TOPLEFT", spellCardName, "BOTTOMLEFT", 0, -SPELL_CARD_GAP_NAME_TIP)

    local nameH = spellCardName:GetStringHeight()
    if not nameH or nameH < 1 then
        nameH = 14
    end
    local tipH = spellCardTip:GetStringHeight()
    if not tipH or tipH < 1 then
        tipH = 14
    end

    local bottomPad = SPELL_CARD_PAD_BOTTOM
    if hasBtn then
        bottomPad = bottomPad + SPELL_CARD_MILESTONE_BTN_INSET + SPELL_CARD_MILESTONE_BTN_H
    end

    local textStack = SPELL_CARD_PAD_TOP + nameH + SPELL_CARD_GAP_NAME_TIP + tipH + bottomPad
    local iconStack = SPELL_CARD_PAD_TOP + SPELL_CARD_ICON_SIZE + SPELL_CARD_PAD_BOTTOM
    local minH = isMilestone and SPELL_CARD_MIN_MILESTONE or SPELL_CARD_MIN_NORMAL
    spellCard:SetHeight(math.max(minH, textStack, iconStack))

    milestoneAcceptBtn:ClearAllPoints()
    milestoneAcceptBtn:SetPoint(
        "BOTTOMRIGHT",
        spellCard,
        "BOTTOMRIGHT",
        -SPELL_CARD_MILESTONE_BTN_INSET,
        SPELL_CARD_MILESTONE_BTN_INSET
    )
end

--- Strip default / template button art that can leave bright rings or squares after Hide (esp. after hover).
local function ClearButtonTemplateArt(btn)
    if not btn then
        return
    end
    btn:UnlockHighlight()
    pcall(function()
        btn:SetNormalTexture(nil)
    end)
    pcall(function()
        btn:SetPushedTexture(nil)
    end)
    pcall(function()
        btn:SetHighlightTexture(nil)
    end)
    pcall(function()
        btn:SetDisabledTexture(nil)
    end)
    pcall(function()
        btn:SetCheckedTexture(nil)
    end)
    local cd = btn.cooldown or btn.Cooldown
    if cd and cd.Hide then
        cd:Hide()
    end
    local mask = btn.IconMask
    if mask and mask.Hide then
        mask:Hide()
    end
end

--- When AM.DEBUG_UI_FRAMES is true, log visible textures under the main frame after each UpdateMainFrame.
function AM:DebugMentorFrameVisibleNodes()
    local root = self.mainFrame or _G.AzerothMentorFrame
    if not root then
        return
    end
    local function walk(frame, depth, path)
        if not frame or not frame.GetObjectType then
            return
        end
        local ok, isContainer = pcall(function()
            return frame:IsObjectType("Frame") or frame:IsObjectType("Button") or frame:IsObjectType("CheckButton")
        end)
        if not ok or not isContainer then
            return
        end
        local indent = string.rep("  ", depth)
        local frameShown = frame:IsShown()
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.IsObjectType and region:IsObjectType("Texture") and region:IsShown() then
                local a = region:GetAlpha() or 1
                local r, g, b = region:GetVertexColor()
                local rname = region:GetName()
                if frameShown and a > 0.01 then
                    print(
                        string.format(
                            "[Azeroth Mentor][UI] %s tex path=%s name=%s a=%.2f rgb=(%.2f,%.2f,%.2f)",
                            indent,
                            path,
                            tostring(rname),
                            a,
                            r or 0,
                            g or 0,
                            b or 0
                        )
                    )
                end
            end
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child:IsShown() then
                local cname = child.GetName and child:GetName()
                local seg = cname or child:GetObjectType() or "?"
                walk(child, depth + 1, path .. "/" .. seg)
            end
        end
    end
    print("[Azeroth Mentor][UI] --- visible texture scan (DEBUG_UI_FRAMES) ---")
    walk(root, 0, "AzerothMentorFrame")
end

--- Reset spell card widgets before applying a new card (avoids empty backdrop / stale button art after milestone → spotlight).
function AM:ClearMentorSpellCardUI()
    milestoneAcceptBtn:UnlockHighlight()
    milestoneAcceptBtn:Hide()
    milestoneAcceptBtn:SetScript("OnClick", nil)

    spellIconBtn:UnlockHighlight()
    spellIconBtn:Hide()
    ClearButtonTemplateArt(spellIconBtn)
    spellIconTex:SetTexture(nil)
    spellIconTex:SetAlpha(0)
    spellIconBtn.spellID = nil
    spellIconBtn:EnableMouse(false)

    spellCardName:SetText("")
    spellCardTip:SetText("")
    spellCardTip:SetWidth(SpellCardTextWidth(false))
    spellCard:SetHeight(SPELL_CARD_MIN_NORMAL)
    spellCard:Hide()
end

-- Optional footnote region (mentor teaching copy lives on the spell card; avoids duplicating Blizzard unlock banners).
local learnedSpellText = AzerothMentorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
learnedSpellText:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
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
local LEVEL_UP_DISPLAY_SECONDS = 8
local LEVEL_UP_FADE_SECONDS = 1.25
local levelUpBannerSeq = 0

--- @param level number new player level from PLAYER_LEVEL_UP
function AM:SetLevelUpMessage(level)
    if type(level) ~= "number" or not levelUpText then
        return
    end

    levelUpBannerSeq = levelUpBannerSeq + 1
    local seq = levelUpBannerSeq

    local loc = AM.L
    local headline = string.format("%s %s", loc["LEVEL_UP"], string.format(loc["LEVEL_REACHED"], level))
    levelUpText:SetText(headline .. "\n\n" .. loc["NEW_TRAINING_AVAILABLE"])
    levelUpText:SetAlpha(1)
    levelUpText:Show()

    C_Timer.After(LEVEL_UP_DISPLAY_SECONDS, function()
        if seq ~= levelUpBannerSeq then
            return
        end
        if levelUpText:IsShown() and UIFrameFadeOut then
            UIFrameFadeOut(levelUpText, LEVEL_UP_FADE_SECONDS, levelUpText:GetAlpha(), 0)
        elseif levelUpText:IsShown() then
            levelUpText:SetAlpha(0)
        end
    end)

    C_Timer.After(LEVEL_UP_DISPLAY_SECONDS + LEVEL_UP_FADE_SECONDS + 0.05, function()
        if seq ~= levelUpBannerSeq then
            return
        end
        levelUpText:Hide()
        levelUpText:SetText("")
        levelUpText:SetAlpha(1)
        if AzerothMentorFrame and AzerothMentorFrame:IsShown() then
            AM:UpdateMainFrame({ skipDetect = true })
        end
    end)
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
        if type(self.HideLessonToast) == "function" then
            self:HideLessonToast()
        end
    end
end

--------------------------------------------------------------------------------
-- Slash command: /am toggles visibility; dev/testing subcommands below.
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

    if lower == "retstate" then
        if AM.RetributionCombat and AM.RetributionCombat.PrintStateToChat then
            AM.RetributionCombat:PrintStateToChat()
        end
        return
    end

    if lower == "toast reset" then
        if type(AM.ResetLessonToastAcknowledgements) == "function" then
            AM:ResetLessonToastAcknowledgements()
        end
        print("Azeroth Mentor: lesson toast acknowledgements reset.")
        if type(AM.UpdateMainFrame) == "function" then
            AM:UpdateMainFrame({ skipDetect = true })
        end
        return
    end

    if lower == "toast status" then
        if type(AM.PrintLessonToastStatus) == "function" then
            AM:PrintLessonToastStatus()
        end
        return
    end

    if lower == "reset milestones" then
        if type(AM.ResetSeenMilestones) == "function" then
            AM:ResetSeenMilestones()
        end
        if type(AM.UpdateMainFrame) == "function" then
            AM:UpdateMainFrame({ skipDetect = true })
        end
        print("Azeroth Mentor: seen milestones reset.")
        return
    end

    if lower == "debug milestones" then
        AM.DEBUG_MILESTONES = not AM.DEBUG_MILESTONES
        print(string.format("[Azeroth Mentor] DEBUG_MILESTONES = %s", tostring(AM.DEBUG_MILESTONES)))
        return
    end

    if lower == "debug cards" then
        AM.DEBUG_CARD_SELECTION = not AM.DEBUG_CARD_SELECTION
        print(string.format("[Azeroth Mentor] DEBUG_CARD_SELECTION = %s", tostring(AM.DEBUG_CARD_SELECTION)))
        return
    end

    if lower == "debug lessonlog" then
        AM.DEBUG_LESSON_LOG = not AM.DEBUG_LESSON_LOG
        print(string.format("[Azeroth Mentor] DEBUG_LESSON_LOG = %s", tostring(AM.DEBUG_LESSON_LOG)))
        return
    end

    if lower == "debug toast" then
        AM.DEBUG_LESSON_TOAST = not AM.DEBUG_LESSON_TOAST
        print(string.format("[Azeroth Mentor] DEBUG_LESSON_TOAST = %s", tostring(AM.DEBUG_LESSON_TOAST)))
        return
    end

    if lower == "cooldowns" then
        if type(AM.PrintCooldownStatusReport) == "function" then
            AM:PrintCooldownStatusReport()
        end
        return
    end

    if lower == "localcds" then
        if type(AM.PrintLocalCooldownStatus) == "function" then
            AM:PrintLocalCooldownStatus()
        end
        return
    end

    if lower == "debug cooldowns" then
        AM.DEBUG_COOLDOWNS = not AM.DEBUG_COOLDOWNS
        print(string.format("[Azeroth Mentor] DEBUG_COOLDOWNS = %s (verbose debug mode)", tostring(AM.DEBUG_COOLDOWNS)))
        print("  /am cooldowns          — one-shot status report (use while testing)")
        print("  /am debug cooldowns    — toggles verbose debug flag (no auto-print)")
        if AM.DEBUG_COOLDOWNS and type(AM.PrintCooldownDebugReport) == "function" then
            print("  Tip: run /am cooldowns for a snapshot, or call verbose report manually if needed.")
        end
        return
    end

    if lower == "log clear" then
        if type(AM.ClearLessonLog) == "function" then
            AM:ClearLessonLog()
        end
        return
    end

    if lower == "log" then
        if type(AM.PrintLessonLog) == "function" then
            AM:PrintLessonLog(5)
        end
        return
    end

    if lower == "status" then
        local level = UnitLevel("player") or 0
        local _, classFile = UnitClass("player")
        classFile = classFile or "?"
        local className = classFile
        local specLine = "?"
        local specId = nil
        if type(AM.GetPlayerState) == "function" then
            local ok, st = pcall(AM.GetPlayerState, AM)
            if ok and type(st) == "table" then
                className = st.className or className
                specLine = st.specLine or specLine
                specId = st.specId
            end
        end
        local hpStr = "n/a"
        if AM.RetributionCombat and AM.RetributionCombat.GetState then
            local ok, hp = pcall(AM.RetributionCombat.GetState, AM.RetributionCombat)
            if ok and type(hp) == "table" then
                hpStr = string.format("%d / %d", tonumber(hp.holyPowerCurrent) or 0, tonumber(hp.holyPowerMax) or 0)
            end
        end
        local mileStr = "n/a"
        local mileWasNo = false
        if type(AM.GetCurrentLevelMilestone) == "function" then
            local ok, m = pcall(AM.GetCurrentLevelMilestone, AM)
            if ok and type(m) == "table" and m.milestoneKey then
                mileStr = string.format("yes (%s)", tostring(m.milestoneKey))
            elseif ok then
                mileStr = "no"
                mileWasNo = true
            end
        end
        local cardStr = "n/a"
        if type(AM.GetSpellCardDisplayInfo) == "function" then
            local ok, c = pcall(AM.GetSpellCardDisplayInfo, AM, { skipLessonLog = true })
            if ok and type(c) == "table" then
                local ty = c.type or "spell"
                local title = c.title or c.name or c.tutorialKey or "?"
                cardStr = string.format("%s | %s", tostring(ty), tostring(title))
            elseif ok then
                cardStr = "(nil)"
            end
        end
        print(string.format("[Azeroth Mentor] status: level=%d class=%s (%s) spec=%s (%s) holyPower=%s milestone=%s card=%s", level, tostring(className), classFile, tostring(specLine), tostring(specId or "?"), hpStr, mileStr, cardStr))
        if mileWasNo and AM.DEBUG_MILESTONES and type(AM.GetLevelMilestoneDebugReason) == "function" then
            local okR, r = pcall(AM.GetLevelMilestoneDebugReason, AM)
            if okR and type(r) == "string" and r ~= "" then
                print("[Azeroth Mentor] milestone detail: " .. r)
            end
        end
        return
    end

    if lower == "xpbar show" then
        if type(AM.XPBarShow) == "function" then
            AM:XPBarShow()
        end
        return
    end

    if lower == "xpbar hide" then
        if type(AM.XPBarHide) == "function" then
            AM:XPBarHide()
        end
        return
    end

    if lower == "xpbar lock" then
        if type(AM.XPBarSetLocked) == "function" then
            AM:XPBarSetLocked(true)
        end
        return
    end

    if lower == "xpbar unlock" then
        if type(AM.XPBarSetLocked) == "function" then
            AM:XPBarSetLocked(false)
        end
        return
    end

    if lower == "xpbar reset" then
        if type(AM.XPBarReset) == "function" then
            AM:XPBarReset()
        end
        return
    end

    if lower == "xpbar status" then
        if type(AM.XPBarPrintStatus) == "function" then
            AM:XPBarPrintStatus()
        end
        return
    end

    if lower == "xpbar fontsize" then
        print("[Azeroth Mentor] Usage: /am xpbar fontsize <number>  (body 8-24; chrome title uses body + 2)")
        return
    end

    if lower == "xpbar reloadbutton on" then
        if type(AM.XPBarSetReloadButtonShown) == "function" then
            AM:XPBarSetReloadButtonShown(true)
        end
        return
    end

    if lower == "xpbar reloadbutton off" then
        if type(AM.XPBarSetReloadButtonShown) == "function" then
            AM:XPBarSetReloadButtonShown(false)
        end
        return
    end

    do
        local fsArg = string.match(lower, "^xpbar fontsize%s+(.+)$")
        if fsArg then
            if type(AM.XPBarSetFontSize) == "function" then
                AM:XPBarSetFontSize(tonumber(strtrim(fsArg)))
            end
            return
        end
    end

    if lower == "xpbar scale" then
        print("[Azeroth Mentor] Usage: /am xpbar scale <number>  (allowed: 0.5 to 2.5, e.g. 1.2)")
        return
    end

    do
        local scaleArg = string.match(lower, "^xpbar scale%s+(.+)$")
        if scaleArg then
            if type(AM.XPBarSetScale) == "function" then
                AM:XPBarSetScale(tonumber(strtrim(scaleArg)))
            end
            return
        end
    end

    if lower == "combathint show" then
        if type(AM.CombatHintShow) == "function" then
            AM:CombatHintShow()
        end
        return
    end

    if lower == "combathint hide" then
        if type(AM.CombatHintHide) == "function" then
            AM:CombatHintHide()
        end
        return
    end

    if lower == "combathint lock" then
        if type(AM.CombatHintSetLocked) == "function" then
            AM:CombatHintSetLocked(true)
        end
        return
    end

    if lower == "combathint unlock" then
        if type(AM.CombatHintSetLocked) == "function" then
            AM:CombatHintSetLocked(false)
        end
        return
    end

    if lower == "combathint reset" then
        if type(AM.CombatHintReset) == "function" then
            AM:CombatHintReset()
        end
        return
    end

    if lower == "combathint scale" then
        print("[Azeroth Mentor] Usage: /am combathint scale <number>  (allowed: 0.5 to 2.5, e.g. 1.2)")
        return
    end

    do
        local chScaleArg = string.match(lower, "^combathint scale%s+(.+)$")
        if chScaleArg then
            if type(AM.CombatHintSetScale) == "function" then
                AM:CombatHintSetScale(tonumber(strtrim(chScaleArg)))
            end
            return
        end
    end

    if lower == "combathint keybinds on" then
        if type(AM.CombatHintSetShowKeybinds) == "function" then
            AM:CombatHintSetShowKeybinds(true)
        end
        return
    end

    if lower == "combathint keybinds off" then
        if type(AM.CombatHintSetShowKeybinds) == "function" then
            AM:CombatHintSetShowKeybinds(false)
        end
        return
    end

    if lower == "combathint keybinds" then
        if type(AM.CombatHintSetShowKeybinds) == "function" and type(AM.EnsureCombatHintDB) == "function" then
            local db = AM:EnsureCombatHintDB()
            AM:CombatHintSetShowKeybinds(not db.showKeybinds)
        end
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

    -- Specialization onboarding: Paladin at level 10+ with no spec yet (PLAYER_SPECIALIZATION_CHANGED clears this).
    local showSpecOnboarding = s.specOnboardingActive
    specOnboardTitle:SetText(L["SPEC_ONBOARDING_TITLE"])
    specOnboardBody:SetText(
        L["SPEC_ONBOARD_PALADIN_RETRIBUTION"]
            .. "\n\n"
            .. L["SPEC_ONBOARD_PALADIN_PROTECTION"]
            .. "\n\n"
            .. L["SPEC_ONBOARD_PALADIN_HOLY"]
    )
    local specCardH = specOnboardTitle:GetStringHeight() + specOnboardBody:GetStringHeight() + 28
    specOnboardFrame:SetHeight(math.max(100, math.min(200, specCardH)))
    if showSpecOnboarding then
        specOnboardFrame:Show()
    else
        specOnboardFrame:Hide()
    end

    -- Retribution Paladin: show Holy Power snapshot + build/spend hint (below tutorial, above spell card stack).
    local showHolyPowerTraining = false
    if s.classFile == "PALADIN" and s.specId == SPEC_ID_RETRIBUTION_PALADIN and AM.RetributionCombat and AM.RetributionCombat.GetState then
        local hpState = AM.RetributionCombat:GetState()
        local hpLine = string.format(L["RET_HOLY_POWER_LABEL"], hpState.holyPowerCurrent, hpState.holyPowerMax)
        local recMod = AM.SpecModules.PALADIN and AM.SpecModules.PALADIN.RETRIBUTION
        local rec = recMod and recMod.GetCombatRecommendation and recMod.GetCombatRecommendation({ combat = hpState })
        local line2Key = rec and rec.displayLineKey
        local line2 = (line2Key and L[line2Key]) or ""
        holyPowerTrainingText:SetText(hpLine .. "\n" .. line2)
        holyPowerTrainingText:Show()
        showHolyPowerTraining = true
    else
        holyPowerTrainingText:Hide()
    end

    levelUpText:ClearAllPoints()
    if showSpecOnboarding then
        levelUpText:SetPoint("TOP", specOnboardFrame, "BOTTOM", 0, -10)
    elseif showHolyPowerTraining then
        levelUpText:SetPoint("TOP", holyPowerTrainingText, "BOTTOM", 0, -10)
    else
        levelUpText:SetPoint("TOP", tutorialText, "BOTTOM", 0, -12)
    end

    if self._newAbilityBanner then
        self._newAbilityBanner = false
    end

    self:ClearMentorSpellCardUI()

    local cardInfo = self:GetSpellCardDisplayInfo()
    local isMilestone = cardInfo and cardInfo.type == "LEVEL_MILESTONE"

    local now = GetTime()
    local mentorExplainActive = self._mentorExplainUntil and now < self._mentorExplainUntil and self._mentorExplainSpellID
    local levelUpShown = levelUpText:IsShown() and (levelUpText:GetText() or "") ~= ""
    local latestId = self.latestLearnedSpellID
    local showMentorTipLabel = cardInfo
        and (
            isMilestone
            or (latestId and cardInfo.spellID == latestId and self:IsSpellKnownSafe(latestId))
            or (mentorExplainActive and self._mentorExplainSpellID == cardInfo.spellID)
            or cardInfo.isUnknownUntracked
            or cardInfo.isRetCombatMentorFocus
        )

    local anchorFrame, anchorPoint, anchorYOffset
    if levelUpShown then
        anchorFrame = levelUpText
        anchorPoint = "BOTTOM"
        anchorYOffset = -16
    elseif showSpecOnboarding then
        anchorFrame = specOnboardFrame
        anchorPoint = "BOTTOM"
        anchorYOffset = -10
    elseif showHolyPowerTraining then
        anchorFrame = holyPowerTrainingText
        anchorPoint = "BOTTOM"
        anchorYOffset = -10
    else
        anchorFrame = tutorialText
        anchorPoint = "BOTTOM"
        anchorYOffset = -12
    end

    if showMentorTipLabel then
        spellCardLabel:SetText(isMilestone and L["MILESTONE_TIP_LABEL"] or L["MENTOR_TIP"])
        spellCardLabel:ClearAllPoints()
        spellCardLabel:SetPoint("TOP", anchorFrame, anchorPoint, 0, anchorYOffset)
        spellCardLabel:Show()
        spellCard:ClearAllPoints()
        spellCard:SetPoint("TOP", spellCardLabel, "BOTTOM", 0, -8)
    else
        spellCardLabel:Hide()
        spellCard:ClearAllPoints()
        spellCard:SetPoint("TOP", anchorFrame, anchorPoint, 0, anchorYOffset)
    end

    if cardInfo then
        spellCard:Show()
        if cardInfo.type == "LEVEL_MILESTONE" then
            spellCardTip:SetFontObject(GameFontHighlight)
            spellCardTip:SetSpacing(4)
            local sid = cardInfo.spellID
            spellIconBtn.spellID = (sid and sid > 0) and sid or nil
            local ic = cardInfo.icon or 134400
            spellIconTex:SetTexture(ic)
            spellIconTex:SetAlpha(1)
            spellIconBtn:Show()
            spellIconBtn:EnableMouse(spellIconBtn.spellID ~= nil)
            local titleBlock = cardInfo.title or ""
            if cardInfo.subtitle and cardInfo.subtitle ~= "" then
                titleBlock = titleBlock .. "\n" .. cardInfo.subtitle
            end
            spellCardName:SetText(titleBlock)
            local tip = cardInfo.body or ""
            if cardInfo.instruction and cardInfo.instruction ~= "" then
                tip = tip .. "\n\n" .. cardInfo.instruction
            end
            spellCardTip:SetText(tip)
            milestoneAcceptBtn:SetText(cardInfo.actionText or L["MILESTONE_ACTION_GOT_IT"])
            milestoneAcceptBtn:Show()
            milestoneAcceptBtn:SetScript("OnClick", function()
                if cardInfo.onAccept then
                    cardInfo.onAccept()
                end
            end)
            ApplySpellCardLayout(true)
        else
            if showMentorTipLabel then
                spellCardTip:SetFontObject(GameFontHighlight)
                spellCardTip:SetSpacing(5)
            else
                spellCardTip:SetFontObject(GameFontHighlightSmall)
                spellCardTip:SetSpacing(2)
            end
            milestoneAcceptBtn:Hide()
            spellIconBtn.spellID = cardInfo.spellID
            local dispName, dispIcon = self:GetSpellDisplayInfo(cardInfo.spellID)
            spellIconTex:SetTexture(dispIcon)
            spellIconTex:SetAlpha(1)
            spellIconBtn:Show()
            spellIconBtn:EnableMouse(cardInfo.spellID ~= nil)
            spellCardName:SetText(dispName)
            spellCardTip:SetText(L[cardInfo.tutorialKey] or "")
            ApplySpellCardLayout(false)
        end
    else
        spellCard:Hide()
    end

    learnedSpellText:ClearAllPoints()
    if cardInfo then
        learnedSpellText:SetPoint("TOP", spellCard, "BOTTOM", 0, -12)
    elseif spellCardLabel:IsShown() then
        learnedSpellText:SetPoint("TOP", spellCardLabel, "BOTTOM", 0, -8)
    else
        learnedSpellText:SetPoint("TOP", anchorFrame, anchorPoint, 0, anchorYOffset - 10)
    end

    learnedSpellText:SetText("")
    if self.pendingNewSpellIds then
        self.pendingNewSpellIds = nil
    end

    if AM.DEBUG_UI_FRAMES and self.DebugMentorFrameVisibleNodes then
        self:DebugMentorFrameVisibleNodes()
    end

    if type(self.MaybeShowLessonToastForCurrentCard) == "function" then
        self:MaybeShowLessonToastForCurrentCard(cardInfo)
    end
end

--------------------------------------------------------------------------------
-- Visible on load (same as pre-refactor: show panel and first paint)
--------------------------------------------------------------------------------
AzerothMentorFrame:Show()
AM:UpdateMainFrame()
