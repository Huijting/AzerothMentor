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
        "Use Judgment, Blade of Justice, and Crusader Strike to build Holy Power, then spend it with your single-target spender."
    L.RET_HOLY_POWER_LABEL = "Holy Power: %d / %d"
    L.RET_HOLY_POWER_BUILD = "Build Holy Power with Judgment, Blade of Justice, and Crusader Strike."
    L.RET_HOLY_POWER_SPEND = "You have enough Holy Power. Use your single-target spender."
    L.RET_COMBAT_LINE_OOC =
        "Start with Judgment or Blade of Justice, then move in and use Crusader Strike."
    L.RET_COMBAT_LINE_BUILD =
        "Build Holy Power with Judgment, Blade of Justice, or Crusader Strike."
    L.RET_COMBAT_LINE_BUILD_WAIT = "Wait briefly for a builder to become ready."
    L.RET_COMBAT_LINE_SPEND = "Spend Holy Power with your single-target spender."
    L.RET_COMBAT_LINE_SPEND_WAIT = "Wait briefly for your spender to become ready."
    L.COMBAT_HINT_TITLE = "Azeroth Mentor"
    L.COMBAT_HINT_UNKNOWN_SPELL = "Unknown spell"
    L.COMBAT_HINT_NO_HINT = "No combat hint"
    L.COMBAT_HINT_ACTION_BUILD = "Build Holy Power"
    L.COMBAT_HINT_ACTION_SPEND = "Spend Holy Power"
    L.COMBAT_HINT_ACTION_WAIT = "Wait briefly"
    L.COMBAT_HINT_KEY = "Key: %s"
    L.COMBAT_HINT_ACTION_START = "Start fight"
    L.COMBAT_HINT_ACTION_MOVE_CLOSE = "Move close and start"
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
    L.SPELL_RET_FINAL_VERDICT =
        "Final Verdict is connected to your Holy Power spender gameplay. When you take this talent, it replaces Templar's Verdict on your action bar and changes how you deal heavy single-target damage as Retribution.\n\nKeep following the same idea: build Holy Power first, then spend it on your strongest single-target spender."
    L.SPELL_RET_DIVINE_STORM =
        "Divine Storm spends Holy Power to hit multiple nearby enemies. Use Templar's Verdict for one enemy, and Divine Storm when you are fighting several enemies close together.\n\nIf there is only one enemy, keep using Templar's Verdict. If several enemies are near you, Divine Storm becomes useful."
    L.SPELL_RET_CONSECRATED_BLADE =
        "Consecrated Blade is a passive effect. That means it improves your Paladin automatically; it is not a new button you need to press.\n\nKeep using your normal Retribution rhythm: build Holy Power, then spend it."
    L.SPELL_RET_BLADE_OF_JUSTICE =
        "Blade of Justice is a core builder: it generates Holy Power from range so you can spend it on finishers like Templar's Verdict."
    L.SPELL_RET_WAKE_OF_ASHES =
        "Wake of Ashes damages enemies in a cone in front of you and gives Holy Power. Use it when several enemies are grouped or you need Holy Power quickly."
    L.SPELL_PALADIN_FLASH_OF_LIGHT =
        "Flash of Light is a quick heal for you or an ally. Use it when health gets dangerously low."
    L.SPELL_PALADIN_DIVINE_STEED =
        "Divine Steed makes you move faster for a short time. It is useful for reaching enemies, moving out of danger, or traveling a little faster.\n\nUse Divine Steed when you need to move quickly. It is not part of your normal damage rotation."
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
    L.SPELL_PALADIN_REDEMPTION =
        "Redemption lets you bring a dead friendly player back to life. This is useful in groups after someone dies.\n\nYou usually use Redemption outside combat. It is not part of your normal damage rotation."
    L.SPELL_PALADIN_INTERCESSION =
        "Intercession lets you bring a dead friendly player back during dangerous group moments. It is useful in dungeons or group content when someone dies.\n\nYou usually do not use Intercession while solo questing. It is not part of your normal damage rotation."
    L.SPELL_PALADIN_LAY_ON_HANDS =
        "Lay on Hands is a powerful emergency heal. It can restore a large amount of health, but it has a long cooldown.\n\nSave Lay on Hands for dangerous moments when you or an important friendly target might die. It is not part of your normal damage rotation."
    L.SPELL_GENERAL_EXPERT_RIDING =
        "Expert Riding improves your riding and flying skill. This helps you travel faster, but it is not part of your Paladin combat abilities.\n\nUse riding and flying to move around the world faster. It does not change your damage rotation."
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
        "Judgment is one of your important Holy Power builders. It lets you start a fight from range and helps prepare your next attacks.\n\nTalents may look overwhelming, but you do not need to understand the whole tree yet. Start with simple choices that support abilities you already use."
    L.MILESTONE_PALADIN_RET_L10_INSTRUCTION = "Open your next fight with Judgment, then move in and use Crusader Strike."
    L.MILESTONE_PALADIN_RET_L11_TITLE = "Build, then spend"
    L.MILESTONE_PALADIN_RET_L11_SUBTITLE = "Retribution · Level 11"
    L.MILESTONE_PALADIN_RET_L11_BODY =
        "Retribution becomes easier when you think in two steps: build Holy Power first, then spend it on a stronger attack."
    L.MILESTONE_PALADIN_RET_L11_INSTRUCTION = "Try to reach 3 Holy Power, then use Templar's Verdict."
    L.MILESTONE_PALADIN_RET_L12_TITLE = "Do not waste Holy Power"
    L.MILESTONE_PALADIN_RET_L12_SUBTITLE = "Retribution · Level 12"
    L.MILESTONE_PALADIN_RET_L12_BODY =
        "You can only hold a limited amount of Holy Power. If you keep building while full, the extra Holy Power is wasted."
    L.MILESTONE_PALADIN_RET_L12_INSTRUCTION = "When you are near full Holy Power, spend it before using more builders."
    L.MILESTONE_PALADIN_RET_L13_TITLE = "Stay close for melee attacks"
    L.MILESTONE_PALADIN_RET_L13_SUBTITLE = "Retribution · Level 13"
    L.MILESTONE_PALADIN_RET_L13_BODY =
        "Some Paladin attacks only work when you are close to the enemy. If a melee ability does not work, you may be too far away."
    L.MILESTONE_PALADIN_RET_L13_INSTRUCTION = "Move close to your target before using Crusader Strike or Templar's Verdict."
    L.MILESTONE_PALADIN_RET_L14_TITLE = "Watch your buttons"
    L.MILESTONE_PALADIN_RET_L14_SUBTITLE = "Retribution · Level 14"
    L.MILESTONE_PALADIN_RET_L14_BODY =
        "Abilities have cooldowns. If one button is unavailable, use another recommended ability instead of pressing the same one repeatedly."
    L.MILESTONE_PALADIN_RET_L14_INSTRUCTION =
        "During combat, follow the mentor card and switch buttons when your current ability is not ready."
    L.MILESTONE_PALADIN_RET_L15_TITLE = "Talent checkpoint"
    L.MILESTONE_PALADIN_RET_L15_SUBTITLE = "Retribution · Level 15"
    L.MILESTONE_PALADIN_RET_L15_BODY =
        "You have now used your basic Retribution rhythm for a while. Talents can add power or new buttons, but you do not need to make perfect choices yet."
    L.MILESTONE_PALADIN_RET_L15_INSTRUCTION =
        "For now, prefer simple or passive talents that improve abilities you already use. Avoid adding too many new active buttons until the basic build-and-spend rhythm feels comfortable."
    L.MILESTONE_PALADIN_RET_L16_TITLE = "Keep building Holy Power"
    L.MILESTONE_PALADIN_RET_L16_SUBTITLE = "Retribution · Level 16"
    L.MILESTONE_PALADIN_RET_L16_BODY =
        "Your main goal is still simple: build Holy Power with your basic attacks, then spend it before you waste any."
    L.MILESTONE_PALADIN_RET_L16_INSTRUCTION = "In your next fights, try not to sit at full Holy Power for too long."
    L.MILESTONE_PALADIN_RET_L17_TITLE = "Start fights cleanly"
    L.MILESTONE_PALADIN_RET_L17_SUBTITLE = "Retribution · Level 17"
    L.MILESTONE_PALADIN_RET_L17_BODY =
        "Starting with a ranged ability helps you begin dealing damage before the enemy reaches you."
    L.MILESTONE_PALADIN_RET_L17_INSTRUCTION = "Try opening with Judgment, then use Crusader Strike when the enemy is close."
    L.MILESTONE_PALADIN_RET_L18_TITLE = "When everything is on cooldown"
    L.MILESTONE_PALADIN_RET_L18_SUBTITLE = "Retribution · Level 18"
    L.MILESTONE_PALADIN_RET_L18_BODY =
        "Sometimes your main abilities are not ready yet. That is normal. Wait briefly or use the next available builder."
    L.MILESTONE_PALADIN_RET_L18_INSTRUCTION = "Do not panic when buttons are unavailable. Follow the next mentor suggestion."
    L.MILESTONE_PALADIN_RET_L19_TITLE = "Spend before you overcap"
    L.MILESTONE_PALADIN_RET_L19_SUBTITLE = "Retribution · Level 19"
    L.MILESTONE_PALADIN_RET_L19_BODY =
        "If you keep building Holy Power while already full, the extra Holy Power is lost."
    L.MILESTONE_PALADIN_RET_L19_INSTRUCTION = "When you reach high Holy Power, use Templar's Verdict before building more."
    L.MILESTONE_PALADIN_RET_L20_TITLE = "Your first real rhythm"
    L.MILESTONE_PALADIN_RET_L20_SUBTITLE = "Retribution · Level 20"
    L.MILESTONE_PALADIN_RET_L20_BODY =
        "You now have the start of a real Retribution rhythm: build Holy Power, spend it, and repeat."
    L.MILESTONE_PALADIN_RET_L20_INSTRUCTION =
        "Practice this loop: Judgment, Crusader Strike, build to 3 Holy Power, then Templar's Verdict."
    L.LESSON_TOAST_TITLE = "New lesson available"
    L.LESSON_TOAST_SUBTITLE = "Click to open Azeroth Mentor"
    L.MINIMAP_TOOLTIP_TITLE = "Azeroth Mentor"
    L.MINIMAP_TOOLTIP_LEFT_CLICK = "Left-click to open or close the mentor."

    print("|cff00ff00" .. L.LOADED .. "|r")
end
