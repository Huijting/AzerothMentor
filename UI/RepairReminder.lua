--[[
  Azeroth Mentor - one-time repair reminder after revive (beginner survival tip).
  Stored under AzerothMentorDB.repairReminder (see AM:EnsureRepairReminderDB).
]]

local AM = _G.AM
local L = AM.L

local REMINDER_DURATION = 14
local PULSE_SPEED = 2.8
local REMINDER_FONT_SIZE = 22

local REVIVE_CHECK_DELAYS = { 0.4, 1.2, 2.5, 4.0 }

local INVENTORY_ALERT_SLOTS = {
    "Head",
    "Shoulders",
    "Chest",
    "Waist",
    "Legs",
    "Feet",
    "Wrists",
    "Hands",
    "Weapon",
    "Shield",
    "Ranged",
}

local reminderRoot
local eventFrame
local hideTimer
local reviveCheckTimers = {}
local reminderArmed = true
local lastPlayerDeadOrGhost = false
local reviveNotifyCooldownUntil = 0

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(fn, ...)
    if ok then
        return a, b
    end
    return nil
end

function AM:EnsureRepairReminderDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    local rr = AzerothMentorDB.repairReminder
    if type(rr) ~= "table" then
        AzerothMentorDB.repairReminder = {}
        rr = AzerothMentorDB.repairReminder
    end
    if rr.enabled == nil then
        rr.enabled = true
    end
    return rr
end

--- @param slot number
--- @return number|nil current
--- @return number|nil maximum
local function GetSlotDurability(slot)
    local cur, max = SafeCall(GetInventoryItemDurability, "player", slot)
    if type(max) == "number" and max > 0 then
        return cur, max
    end
    cur, max = SafeCall(GetInventoryItemDurability, slot)
    return cur, max
end

--- Uses Blizzard armor-man alert when available, then equipped-slot durability scan.
--- @return boolean
function AM:NeedsGearRepair()
    if type(GetInventoryAlertStatus) == "function" then
        for _, slotName in ipairs(INVENTORY_ALERT_SLOTS) do
            local status = SafeCall(GetInventoryAlertStatus, slotName)
            if type(status) == "number" and status > 0 then
                return true
            end
        end
    end

    for slot = 1, 19 do
        if SafeCall(GetInventoryItemLink, "player", slot) then
            local current, maximum = GetSlotDurability(slot)
            if type(maximum) == "number" and maximum > 0 then
                current = tonumber(current) or 0
                if current < maximum then
                    return true
                end
            end
        end
    end
    return false
end

--- Lowest durability % among equipped items (0–100); nil when nothing to measure.
--- @return number|nil
function AM:GetGearDurabilityPercent()
    local lowest
    for slot = 1, 19 do
        if SafeCall(GetInventoryItemLink, "player", slot) then
            local current, maximum = GetSlotDurability(slot)
            if type(maximum) == "number" and maximum > 0 then
                current = tonumber(current) or 0
                local pct = math.floor((current / maximum) * 100 + 0.5)
                if pct < 0 then
                    pct = 0
                elseif pct > 100 then
                    pct = 100
                end
                if lowest == nil or pct < lowest then
                    lowest = pct
                end
            end
        end
    end
    return lowest
end

--- @return string
function AM:FormatRepairReminderText()
    local pct = self:GetGearDurabilityPercent()
    local pctStr = (pct ~= nil) and tostring(pct) or "?"
    return string.format(L["REPAIR_REMINDER_TEXT"], pctStr)
end

local function ApplyRepairReminderFont(fontString)
    if not fontString then
        return
    end
    if GameFontNormalHuge and type(GameFontNormalHuge.GetFont) == "function" then
        local ok, path, size, flags = pcall(function()
            return GameFontNormalHuge:GetFont()
        end)
        if ok and path then
            pcall(function()
                fontString:SetFont(path, REMINDER_FONT_SIZE, flags or "")
            end)
            return
        end
    end
    fontString:SetFontObject("GameFontNormalHuge")
end

local function CancelHideTimer()
    if hideTimer and hideTimer.Cancel then
        hideTimer:Cancel()
    end
    hideTimer = nil
end

local function CancelReviveCheckTimers()
    for _, t in ipairs(reviveCheckTimers) do
        if t and t.Cancel then
            t:Cancel()
        end
    end
    wipe(reviveCheckTimers)
end

function AM:HideRepairReminder()
    CancelHideTimer()
    if not reminderRoot then
        return
    end
    reminderRoot:SetScript("OnUpdate", nil)
    reminderRoot:Hide()
end

--- @param force boolean|nil show even when durability API says full
--- @param isTest boolean|nil true for /am repair test (does not disarm revive reminder)
function AM:ShowRepairReminder(force, isTest)
    local db = AM:EnsureRepairReminderDB()
    if db.enabled == false then
        return false
    end
    if not force and not self:NeedsGearRepair() then
        return false
    end

    if not reminderRoot then
        AM:RepairReminderInit()
    end
    if not reminderRoot then
        return false
    end

    ApplyRepairReminderFont(reminderRoot.text)
    reminderRoot:SetHeight(72)
    reminderRoot.text:SetText(self:FormatRepairReminderText())
    reminderRoot.text:SetAlpha(1)
    reminderRoot:Show()
    if not isTest then
        reminderArmed = false
    end

    CancelHideTimer()
    if C_Timer and C_Timer.NewTimer then
        hideTimer = C_Timer.NewTimer(REMINDER_DURATION, function()
            AM:HideRepairReminder()
        end)
    end

    reminderRoot:SetScript("OnUpdate", function(self)
        local t = GetTime()
        local alpha = 0.62 + 0.38 * (0.5 + 0.5 * math.sin(t * PULSE_SPEED))
        if self.text then
            self.text:SetAlpha(alpha)
        end
    end)

    return true
end

function AM:ScheduleRepairReminderAfterRevive()
    CancelReviveCheckTimers()
    if not reminderArmed then
        return
    end
    local db = AM:EnsureRepairReminderDB()
    if db.enabled == false then
        return
    end

    if not (C_Timer and C_Timer.After) then
        if AM:NeedsGearRepair() then
            AM:ShowRepairReminder()
        end
        return
    end

    for _, delay in ipairs(REVIVE_CHECK_DELAYS) do
        local t = C_Timer.After(delay, function()
            if reminderArmed and AM:NeedsGearRepair() then
                AM:ShowRepairReminder()
            end
        end)
        reviveCheckTimers[#reviveCheckTimers + 1] = t
    end
end

local function PollPlayerDeadOrGhost()
    local deadOrGhost = SafeCall(UnitIsDeadOrGhost, "player") and true or false
    if deadOrGhost then
        lastPlayerDeadOrGhost = true
        return
    end
    if lastPlayerDeadOrGhost then
        lastPlayerDeadOrGhost = false
        AM:OnPlayerRevived()
    end
end

function AM:OnPlayerRevived()
    local now = GetTime()
    if now < reviveNotifyCooldownUntil then
        return
    end
    reviveNotifyCooldownUntil = now + 3

    if AM:NeedsGearRepair() and not reminderArmed then
        local shown = reminderRoot and reminderRoot:IsShown()
        if not shown then
            reminderArmed = true
        end
    end
    AM:ScheduleRepairReminderAfterRevive()
end

function AM:RepairReminderRearm()
    reminderArmed = true
    AM:HideRepairReminder()
end

function AM:PrintRepairReminderStatus()
    local db = AM:EnsureRepairReminderDB()
    local needs = self:NeedsGearRepair()
    local shown = reminderRoot and reminderRoot:IsShown()
    print("|cffaaaaff[Azeroth Mentor]|r Repair reminder status:")
    print("  enabled: " .. tostring(db.enabled ~= false))
    print("  armed (will show on next revive): " .. tostring(reminderArmed))
    print("  needs repair (API): " .. tostring(needs))
    print("  frame visible: " .. tostring(shown and true or false))
    print("  last was dead/ghost: " .. tostring(lastPlayerDeadOrGhost))
    print("  lowest durability %: " .. tostring(self:GetGearDurabilityPercent() or "n/a"))
    if needs and not reminderArmed and not shown then
        print("  tip: /am repair reset — then die & revive again (test no longer blocks this)")
    end
end

local function SafeRegisterEvent(frame, event)
    if not frame or not event then
        return
    end
    pcall(function()
        frame:RegisterEvent(event)
    end)
end

local function SafeRegisterUnitEvent(frame, event, unit)
    if not frame or not event or not unit then
        return
    end
    pcall(function()
        frame:RegisterUnitEvent(event, unit)
    end)
end

local function WireRepairReminderEvents()
    if eventFrame and eventFrame._repairEventsWired then
        return
    end
    eventFrame = eventFrame or CreateFrame("Frame")
    SafeRegisterEvent(eventFrame, "PLAYER_ALIVE")
    SafeRegisterEvent(eventFrame, "PLAYER_UNGHOST")
    SafeRegisterEvent(eventFrame, "PLAYER_DEAD")
    SafeRegisterEvent(eventFrame, "UPDATE_INVENTORY_DURABILITY")
    SafeRegisterUnitEvent(eventFrame, "UNIT_HEALTH", "player")
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_DEAD" then
            lastPlayerDeadOrGhost = true
            return
        end

        if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            AM:OnPlayerRevived()
            return
        end

        if event == "UNIT_HEALTH" and unit == "player" then
            PollPlayerDeadOrGhost()
            return
        end

        if event == "UPDATE_INVENTORY_DURABILITY" then
            if not AM:NeedsGearRepair() then
                reminderArmed = true
                AM:HideRepairReminder()
            end
        end
    end)
    eventFrame._repairEventsWired = true
    lastPlayerDeadOrGhost = SafeCall(UnitIsDeadOrGhost, "player") and true or false

    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        self._repairPollAcc = (self._repairPollAcc or 0) + elapsed
        if self._repairPollAcc < 0.35 then
            return
        end
        self._repairPollAcc = 0
        PollPlayerDeadOrGhost()
    end)
end

function AM:RepairReminderInit()
    AM:EnsureRepairReminderDB()

    if not reminderRoot then
        local existing = _G.AzerothMentorRepairReminderFrame
        if existing and existing.text then
            reminderRoot = existing
            AM.repairReminderFrame = existing
        else
            local f = CreateFrame("Frame", "AzerothMentorRepairReminderFrame", UIParent)
            f:SetSize(560, 72)
            f:SetPoint("TOP", UIParent, "TOP", 0, -220)
            f:SetFrameStrata("TOOLTIP")
            f:SetFrameLevel(200)
            f:EnableMouse(false)
            f:Hide()

            local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            text:SetPoint("CENTER")
            text:SetJustifyH("CENTER")
            text:SetMaxLines(3)
            text:SetWidth(540)
            ApplyRepairReminderFont(text)
            text:SetTextColor(1, 0.92, 0.45)
            text:SetShadowColor(0, 0, 0, 1)
            text:SetShadowOffset(1, -1)
            f.text = text

            reminderRoot = f
            AM.repairReminderFrame = f
        end
    end

    WireRepairReminderEvents()
end

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= AM.name then
        return
    end
    loadFrame:UnregisterAllEvents()
    AM:RepairReminderInit()
end)
