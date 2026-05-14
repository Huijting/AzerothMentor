--[[
  Azeroth Mentor - English (enUS) strings
  Applied for enUS clients and as the default when no dedicated locale pack matches.
]]

local AM = _G.AM
local L = AM.L
local locale = GetLocale()

-- English when the client is enUS, or when Dutch (nlNL) is not the active locale.
if locale == "enUS" or locale ~= "nlNL" then
    L.ADDON_TITLE = "Azeroth Mentor"
    L.LOADED = "[Azeroth Mentor] Loaded successfully!"
    L.CLASS_BASICS = "Class Basics"
    L.CHOOSE_YOUR_PATH = "Choose Your Path"
    L.SPEC_TRAINING = "Spec Training"
    L.GUIDANCE_CLASS_BASICS = "Learn movement, combat, and survival."
    L.GUIDANCE_CHOOSE_PATH = "Choose a specialization to begin advanced training."
    L.GUIDANCE_SPEC_TRAINING = "Advanced combat mentoring active."
    L.TUTORIAL_CLASS_BASICS =
        "Tip: Start by learning how to move, target an enemy, and use your first attack."
    L.TUTORIAL_CHOOSE_PATH =
        "Tip: Open your Specialization & Talents window and choose a specialization."
    L.TUTORIAL_SPEC_TRAINING =
        "Tip: Watch your abilities and learn which buttons build and spend your main resource."
    L.RET_GUIDANCE = "Retribution Paladin combat mentoring active."
    L.RET_TUTORIAL = "Tip: Build Holy Power first, then spend it on powerful attacks."
    L.LABEL_CHARACTER = "Character"
    L.LABEL_CLASS = "Class"
    L.LABEL_SPEC = "Spec"
    L.LABEL_LEVEL = "Level"
    L.LABEL_MENTOR_STAGE = "Mentor Stage"
    L.SPEC_NOT_SELECTED = "Not selected yet"
    L.SPELL_NEW_ABILITY = "New Ability Learned:"
    L.NEW_ABILITY_LEARNED = "New Ability Learned"
    L.MENTOR_TIP = "Mentor Tip"
    L.UNKNOWN_SPELL_NOTICE =
        "Mentor noticed a new ability, but no lesson is available for it yet."
    L.SPELL_PALADIN_CRUSADER_STRIKE =
        "Crusader Strike is a melee attack that builds Holy Power. Use it when you are close to your target."
    L.SPELL_PALADIN_JUDGMENT =
        "Judgment damages your enemy from range and helps your next Holy Power spenders hit harder."
    L.SPELL_PALADIN_FLASH_OF_LIGHT =
        "Flash of Light is a quick heal for you or an ally. Use it when health gets dangerously low."
    L.SPELL_PALADIN_SHIELD_OF_THE_RIGHTEOUS =
        "Shield of the Righteous spends Holy Power to hit enemies in front of you and greatly raises your armor for a short time. Use it when you are taking heavy damage (Protection, with a shield)."
    L.SPELL_PALADIN_HAMMER_OF_JUSTICE =
        "Hammer of Justice stuns an enemy for a short time. Use it to stop dangerous enemies."
    L.SPELL_PALADIN_CONSECRATION =
        "Consecration creates a holy damage area around you. Use it when fighting multiple enemies."
    L.SPELL_PALADIN_WORD_OF_GLORY =
        "Word of Glory spends Holy Power to heal you or an ally. Use it when you or someone nearby is hurt."
    L.SPELL_PALADIN_HAND_OF_RECKONING =
        "Hand of Reckoning taunts an enemy, making it focus on you. Be careful: this is mostly useful when you are tanking."
    L.LEVEL_UP = "Level Up!"
    L.LEVEL_REACHED = "You reached level %d."
    L.NEW_TRAINING_AVAILABLE = "New training may be available."
    L.MINIMAP_TOOLTIP_TITLE = "Azeroth Mentor"
    L.MINIMAP_TOOLTIP_LEFT_CLICK = "Left-click to open or close the mentor."

    print("|cff00ff00" .. L.LOADED .. "|r")
end
