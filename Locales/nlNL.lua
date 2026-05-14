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
    L.RET_GUIDANCE = "Retribution Paladin gevechtshulp is actief."
    L.RET_TUTORIAL = "Tip: Bouw eerst Holy Power op en gebruik die daarna voor sterke aanvallen."
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
