--[[
  Azeroth Mentor - bootstrap
  Defines the global addon table and shared localization container.
  Locale packs and the rest of the addon load from later TOC entries.
]]

_G.AM = _G.AM or {}
local AM = _G.AM

-- Used by Core/Events.lua when filtering ADDON_LOADED (must match the addon folder / TOC name).
AM.name = "AzerothMentor"

-- Optional dev toggles (see `/am debug milestones`, `/am debug cards`, `/am debug lessonlog`, `/am debug cooldowns`; `/am cooldowns` for one-shot report).
AM.DEBUG_CARD_SELECTION = AM.DEBUG_CARD_SELECTION or false
AM.DEBUG_LESSON_LOG = AM.DEBUG_LESSON_LOG or false
AM.DEBUG_LESSON_TOAST = AM.DEBUG_LESSON_TOAST or false
AM.DEBUG_COOLDOWNS = AM.DEBUG_COOLDOWNS or false

--------------------------------------------------------------------------------
-- Defaults (uiScale is in-memory until a future save pipeline persists AM.db)
--------------------------------------------------------------------------------
AM.db = AM.db or {}
AM.db.uiScale = AM.db.uiScale or 1.0
-- Custom minimap button orbit angle (degrees); set by UI/MinimapButton.lua when dragged.
AM.db.minimapButtonAngle = AM.db.minimapButtonAngle or 205
--------------------------------------------------------------------------------
-- Localization table (filled by Locales/*.lua; missing keys fall back to the key string)
--------------------------------------------------------------------------------
do
    local L = AM.L or {}
    AM.L = setmetatable(L, {
        __index = function(_, k)
            return tostring(k)
        end,
    })
end
