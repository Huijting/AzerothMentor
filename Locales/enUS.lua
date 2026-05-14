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
    L.SPEC_ONBOARDING_TITLE = L.CHOOSE_YOUR_PATH
    L.SPEC_ONBOARD_PALADIN_RETRIBUTION =
        "Retribution focuses on dealing damage with holy attacks."
    L.SPEC_ONBOARD_PALADIN_PROTECTION =
        "Protection focuses on defending allies and surviving enemy attacks."
    L.SPEC_ONBOARD_PALADIN_HOLY =
        "Holy focuses on healing allies and keeping the group alive."
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
    L.RET_STAGE_TITLE = "Retribution Training"
    L.RET_GUIDANCE =
        "Retribution Paladins build Holy Power with basic attacks and spend it on stronger abilities."
    L.RET_TUTORIAL =
        "Try using Crusader Strike and Judgment first, then spend Holy Power on stronger attacks."
    L.RET_HOLY_POWER_LABEL = "Holy Power: %d / %d"
    L.RET_HOLY_POWER_BUILD = "Build Holy Power with Crusader Strike and Judgment."
    L.RET_HOLY_POWER_SPEND = "You have enough Holy Power. Use a spender like Templar's Verdict."
    L.RET_COMBAT_LINE_OOC =
        "Out of combat: get familiar with Crusader Strike and Judgment so you are ready to build Holy Power in a fight."
    L.RET_COMBAT_LINE_BUILD = "Use Crusader Strike or Judgment to build Holy Power."
    L.RET_COMBAT_LINE_SPEND = "Use Templar's Verdict now for heavy damage."
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
    L.SPELL_RET_JUDGMENT =
        "As Retribution, use Judgment often from medium range. It hurts your target and makes your next Holy Power spenders hit harder."
    L.SPELL_RET_TEMPLARS_VERDICT =
        "Templar's Verdict spends Holy Power for a strong single-target attack. Build Holy Power with builders first, then use it when you want a big hit."
    L.SPELL_RET_CONSECRATED_BLADE =
        "Consecrated Blade is a passive effect. That means it improves your Paladin automatically; it is not a new button you need to press.\n\nKeep using your normal Retribution rhythm: build Holy Power, then spend it."
    L.SPELL_RET_BLADE_OF_JUSTICE =
        "Blade of Justice is a core builder: it generates Holy Power from range so you can spend it on finishers like Templar's Verdict."
    L.SPELL_RET_WAKE_OF_ASHES =
        "Wake of Ashes damages enemies in a cone in front of you and gives Holy Power. Use it when several enemies are grouped or you need Holy Power quickly."
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
    L.MILESTONE_ACTION_GOT_IT = "Got it"
    L.MILESTONE_TIP_LABEL = "Level milestone"
    L.MILESTONE_PALADIN_L1_TITLE = "Welcome, Paladin"
    L.MILESTONE_PALADIN_L1_SUBTITLE = "Level 1"
    L.MILESTONE_PALADIN_L1_BODY =
        "You wear plate armor and fight in melee range. Your toolkit mixes damage, utility, and self-healing as you grow."
    L.MILESTONE_PALADIN_L1_INSTRUCTION = "Practice moving, selecting a target, and using your first attack on a training dummy or easy quest mob."
    L.MILESTONE_PALADIN_L2_TITLE = "Growing stronger"
    L.MILESTONE_PALADIN_L2_SUBTITLE = "Level 2"
    L.MILESTONE_PALADIN_L2_BODY = "Each level unlocks stats and often new abilities. Check your spellbook when you ding."
    L.MILESTONE_PALADIN_L2_INSTRUCTION = "Open your spellbook and read what each ability does, even if you do not use them all yet."
    L.MILESTONE_PALADIN_L3_TITLE = "Basics of combat"
    L.MILESTONE_PALADIN_L3_SUBTITLE = "Level 3"
    L.MILESTONE_PALADIN_L3_BODY =
        "Stay in range of your target, watch your health bar, and use defensive or healing buttons when things go wrong."
    L.MILESTONE_PALADIN_L3_INSTRUCTION = "Try fighting one enemy at a time until your keybinds feel comfortable."
    L.MILESTONE_PALADIN_L5_TITLE = "Questing flow"
    L.MILESTONE_PALADIN_L5_SUBTITLE = "Level 5"
    L.MILESTONE_PALADIN_L5_BODY =
        "You will rotate through several abilities. Reading tooltips now saves confusion later when rotations get busier."
    L.MILESTONE_PALADIN_L5_INSTRUCTION = "After each new spell, hover its icon in the spellbook and read the tooltip once."
    L.MILESTONE_PALADIN_L10_TITLE = "Big milestone: specializations"
    L.MILESTONE_PALADIN_L10_SUBTITLE = "Level 10"
    L.MILESTONE_PALADIN_L10_BODY =
        "At level 10 you choose a specialization: Retribution (damage), Protection (tank), or Holy (healer). Your mentor lessons will follow that path."
    L.MILESTONE_PALADIN_L10_INSTRUCTION = "Open Specialization & Talents and pick the role you want to learn first."
    L.MILESTONE_PALADIN_RET_L10_TITLE = "Judgment in Retribution"
    L.MILESTONE_PALADIN_RET_L10_SUBTITLE = "Retribution · Level 10"
    L.MILESTONE_PALADIN_RET_L10_BODY =
        "Judgment strikes from medium range and empowers your next Holy Power spenders. It is a core part of your rotation."
    L.MILESTONE_PALADIN_RET_L10_INSTRUCTION = "Use Judgment early in a pull so your spenders benefit from its effect."
    L.MILESTONE_PALADIN_RET_L11_TITLE = "Crusader Strike"
    L.MILESTONE_PALADIN_RET_L11_SUBTITLE = "Retribution · Level 11"
    L.MILESTONE_PALADIN_RET_L11_BODY =
        "Crusader Strike is a melee builder that generates Holy Power. Pair it with Judgment to set up bigger hits."
    L.MILESTONE_PALADIN_RET_L11_INSTRUCTION = "Stay in melee range and weave Crusader Strike between other abilities."
    L.MILESTONE_PALADIN_RET_L12_TITLE = "Blade of Justice"
    L.MILESTONE_PALADIN_RET_L12_SUBTITLE = "Retribution · Level 12"
    L.MILESTONE_PALADIN_RET_L12_BODY =
        "Blade of Justice builds Holy Power from range, helping when you cannot stick to the target for a melee swing."
    L.MILESTONE_PALADIN_RET_L12_INSTRUCTION = "Use it when you need Holy Power but cannot Crusader Strike safely."
    L.MILESTONE_PALADIN_RET_L15_TITLE = "Templar's Verdict"
    L.MILESTONE_PALADIN_RET_L15_SUBTITLE = "Retribution · Level 15"
    L.MILESTONE_PALADIN_RET_L15_BODY =
        "Templar's Verdict spends Holy Power for a strong single-target nuke. Build Holy Power first, then spend it here."
    L.MILESTONE_PALADIN_RET_L15_INSTRUCTION = "After builders fill your Holy Power bar, press Templar's Verdict for a big spike of damage."
    L.MINIMAP_TOOLTIP_TITLE = "Azeroth Mentor"
    L.MINIMAP_TOOLTIP_LEFT_CLICK = "Left-click to open or close the mentor."

    print("|cff00ff00" .. L.LOADED .. "|r")
end
