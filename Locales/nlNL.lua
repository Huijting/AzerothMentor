--[[
  Azeroth Mentor - Dutch (nlNL) strings
  Applied only when the client locale is nlNL (overrides defaults from enUS.lua).
]]

local AM = _G.AM
local L = AM.L

if GetLocale() == "nlNL" then
    L.ADDON_TITLE = "Azeroth Mentor"
    L.LOADED = "[Azeroth Mentor] Succesvol geladen!"
    L.CLASS_BASICS = "Basis van je klasse"
    L.CHOOSE_YOUR_PATH = "Kies je pad"
    L.SPEC_ONBOARDING_TITLE = "Kies Je Pad"
    L.SPEC_ONBOARD_PALADIN_RETRIBUTION =
        "Retribution richt zich op het uitdelen van schade met heilige aanvallen."
    L.SPEC_ONBOARD_PALADIN_PROTECTION =
        "Protection richt zich op het beschermen van bondgenoten en het overleven van aanvallen."
    L.SPEC_ONBOARD_PALADIN_HOLY =
        "Holy richt zich op het genezen van bondgenoten en het in leven houden van de groep."
    L.SPEC_TRAINING = "Specialisatie training"
    L.GUIDANCE_CLASS_BASICS = "Leer bewegen, vechten en overleven."
    L.GUIDANCE_CHOOSE_PATH = "Kies een specialisatie om verder te leren."
    L.GUIDANCE_SPEC_TRAINING = "Gevechtshulp is actief."
    L.TUTORIAL_CLASS_BASICS =
        "Tip: Leer eerst bewegen, een vijand aanklikken en je eerste aanval gebruiken."
    L.TUTORIAL_CHOOSE_PATH =
        "Tip: Open je Specialisatie & Talenten venster en kies een specialisatie."
    L.TUTORIAL_SPEC_TRAINING =
        "Tip: Let op je vaardigheden en leer welke knoppen je energie opbouwen en uitgeven."
    L.RET_STAGE_TITLE = "Training: Retribution"
    L.RET_GUIDANCE =
        "Retribution Paladins bouwen Holy Power op met basisaanvallen en gebruiken het daarna voor sterkere vaardigheden."
    L.RET_TUTORIAL =
        "Gebruik eerst Crusader Strike en Judgment om Holy Power op te bouwen en gebruik daarna sterkere aanvallen."
    L.LABEL_CHARACTER = "Personage"
    L.LABEL_CLASS = "Klasse"
    L.LABEL_SPEC = "Specialisatie"
    L.LABEL_LEVEL = "Level"
    L.LABEL_MENTOR_STAGE = "Mentor fase"
    L.SPEC_NOT_SELECTED = "Nog niet gekozen"
    L.SPELL_NEW_ABILITY = "Nieuwe vaardigheid geleerd:"
    L.NEW_ABILITY_LEARNED = "Nieuwe vaardigheid geleerd"
    L.MENTOR_TIP = "Mentor Tip"
    L.UNKNOWN_SPELL_NOTICE =
        "Mentor heeft een nieuwe vaardigheid gezien, maar er is nog geen les voor beschikbaar."
    L.SPELL_PALADIN_CRUSADER_STRIKE =
        "Crusader Strike is een melee-aanval die Holy Power opbouwt. Gebruik het als je dicht bij je doelwit bent."
    L.SPELL_PALADIN_JUDGMENT =
        "Judgment raakt je vijand op afstand en maakt je volgende Holy Power-uitgaven effectiever."
    L.SPELL_RET_JUDGMENT =
        "Als Retribution gebruik je Judgment vaak op middelbare afstand. Het raakt je doelwit en maakt je volgende Holy Power-uitgaven sterker."
    L.SPELL_RET_TEMPLARS_VERDICT =
        "Templar's Verdict gebruikt Holy Power voor een harde single-target aanval. Bouw eerst Holy Power op en gebruik het als je één groot slag wilt uitdelen."
    L.SPELL_RET_BLADE_OF_JUSTICE =
        "Blade of Justice is een belangrijke builder: het geeft Holy Power op afstand zodat je het kunt uitgeven op afmakers zoals Templar's Verdict."
    L.SPELL_RET_WAKE_OF_ASHES =
        "Wake of Ashes raakt vijanden in een kegel voor je en geeft Holy Power. Gebruik het als meerdere vijanden bij elkaar staan of je snel Holy Power nodig hebt."
    L.SPELL_PALADIN_FLASH_OF_LIGHT =
        "Flash of Light is een snelle genezing voor jou of een bondgenoot. Gebruik het als het leven laag wordt."
    L.SPELL_PALADIN_SHIELD_OF_THE_RIGHTEOUS =
        "Shield of the Righteous gebruikt Holy Power om vijanden voor je te raken en je pantser kort sterk te verhogen. Gebruik het bij zwaar inkomend schade (Bescherming, met schild)."
    L.SPELL_PALADIN_HAMMER_OF_JUSTICE =
        "Hammer of Justice verdooft een vijand voor korte tijd. Gebruik het om gevaarlijke vijanden te stoppen."
    L.SPELL_PALADIN_CONSECRATION =
        "Consecration creëert een heilig gebied dat vijanden beschadigt. Gebruik het tegen meerdere vijanden tegelijk."
    L.SPELL_PALADIN_WORD_OF_GLORY =
        "Word of Glory gebruikt Holy Power om jou of een bondgenoot te genezen. Gebruik het als jij of iemand dichtbij gewond is."
    L.SPELL_PALADIN_HAND_OF_RECKONING =
        "Hand of Reckoning daagt een vijand uit, waardoor die zich op jou richt. Wees voorzichtig: dit is vooral nuttig als je tank bent."
    L.LEVEL_UP = "Level omhoog!"
    L.LEVEL_REACHED = "Je bent nu level %d."
    L.NEW_TRAINING_AVAILABLE = "Nieuwe training kan beschikbaar zijn."
    L.MINIMAP_TOOLTIP_TITLE = "Azeroth Mentor"
    L.MINIMAP_TOOLTIP_LEFT_CLICK = "Linksklik om de mentor te openen of sluiten."

    print("|cff00ff00" .. L.LOADED .. "|r")
end
