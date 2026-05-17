--[[
  Azeroth Mentor - compact combat hint (movable when unlocked, SavedVariables).
  Retribution: opener hint when out of combat with a hostile target; BUILD/SPEND in combat.
  Stored under AzerothMentorDB.combatHint (see AM:EnsureCombatHintDB).
]]

local AM = _G.AM
local L = AM.L

local SPEC_ID_RETRIBUTION_PALADIN = 70

local SPELL_JUDGMENT = 20271
local SPELL_BLADE_OF_JUSTICE = 184575
local SPELL_CRUSADER_STRIKE = 35395

local OPENER_SPELL_ORDER = {
    SPELL_JUDGMENT,
    SPELL_BLADE_OF_JUSTICE,
    SPELL_CRUSADER_STRIKE,
}

local SCALE_MIN = 0.5
local SCALE_MAX = 2.5

local ICON_SIZE = 36
local FRAME_W = 196
local FRAME_H = 64

local ACTION_SLOT_MAX = 120

local eventFrame
local hintRoot
local slotBindingMap
local keybindCache = {}

--- Blizzard default action slot → binding command (slots without bindings stay nil).
local function BuildSlotBindingMap()
    local map = {}
    for i = 1, 12 do
        map[i] = "ACTIONBUTTON" .. i
    end
    for i = 1, 12 do
        map[12 + i] = "MULTIACTIONBAR4BUTTON" .. i
        map[24 + i] = "MULTIACTIONBAR3BUTTON" .. i
        map[48 + i] = "MULTIACTIONBAR2BUTTON" .. i
        map[60 + i] = "MULTIACTIONBAR1BUTTON" .. i
    end
    return map
end

slotBindingMap = BuildSlotBindingMap()

local function InvalidateCombatHintKeybindCache()
    keybindCache.spellID = nil
    keybindCache.key = nil
end

local function FormatBindingKey(key)
    if not key or key == "" then
        return nil
    end
    if type(GetBindingText) == "function" then
        local ok, text = pcall(GetBindingText, key, "KEY_", true)
        if ok and text and text ~= "" then
            return text
        end
    end
    return key
end

--- @param bindingName string|nil
--- @return string|nil first bound key label
local function GetFirstKeyForBinding(bindingName)
    if not bindingName or bindingName == "" or type(GetBindingKey) ~= "function" then
        return nil
    end
    local ok, key1, key2 = pcall(GetBindingKey, bindingName)
    if not ok then
        return nil
    end
    return FormatBindingKey(key1) or FormatBindingKey(key2)
end

--- @param slot number
--- @return number|nil spellID on the slot, if any
local function GetActionSlotSpellID(slot)
    if type(GetActionInfo) ~= "function" then
        return nil
    end
    if type(HasAction) == "function" then
        local okHas, has = pcall(HasAction, slot)
        if okHas and not has then
            return nil
        end
    end
    local ok, actionType, id = pcall(GetActionInfo, slot)
    if not ok or actionType ~= "spell" then
        return nil
    end
    id = tonumber(id)
    if not id or id <= 0 then
        return nil
    end
    return id
end

--- Find the first action-bar key label for a spell (main bar first, then multi-bars).
--- @param spellID number
--- @return string|nil
function AM:GetSpellActionBarKeybind(spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then
        return nil
    end

    if keybindCache.spellID == spellID then
        if keybindCache.key == false then
            return nil
        end
        return keybindCache.key
    end

    local found
    for slot = 1, ACTION_SLOT_MAX do
        local slotSpell = GetActionSlotSpellID(slot)
        if slotSpell == spellID then
            local bindingName = slotBindingMap[slot]
            found = bindingName and GetFirstKeyForBinding(bindingName) or nil
            if found then
                break
            end
        end
    end

    keybindCache.spellID = spellID
    keybindCache.key = found or false
    return found
end

local function ClampCombatHintScale(n)
    n = tonumber(n)
    if not n or n ~= n then
        return nil
    end
    return math.max(SCALE_MIN, math.min(SCALE_MAX, n))
end

function AM:EnsureCombatHintDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    local ch = AzerothMentorDB.combatHint
    if type(ch) ~= "table" then
        AzerothMentorDB.combatHint = {}
        ch = AzerothMentorDB.combatHint
    end
    if ch.shown == nil then
        ch.shown = true
    end
    if ch.locked == nil then
        ch.locked = false
    end
    if ch.scale == nil then
        ch.scale = 1.0
    end
    if ch.point == nil then
        ch.point = "CENTER"
    end
    if ch.relativePoint == nil then
        ch.relativePoint = "CENTER"
    end
    if ch.x == nil then
        ch.x = 0
    end
    if ch.y == nil then
        ch.y = -220
    end
    if ch.showKeybinds == nil then
        ch.showKeybinds = true
    end
    return ch
end

local function IsRetributionPaladin()
    if type(AM.GetPlayerState) ~= "function" then
        return false
    end
    local ok, s = pcall(AM.GetPlayerState, AM)
    if not ok or type(s) ~= "table" then
        return false
    end
    return s.classFile == "PALADIN" and s.specId == SPEC_ID_RETRIBUTION_PALADIN
end

--- Short action line for the combat hint (not the long main-frame combat copy).
--- @param rec table|nil
--- @return string
local function GetCombatHintActionText(rec)
    if not rec then
        return L["COMBAT_HINT_NO_HINT"]
    end
    local key = rec.displayLineKey
    if key == "RET_COMBAT_LINE_BUILD_WAIT" or key == "RET_COMBAT_LINE_SPEND_WAIT" then
        return L["COMBAT_HINT_ACTION_WAIT"]
    end
    if rec.phase == "BUILD" then
        return L["COMBAT_HINT_ACTION_BUILD"]
    end
    if rec.phase == "SPEND" then
        return L["COMBAT_HINT_ACTION_SPEND"]
    end
    if rec.suggestedSpellID then
        return L["COMBAT_HINT_ACTION_WAIT"]
    end
    return L["COMBAT_HINT_NO_HINT"]
end

--- @return boolean
function AM:HasHostileTarget()
    if type(UnitExists) ~= "function" then
        return false
    end
    local okExists, exists = pcall(UnitExists, "target")
    if not okExists or not exists then
        return false
    end
    if type(UnitIsDead) == "function" then
        local okDead, dead = pcall(UnitIsDead, "target")
        if okDead and dead then
            return false
        end
    end
    if type(UnitCanAttack) ~= "function" then
        return false
    end
    local okAttack, canAttack = pcall(UnitCanAttack, "player", "target")
    return okAttack and canAttack and true or false
end

--- Opener priority for pull: Judgment → Blade of Justice → Crusader Strike (known only).
--- @return number|nil spellID
function AM:GetCombatHintOpenerSpellID()
    if type(AM.IsSpellKnownSafe) ~= "function" then
        return nil
    end
    for _, sid in ipairs(OPENER_SPELL_ORDER) do
        if AM:IsSpellKnownSafe(sid) then
            return sid
        end
    end
    return nil
end

--- @param spellID number|nil
--- @return string
local function GetOpenerActionText(spellID)
    if spellID == SPELL_CRUSADER_STRIKE then
        return L["COMBAT_HINT_ACTION_MOVE_CLOSE"]
    end
    return L["COMBAT_HINT_ACTION_START"]
end

--- @param spellID number|nil
--- @param actionText string
--- @param db table
local function ApplyCombatHintDisplay(spellID, actionText, db)
    hintRoot.actionText:SetText(actionText or "")

    if spellID and type(AM.GetSpellDisplayInfo) == "function" then
        local spellName, spellIcon = AM:GetSpellDisplayInfo(spellID)
        hintRoot.spellName:SetText(spellName or L["COMBAT_HINT_UNKNOWN_SPELL"])
        hintRoot.iconTex:SetTexture(spellIcon)
        hintRoot.iconTex:SetAlpha(1)
        hintRoot.iconBtn.spellID = spellID
        hintRoot.iconBtn:Show()
        hintRoot.spellName:SetTextColor(1, 1, 1)
    else
        hintRoot.iconBtn.spellID = nil
        hintRoot.iconTex:SetTexture(nil)
        hintRoot.iconTex:SetAlpha(0)
        hintRoot.iconBtn:Hide()
        hintRoot.spellName:SetText(L["COMBAT_HINT_TITLE"])
        hintRoot.spellName:SetTextColor(0.95, 0.82, 0.45)
    end

    local keyLine = hintRoot.keybindText
    if keyLine then
        if db.showKeybinds ~= false and spellID and type(AM.GetSpellActionBarKeybind) == "function" then
            local keyLabel = AM:GetSpellActionBarKeybind(spellID)
            if keyLabel and keyLabel ~= "" then
                keyLine:SetText(string.format(L["COMBAT_HINT_KEY"], keyLabel))
                keyLine:Show()
            else
                keyLine:SetText("")
                keyLine:Hide()
            end
        else
            keyLine:SetText("")
            keyLine:Hide()
        end
    end
end

local function ApplyLockState()
    local db = AM:EnsureCombatHintDB()
    if not hintRoot then
        return
    end
    hintRoot:SetMovable(not db.locked)
    hintRoot:RegisterForDrag("LeftButton")
    hintRoot:SetScript("OnDragStart", function(self)
        if AM:EnsureCombatHintDB().locked then
            return
        end
        self:StartMoving()
    end)
    hintRoot:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if type(AM.CombatHintSavePosition) == "function" then
            AM:CombatHintSavePosition()
        end
    end)
end

function AM:CombatHintSavePosition()
    if not hintRoot then
        return
    end
    local db = AM:EnsureCombatHintDB()
    local pt, _, relPt, xOfs, yOfs = hintRoot:GetPoint(1)
    if not pt or not relPt then
        return
    end
    db.point = pt
    db.relativePoint = relPt
    db.x = tonumber(xOfs) or 0
    db.y = tonumber(yOfs) or 0
end

local function ApplyLayoutFromDB()
    local db = AM:EnsureCombatHintDB()
    if not hintRoot then
        return
    end
    hintRoot:ClearAllPoints()
    local pt = db.point or "CENTER"
    local rpt = db.relativePoint or "CENTER"
    local x = tonumber(db.x) or 0
    local y = tonumber(db.y) or -220
    hintRoot:SetPoint(pt, UIParent, rpt, x, y)
    local sc = ClampCombatHintScale(db.scale) or 1.0
    db.scale = sc
    hintRoot:SetScale(sc)
end

function AM:CombatHintShow()
    local db = AM:EnsureCombatHintDB()
    db.shown = true
    if not hintRoot then
        AM:CombatHintInit()
    end
    AM:CombatHintUpdate()
    print("[Azeroth Mentor] Combat hint enabled (combat + hostile-target opener).")
end

function AM:CombatHintHide()
    local db = AM:EnsureCombatHintDB()
    db.shown = false
    if hintRoot then
        hintRoot:Hide()
    end
    print("[Azeroth Mentor] Combat hint disabled.")
end

function AM:CombatHintSetLocked(locked)
    local db = AM:EnsureCombatHintDB()
    db.locked = locked and true or false
    if not hintRoot then
        AM:CombatHintInit()
    end
    ApplyLockState()
    print(string.format("[Azeroth Mentor] Combat hint %s.", db.locked and "locked (drag disabled)" or "unlocked (drag to move)"))
end

function AM:CombatHintSetScale(scale)
    local db = AM:EnsureCombatHintDB()
    local s = ClampCombatHintScale(scale)
    if not s then
        print("[Azeroth Mentor] Combat hint scale: invalid number. Use a value between " .. SCALE_MIN .. " and " .. SCALE_MAX .. ".")
        return
    end
    db.scale = s
    if not hintRoot then
        AM:CombatHintInit()
    end
    if hintRoot then
        hintRoot:SetScale(s)
    end
    print(string.format("[Azeroth Mentor] Combat hint scale = %.2f", s))
end

function AM:CombatHintSetShowKeybinds(show)
    local db = AM:EnsureCombatHintDB()
    db.showKeybinds = show and true or false
    InvalidateCombatHintKeybindCache()
    if not hintRoot then
        AM:CombatHintInit()
    end
    AM:CombatHintUpdate()
    print(string.format("[Azeroth Mentor] Combat hint keybinds: %s.", db.showKeybinds and "on" or "off"))
end

function AM:CombatHintReset()
    local db = AM:EnsureCombatHintDB()
    db.shown = true
    db.locked = false
    db.scale = 1.0
    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = 0
    db.y = -220
    if not hintRoot then
        AM:CombatHintInit()
    end
    if hintRoot then
        ApplyLayoutFromDB()
        ApplyLockState()
        AM:CombatHintUpdate()
    end
    print("[Azeroth Mentor] Combat hint reset to defaults (shown, unlocked, scale 1, lower center).")
end

--- Refresh visibility and content (combat BUILD/SPEND or out-of-combat opener; no cooldown logic).
function AM:CombatHintUpdate()
    if not hintRoot then
        return
    end

    local db = AM:EnsureCombatHintDB()
    if db.shown == false then
        hintRoot:Hide()
        return
    end

    if not IsRetributionPaladin() then
        hintRoot:Hide()
        return
    end

    if not AM.RetributionCombat or not AM.RetributionCombat.GetState then
        hintRoot:Hide()
        return
    end

    local combat = AM.RetributionCombat:GetState()
    local spellID
    local actionText

    if combat.inCombat then
        local recMod = AM.SpecModules and AM.SpecModules.PALADIN and AM.SpecModules.PALADIN.RETRIBUTION
        local rec = recMod and recMod.GetCombatRecommendation and recMod.GetCombatRecommendation({ combat = combat })
        if not rec or rec.phase == "OUT_OF_COMBAT" then
            hintRoot:Hide()
            return
        end
        spellID = rec.suggestedSpellID
        actionText = GetCombatHintActionText(rec)
    else
        if not AM:HasHostileTarget() then
            hintRoot:Hide()
            return
        end
        spellID = AM:GetCombatHintOpenerSpellID()
        if not spellID then
            hintRoot:Hide()
            return
        end
        actionText = GetOpenerActionText(spellID)
    end

    ApplyCombatHintDisplay(spellID, actionText, db)
    hintRoot:Show()
end

function AM:CombatHintInit()
    if hintRoot then
        return
    end

    AM:EnsureCombatHintDB()
    local db = AzerothMentorDB.combatHint

    local f = CreateFrame("Frame", "AzerothMentorCombatHintFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(12)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(false)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    f:SetBackdropBorderColor(0.72, 0.58, 0.22, 0.9)

    local iconBtn = CreateFrame("Button", nil, f)
    iconBtn:SetSize(ICON_SIZE, ICON_SIZE)
    iconBtn:SetPoint("LEFT", f, "LEFT", 8, 0)
    iconBtn:SetFrameLevel(f:GetFrameLevel() + 2)
    iconBtn:EnableMouse(true)

    local iconBorder = iconBtn:CreateTexture(nil, "BACKGROUND")
    iconBorder:SetAllPoints()
    iconBorder:SetColorTexture(0.12, 0.12, 0.16, 1)

    local iconTex = iconBtn:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", iconBtn, "TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMRIGHT", -1, 1)
    f.iconTex = iconTex
    f.iconBtn = iconBtn

    iconBtn:SetScript("OnEnter", function(self)
        if not self.spellID then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(self.spellID)
        end
        GameTooltip:Show()
    end)
    iconBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local spellName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellName:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 8, -2)
    spellName:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    spellName:SetJustifyH("LEFT")
    spellName:SetMaxLines(1)
    f.spellName = spellName

    local actionText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    actionText:SetPoint("TOPLEFT", spellName, "BOTTOMLEFT", 0, -2)
    actionText:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    actionText:SetJustifyH("LEFT")
    actionText:SetTextColor(0.92, 0.78, 0.35)
    f.actionText = actionText

    local keybindText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    keybindText:SetPoint("TOPLEFT", actionText, "BOTTOMLEFT", 0, -1)
    keybindText:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    keybindText:SetJustifyH("LEFT")
    keybindText:SetTextColor(0.75, 0.75, 0.8)
    keybindText:Hide()
    f.keybindText = keybindText

    hintRoot = f
    AM.combatHintFrame = f

    ApplyLayoutFromDB()
    ApplyLockState()
    AM:CombatHintUpdate()

    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        eventFrame:RegisterEvent("SPELLS_CHANGED")
        eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        eventFrame:RegisterEvent("UPDATE_BINDINGS")
        eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
        eventFrame:SetScript("OnEvent", function(_, event)
            if event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
                InvalidateCombatHintKeybindCache()
            end
            AM:CombatHintUpdate()
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
    AM:CombatHintInit()
end)
