-- Dark Legacy — Crucible Trial Definitions
-- 10 autonomous gauntlets. Each has 3-5 stages with personality-routed paths
-- and trait-based success scoring.
-- Pure Lua data file, zero dependencies.

-- Path format:
--   personality_axis: which axis selects this path
--   direction: "high" means higher axis value favors this path, "low" = lower
--   trait_checks: { { trait_id, weight, threshold } }
--     weight: how much this check matters (all weights in a path should sum ~1.0)
--     threshold: trait value needed for full success

return {
    -- ================================================================
    -- 1. TRIAL BY FIRE — War/survival gauntlet
    -- ================================================================
    {
        id = "trial_by_fire",
        name = "Trial by Fire",
        theme = "combat",
        affinity = { conditions = { "war" }, eras = { "ancient", "iron" } },
        opening = "War reaches the bloodline. {heir_name} is, by default, the one left holding the blade.",
        stages = {
            {
                title = "The Ambush",
                narrative = "Raiders strike without warning. The camp burns.",
                paths = {
                    {
                        id = "fight",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} charges into the fray, blade drawn.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_REF", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "flee",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} retreats into the darkness, saving what can be saved.",
                        trait_checks = {
                            { trait_id = "PHY_AGI", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_PER", weight = 0.3, threshold = 50 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Siege",
                narrative = "The enemy surrounds the holdfast. Resources dwindle.",
                paths = {
                    {
                        id = "hold",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} rallies the defenders. No one leaves.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.35, threshold = 60 },
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "sortie",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} leads a desperate sortie against the siege lines.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.35, threshold = 65 },
                            { trait_id = "MEN_DEC", weight = 0.3, threshold = 55 },
                            { trait_id = "PHY_REF", weight = 0.35, threshold = 55 },
                        },
                    },
                    {
                        id = "negotiate",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} sends terms to the enemy commander.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_ELO", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Duel",
                narrative = "The enemy champion demands single combat. There is no refusing.",
                paths = {
                    {
                        id = "brute_force",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} meets strength with strength, roaring defiance.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.45, threshold = 65 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 60 },
                            { trait_id = "PHY_PAI", weight = 0.25, threshold = 50 },
                        },
                    },
                    {
                        id = "cunning",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} fights dirty. Honor is for the dead.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_REF", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_AGI", weight = 0.25, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Aftermath",
                narrative = "The battle is done. Bodies litter the field. What remains must be gathered.",
                paths = {
                    {
                        id = "mercy",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} tends to the wounded, friend and foe alike.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_LEA", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "exploit",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} strips the dead and claims the spoils.",
                        trait_checks = {
                            { trait_id = "MEN_STR", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 50 },
                            { trait_id = "CRE_RES", weight = 0.3, threshold = 45 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 2. THE PLAGUE COURT — Plague crisis
    -- ================================================================
    {
        id = "the_plague_court",
        name = "The Plague Court",
        theme = "survival",
        affinity = { conditions = { "plague" }, eras = { "ancient", "iron", "dark" } },
        opening = "The sickness comes without warning. {heir_name} wakes to the sound of retching and weeping.",
        stages = {
            {
                title = "The Infection",
                narrative = "The plague breaches the household. Servants fall first.",
                paths = {
                    {
                        id = "quarantine",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} seals the sick wing. Let the weak perish behind closed doors.",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "care",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} enters the sick rooms personally, risking everything.",
                        trait_checks = {
                            { trait_id = "PHY_IMM", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Quarantine Decision",
                narrative = "Neighboring families beg for shelter. Letting them in risks spreading the plague further.",
                paths = {
                    {
                        id = "admit",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} opens the gates. Blood protects blood.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_IMM", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "refuse",
                        personality_axis = "PER_LOY",
                        direction = "low",
                        narrative = "{heir_name} bars the gates. Survival demands sacrifice.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "Treating the Sick",
                narrative = "The plague worsens. Knowledge or instinct must guide the cure.",
                paths = {
                    {
                        id = "science",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} experiments with herbs and remedies, searching for a pattern.",
                        trait_checks = {
                            { trait_id = "MEN_INT", weight = 0.35, threshold = 60 },
                            { trait_id = "MEN_PAT", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_ING", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "ritual",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} turns to ancient rites, burning incense and chanting through the night.",
                        trait_checks = {
                            { trait_id = "CRE_RIT", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 55 },
                            { trait_id = "CRE_SYM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Aftermath",
                narrative = "The plague recedes. The living count their losses.",
                paths = {
                    {
                        id = "rebuild",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} surveys the ruins and begins again. Adaptation is survival.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_RES", weight = 0.35, threshold = 50 },
                            { trait_id = "MEN_PLA", weight = 0.3, threshold = 45 },
                        },
                    },
                    {
                        id = "mourn",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} retreats into grief, clinging to the old ways.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 45 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 3. THE BETRAYAL — Diplomatic crisis
    -- ================================================================
    {
        id = "the_betrayal",
        name = "The Betrayal",
        theme = "diplomatic",
        affinity = { conditions = {}, eras = { "iron", "dark", "renaissance" } },
        opening = "A trusted ally has turned. {heir_name} discovers the treachery too late.",
        stages = {
            {
                title = "The Discovery",
                narrative = "Letters found. Plans revealed. The betrayal is deep.",
                paths = {
                    {
                        id = "rage",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} storms into the hall, demanding blood.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 55 },
                            { trait_id = "PHY_STR", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_DEC", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "patience",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} says nothing. Watches. Waits.",
                        trait_checks = {
                            { trait_id = "MEN_COM", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_PER", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Confrontation",
                narrative = "Face to face with the betrayer. Words are weapons now.",
                paths = {
                    {
                        id = "accuse",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} lays out every crime before the assembled court.",
                        trait_checks = {
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_MEM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "manipulate",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} plays the betrayer against their own allies.",
                        trait_checks = {
                            { trait_id = "SOC_MAN", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_DEC", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Negotiation",
                narrative = "Terms must be set. The betrayer has leverage still.",
                paths = {
                    {
                        id = "bargain",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} offers a deal. Pragmatism over pride.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_ANA", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_AWR", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "demand",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} demands unconditional surrender. No compromise.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_CHA", weight = 0.25, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Judgment",
                narrative = "The betrayer's fate is sealed. Justice — or vengeance.",
                paths = {
                    {
                        id = "forgive",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} shows mercy. The betrayer is exiled, not executed.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_PLA", weight = 0.3, threshold = 50 },
                            { trait_id = "SOC_LEA", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "execute",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} delivers the sentence personally. A blade across the throat.",
                        trait_checks = {
                            { trait_id = "MEN_COM", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 50 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 4. THE DESCENT — Mystical/psychological
    -- ================================================================
    {
        id = "the_descent",
        name = "The Descent",
        theme = "mystical",
        affinity = { conditions = { "mystical" }, eras = { "ancient", "dark" } },
        opening = "Something was found beneath the estate. {heir_name} descends. The reasons are not recorded.",
        stages = {
            {
                title = "The Call",
                narrative = "Dreams that won't stop. Whispers in the stone. Something wants to be found.",
                paths = {
                    {
                        id = "embrace",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} follows the whispers eagerly, torch held high.",
                        trait_checks = {
                            { trait_id = "MEN_DRM", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_ABS", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "resist",
                        personality_axis = "PER_CUR",
                        direction = "low",
                        narrative = "{heir_name} descends with dread, each step a battle against instinct.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Dark",
                narrative = "Light fails. The tunnels breathe. Something watches.",
                paths = {
                    {
                        id = "push_on",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} presses deeper. Fear is just another enemy.",
                        trait_checks = {
                            { trait_id = "PHY_SEN", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_STH", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "study",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} maps the walls, reading the old marks left by those who came before.",
                        trait_checks = {
                            { trait_id = "MEN_PAT", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_SPA", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_INT", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Trial",
                narrative = "The chamber reveals itself. Old power sleeps here. A test awaits.",
                paths = {
                    {
                        id = "commune",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} reaches out to the power, mind open, will fixed.",
                        trait_checks = {
                            { trait_id = "MEN_ABS", weight = 0.35, threshold = 60 },
                            { trait_id = "MEN_FOC", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_SYM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "dominate",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} attempts to seize the power by force of will.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 65 },
                            { trait_id = "MEN_STH", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Return",
                narrative = "The surface beckons. But something has changed inside.",
                paths = {
                    {
                        id = "transformed",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} emerges different. The old self was left in the dark.",
                        trait_checks = {
                            { trait_id = "MEN_PLA", weight = 0.4, threshold = 55 },
                            { trait_id = "PHY_ADP", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_ITU", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "scarred",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} claws back to the light, shaken to the core but unbroken.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 5. THE FAMINE MARCH — Survival trek
    -- ================================================================
    {
        id = "the_famine_march",
        name = "The Famine March",
        theme = "survival",
        affinity = { conditions = { "famine" }, eras = { "iron", "dark" } },
        opening = "The stores are empty. The land is dead. {heir_name} must lead the family across the wastes or starve.",
        stages = {
            {
                title = "Rationing",
                narrative = "What little remains must be divided. Every morsel counts.",
                paths = {
                    {
                        id = "fair",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} shares equally. The weak eat the same as the strong.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_DEC", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "harsh",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} rations by strength. The useful eat. The rest endure.",
                        trait_checks = {
                            { trait_id = "MEN_STR", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Crossing",
                narrative = "A dead expanse lies between the family and salvation.",
                paths = {
                    {
                        id = "endure",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} carries the weakest. No one is left behind.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "scout",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} scouts ahead, finding the safest path through the waste.",
                        trait_checks = {
                            { trait_id = "MEN_SPA", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_SEN", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_AGI", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Desperate Choice",
                narrative = "A fork in the road. One path is quick but dangerous. The other is long but safer.",
                paths = {
                    {
                        id = "risk",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} takes the dangerous path. Speed is survival.",
                        trait_checks = {
                            { trait_id = "PHY_REF", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_DEC", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_AGI", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "caution",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} chooses the long road. Patience outlasts haste.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                            { trait_id = "PHY_LUN", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 6. THE USURPER'S CHALLENGE — Political crisis
    -- ================================================================
    {
        id = "the_usurper",
        name = "The Usurper's Challenge",
        theme = "political",
        affinity = { conditions = {}, eras = { "iron", "renaissance", "industrial" } },
        opening = "A rival claims {heir_name}'s birthright. The court watches. Power hangs by a thread.",
        stages = {
            {
                title = "The Accusation",
                narrative = "Before the assembled court, the usurper speaks. The bloodline's legitimacy is questioned.",
                paths = {
                    {
                        id = "defiance",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} rises, voice like iron: 'I am the blood. Prove otherwise.'",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "composure",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} listens in silence, letting the usurper exhaust their venom.",
                        trait_checks = {
                            { trait_id = "MEN_COM", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_PER", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_AWR", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Court",
                narrative = "Allies must be secured. The court is a battlefield of whispers.",
                paths = {
                    {
                        id = "charm",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} works the room, promising, persuading, smiling through teeth.",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.35, threshold = 60 },
                            { trait_id = "SOC_NEG", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_AWR", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "threaten",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} reminds the court what happens to those who back the wrong horse.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_MAN", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Gambit",
                narrative = "The decisive moment. One move to end the challenge.",
                paths = {
                    {
                        id = "public_trial",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} demands a public test of worthiness. Let the people decide.",
                        trait_checks = {
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "backroom",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} arranges a private meeting. Some things are settled in the dark.",
                        trait_checks = {
                            { trait_id = "SOC_MAN", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_DEC", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 7. THE MADNESS — Psychological crisis
    -- ================================================================
    {
        id = "the_madness",
        name = "The Madness",
        theme = "psychological",
        affinity = { conditions = {}, eras = { "dark", "renaissance" } },
        opening = "It begins with small things. Shadows where there should be none. {heir_name}'s grip on reality falters.",
        stages = {
            {
                title = "The Whispers",
                narrative = "Voices in the walls. Faces in the fire. Something is wrong.",
                paths = {
                    {
                        id = "listen",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} leans in to the whispers. Perhaps they speak truth.",
                        trait_checks = {
                            { trait_id = "MEN_DRM", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_ITU", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_ABS", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "deny",
                        personality_axis = "PER_CUR",
                        direction = "low",
                        narrative = "{heir_name} refuses to acknowledge them. Stone faces the storm.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "Isolation",
                narrative = "Trust erodes. {heir_name} can no longer tell friend from phantom.",
                paths = {
                    {
                        id = "withdraw",
                        personality_axis = "PER_LOY",
                        direction = "low",
                        narrative = "{heir_name} locks the door. Alone is safe. Alone is quiet.",
                        trait_checks = {
                            { trait_id = "MEN_STH", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "confide",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} reaches out to those who remain. 'I am losing myself.'",
                        trait_checks = {
                            { trait_id = "SOC_TRU", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.35, threshold = 50 },
                            { trait_id = "SOC_PAK", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Break",
                narrative = "The crisis peaks. Reality tears at the seams.",
                paths = {
                    {
                        id = "snap",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} shatters. The fury is absolute, indiscriminate, terrifying.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_STH", weight = 0.35, threshold = 40 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "endure",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} holds. Barely. The mind bends but does not break.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 65 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 60 },
                            { trait_id = "MEN_STH", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "Clarity or Ruin",
                narrative = "Dawn breaks. The worst has passed — or the worst has just begun.",
                paths = {
                    {
                        id = "clarity",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} pieces together a new understanding. The madness was a chrysalis.",
                        trait_checks = {
                            { trait_id = "MEN_PLA", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_INT", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_ITU", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "scarred",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} survives, but something is missing. A piece of the self, gone forever.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 55 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 8. THE INHERITANCE — Legacy crisis
    -- ================================================================
    {
        id = "the_inheritance",
        name = "The Inheritance",
        theme = "legacy",
        affinity = { conditions = {}, eras = {} },
        opening = "A contested claim. A rival heir emerges from the shadows. {heir_name} must prove they are worthy of the bloodline.",
        stages = {
            {
                title = "The Claim",
                narrative = "Documents surface. Another carries the blood. The line splits.",
                paths = {
                    {
                        id = "assert",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} will not share what is theirs by right.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "investigate",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} digs into the claim. Truth is the only weapon worth wielding.",
                        trait_checks = {
                            { trait_id = "MEN_ANA", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_PER", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_INT", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Rival",
                narrative = "The rival heir stands before the family. They are not what was expected.",
                paths = {
                    {
                        id = "challenge",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} challenges the rival directly. Let the blood decide.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_DEC", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_REF", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "undermine",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} works to destroy the rival's reputation before the contest begins.",
                        trait_checks = {
                            { trait_id = "SOC_MAN", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_DEC", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Test",
                narrative = "The family demands proof. An ancient rite determines the true heir.",
                paths = {
                    {
                        id = "submit",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} submits fully to the rite. Nothing matters but the bloodline.",
                        trait_checks = {
                            { trait_id = "MEN_FOC", weight = 0.35, threshold = 60 },
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_RIT", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "game",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} adapts the rite to play to their strengths.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_IMP", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_PLA", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 9. THE EXODUS — Mass migration
    -- ================================================================
    {
        id = "the_exodus",
        name = "The Exodus",
        theme = "survival",
        affinity = { conditions = { "war", "famine" }, eras = { "iron", "dark", "industrial" } },
        opening = "The homeland is lost. {heir_name} must lead the family into the unknown.",
        stages = {
            {
                title = "The Decision",
                narrative = "Stay and die, or leave everything behind. There is no middle ground.",
                paths = {
                    {
                        id = "decisive",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} gives the order at once. 'We leave at dawn. Take only what you can carry.'",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.4, threshold = 55 },
                            { trait_id = "SOC_LEA", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "plan",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} plans every detail. Routes, supplies, contingencies.",
                        trait_checks = {
                            { trait_id = "MEN_STR", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_ANA", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The March",
                narrative = "Days blur. The column stretches thin. The weak fall behind.",
                paths = {
                    {
                        id = "drive",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} pushes the pace. The strong survive. That is the way.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "carry",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} slows the march for the stragglers. Everyone or no one.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_END", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Threat",
                narrative = "Bandits. Border guards. Someone stands between the family and safety.",
                paths = {
                    {
                        id = "fight",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} draws steel. The family's path will not be blocked.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.35, threshold = 55 },
                            { trait_id = "PHY_REF", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "talk",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} negotiates passage. Words where blades would fail.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_ELO", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The New Land",
                narrative = "A place to rest. But will it hold? The family must root here or perish.",
                paths = {
                    {
                        id = "build",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} drives the family to build immediately. Every hour counts.",
                        trait_checks = {
                            { trait_id = "CRE_CRA", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_MEC", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "adapt",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} studies the new land first. Learn the soil before planting.",
                        trait_checks = {
                            { trait_id = "PHY_ADP", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_PER", weight = 0.35, threshold = 55 },
                            { trait_id = "CRE_RES", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 10. THE RECKONING — Confrontation with family past
    -- ================================================================
    {
        id = "the_reckoning",
        name = "The Reckoning",
        theme = "legacy",
        affinity = { conditions = {}, eras = {} },
        opening = "An old debt arrives for collection. {heir_name} is the only signatory still breathing.",
        stages = {
            {
                title = "The Ghost",
                narrative = "An old wrong surfaces. A voice from the past demands to be heard.",
                paths = {
                    {
                        id = "face",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} confronts the accusation head-on. The blood does not hide.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "deny",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} refuses to acknowledge the sins. The family is above reproach.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_ELO", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Accusation",
                narrative = "The weight of generational wrongs is laid bare. The evidence is damning.",
                paths = {
                    {
                        id = "accept",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} accepts the truth. 'We were wrong. I will make it right.'",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_PLA", weight = 0.3, threshold = 50 },
                            { trait_id = "SOC_TRU", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "justify",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} argues that every choice was necessary. Survival justifies all.",
                        trait_checks = {
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 55 },
                            { trait_id = "MEN_ANA", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Choice",
                narrative = "Something must be given. A sacrifice to settle the debt, or a refusal to pay.",
                paths = {
                    {
                        id = "sacrifice",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} gives up something precious. For the family. For the blood.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "refuse",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} refuses to pay for the sins of the dead. The living owe nothing.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.35, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Weight",
                narrative = "The reckoning ends. The bloodline is forever changed — lightened or burdened.",
                paths = {
                    {
                        id = "peace",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} finds a fragile peace. The ancestors rest easier.",
                        trait_checks = {
                            { trait_id = "MEN_PLA", weight = 0.35, threshold = 55 },
                            { trait_id = "SOC_EMP", weight = 0.35, threshold = 50 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "defiance",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} shoulders the weight and walks on. The blood endures.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_END", weight = 0.3, threshold = 50 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 11. THE SHADOW'S REACH — Stealth/Cunning gauntlet
    -- ================================================================
    {
        id = "shadow_reach",
        name = "The Shadow's Reach",
        theme = "diplomatic",
        affinity = { conditions = {}, eras = { "iron", "dark", "renaissance" } },
        opening = "Whispers in the dark halls suggest a conspiracy that {heir_name} must unravel or fall victim to.",
        stages = {
            {
                title = "The Infiltration",
                narrative = "To learn the truth, {heir_name} must enter a rival's feast uninvited.",
                paths = {
                    {
                        id = "stealth",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} slips through the shadows, a ghost in the machine.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.4, threshold = 60 },
                            { trait_id = "PHY_AGI", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_PER", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "disguise",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} wears a servant's face and walks in the front door.",
                        trait_checks = {
                            { trait_id = "SOC_DEC", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_AWR", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Eavesdropping",
                narrative = "The conspirators are gathered. Their plan is worse than imagined.",
                paths = {
                    {
                        id = "listen",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} remains motionless, recording every word in memory.",
                        trait_checks = {
                            { trait_id = "MEN_MEM", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                            { trait_id = "PHY_SEN", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "intervene",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} waits for the perfect moment to 'accidentally' disrupt the meeting.",
                        trait_checks = {
                            { trait_id = "SOC_HUM", weight = 0.35, threshold = 60 },
                            { trait_id = "SOC_DEC", weight = 0.35, threshold = 55 },
                            { trait_id = "MEN_CUN", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Escape",
                narrative = "The alarm is raised. The way back is blocked.",
                paths = {
                    {
                        id = "acrobatic",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} leaps from the high balcony into the night.",
                        trait_checks = {
                            { trait_id = "PHY_AGI", weight = 0.4, threshold = 65 },
                            { trait_id = "PHY_REF", weight = 0.3, threshold = 60 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 50 },
                        },
                    },
                    {
                        id = "bluff",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} walks past the guards, commanding them to stand aside.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 65 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 12. THE ARCHITECT'S VISION — Creative/Structure gauntlet
    -- ================================================================
    {
        id = "architect_vision",
        name = "The Architect's Vision",
        theme = "legacy",
        affinity = { conditions = {}, eras = { "renaissance", "industrial" } },
        opening = "The family's great project is failing. {heir_name} must salvage the vision or watch it crumble.",
        stages = {
            {
                title = "The Design Flaw",
                narrative = "The foundations are unstable. The plans are flawed.",
                paths = {
                    {
                        id = "redesign",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} scraps the old plans and reimagines the structure.",
                        trait_checks = {
                            { trait_id = "CRE_VIS", weight = 0.4, threshold = 60 },
                            { trait_id = "CRE_ARC", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_ANA", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "reinforce",
                        personality_axis = "PER_CUR",
                        direction = "low",
                        narrative = "{heir_name} works within the existing design, patching the weaknesses.",
                        trait_checks = {
                            { trait_id = "CRE_CRA", weight = 0.4, threshold = 60 },
                            { trait_id = "CRE_MEC", weight = 0.3, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Labor Crisis",
                narrative = "The workers are exhausted and ready to revolt.",
                paths = {
                    {
                        id = "inspire",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} speaks of the legacy they are building together.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_ELO", weight = 0.3, threshold = 55 },
                            { trait_id = "SOC_CHA", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "organize",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} restructures the workflow, improving efficiency and safety.",
                        trait_checks = {
                            { trait_id = "MEN_STR", weight = 0.4, threshold = 60 },
                            { trait_id = "MEN_ANA", weight = 0.3, threshold = 55 },
                            { trait_id = "CRE_RES", weight = 0.3, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Finishing Touch",
                narrative = "The project is nearly complete. It needs a soul.",
                paths = {
                    {
                        id = "artistic",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} dedicates the project to beauty and the ancestors.",
                        trait_checks = {
                            { trait_id = "CRE_AES", weight = 0.4, threshold = 65 },
                            { trait_id = "CRE_SYM", weight = 0.3, threshold = 60 },
                            { trait_id = "CRE_EXP", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "utilitarian",
                        personality_axis = "PER_CUR",
                        direction = "low",
                        narrative = "{heir_name} ensures the project serves the family's survival above all.",
                        trait_checks = {
                            { trait_id = "CRE_RES", weight = 0.4, threshold = 65 },
                            { trait_id = "CRE_MEC", weight = 0.3, threshold = 60 },
                            { trait_id = "MEN_STR", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 13. THE LAST STAND — Unavoidable final siege (Interactive Game Over)
    -- ================================================================
    {
        id = "the_last_stand",
        name = "The Last Stand",
        theme = "legacy",
        affinity = { conditions = {}, eras = {} },
        opening = "The walls are breached. The coffers are empty. The enemies of {lineage_name} have come to end the story. {heir_name} stands in the ruins of what the ancestors built.",
        stages = {
            {
                title = "The Breach",
                narrative = "The gates shatter. Iron and fire pour into the inner court.",
                paths = {
                    {
                        id = "suicidal_charge",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} roars a final defiance and charges the wave of steel.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 80 },
                            { trait_id = "PHY_PAI", weight = 0.5, threshold = 70 },
                        },
                    },
                    {
                        id = "orderly_retreat",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} directs the survivors to the secret tunnels, buying every second with blood.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 75 },
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 70 },
                        },
                    },
                },
            },
            {
                title = "The Archives",
                narrative = "The library of the ancestors is burning. Centuries of memory are turning to ash.",
                paths = {
                    {
                        id = "save_the_blood",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} dives into the flames to save the genealogical scrolls.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.5, threshold = 75 },
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 75 },
                        },
                    },
                    {
                        id = "scorch_the_earth",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} fans the flames. If we cannot have our history, no one will.",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.5, threshold = 70 },
                            { trait_id = "CRE_RIT", weight = 0.5, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Final Choice",
                narrative = "Trapped in the high tower. The enemy commander offers a choice: surrender and be forgotten, or die and be remembered.",
                paths = {
                    {
                        id = "martyrdom",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} leaps from the tower, choosing the fall over the chain.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.7, threshold = 85 },
                            { trait_id = "PHY_PAI", weight = 0.3, threshold = 80 },
                        },
                    },
                    {
                        id = "vassalage",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} kneels. The blood continues, but the name is stripped of its pride.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.6, threshold = 70 },
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 70 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 14. THE GREAT EXODUS — Movement/Survival gauntlet
    -- ================================================================
    {
        id = "the_great_exodus",
        name = "The Great Exodus",
        theme = "survival",
        affinity = { conditions = { "exodus", "war" }, eras = { "ancient", "iron", "dark" } },
        opening = "The land itself turns against the bloodline. {heir_name} must lead thousands across a dying world.",
        stages = {
            {
                title = "The Departure",
                narrative = "Leaving the ancestral home is a wound that won't heal.",
                paths = {
                    {
                        id = "heirloom",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} ensures every sacred relic is packed, slowing the departure.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.4, threshold = 65 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 60 },
                            { trait_id = "CRE_SYM", weight = 0.3, threshold = 55 },
                        },
                    },
                    {
                        id = "burn_it",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} sets fire to the halls. 'If we cannot have it, the world will have the ash.'",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.4, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 60 },
                            { trait_id = "PHY_STR", weight = 0.3, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Mountain Pass",
                narrative = "Winter strikes early in the high peaks.",
                paths = {
                    {
                        id = "endure",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} walks the line, sharing their own cloak with the weak.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.4, threshold = 70 },
                            { trait_id = "PHY_VIT", weight = 0.3, threshold = 65 },
                            { trait_id = "SOC_EMP", weight = 0.3, threshold = 60 },
                        },
                    },
                    {
                        id = "sacrifice",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} orders the stragglers left behind to save the column.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 70 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 65 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 60 },
                        },
                    },
                },
            },
            {
                title = "The New Horizon",
                narrative = "The column reaches the edge of the known world. A vast, empty plain lies ahead.",
                paths = {
                    {
                        id = "settle",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} orders the foundations laid immediately. 'This ash will grow grain eventually.'",
                        trait_checks = {
                            { trait_id = "MEN_PLA", weight = 0.4, threshold = 75 },
                            { trait_id = "CRE_MEC", weight = 0.3, threshold = 70 },
                            { trait_id = "SOC_LEA", weight = 0.3, threshold = 65 },
                        },
                    },
                    {
                        id = "conquer",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} sees the smoke of existing settlements. 'We did not come this far to beg.'",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.4, threshold = 75 },
                            { trait_id = "SOC_INM", weight = 0.3, threshold = 70 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 65 },
                        },
                    },
                },
            },
        },
    },

    -- ================================================================
    -- 16. THE ASCENSION — Multi-Era Win State Trial
    -- ================================================================
    {
        id = "the_ascension",
        name = "The Ascension",
        theme = "mystical",
        affinity = { conditions = { "mystical" }, eras = { "arcane", "twilight" } },
        opening = "The final audit. {heir_name} stands at the threshold. The ledger demands a reckoning.",
        stages = {
            {
                title = "The Shedding",
                narrative = "The physical body resists the transition. Flesh and bone feel like lead.",
                paths = {
                    {
                        id = "discipline",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} ignores the agony, focusing purely on the geometric truth of the patterns.",
                        trait_checks = {
                            { trait_id = "MEN_FOC", weight = 0.5, threshold = 85 },
                            { trait_id = "PHY_PAI", weight = 0.5, threshold = 80 },
                        },
                    },
                    {
                        id = "vitality",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} forces the physical form to endure through sheer biological stubbornness.",
                        trait_checks = {
                            { trait_id = "PHY_VIT", weight = 0.6, threshold = 85 },
                            { trait_id = "PHY_STR", weight = 0.4, threshold = 80 },
                        },
                    },
                },
            },
            {
                title = "The Memory Storm",
                narrative = "The ghosts of a thousand ancestors scream through {heir_name}'s mind.",
                paths = {
                    {
                        id = "absorb",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} opens their mind, absorbing the collective trauma and wisdom of the entire lineage.",
                        trait_checks = {
                            { trait_id = "MEN_ABS", weight = 0.6, threshold = 90 },
                            { trait_id = "MEN_MEM", weight = 0.4, threshold = 85 },
                        },
                    },
                    {
                        id = "anchor",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} ignores the voices, anchoring their identity to a single, cold point of logic.",
                        trait_checks = {
                            { trait_id = "MEN_ANA", weight = 0.6, threshold = 90 },
                            { trait_id = "MEN_FOC", weight = 0.4, threshold = 85 },
                        },
                    },
                },
            },
            {
                title = "The Threshold",
                narrative = "The world begins to blur. The rival houses launch their final, desperate attack to stop the ritual.",
                paths = {
                    {
                        id = "unwavering",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} remains at the altar, trusting in the blood to hold the line.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.7, threshold = 90 },
                            { trait_id = "SOC_LEA", weight = 0.3, threshold = 80 },
                        },
                    },
                    {
                        id = "annihilation",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} unleashes the nascent power of the patterns to erase the attackers from existence.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.6, threshold = 90 },
                            { trait_id = "MEN_WIL", weight = 0.4, threshold = 85 },
                        },
                    },
                },
            },
        },
    },
    {
        id = "the_exodus_march",
        name = "The Exodus March",
        theme = "physical",
        opening = "The land has failed. {heir_name} must lead thousands of starving refugees through the Iron Pass to a new home.",
        stages = {
            {
                title = "The Pass of Shadows",
                narrative = "The mountain path is narrow and choked with snow. The weak are falling.",
                paths = {
                    {
                        id = "discipline",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} walks among the stragglers, sharing their burden and keeping order.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.5, threshold = 65 },
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "abandon",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} orders the march to double its pace. Those who cannot keep up must be left behind for the good of the bloodline.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.6, threshold = 65 },
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 60 },
                        },
                    },
                },
            },
            {
                title = "The Promised Land",
                narrative = "The valley beyond is occupied. A choice between peace and conquest.",
                paths = {
                    {
                        id = "negotiate",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} seeks to share the land, offering secrets and service for a home.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.6, threshold = 70 },
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 65 },
                        },
                    },
                    {
                        id = "seize",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} orders the vanguard to strike. The valley will be ours by right of blood.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.7, threshold = 75 },
                            { trait_id = "MEN_COM", weight = 0.3, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Iron Foundation",
                narrative = "The first winter in the new land. Survival depends on the strength of the new walls.",
                paths = {
                    {
                        id = "fortify",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} personally oversees the masonry, ensuring the foundations are deep and cold.",
                        trait_checks = {
                            { trait_id = "CRE_MEC", weight = 0.6, threshold = 75 },
                            { trait_id = "PHY_END", weight = 0.4, threshold = 70 },
                        },
                    },
                    {
                        id = "inspire",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} walks the battlements, keeping the hope of the bloodline alive through the dark months.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.6, threshold = 75 },
                            { trait_id = "SOC_CHA", weight = 0.4, threshold = 70 },
                        },
                    },
                },
            },
        },
    },
    {
        id = "the_artisan_trial",
        name = "The Great Forge-Rite",
        theme = "creative",
        opening = "The bloodline's assets are sufficient for a masterwork. {heir_name} must produce something worth the expenditure.",
        stages = {
            {
                title = "The Material",
                narrative = "The core of the relic requires rare alloys and a drop of ancestral blood.",
                paths = {
                    {
                        id = "purity",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} uses only the finest materials, sparing no expense to ensure perfection.",
                        trait_checks = {
                            { trait_id = "CRE_CRA", weight = 0.5, threshold = 65 },
                            { trait_id = "CRE_AES", weight = 0.5, threshold = 65 },
                        },
                    },
                    {
                        id = "innovation",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} experiments with forbidden techniques, seeking a power that surpasses tradition.",
                        trait_checks = {
                            { trait_id = "CRE_ING", weight = 0.6, threshold = 70 },
                            { trait_id = "MEN_ANA", weight = 0.4, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Quench",
                narrative = "The blade is white-hot. One mistake will shatter a century of pride.",
                paths = {
                    {
                        id = "steady_hand",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} remains calm, timing the quench to the heartbeat of the earth.",
                        trait_checks = {
                            { trait_id = "PHY_COR", weight = 0.6, threshold = 70 },
                            { trait_id = "MEN_FOC", weight = 0.4, threshold = 70 },
                        },
                    },
                    {
                        id = "flaming_will",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} forces the metal to submit through sheer willpower and intensity.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.7, threshold = 75 },
                            { trait_id = "CRE_MEC", weight = 0.3, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Final Polish",
                narrative = "The relic is cooling. Now comes the intricate work of etching the family sigil.",
                paths = {
                    {
                        id = "artistry",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} adds flourishes that represent the current era's unique struggles.",
                        trait_checks = {
                            { trait_id = "CRE_AES", weight = 0.6, threshold = 75 },
                            { trait_id = "CRE_ING", weight = 0.4, threshold = 70 },
                        },
                    },
                    {
                        id = "precision",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} etches the sigil with mathematical exactness, honoring the ancestors' rigid tradition.",
                        trait_checks = {
                            { trait_id = "CRE_CRA", weight = 0.6, threshold = 75 },
                            { trait_id = "MEN_FOC", weight = 0.4, threshold = 70 },
                        },
                    },
                },
            },
        },
    },
    {
        id = "the_judgment_of_blood",
        name = "The Judgment of Blood",
        theme = "social",
        opening = "The people demand an accounting of the bloodline's sins. {heir_name} is brought before the high magistrate.",
        stages = {
            {
                title = "The Accusation",
                narrative = "Decades of cruelty and broken promises are laid bare. The crowd hungers for execution.",
                paths = {
                    {
                        id = "intimidation",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} turns on the accusers, projecting a terrifying aura of inevitable vengeance.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.7, threshold = 75 },
                            { trait_id = "MEN_WIL", weight = 0.3, threshold = 70 },
                        },
                    },
                    {
                        id = "contrition",
                        personality_axis = "PER_PRI",
                        direction = "low",
                        narrative = "{heir_name} humbles themselves, invoking past virtues and expressing deep empathy for the suffering.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.6, threshold = 70 },
                            { trait_id = "SOC_ELO", weight = 0.4, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Reparation",
                narrative = "Words are not enough. A price must be paid to satisfy the scales of justice.",
                paths = {
                    {
                        id = "bribery",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} opens the ancestral vaults, using vast wealth to buy silence and compliance.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.5, threshold = 65 },
                            { trait_id = "MEN_CUN", weight = 0.5, threshold = 60 },
                        },
                        -- Mechanically relies on wealth, but tested via stats here (Crucible context handles resources later)
                    },
                    {
                        id = "flesh_tithe",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} offers their own flesh instead of gold, enduring the lash without a sound to prove their resolve.",
                        trait_checks = {
                            { trait_id = "PHY_PAI", weight = 0.8, threshold = 80 },
                            { trait_id = "PHY_END", weight = 0.2, threshold = 60 },
                        },
                    },
                },
            },
            {
                title = "The New Decree",
                narrative = "The magistrate demands a permanent change to the law of the land.",
                paths = {
                    {
                        id = "mercy",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} institutes a new code of protection for the weak, binding the bloodline to the people.",
                        trait_checks = {
                            { trait_id = "SOC_TRU", weight = 0.6, threshold = 70 },
                            { trait_id = "SOC_EMP", weight = 0.4, threshold = 65 },
                        },
                    },
                    {
                        id = "tyranny",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} declares the bloodline's word as the only law, silencing all dissent through absolute authority.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.6, threshold = 70 },
                            { trait_id = "SOC_INM", weight = 0.4, threshold = 65 },
                        },
                    },
                },
            },
        },
    },
    {
        id = "the_iron_engine",
        name = "The Iron Engine",
        theme = "mental",
        opening = "A ruin from the golden age has been unearthed. Its complex mechanisms hold terrible power, if {heir_name} can master them.",
        stages = {
            {
                title = "The Mechanism",
                narrative = "Thousands of interlocking gears scream for a logic the modern world has forgotten.",
                paths = {
                    {
                        id = "instinctive_engineering",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} plunges their hands into the machine, feeling the rhythm of the iron.",
                        trait_checks = {
                            { trait_id = "CRE_MEC", weight = 0.7, threshold = 70 },
                            { trait_id = "PHY_REF", weight = 0.3, threshold = 60 },
                        },
                    },
                    {
                        id = "structural_analysis",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} steps back, meticulously charting the geometry and logic of the construct.",
                        trait_checks = {
                            { trait_id = "MEN_SPA", weight = 0.6, threshold = 70 },
                            { trait_id = "MEN_ANA", weight = 0.4, threshold = 65 },
                        },
                    },
                },
            },
            {
                title = "The Override",
                narrative = "The engine rejects the new master, reconfiguring itself to execute a purge sequence.",
                paths = {
                    {
                        id = "rapid_adaptation",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} alters their approach instantly, rewiring the control nodes faster than the machine can react.",
                        trait_checks = {
                            { trait_id = "MEN_PLA", weight = 0.8, threshold = 75 },
                            { trait_id = "CRE_ING", weight = 0.2, threshold = 65 },
                        },
                    },
                    {
                        id = "brute_force_jam",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} shoves their own arm into the primary gear, sacrificing bone to halt the purge.",
                        trait_checks = {
                            { trait_id = "PHY_BON", weight = 0.6, threshold = 75 },
                            { trait_id = "PHY_PAI", weight = 0.4, threshold = 70 },
                        },
                    },
                },
            },
            {
                title = "The Master Control",
                narrative = "The machine's central core opens, demanding a final mental merge.",
                paths = {
                    {
                        id = "mental_ascension",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} projects their consciousness into the machine, becoming one with the iron logic.",
                        trait_checks = {
                            { trait_id = "MEN_INT", weight = 0.6, threshold = 85 },
                            { trait_id = "MEN_FOC", weight = 0.4, threshold = 80 },
                        },
                    },
                    {
                        id = "primal_mastery",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} overrides the machine's logic with pure, chaotic ancestral memory.",
                        trait_checks = {
                            { trait_id = "MEN_ITU", weight = 0.6, threshold = 85 },
                            { trait_id = "MEN_ABS", weight = 0.4, threshold = 80 },
                        },
                    },
                },
            },
        },
    },
}
