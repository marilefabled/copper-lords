-- Dark Legacy — Multi-stat Legacy Events
-- Events referencing religion, culture, deep cultural memory, and long-term consequences.

return {
    {
        id = "ancestral_trial",
        title = "The Ancestral Trial",
        narrative = "An ancient family tradition requires {heir_name} to undergo a trial of worthiness. The dead are watching.",
        chance = 0.2,
        requires_generation = 8,
        cooldown = 10,
        options = {
            {
                label = "Face the trial of body",
                description = "Endurance and vitality tested to breaking point.",
                check = { primary = { trait = "PHY_END", weight = 1.0 }, secondary = { trait = "PHY_VIT", weight = 0.7 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 4 },
                    narrative = "{heir_name} endures what would break lesser heirs. The ancestors nod approval.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    narrative = "{heir_name} collapses before the trial's end. Shame lingers like a bruise.",
                },
            },
            {
                label = "Face the trial of mind",
                description = "Intellect and willpower navigate the labyrinth.",
                check = { primary = { trait = "MEN_INT", weight = 1.0 }, secondary = { trait = "MEN_WIL", weight = 0.6 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 4 },
                    narrative = "{heir_name} solves riddles that have stumped the line for generations.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -2 },
                    narrative = "The labyrinth defeats {heir_name}. Some puzzles outlive their solvers.",
                },
            },
            {
                label = "Refuse the trial entirely",
                description = "Break with tradition. Risk the consequences.",
                requires = { axis = "PER_ADA", min = 60 },
                consequences = {
                    cultural_memory_shift = { social = -3 },
                    taboo_chance = 0.4,
                    taboo_data = { trigger = "refused_ancestral_trial", effect = "broken_tradition", strength = 75 },
                    narrative = "{heir_name} declares the trial outdated. A bold statement — and a dangerous one.",
                },
            },
        },
    },

    {
        id = "generational_debt",
        title = "The Debt Comes Due",
        narrative = "An oath sworn by a forgotten ancestor surfaces. A distant faction arrives to collect.",
        chance = 0.2,
        requires_generation = 12,
        cooldown = 15,
        once_per_run = true,
        options = {
            {
                label = "Honor the oath",
                description = "Trustworthiness and loyalty pay the price.",
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    faction_power_shift = -5,
                    narrative = "The debt is paid. The bloodline's word — even from generations past — holds.",
                },
            },
            {
                label = "Renegotiate the terms",
                description = "Negotiation and eloquence rewrite the deal.",
                check = { primary = { trait = "SOC_NEG", weight = 1.0 }, secondary = { trait = "SOC_ELO", weight = 0.6 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { social = 3, mental = 1 },
                    narrative = "{heir_name} finds loopholes in the ancient pact. The debt is reduced — legitimately.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The creditors are not amused by legal tricks. The full price is demanded.",
                },
            },
            {
                label = "Refuse and prepare for conflict",
                description = "Strength and intimidation send a message.",
                requires = { axis = "PER_BLD", min = 60 },
                check = { primary = { trait = "PHY_STR", weight = 0.7 }, secondary = { trait = "SOC_INM", weight = 0.8 }, tertiary = { trait = "PHY_HGT", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    taboo_chance = 0.3,
                    taboo_data = { trigger = "broke_ancestral_oath", effect = "oathbreaker_reputation", strength = 80 },
                    narrative = "{heir_name} refuses. The word of the dead means nothing to the living.",
                },
                consequences_fail = {
                    add_condition = { type = "war", intensity = 0.5, duration = 2 },
                    narrative = "Your refusal brings war. The debt is now paid in blood.",
                },
            },
        },
    },

    {
        id = "heir_defied_religion",
        title = "Against the Faith",
        narrative = "{heir_name}'s actions directly contradict the tenets of the family's faith. The devout are outraged.",
        chance = 0.25,
        requires_generation = 6,
        cooldown = 8,
        options = {
            {
                label = "Repent publicly",
                description = "Charisma and social awareness smooth over the crisis.",
                check = { primary = { trait = "SOC_CHA", weight = 0.8 }, secondary = { trait = "SOC_AWR", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "{heir_name} bows before the altar. Sincerity — or a convincing performance. Either way, the crisis passes.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The repentance rings hollow. Faith cracks further.",
                },
            },
            {
                label = "Double down — challenge the faith",
                description = "Willpower and eloquence redefine orthodoxy.",
                requires = { axis = "PER_BLD", min = 60 },
                check = { primary = { trait = "MEN_WIL", weight = 0.8 }, secondary = { trait = "SOC_ELO", weight = 0.7 }, difficulty = 65 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    taboo_chance = 0.4,
                    taboo_data = { trigger = "heir_defied_religion", effect = "religious_schism", strength = 70 },
                    narrative = "{heir_name} declares a new interpretation. Some follow. Others seethe.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -4 },
                    narrative = "The challenge fails. {heir_name} is branded apostate. The wound runs deep.",
                },
            },
            {
                label = "Ignore the controversy",
                description = "Let time blur the memory.",
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The controversy fades — slowly. Some grudges, however, do not.",
                },
            },
        },
    },

    {
        id = "culture_broken",
        title = "The Custom Dies",
        narrative = "A beloved cultural custom can no longer be sustained. The family must decide whether to mourn or move on.",
        chance = 0.2,
        requires_generation = 10,
        cooldown = 12,
        options = {
            {
                label = "Revive the custom at any cost",
                description = "Leadership and craftsmanship restore what was lost.",
                check = { primary = { trait = "SOC_LEA", weight = 0.7 }, secondary = { trait = "CRE_CRA", weight = 0.6 }, tertiary = { trait = "CRE_MUS", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 2, creative = 2 },
                    narrative = "{heir_name} pours resources into keeping the tradition alive. It endures — for now.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -2 },
                    narrative = "Despite the effort, the custom withers. Some things cannot be forced.",
                },
            },
            {
                label = "Let it go",
                description = "Adaptability accepts that all things end.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    taboo_chance = 0.25,
                    taboo_data = { trigger = "culture_broken", effect = "cultural_wound", strength = 55 },
                    narrative = "The custom passes into memory. The family is lighter — and emptier.",
                },
            },
            {
                label = "Replace it with something new",
                description = "Innovation and vision create from destruction.",
                check = { primary = { trait = "CRE_ING", weight = 1.0 }, secondary = { trait = "CRE_VIS", weight = 0.5 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 4 },
                    narrative = "{heir_name} invents a new tradition to fill the void. Whether it takes root remains to be seen.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The replacement feels hollow. Novelty is not heritage.",
                },
            },
        },
    },

    {
        id = "whisper_of_ancestors",
        title = "Whispers from the Blood",
        narrative = "In the depths of sleep, {heir_name} hears the voices of ancestors. They speak of a path not taken.",
        chance = 0.15,
        requires_generation = 15,
        cooldown = 15,
        options = {
            {
                label = "Listen and follow their guidance",
                description = "Intuition and dream clarity open the way.",
                check = { primary = { trait = "MEN_ITU", weight = 1.0 }, secondary = { trait = "MEN_DRM", weight = 0.8 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    mutation_triggers = { { type = "mystical", intensity = 0.3 } },
                    narrative = "The ancestors speak true. A forgotten path opens. {heir_name} walks it with eyes wide open.",
                },
                consequences_fail = {
                    narrative = "The whispers are garbled. Perhaps {heir_name}'s blood is not pure enough to hear.",
                },
            },
            {
                label = "Reject the voices",
                description = "Willpower and composure resist the dead.",
                check = { primary = { trait = "MEN_WIL", weight = 1.0 }, secondary = { trait = "MEN_COM", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "{heir_name} silences the voices by force of will. The living decide for the living.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -2 },
                    narrative = "The voices persist. Sleep becomes a battleground.",
                },
            },
        },
    },

    -- USURPATION EVENTS
    {
        id = "usurpation_military",
        title = "The Iron Pretender",
        narrative = "A rival general claims the bloodline is weak. Soldiers rally to their banner. The usurper marches.",
        chance = 0.15,
        requires_generation = 8,
        cooldown = 15,
        once_per_run = true,
        options = {
            {
                label = "Meet the usurper in battle",
                description = "Strength, strategy, and courage on the field.",
                check = { primary = { trait = "PHY_STR", weight = 0.8 }, secondary = { trait = "MEN_STR", weight = 0.8 }, tertiary = { trait = "PHY_BLD", weight = 0.3 }, personality = { axis = "PER_BLD", weight = 0.3 }, difficulty = 65 },
                consequences = {
                    cultural_memory_shift = { physical = 5 },
                    narrative = "{heir_name} leads the charge personally. The usurper's army breaks. The bloodline endures.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -3 },
                    faction_power_shift = -15,
                    narrative = "The battle is lost. {heir_name} retreats. The family's grip on power weakens terribly.",
                },
            },
            {
                label = "Rally allies through diplomacy",
                description = "Charisma and leadership build a coalition.",
                check = { primary = { trait = "SOC_CHA", weight = 1.0 }, secondary = { trait = "SOC_LEA", weight = 0.7 }, tertiary = { trait = "PHY_HGT", weight = 0.2 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    narrative = "{heir_name} gathers allies from every corner. The usurper, outnumbered, surrenders.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -3 },
                    faction_power_shift = -10,
                    narrative = "No one answers the call. The family stands alone against the pretender.",
                },
            },
            {
                label = "Assassinate the usurper",
                description = "Cunning and deception eliminate the threat quietly.",
                requires = { axis = "PER_CRM", min = 55 },
                check = { primary = { trait = "MEN_CUN", weight = 1.0 }, secondary = { trait = "SOC_DEC", weight = 0.6 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    taboo_chance = 0.35,
                    taboo_data = { trigger = "assassinated_rival", effect = "feared_as_shadow", strength = 75 },
                    narrative = "The usurper dies in the night. No one claims credit. Everyone suspects.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -4 },
                    add_condition = { type = "war", intensity = 0.6, duration = 3 },
                    narrative = "The assassination fails. Now it's open war — with the stain of attempted murder.",
                },
            },
        },
    },

    {
        id = "usurpation_political",
        title = "The Court Coup",
        narrative = "Powerful courtiers conspire to strip {heir_name}'s family of titles and land. The coup is silent but deadly.",
        chance = 0.12,
        requires_generation = 10,
        cooldown = 15,
        once_per_run = true,
        options = {
            {
                label = "Outmaneuver them in court",
                description = "Social awareness, eloquence, and cunning are your weapons.",
                check = { primary = { trait = "SOC_AWR", weight = 0.8 }, secondary = { trait = "SOC_ELO", weight = 0.7 }, personality = { axis = "PER_CUR", weight = 0.2 }, difficulty = 65 },
                consequences = {
                    cultural_memory_shift = { social = 5 },
                    narrative = "{heir_name} turns the conspirators against each other. The family's position is stronger than ever.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -4 },
                    faction_power_shift = -12,
                    narrative = "The conspirators succeed partially. Titles are stripped. The family endures — diminished.",
                },
            },
            {
                label = "Bribe the key conspirators",
                description = "Wealth and negotiation dissolve the plot.",
                check = { primary = { trait = "SOC_NEG", weight = 1.0 }, secondary = { trait = "SOC_MAN", weight = 0.5 }, tertiary = { trait = "SOC_CON", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    faction_power_shift = -3,
                    narrative = "Gold changes hands. The conspiracy evaporates. Expensive, but effective.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The conspirators pocket the gold and continue plotting. Costly mistake.",
                },
            },
            {
                label = "Appeal directly to the ruler",
                description = "Loyalty and charisma earn royal protection.",
                requires = { axis = "PER_LOY", min = 50 },
                check = { primary = { trait = "SOC_CHA", weight = 1.0 }, secondary = { trait = "SOC_TRU", weight = 0.5 }, tertiary = { trait = "CRE_FLV", weight = 0.2 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    narrative = "{heir_name}'s loyalty moves the ruler. The conspirators are punished. But owing the crown is its own burden.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -3 },
                    narrative = "The ruler is unmoved — or part of the plot. Cold comfort at the bottom.",
                },
            },
        },
    },

    {
        id = "usurpation_religious",
        title = "The Faith's Judgment",
        narrative = "Religious authorities declare {heir_name}'s family unfit to rule. Without spiritual legitimacy, the people waver.",
        chance = 0.1,
        requires_generation = 12,
        cooldown = 20,
        once_per_run = true,
        options = {
            {
                label = "Submit to a trial of faith",
                description = "Willpower and composure under divine scrutiny.",
                check = { primary = { trait = "MEN_WIL", weight = 1.0 }, secondary = { trait = "MEN_COM", weight = 0.7 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "{heir_name} endures the trial with unbreakable calm. Even the priests acknowledge the bloodline's strength.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -3, social = -2 },
                    narrative = "The trial reveals weakness. The family's legitimacy is questioned openly.",
                },
            },
            {
                label = "Challenge the religious authority",
                description = "Eloquence and intimidation silence the accusers.",
                requires = { axis = "PER_BLD", min = 55 },
                check = { primary = { trait = "SOC_ELO", weight = 0.8 }, secondary = { trait = "SOC_INM", weight = 0.7 }, difficulty = 65 },
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    taboo_chance = 0.3,
                    taboo_data = { trigger = "defied_religious_authority", effect = "scorned_by_faithful", strength = 65 },
                    narrative = "{heir_name} stands before the faithful and demands: 'By what right do YOU judge MY blood?' Silence follows.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -5 },
                    faction_power_shift = -10,
                    narrative = "The defiance backfires catastrophically. The faithful turn away entirely.",
                },
            },
            {
                label = "Found a new sect loyal to the family",
                description = "Vision and narrative instinct create a new faith.",
                requires = { axis = "PER_OBS", min = 50 },
                check = { primary = { trait = "CRE_NAR", weight = 0.8 }, secondary = { trait = "CRE_SYM", weight = 0.7 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { creative = 4 },
                    narrative = "{heir_name} writes new scripture. A sect forms around the family's own divine right.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -2 },
                    narrative = "The new teachings are mocked as vanity. The effort only deepens the crisis.",
                },
            },
        },
    },
}
