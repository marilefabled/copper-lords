-- Bloodweight — Death Narratives
-- Text fragments for heir death, infant death, and extinction.
-- Era-specific variants for narrative richness.
-- Pure data, zero dependencies.

local death_narratives = {}

-- Heir death narratives by cause (3+ per cause)
death_narratives.heir_death = {
    plague = {
        "{heir_name} was taken by the pestilence. No remedy, no prayer, no bloodline strength could hold back the rot.",
        "The plague claimed {heir_name} in the night. By dawn, the lineage stood without its pillar.",
        "{heir_name} succumbed to the sweating sickness. The healers could only watch as another generation ended in fever.",
        "The black marks appeared on {heir_name}'s skin at midday. By evening, the {lineage_name} had lost their future.",
    },
    killed_in_war = {
        "{heir_name} fell on the battlefield, blade in hand. The {lineage_name} line pays the price of boldness.",
        "Word came from the front: {heir_name} was struck down in the fighting. The war takes what it will.",
        "{heir_name} rode to war and did not return. The crows feast, and the {lineage_name} mourn.",
        "An arrow found {heir_name} during the siege. The bloodline's champion died far from home.",
    },
    starvation = {
        "The famine was merciless. {heir_name} gave their portion to the children, and withered for it.",
        "{heir_name} wasted away as the granaries ran dry. The {lineage_name} could not outrun hunger.",
        "Starvation took {heir_name} slowly. The family watched, powerless, as their heir grew thin as shadow.",
    },
    natural_frailty = {
        "{heir_name} was never strong. The body failed where the will could not compensate.",
        "A weakness in the blood took {heir_name} before their time. Some lines carry fragility like a hidden curse.",
        "{heir_name} collapsed without warning. The physicians spoke of a weak constitution, inherited and inescapable.",
        "The frailty that had always shadowed {heir_name} finally claimed its due. The {lineage_name} bloodline thins.",
    },
    madness = {
        "{heir_name} was found wandering the moors, speaking to things unseen. They never returned to reason.",
        "The madness came suddenly. {heir_name} could not be reached by voice or reason. The {lineage_name} are shaken.",
        "{heir_name}'s mind shattered like glass. Whether it was the pressure or the blood, none can say.",
        "{heir_name} stopped recognizing the world. The court spoke in whispers. The physicians spoke not at all.",
    },
}

-- Era-specific heir death variants (keyed by cause_era)
death_narratives.heir_death_era = {
    -- === PLAGUE ===
    plague_ancient = {
        "The sickness had no name yet. {heir_name} was among the first to learn what it took.",
        "{heir_name} died before the healers had words for what killed them. The ancient world offered no diagnosis, only a body.",
    },
    plague_iron = {
        "The plague cut through the war camp like a second army. {heir_name} fell to the enemy no blade could parry.",
        "{heir_name} survived the battles only to be claimed by the camp fever. The iron age's truest killer wore no armor.",
    },
    plague_dark = {
        "In the rotting years, plague was not an event. It was the weather. {heir_name} was taken by the climate.",
        "The pestilence that had become the dark age's permanent resident finally reached the holdfast. {heir_name} was not spared.",
        "{heir_name} died in a room that smelled of vinegar and prayer. Neither helped.",
    },
    plague_arcane = {
        "The plague carried traces of something that was not entirely natural. {heir_name} died with strange lights behind their eyes.",
        "Sorcery could not cure what sorcery may have caused. {heir_name} learned this too late.",
    },
    plague_gilded = {
        "{heir_name} had access to the finest physicians gold could buy. The plague did not accept payment.",
        "The gilded age believed it had conquered disease. {heir_name}'s death was an uncomfortable correction.",
    },
    plague_twilight = {
        "The plague took {heir_name} in the twilight, when medicine had been forgotten and prayer had stopped working.",
        "{heir_name} died of a sickness that an earlier age would have cured. The twilight offered only sympathy.",
    },

    -- === KILLED IN WAR ===
    killed_in_war_ancient = {
        "{heir_name} fell in a skirmish that history would not bother to name. The ancient world was generous with violence.",
        "A stone axe ended {heir_name}'s ambitions. In the ancient age, death was unceremonious.",
    },
    killed_in_war_iron = {
        "{heir_name} was cut down in the fighting, blade against blade, the way the Iron Age preferred.",
        "The Iron Age asked for {heir_name}'s life. The Iron Age does not ask twice.",
    },
    killed_in_war_dark = {
        "{heir_name} died in a war fought over ruins. The dark age's battles were fought for what remained, which was not much.",
        "They found {heir_name} face-down in the mud. In the dark years, this was the standard posture for the dead.",
    },
    killed_in_war_arcane = {
        "{heir_name} was killed by something that was not entirely a weapon and not entirely alive.",
        "The arcane wars left bodies that did not decay normally. {heir_name}'s was one of them.",
    },
    killed_in_war_gilded = {
        "{heir_name} died in a war that was, strictly speaking, unnecessary. The gilded age specialized in those.",
        "The war was profitable for everyone except {heir_name}, who paid the only price that cannot be refunded.",
    },
    killed_in_war_twilight = {
        "{heir_name} fell in one of the twilight's last battles, fought over resources no one could remember hoarding.",
        "War in the final age was desperate and small. {heir_name} died in it anyway.",
    },

    -- === STARVATION ===
    starvation_ancient = {
        "{heir_name} starved in an age when the land had not yet learned to be generous.",
        "The ancient world fed the strong and forgot the rest. {heir_name} was forgotten.",
    },
    starvation_iron = {
        "The armies ate the countryside bare. {heir_name} starved in the wake of someone else's campaign.",
        "Iron feeds no one. {heir_name} learned this when the granaries were melted down for arrowheads.",
    },
    starvation_dark = {
        "Famine in the dark age was not an event. It was the season. {heir_name} did not survive the season.",
        "{heir_name} wasted away in the rot, which was at least consistent in what it took.",
    },
    starvation_arcane = {
        "{heir_name} starved while the arcane fires burned grain that could have fed a province.",
        "Power was abundant in the arcane age. Food was not. {heir_name} could not eat power.",
    },
    starvation_gilded = {
        "{heir_name} starved in an age of plenty, which takes a particular failure of distribution.",
        "The gilded age had surplus in the wrong places and {heir_name} in the wrong place.",
    },
    starvation_twilight = {
        "{heir_name} starved as the twilight consumed the last arable land. There was nothing poetic about it.",
        "The final age ran out of food before it ran out of heirs. {heir_name} corrected this imbalance.",
    },

    -- === NATURAL FRAILTY ===
    natural_frailty_ancient = {
        "The ancient world had no patience for the frail. {heir_name}'s body failed in a world that did not pause.",
        "{heir_name} was too fragile for an age that demanded stone and sinew. The bloodline paid the entry fee.",
    },
    natural_frailty_iron = {
        "{heir_name}'s constitution was unsuited for an age of iron. The body broke where the age demanded it bend.",
        "The iron years required endurance. {heir_name} had everything except that.",
    },
    natural_frailty_dark = {
        "The dark age weakened everything. {heir_name}, already frail, had no reserves to spend.",
        "{heir_name}'s body surrendered to the rot that claimed the age itself.",
    },
    natural_frailty_arcane = {
        "The arcane energies aggravated {heir_name}'s frailty. The body was not designed for what the age demanded.",
        "{heir_name} was too fragile to channel what the arcane age poured through every living thing.",
    },
    natural_frailty_gilded = {
        "The physicians of the gilded age prolonged {heir_name}'s decline but could not prevent it.",
        "{heir_name} died comfortably, which in the gilded age was the only innovation applied to death.",
    },
    natural_frailty_twilight = {
        "{heir_name}'s body failed in the twilight, as bodies do when the world itself is failing.",
        "The final age and {heir_name}'s constitution reached their end at approximately the same pace.",
    },

    -- === MADNESS ===
    madness_ancient = {
        "{heir_name}'s mind broke under the weight of a world too vast and too new to comprehend.",
        "Madness in the ancient age was called possession. {heir_name} was possessed by something that had no name.",
    },
    madness_iron = {
        "The relentless violence of the Iron Age finally cracked {heir_name}'s mind. The blade does not only cut flesh.",
        "{heir_name} went mad between battles. The silence between the fighting was, apparently, worse.",
    },
    madness_dark = {
        "The dark age drove {heir_name} mad, which was barely distinguishable from the age's effect on everyone else.",
        "{heir_name}'s mind rotted alongside the world. In the dark years, this was considered normal.",
    },
    madness_arcane = {
        "The arcane whispered to {heir_name} until the whispers drowned out everything else.",
        "{heir_name} saw things in the arcane fire that a human mind was not built to contain. The mind agreed.",
    },
    madness_gilded = {
        "{heir_name} went mad in the gilded age, which the court attributed to eccentricity until the screaming started.",
        "Prosperity drove {heir_name} to madness. Comfort, it turns out, does not cure what comfort causes.",
    },
    madness_twilight = {
        "{heir_name} lost their mind in the twilight. Whether this was the age's fault or the blood's is a question no one remained to answer.",
        "Madness in the final age was merciful. {heir_name} stopped understanding what was being lost.",
    },
}

-- Infant/offspring death narratives by cause (2+ per cause)
death_narratives.infant_death = {
    plague = {
        "A child of the {lineage_name} was claimed by plague before drawing a full year's breath.",
        "The pestilence took the youngest first. One of {heir_name}'s children did not survive.",
    },
    starvation = {
        "Famine is cruelest to the young. One of {heir_name}'s children could not be sustained.",
        "There was not enough. A child of the {lineage_name} perished from want.",
    },
    war_casualty = {
        "The violence spared no one — not even the children. One of {heir_name}'s offspring was lost.",
        "War does not distinguish age. A child of the {lineage_name} was caught in the destruction.",
    },
    natural_frailty = {
        "One of {heir_name}'s children was born too fragile for this world. They lived only briefly.",
        "A weak child of the {lineage_name} could not hold on. The bloodline's frailty claims another.",
        "The infant never thrived. Some weakness in the blood ensured a short, quiet life.",
    },
}

-- Extinction messages (when the lineage ends)
death_narratives.extinction = {
    no_children = {
        "The {lineage_name} bloodline ends here. No children survived to carry the name forward. The Weight falls silent.",
        "No heir remains. The {lineage_name} line, which endured {generation} generations, is extinguished. The ancestors have no voice.",
        "The cradle stands empty. The {lineage_name} produced no surviving offspring. What was built across {generation} generations crumbles to dust.",
    },
    heir_death = {
        "{heir_name} is dead, and with them, the {lineage_name} line. There is no one left to carry the Weight.",
        "The death of {heir_name} ends everything. {generation} generations of blood, choice, and consequence — silenced.",
        "With {heir_name}'s final breath, the {lineage_name} legacy dies. The world moves on, indifferent to what was lost.",
    },
}

-- Short death cause labels for UI
death_narratives.cause_labels = {
    plague = "Taken by Plague",
    killed_in_war = "Killed in War",
    starvation = "Claimed by Famine",
    natural_frailty = "Constitutional Failure",
    madness = "Lost to Madness",
    war_casualty = "Casualty of War",
    crucible = "Broken by the Crucible",
    no_children = "The Cradle is Empty",
}

-- Death knell ceremony: large dramatic cause labels (all caps)
death_narratives.knell_labels = {
    plague = "TAKEN BY PLAGUE",
    killed_in_war = "FALLEN IN WAR",
    starvation = "CLAIMED BY FAMINE",
    natural_frailty = "THE BODY FAILED",
    madness = "CONSUMED BY MADNESS",
    war_casualty = "LOST TO WAR",
    crucible = "BROKEN BY THE CRUCIBLE",
    no_children = "THE CRADLE IS EMPTY",
}

-- Final words for the death knell ceremony
death_narratives.final_words = {
    heir_death = {
        "The weight passes to no one.",
        "The ancestors fall silent.",
        "There is no one left to remember.",
        "The name dies on no one's lips.",
    },
    no_children = {
        "The cradle stands empty.",
        "There will be no next generation.",
        "The blood has run its course.",
        "No cry of life. Only silence.",
    },
}

-- Game over screen flavor text
death_narratives.game_over_flavor = {
    "Every dynasty ends. Yours lasted {generation} generations.",
    "The Weight is lifted. The bloodline is no more.",
    "What your ancestors built, time and fate have unmade.",
    "The name {lineage_name} will be forgotten. Such is the way of all things.",
}

return death_narratives
