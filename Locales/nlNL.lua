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
        "Gebruik Judgment, Blade of Justice en Crusader Strike om Holy Power op te bouwen en geef het daarna uit met je single-target spender."
    L.RET_HOLY_POWER_LABEL = "Holy Power: %d / %d"
    L.RET_HOLY_POWER_BUILD = "Bouw Holy Power op met Judgment, Blade of Justice en Crusader Strike."
    L.RET_HOLY_POWER_SPEND = "Je hebt genoeg Holy Power. Gebruik je single-target spender."
    L.RET_COMBAT_LINE_OOC =
        "Begin met Judgment of Blade of Justice, loop er dan naartoe en gebruik Crusader Strike."
    L.RET_COMBAT_LINE_BUILD =
        "Bouw Holy Power op met Judgment, Blade of Justice of Crusader Strike."
    L.RET_COMBAT_LINE_BUILD_WAIT = "Wacht kort tot een builder weer klaar is."
    L.RET_COMBAT_LINE_SPEND = "Geef Holy Power uit met je single-target spender."
    L.RET_COMBAT_LINE_SPEND_AOE = "Er zijn meerdere vijanden dichtbij. Geef Holy Power uit met Divine Storm."
    L.RET_COMBAT_LINE_SPEND_WAIT = "Wacht kort tot je spender weer klaar is."
    L.COMBAT_HINT_TITLE = "Azeroth Mentor"
    L.COMBAT_HINT_UNKNOWN_SPELL = "Onbekende vaardigheid"
    L.COMBAT_HINT_NO_HINT = "Geen gevechtstip"
    L.COMBAT_HINT_ACTION_BUILD = "Bouw Holy Power op"
    L.COMBAT_HINT_ACTION_SPEND = "Geef Holy Power uit"
    L.COMBAT_HINT_ACTION_WAIT = "Wacht kort"
    L.COMBAT_HINT_KEY = "Toets: %s"
    L.COMBAT_HINT_ACTION_START = "Start het gevecht"
    L.COMBAT_HINT_ACTION_MOVE_CLOSE = "Loop dichterbij en start"
    L.LABEL_CHARACTER = "Personage"
    L.LABEL_CLASS = "Klasse"
    L.LABEL_SPEC = "Specialisatie"
    L.LABEL_LEVEL = "Level"
    L.LABEL_MENTOR_STAGE = "Mentor fase"
    L.SPEC_NOT_SELECTED = "Nog niet gekozen"
    L.SPELL_NEW_ABILITY = "Nieuwe vaardigheid geleerd:"
    L.NEW_ABILITY_LEARNED = "Nieuwe vaardigheid geleerd"
    L.MENTOR_TIP = "Mentor Tip"
    L.TALENT_HELP_LABEL = "Talent hulp"
    L.TALENT_HELP_INLINE = "Talentpunt beschikbaar: besteed het wanneer je er klaar voor bent."
    L.TALENT_HELP_TITLE = "Talentpunt beschikbaar"
    L.TALENT_HELP_BODY =
        "Je hebt een onbesteed talentpunt. Volg je buildgids als je die gebruikt. Tijdens het leren zijn simpele of passieve talenten meestal makkelijker dan veel nieuwe knoppen."
    L.TALENT_HELP_INSTRUCTION =
        "Geeft een talent je een nieuwe vaardigheid, zet die op je balken en oefen rustig."
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
    L.SPELL_RET_FINAL_VERDICT =
        "Final Verdict hoort bij je Holy Power-spender gameplay. Met dit talent vervangt het Templar's Verdict op je actiebalk en verandert hoe je als Retribution zware single-target damage doet.\n\nBlijf hetzelfde basisidee volgen: bouw eerst Holy Power op en geef het daarna uit aan je sterkste single-target spender."
    L.SPELL_RET_DIVINE_STORM =
        "Divine Storm gebruikt Holy Power om meerdere vijanden dichtbij te raken. Gebruik Templar's Verdict tegen één vijand, en Divine Storm als je tegen meerdere vijanden tegelijk vecht.\n\nIs er maar één vijand, blijf dan Templar's Verdict gebruiken. Staan er meerdere vijanden dichtbij, dan wordt Divine Storm nuttig."
    L.SPELL_RET_CONSECRATED_BLADE =
        "Consecrated Blade is een passief effect. Dat betekent dat het je Paladin automatisch verbetert; het is geen nieuwe knop die je hoeft in te drukken.\n\nBlijf je normale Retribution-ritme gebruiken: bouw Holy Power op en geef het daarna uit."
    L.SPELL_RET_BLADE_OF_JUSTICE =
        "Blade of Justice is een belangrijke builder: het geeft Holy Power op afstand zodat je het kunt uitgeven op afmakers zoals Templar's Verdict."
    L.SPELL_RET_WAKE_OF_ASHES =
        "Wake of Ashes raakt vijanden in een kegel voor je en geeft Holy Power. Gebruik het als meerdere vijanden bij elkaar staan of je snel Holy Power nodig hebt."
    L.SPELL_PALADIN_AVENGING_WRATH =
        "Avenging Wrath is een sterke cooldown die je tijdelijk sterker maakt. Hij is handig tegen sterkere vijanden of wanneer je extra damage nodig hebt.\n\nHet is geen Holy Power-builder of -spender. Gebruik het voor extra burst en blijf daarna je normale gevechtsvaardigheden gebruiken."
    L.SPELL_RET_AVENGING_WRATH =
        "Avenging Wrath is een sterke cooldown die je tijdelijk sterker maakt. Hij is handig tegen sterkere vijanden of wanneer je extra damage nodig hebt.\n\nGebruik Avenging Wrath en blijf daarna je normale ritme volgen: bouw Holy Power op en geef het uit met je spender."
    L.SPELL_PALADIN_DIVINE_TOLL =
        "Divine Toll is een sterke talent-ability. Het is een aparte knop die je helpt schade te doen en Paladin-effecten te activeren.\n\nZet Divine Toll op je action bar. Gebruik het als extra sterke knop en ga daarna verder met je normale gevechtsritme."
    L.SPELL_RET_DIVINE_TOLL =
        "Divine Toll is een sterke talent-ability. Het is een aparte knop die je helpt schade te doen en Paladin-effecten te activeren.\n\nZet Divine Toll op je action bar. Gebruik het als extra sterke knop en ga daarna verder met je normale ritme: Holy Power opbouwen en uitgeven."
    L.SPELL_RET_RIGHTEOUS_CAUSE =
        "Righteous Cause is een passief talent. Het werkt automatisch en verbetert je bestaande Paladin-abilities.\n\nJe hoeft het niet op je action bar te zetten. Blijf gewoon je normale build/spend-ritme spelen."
    L.SPELL_RET_HEALING_HANDS =
        "Healing Hands is een passief talent dat je healing/support-tools verbetert. Het hoort niet bij je damage-rotatie.\n\nJe hebt hier geen nieuwe keybind voor nodig. Gebruik je healing abilities wanneer jij of een bondgenoot hulp nodig heeft."
    L.SPELL_PALADIN_FLASH_OF_LIGHT =
        "Flash of Light is een snelle genezing voor jou of een bondgenoot. Gebruik het als het leven laag wordt."
    L.SPELL_PALADIN_DIVINE_STEED =
        "Divine Steed laat je korte tijd sneller bewegen. Het is handig om sneller bij vijanden te komen, uit gevaar te bewegen of iets sneller te reizen.\n\nGebruik Divine Steed als je snel moet bewegen. Het hoort niet bij je normale damage-rotatie."
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
    L.SPELL_PALADIN_REDEMPTION =
        "Met Redemption kun je een dode vriendelijke speler weer tot leven brengen. Dit is vooral handig in groepen nadat iemand is gestorven.\n\nJe gebruikt Redemption meestal buiten gevecht. Het hoort niet bij je normale damage-rotatie."
    L.SPELL_PALADIN_INTERCESSION =
        "Met Intercession kun je een dode vriendelijke speler terugbrengen tijdens gevaarlijke groepsmomenten. Het is vooral handig in dungeons of groepscontent als iemand doodgaat.\n\nTijdens solo questen gebruik je Intercession meestal niet. Het hoort niet bij je normale damage-rotatie."
    L.SPELL_PALADIN_LAY_ON_HANDS =
        "Lay on Hands is een krachtige nood-heal. Het kan veel gezondheid herstellen, maar heeft een lange cooldown.\n\nBewaar Lay on Hands voor gevaarlijke momenten waarop jij of een belangrijke vriendelijke speler bijna doodgaat. Het hoort niet bij je normale damage-rotatie."
    L.SPELL_GENERAL_EXPERT_RIDING =
        "Expert Riding verbetert je rij- en vliegvaardigheid. Dit helpt je sneller te reizen, maar hoort niet bij je Paladin-gevechtsvaardigheden.\n\nGebruik rijden en vliegen om sneller door de wereld te reizen. Het verandert je damage-rotatie niet."
    L.SPELL_GENERAL_WHIRLING_SURGE =
        "Whirling Surge is een vliegbeweging. Het helpt je snel te bewegen tijdens dynamic flying of skyriding.\n\nGebruik het tijdens het vliegen als je extra snelheid of beweging wilt. Het hoort niet bij je Paladin-gevechtsrotatie."
    L.LEVEL_UP = "Level omhoog!"
    L.LEVEL_REACHED = "Je bent nu level %d."
    L.NEW_TRAINING_AVAILABLE = "Nieuwe training kan beschikbaar zijn."
    L.MILESTONE_ACTION_GOT_IT = "Begrepen"
    L.MILESTONE_TIP_LABEL = "Level mijlpaal"
    L.MILESTONE_PALADIN_L1_TITLE = "Welkom, Paladin"
    L.MILESTONE_PALADIN_L1_SUBTITLE = "Level 1"
    L.MILESTONE_PALADIN_L1_BODY =
        "Je draagt plaatpantser en vecht op melee-afstand. Je toolkit combineert schade, nut en zelfgenezing naarmate je groeit."
    L.MILESTONE_PALADIN_L1_INSTRUCTION = "Oefen bewegen, een doelwit kiezen en je eerste aanval op een oefenpop of makkelijke quest."
    L.MILESTONE_PALADIN_L2_TITLE = "Sterker worden"
    L.MILESTONE_PALADIN_L2_SUBTITLE = "Level 2"
    L.MILESTONE_PALADIN_L2_BODY = "Elk level geeft stats en vaak nieuwe vaardigheden. Kijk in je spellbook als je levelt."
    L.MILESTONE_PALADIN_L2_INSTRUCTION = "Open je spellbook en lees wat elke vaardigheid doet, ook als je ze nog niet allemaal gebruikt."
    L.MILESTONE_PALADIN_L3_TITLE = "Basis van gevecht"
    L.MILESTONE_PALADIN_L3_SUBTITLE = "Level 3"
    L.MILESTONE_PALADIN_L3_BODY =
        "Blijf binnen bereik van je doelwit, let op je levensbalk en gebruik verdediging of genezing als het misgaat."
    L.MILESTONE_PALADIN_L3_INSTRUCTION = "Vecht eerst tegen één vijand tegelijk tot je toetsen comfortabel aanvoelen."
    L.MILESTONE_PALADIN_L5_TITLE = "Quest flow"
    L.MILESTONE_PALADIN_L5_SUBTITLE = "Level 5"
    L.MILESTONE_PALADIN_L5_BODY =
        "Je wisselt tussen meerdere vaardigheden. Tooltips lezen nu voorkomt verwarring als je rotatie drukker wordt."
    L.MILESTONE_PALADIN_L5_INSTRUCTION = "Lees na elke nieuwe spell kort de tooltip in je spellbook."
    L.MILESTONE_PALADIN_L10_TITLE = "Grote mijlpaal: specialisaties"
    L.MILESTONE_PALADIN_L10_SUBTITLE = "Level 10"
    L.MILESTONE_PALADIN_L10_BODY =
        "Op level 10 kies je een specialisatie: Retribution (schade), Protection (tank) of Holy (healer). De mentor volgt dat pad."
    L.MILESTONE_PALADIN_L10_INSTRUCTION = "Open Specialisatie & Talenten en kies de rol die je eerst wilt leren."
    L.MILESTONE_PALADIN_RET_L10_TITLE = "Judgment als Retribution"
    L.MILESTONE_PALADIN_RET_L10_SUBTITLE = "Retribution · Level 10"
    L.MILESTONE_PALADIN_RET_L10_BODY =
        "Judgment is een belangrijke Holy Power-builder. Je kunt ermee op afstand beginnen en je volgende aanvallen voorbereiden.\n\nTalenten kunnen overweldigend ogen, maar je hoeft de hele boom nog niet te snappen. Begin met eenvoudige keuzes die vaardigheden ondersteunen die je al gebruikt."
    L.MILESTONE_PALADIN_RET_L10_INSTRUCTION = "Begin je volgende gevecht met Judgment, loop er dan naartoe en gebruik Crusader Strike."
    L.MILESTONE_PALADIN_RET_L11_TITLE = "Eerst opbouwen, dan uitgeven"
    L.MILESTONE_PALADIN_RET_L11_SUBTITLE = "Retribution · Level 11"
    L.MILESTONE_PALADIN_RET_L11_BODY =
        "Retribution wordt makkelijker als je in twee stappen denkt: bouw eerst Holy Power op, besteed het daarna op een sterkere aanval."
    L.MILESTONE_PALADIN_RET_L11_INSTRUCTION = "Probeer naar 3 Holy Power te gaan en gebruik dan Templar's Verdict."
    L.MILESTONE_PALADIN_RET_L12_TITLE = "Verspil geen Holy Power"
    L.MILESTONE_PALADIN_RET_L12_SUBTITLE = "Retribution · Level 12"
    L.MILESTONE_PALADIN_RET_L12_BODY =
        "Je kunt maar een beperkte hoeveelheid Holy Power vasthouden. Blijf je opbouwen terwijl je vol zit, dan raakt extra Holy Power verloren."
    L.MILESTONE_PALADIN_RET_L12_INSTRUCTION = "Als je bijna vol zit, besteed Holy Power voordat je weer builders gebruikt."
    L.MILESTONE_PALADIN_RET_L13_TITLE = "Blijf dichtbij voor melee"
    L.MILESTONE_PALADIN_RET_L13_SUBTITLE = "Retribution · Level 13"
    L.MILESTONE_PALADIN_RET_L13_BODY =
        "Sommige Paladin-aanvallen werken alleen dicht bij de vijand. Werkt een melee-vaardigheid niet, dan sta je misschien te ver."
    L.MILESTONE_PALADIN_RET_L13_INSTRUCTION = "Loop dicht naar je doelwit voordat je Crusader Strike of Templar's Verdict gebruikt."
    L.MILESTONE_PALADIN_RET_L14_TITLE = "Let op je knoppen"
    L.MILESTONE_PALADIN_RET_L14_SUBTITLE = "Retribution · Level 14"
    L.MILESTONE_PALADIN_RET_L14_BODY =
        "Vaardigheden hebben cooldowns. Is een knop even niet beschikbaar, gebruik dan een andere aanbevolen vaardigheid in plaats van steeds hetzelfde te spammen."
    L.MILESTONE_PALADIN_RET_L14_INSTRUCTION =
        "Volg in gevecht de mentor-kaart en wissel van knop als je huidige vaardigheid nog niet klaar is."
    L.MILESTONE_PALADIN_RET_L15_TITLE = "Talent-check"
    L.MILESTONE_PALADIN_RET_L15_SUBTITLE = "Retribution · Level 15"
    L.MILESTONE_PALADIN_RET_L15_BODY =
        "Je hebt nu een tijdje je basis-Retribution-ritme gebruikt. Talenten kunnen extra kracht of nieuwe knoppen geven, maar je hoeft nog geen perfecte keuzes te maken."
    L.MILESTONE_PALADIN_RET_L15_INSTRUCTION =
        "Kies voorlopig liever eenvoudige of passieve talenten die vaardigheden verbeteren die je al gebruikt. Voeg niet te veel nieuwe actieve knoppen toe tot het basis-ritme van opbouwen en uitgeven prettig voelt."
    L.MILESTONE_PALADIN_RET_L16_TITLE = "Blijf Holy Power opbouwen"
    L.MILESTONE_PALADIN_RET_L16_SUBTITLE = "Retribution · Level 16"
    L.MILESTONE_PALADIN_RET_L16_BODY =
        "Je hoofddoel blijft simpel: bouw Holy Power met je basisaanvallen en besteed het voordat je iets verspilt."
    L.MILESTONE_PALADIN_RET_L16_INSTRUCTION = "Probeer in je volgende gevechten niet te lang op vol Holy Power te blijven staan."
    L.MILESTONE_PALADIN_RET_L17_TITLE = "Begin gevechten rustig"
    L.MILESTONE_PALADIN_RET_L17_SUBTITLE = "Retribution · Level 17"
    L.MILESTONE_PALADIN_RET_L17_BODY =
        "Als je begint met een afstandsvaardigheid, kun je eerder schade doen voordat de vijand bij je is."
    L.MILESTONE_PALADIN_RET_L17_INSTRUCTION = "Open met Judgment en gebruik Crusader Strike als de vijand dichtbij is."
    L.MILESTONE_PALADIN_RET_L18_TITLE = "Als alles op cooldown is"
    L.MILESTONE_PALADIN_RET_L18_SUBTITLE = "Retribution · Level 18"
    L.MILESTONE_PALADIN_RET_L18_BODY =
        "Soms zijn je belangrijkste vaardigheden nog niet klaar. Dat hoort erbij. Wacht kort of pak de volgende beschikbare builder."
    L.MILESTONE_PALADIN_RET_L18_INSTRUCTION = "Geen paniek als knoppen even grijs zijn. Volg de volgende mentor-suggestie."
    L.MILESTONE_PALADIN_RET_L19_TITLE = "Besteed voordat je overcap"
    L.MILESTONE_PALADIN_RET_L19_SUBTITLE = "Retribution · Level 19"
    L.MILESTONE_PALADIN_RET_L19_BODY =
        "Blijf je Holy Power opbouwen terwijl je al vol zit, dan raakt extra Holy Power verloren."
    L.MILESTONE_PALADIN_RET_L19_INSTRUCTION = "Sta je Holy Power hoog, gebruik dan Templar's Verdict voordat je verder bouwt."
    L.MILESTONE_PALADIN_RET_L20_TITLE = "Je eerste echte ritme"
    L.MILESTONE_PALADIN_RET_L20_SUBTITLE = "Retribution · Level 20"
    L.MILESTONE_PALADIN_RET_L20_BODY =
        "Je hebt nu het begin van een echt Retribution-ritme: Holy Power opbouwen, uitgeven, en herhalen."
    L.MILESTONE_PALADIN_RET_L20_INSTRUCTION =
        "Oefen deze lus: Judgment, Crusader Strike, bouw naar 3 Holy Power, dan Templar's Verdict."
    L.LESSON_TOAST_TITLE = "Nieuwe les beschikbaar"
    L.LESSON_TOAST_SUBTITLE = "Klik om Azeroth Mentor te openen"
    L.MINIMAP_TOOLTIP_TITLE = "Azeroth Mentor"
    L.MINIMAP_TOOLTIP_LEFT_CLICK = "Linksklik om de mentor te openen of sluiten."

    print("|cff00ff00" .. L.LOADED .. "|r")
end
