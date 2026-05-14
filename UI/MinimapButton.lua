--[[
  Azeroth Mentor - custom minimap launcher.
  LibDataBroker-1.1 / LibDBIcon-1.0 are not bundled with this addon, so this is a small standalone button.
  Left-click toggles the main panel; right-click + drag orbits the button around the minimap.
]]

local AM = _G.AM
local L = AM.L

local RADIUS = 78

local function GetMinimapAnchor()
    return Minimap or (MinimapCluster and MinimapCluster.Minimap)
end

local function PositionMinimapButton(btn, angleDeg)
    local minimap = GetMinimapAnchor()
    if not minimap or not btn then
        return
    end
    local angle = math.rad(angleDeg or 0)
    local x = math.cos(angle) * RADIUS
    local y = math.sin(angle) * RADIUS
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", minimap, "CENTER", x, y)
end

local function CrusaderStrikeIconTexture()
    local spellID = 35395
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and tex then
            if type(tex) == "table" and tex.iconID then
                return tex.iconID
            end
            if type(tex) == "number" or type(tex) == "string" then
                return tex
            end
        end
    end
    if type(GetSpellTexture) == "function" then
        local ok, a, b = pcall(GetSpellTexture, spellID)
        if ok and (a or b) then
            return a or b
        end
    end
    return "Interface\\Icons\\Spell_Holy_SealOfMight"
end

local minimapBtn = CreateFrame("Button", "AzerothMentorMinimapButton", Minimap)
minimapBtn:SetSize(26, 26)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel((Minimap and Minimap:GetFrameLevel() or 2) + 6)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("RightButton")

local tex = minimapBtn:CreateTexture(nil, "BACKGROUND")
tex:SetAllPoints()
tex:SetTexture(CrusaderStrikeIconTexture())

local hi = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
hi:SetAllPoints()
hi:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
hi:SetBlendMode("ADD")

minimapBtn:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        AM:ToggleMainFrame()
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L["MINIMAP_TOOLTIP_TITLE"], 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT_CLICK"], 1, 0.82, 0, true)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function MinimapButton_OnDragUpdate(self)
    local minimap = GetMinimapAnchor()
    if not minimap then
        return
    end
    local mx, my = minimap:GetCenter()
    if not mx or not my then
        return
    end
    local scale = minimap:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local dx, dy = cx - mx, cy - my
    AM.db.minimapButtonAngle = math.deg(math.atan2(dy, dx))
    PositionMinimapButton(self, AM.db.minimapButtonAngle)
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", MinimapButton_OnDragUpdate)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

local function InitMinimapButton()
    local minimap = GetMinimapAnchor()
    if not minimap then
        return
    end
    AM.db.minimapButtonAngle = AM.db.minimapButtonAngle or 205
    if minimapBtn:GetParent() ~= minimap then
        minimapBtn:SetParent(minimap)
    end
    minimapBtn:SetFrameLevel((minimap:GetFrameLevel() or 2) + 6)
    PositionMinimapButton(minimapBtn, AM.db.minimapButtonAngle)
end

InitMinimapButton()

local anchorWatcher = CreateFrame("Frame")
anchorWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
anchorWatcher:SetScript("OnEvent", function(self)
    InitMinimapButton()
    self:UnregisterAllEvents()
end)
