--[[
  Azeroth Mentor - compact XP progress bar (movable when unlocked, scalable, SavedVariables).
  Stored under AzerothMentorDB.xpBar (see AM:EnsureXPBarDB).
]]

local AM = _G.AM

local SCALE_MIN = 0.5
local SCALE_MAX = 2.5

local FONT_BODY_MIN = 8
local FONT_BODY_MAX = 24
local FONT_BODY_DEFAULT = 13

-- XP progress fill (bright mentor gold; StatusBar tint).
local XP_BAR_FILL_R, XP_BAR_FILL_G, XP_BAR_FILL_B, XP_BAR_FILL_A = 1.0, 0.72, 0.05, 1.0

local eventFrame
local xpRoot

local function FmtNum(n)
    n = tonumber(n) or 0
    if type(BreakUpLargeNumbers) == "function" then
        return BreakUpLargeNumbers(math.floor(n + 0.5))
    end
    return tostring(math.floor(n + 0.5))
end

local function ClampXPBarScale(n)
    n = tonumber(n)
    if not n then
        return nil
    end
    if n ~= n then
        return nil
    end
    return math.max(SCALE_MIN, math.min(SCALE_MAX, n))
end

--- @return number bodyPx, number titlePx
local function GetClampedBodyTitleSizes()
    local db = AM:EnsureXPBarDB()
    local body = tonumber(db.fontSize) or FONT_BODY_DEFAULT
    body = math.max(FONT_BODY_MIN, math.min(FONT_BODY_MAX, math.floor(body + 0.5)))
    db.fontSize = body
    local titleSz = math.min(FONT_BODY_MAX + 2, body + 2)
    return body, titleSz
end

local function GetUIFontForCopy()
    if GameFontHighlight and type(GameFontHighlight.GetFont) == "function" then
        local ok, fontPath, _h, flags = pcall(function()
            return GameFontHighlight:GetFont()
        end)
        if ok and fontPath then
            if type(fontPath) == "string" and fontPath ~= "" then
                return fontPath, flags or ""
            end
            if type(fontPath) == "number" then
                return fontPath, flags or ""
            end
        end
    end
    return nil, ""
end

local function ResolveXPBarFontFace()
    local path, flags = GetUIFontForCopy()
    if path then
        return path, flags or ""
    end
    local std = _G.STANDARD_TEXT_FONT
    if type(std) == "string" and std ~= "" then
        return std, ""
    end
    return "Fonts\\FRIZQT__.TTF", ""
end

--- Must run before SetText on a bare FontString (no template inheritance).
local function ApplyXPBarFontString(fontString, size)
    if not fontString or not tonumber(size) then
        return
    end
    size = tonumber(size)
    local path, flags = ResolveXPBarFontFace()
    flags = flags or ""
    local ok = pcall(function()
        fontString:SetFont(path, size, flags)
    end)
    if not ok then
        pcall(function()
            fontString:SetFont("Fonts\\FRIZQT__.TTF", size, "")
        end)
    end
end

function AM:EnsureXPBarDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    local xp = AzerothMentorDB.xpBar
    if type(xp) ~= "table" then
        AzerothMentorDB.xpBar = {}
        xp = AzerothMentorDB.xpBar
    end
    if xp.shown == nil then
        xp.shown = true
    end
    if xp.locked == nil then
        xp.locked = true
    end
    if xp.scale == nil then
        xp.scale = 1.0
    end
    if xp.point == nil then
        xp.point = "BOTTOM"
    end
    if xp.relativePoint == nil then
        xp.relativePoint = "BOTTOM"
    end
    if xp.x == nil then
        xp.x = 0
    end
    if xp.y == nil then
        xp.y = 140
    end
    if xp.fontSize == nil then
        xp.fontSize = FONT_BODY_DEFAULT
    end
    if xp.reloadButtonShown == nil then
        xp.reloadButtonShown = true
    end
    return xp
end

local function ApplyLockState()
    local db = AM:EnsureXPBarDB()
    if not xpRoot then
        return
    end
    xpRoot:SetMovable(not db.locked)
    xpRoot:RegisterForDrag("LeftButton")
    xpRoot:SetScript("OnDragStart", function(self)
        if AM:EnsureXPBarDB().locked then
            return
        end
        self:StartMoving()
    end)
    xpRoot:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if type(AM.XPBarSavePosition) == "function" then
            AM:XPBarSavePosition()
        end
    end)
end

function AM:XPBarSavePosition()
    if not xpRoot then
        return
    end
    local db = AM:EnsureXPBarDB()
    local pt, relTo, relPt, xOfs, yOfs = xpRoot:GetPoint(1)
    if not pt or not relPt then
        return
    end
    db.point = pt
    db.relativePoint = relPt
    db.x = tonumber(xOfs) or 0
    db.y = tonumber(yOfs) or 0
end

local function ApplyLayoutFromDB()
    local db = AM:EnsureXPBarDB()
    if not xpRoot then
        return
    end
    xpRoot:ClearAllPoints()
    local pt = db.point or "BOTTOM"
    local rpt = db.relativePoint or "BOTTOM"
    local x = tonumber(db.x) or 0
    local y = tonumber(db.y) or 140
    xpRoot:SetPoint(pt, UIParent, rpt, x, y)
    local sc = ClampXPBarScale(db.scale) or 1.0
    db.scale = sc
    xpRoot:SetScale(sc)
end

local function ResizeXPBarFrame(bodyPx, titlePx)
    if not xpRoot then
        return
    end
    local body = tonumber(bodyPx) or FONT_BODY_DEFAULT
    local titleSz = tonumber(titlePx) or (body + 2)
    local w = math.max(288, math.min(480, 248 + body * 5))
    local h = math.max(100, math.min(260, math.floor(36 + titleSz * 1.25 + body * 3.45 + 24)))
    xpRoot:SetSize(w, h)
end

local function ApplyXPBarFonts()
    if not xpRoot then
        return
    end
    local body, titleSz = GetClampedBodyTitleSizes()

    if xpRoot.titleText then
        ApplyXPBarFontString(xpRoot.titleText, titleSz)
    end
    if xpRoot.levelText then
        ApplyXPBarFontString(xpRoot.levelText, body)
    end
    if xpRoot.xpText then
        ApplyXPBarFontString(xpRoot.xpText, body)
    end
    if xpRoot.restText then
        ApplyXPBarFontString(xpRoot.restText, body)
    end

    ResizeXPBarFrame(body, titleSz)

    local barHolder = xpRoot.barHolder
    if barHolder then
        barHolder:ClearAllPoints()
        barHolder:SetPoint("BOTTOMLEFT", xpRoot, "BOTTOMLEFT", 10, 10)
        barHolder:SetPoint("BOTTOMRIGHT", xpRoot, "BOTTOMRIGHT", -10, 10)
        barHolder:SetHeight(16)
    end

    if type(AM.XPBarSyncReloadButton) == "function" then
        AM:XPBarSyncReloadButton()
    end
end

function AM:XPBarSyncReloadButton()
    if not xpRoot or not xpRoot.reloadButton then
        return
    end
    local db = AM:EnsureXPBarDB()
    if db.reloadButtonShown == false then
        xpRoot.reloadButton:Hide()
    else
        xpRoot.reloadButton:Show()
    end
end

function AM:XPBarSetReloadButtonShown(show)
    local db = AM:EnsureXPBarDB()
    db.reloadButtonShown = show and true or false
    if not xpRoot then
        AM:XPBarInit()
    end
    AM:XPBarSyncReloadButton()
    print(string.format("[Azeroth Mentor] XP bar reload button: %s.", db.reloadButtonShown and "on" or "off"))
end

function AM:XPBarUpdate()
    if not xpRoot then
        return
    end
    local fsLevel = xpRoot.levelText
    local fsXp = xpRoot.xpText
    local fsRest = xpRoot.restText
    local bar = xpRoot.statusBar
    local bg = xpRoot.barBg

    local level = UnitLevel("player")
    if level == nil then
        level = 0
    end
    level = tonumber(level) or 0

    local cur = UnitXP("player")
    local max = UnitXPMax("player")
    cur = tonumber(cur) or 0
    max = tonumber(max) or 0

    if max <= 0 then
        fsLevel:SetText(string.format("Level %d - max level", level))
        fsXp:SetText("No further level XP on this character.")
        fsRest:SetText("")
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        bar:SetStatusBarColor(0.35, 0.35, 0.4)
        if bg then
            bg:SetVertexColor(0.12, 0.12, 0.14)
        end
        return
    end

    local rem = max - cur
    if rem < 0 then
        rem = 0
    end
    local pct = 0
    if max > 0 then
        pct = (cur / max) * 100
    end

    fsLevel:SetText(string.format("Level %d  ·  %.1f%% to next", level, pct))
    fsXp:SetText(string.format("XP %s / %s  (remaining %s)", FmtNum(cur), FmtNum(max), FmtNum(rem)))

    local rested = nil
    if type(GetXPExhaustion) == "function" then
        local ok, r = pcall(GetXPExhaustion)
        if ok and r and tonumber(r) and tonumber(r) > 0 then
            rested = tonumber(r)
        end
    end
    if rested and rested > 0 then
        fsRest:SetText("Rested bonus pool: " .. FmtNum(rested))
    else
        fsRest:SetText("")
    end

    bar:SetMinMaxValues(0, max)
    bar:SetValue(math.min(cur, max))
    bar:SetStatusBarColor(XP_BAR_FILL_R, XP_BAR_FILL_G, XP_BAR_FILL_B, XP_BAR_FILL_A)
    if bg then
        bg:SetVertexColor(0.15, 0.12, 0.18)
    end
end

function AM:XPBarShow()
    local db = AM:EnsureXPBarDB()
    db.shown = true
    if not xpRoot then
        AM:XPBarInit()
    end
    if xpRoot then
        xpRoot:Show()
        AM:XPBarUpdate()
    end
    print("[Azeroth Mentor] XP bar shown.")
end

function AM:XPBarHide()
    local db = AM:EnsureXPBarDB()
    db.shown = false
    if xpRoot then
        xpRoot:Hide()
    end
    print("[Azeroth Mentor] XP bar hidden.")
end

function AM:XPBarSetLocked(locked)
    local db = AM:EnsureXPBarDB()
    db.locked = locked and true or false
    if not xpRoot then
        AM:XPBarInit()
    end
    ApplyLockState()
    print(string.format("[Azeroth Mentor] XP bar %s.", db.locked and "locked (drag disabled)" or "unlocked (drag to move)"))
end

function AM:XPBarSetScale(scale)
    local db = AM:EnsureXPBarDB()
    local s = ClampXPBarScale(scale)
    if not s then
        print("[Azeroth Mentor] XP bar scale: invalid number. Use a value between " .. SCALE_MIN .. " and " .. SCALE_MAX .. ".")
        return
    end
    db.scale = s
    if not xpRoot then
        AM:XPBarInit()
    end
    if xpRoot then
        xpRoot:SetScale(s)
    end
    print(string.format("[Azeroth Mentor] XP bar scale = %.2f", s))
end

function AM:XPBarSetFontSize(size)
    local db = AM:EnsureXPBarDB()
    local n = tonumber(size)
    if not n then
        print("[Azeroth Mentor] XP bar font: invalid number. Allowed body size: " .. FONT_BODY_MIN .. " to " .. FONT_BODY_MAX .. " (title uses body + 2).")
        return
    end
    n = math.max(FONT_BODY_MIN, math.min(FONT_BODY_MAX, math.floor(n + 0.5)))
    db.fontSize = n
    if not xpRoot then
        AM:XPBarInit()
    end
    ApplyXPBarFonts()
    AM:XPBarUpdate()
    print(string.format("[Azeroth Mentor] XP bar fontSize = %d (title = %d)", n, n + 2))
end

function AM:XPBarPrintStatus()
    local db = AM:EnsureXPBarDB()
    local shownStr = (db.shown ~= false) and "yes" or "no"
    local lockStr = db.locked and "locked" or "unlocked"
    local sc = tonumber(db.scale) or 1.0
    local body = tonumber(db.fontSize) or FONT_BODY_DEFAULT
    body = math.max(FONT_BODY_MIN, math.min(FONT_BODY_MAX, math.floor(body + 0.5)))
    print(
        string.format(
            "[Azeroth Mentor] XP bar status: shown=%s, %s, scale=%.2f, fontSize(body)=%d, titleSize=%d, reloadBtn=%s",
            shownStr,
            lockStr,
            sc,
            body,
            math.min(FONT_BODY_MAX + 2, body + 2),
            (db.reloadButtonShown ~= false) and "on" or "off"
        )
    )
end

function AM:XPBarReset()
    local db = AM:EnsureXPBarDB()
    db.shown = true
    db.locked = true
    db.scale = 1.0
    db.point = "BOTTOM"
    db.relativePoint = "BOTTOM"
    db.x = 0
    db.y = 140
    db.fontSize = FONT_BODY_DEFAULT
    db.reloadButtonShown = true
    if not xpRoot then
        AM:XPBarInit()
    end
    if xpRoot then
        ApplyLayoutFromDB()
        ApplyLockState()
        ApplyXPBarFonts()
        if db.shown then
            xpRoot:Show()
        else
            xpRoot:Hide()
        end
        AM:XPBarUpdate()
    end
    print("[Azeroth Mentor] XP bar reset to defaults (shown, locked, scale 1, fontSize 13, bottom center).")
end

function AM:XPBarInit()
    if xpRoot then
        return
    end

    AM:EnsureXPBarDB()
    local db = AzerothMentorDB.xpBar

    local f = CreateFrame("Frame", "AzerothMentorXPBarFrame", UIParent, "BackdropTemplate")
    f:SetSize(312, 110)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(false)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.09, 0.88)
    f:SetBackdropBorderColor(0.75, 0.65, 0.25, 0.85)

    local body, titleSz = GetClampedBodyTitleSizes()

    if not f.reloadButton then
        local reloadBtn = CreateFrame("Button", "AzerothMentorXPBarReloadButton", f)
        reloadBtn:SetSize(18, 18)
        reloadBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -6)
        reloadBtn:SetFrameLevel(f:GetFrameLevel() + 25)
        reloadBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        reloadBtn:SetNormalFontObject("GameFontHighlightSmall")
        reloadBtn:SetHighlightFontObject("GameFontHighlightSmall")
        reloadBtn:SetText("R")
        local rbg = reloadBtn:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints()
        rbg:SetColorTexture(0.12, 0.12, 0.16, 0.9)
        reloadBtn:SetScript("OnClick", function(_, button)
            if button ~= "LeftButton" then
                return
            end
            if IsShiftKeyDown() then
                local ok = pcall(function()
                    ReloadUI()
                end)
                if not ok then
                    print("[Azeroth Mentor] ReloadUI() is not available.")
                end
            else
                print("Azeroth Mentor: Shift-click the R button to reload the UI.")
            end
        end)
        reloadBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Reload UI", 1, 1, 1)
            GameTooltip:AddLine("Shift-click to reload", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        reloadBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        f.reloadButton = reloadBtn
    end

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -6)
    title:SetPoint("TOPRIGHT", f.reloadButton, "TOPLEFT", -6, 0)
    title:SetJustifyH("LEFT")
    ApplyXPBarFontString(title, titleSz)
    title:SetTextColor(0.95, 0.82, 0.45)
    title:SetText("Azeroth Mentor - XP")
    f.titleText = title

    local levelText = f:CreateFontString(nil, "OVERLAY")
    levelText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    levelText:SetJustifyH("LEFT")
    ApplyXPBarFontString(levelText, body)
    f.levelText = levelText

    local xpText = f:CreateFontString(nil, "OVERLAY")
    xpText:SetPoint("TOPLEFT", levelText, "BOTTOMLEFT", 0, -3)
    xpText:SetJustifyH("LEFT")
    ApplyXPBarFontString(xpText, body)
    f.xpText = xpText

    local restText = f:CreateFontString(nil, "OVERLAY")
    restText:SetPoint("TOPLEFT", xpText, "BOTTOMLEFT", 0, -3)
    restText:SetJustifyH("LEFT")
    ApplyXPBarFontString(restText, body)
    restText:SetTextColor(0.55, 0.85, 1)
    f.restText = restText

    local barHolder = CreateFrame("Frame", nil, f)
    barHolder:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    barHolder:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    barHolder:SetHeight(16)
    f.barHolder = barHolder

    local barBg = barHolder:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(0.1, 0.1, 0.12, 1)
    f.barBg = barBg

    local sb = CreateFrame("StatusBar", nil, barHolder)
    sb:SetPoint("TOPLEFT", barHolder, "TOPLEFT", 1, -1)
    sb:SetPoint("BOTTOMRIGHT", barHolder, "BOTTOMRIGHT", -1, 1)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(0)
    sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sb:SetStatusBarColor(XP_BAR_FILL_R, XP_BAR_FILL_G, XP_BAR_FILL_B, XP_BAR_FILL_A)
    f.statusBar = sb

    xpRoot = f
    AM.xpBarFrame = f

    ApplyXPBarFonts()
    ApplyLayoutFromDB()
    ApplyLockState()

    if db.shown ~= false then
        f:Show()
    else
        f:Hide()
    end

    AM:XPBarUpdate()

    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
        eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
        eventFrame:RegisterEvent("UPDATE_EXHAUSTION")
        eventFrame:SetScript("OnEvent", function()
            AM:XPBarUpdate()
        end)
    end
end

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= AM.name then
        return
    end
    loadFrame:UnregisterAllEvents()
    AM:XPBarInit()
end)
