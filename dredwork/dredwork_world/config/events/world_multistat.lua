-- Dark Legacy — Multi-stat World Events
-- Events that leverage stat_check, discoveries, era mechanics, religion, and culture.
-- Richer checks: primary + secondary traits + personality modifiers.

return {
    -- DISCOVERY-RELATED EVENTS
    {
        id = "discovery_fire_ritual",
        title = "The Fire Ritual",
        narrative = "Ancient texts describe a ritual to harness flame itself. Your scholars believe {heir_name} could attempt it.",
        chance = 0.3,
        requires_condition = nil,
        cooldown = 8,
        options = {
            {
                label = "Attempt the ritual",
                description = "Focus and craftsmanship will determine success.",
                check = { primary = { trait = "CRE_CRA", weight = 1.0 }, secondary = { trait = "MEN_FOC", weight = 0.5 }, tertiary = { trait = "CRE_TIN", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 1 },
                    narrative = "{heir_name} channels flame through sheer will. The family's craft deepens.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The flames refuse to obey. Scars are earned, not glory.",
                },
            },
            {
                label = "Study the texts instead",
                description = "Learn from the knowledge without the danger.",
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "Wisdom chosen over spectacle. The texts yield their secrets slowly.",
                },
            },
        },
    },

    {
        id = "star_alignment",
        title = "Stars in Alignment",
        narrative = "The night sky blazes with an alignment not seen in centuries. Scholars and mystics gather to interpret its meaning.",
        chance = 0.2,
        cooldown = 15,
        options = {
            {
                label = "Lead an observation",
                description = "Abstract thought and vision are key.",
                check = { primary = { trait = "MEN_ABS", weight = 1.0 }, secondary = { trait = "CRE_VIS", weight = 0.6 }, tertiary = { trait = "CRE_MUS", weight = 0.2 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    mutation_triggers = { { type = "mystical", intensity = 0.4 } },
                    narrative = "{heir_name} reads the sky like a book. New patterns are revealed.",
                },
                consequences_fail = {
                    narrative = "The stars remain inscrutable. Perhaps the next generation will understand.",
                },
            },
            {
                label = "Declare it an omen",
                description = "Use the event to rally the people.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "{heir_name} declares the alignment a sign of divine favor. The people believe.",
                },
            },
            {
                label = "Ignore it",
                description = "Stars are for fools. There is real work to do.",
                consequences = {
                    narrative = "The alignment passes without ceremony. Perhaps that was wise.",
                },
            },
        },
    },

    -- ERA-DRIVEN EVENTS
    {
        id = "arcane_surge",
        title = "The Arcane Surge",
        narrative = "Raw magical energy erupts from the earth. The untrained are overwhelmed; the gifted feel its pull.",
        chance = 0.35,
        requires_condition = nil,
        cooldown = 10,
        options = {
            {
                label = "Channel the energy",
                description = "Willpower and abstract thought will be tested.",
                check = { primary = { trait = "MEN_WIL", weight = 1.0 }, secondary = { trait = "MEN_ABS", weight = 0.7 }, tertiary = { trait = "CRE_INN", weight = 0.3 }, difficulty = 60 },
                consequences = {
                    mutation_triggers = { { type = "mystical", intensity = 0.6 } },
                    cultural_memory_shift = { mental = 4 },
                    narrative = "{heir_name} bends the surge to will. The bloodline drinks deep of power.",
                },
                consequences_fail = {
                    mutation_triggers = { { type = "mystical", intensity = 0.8 } },
                    cultural_memory_shift = { mental = -2 },
                    narrative = "The surge overwhelms {heir_name}. Power courses through uncontrolled.",
                },
            },
            {
                label = "Shield the family",
                description = "Endurance and composure protect against the storm.",
                check = { primary = { trait = "PHY_END", weight = 0.8 }, secondary = { trait = "MEN_COM", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    narrative = "Through sheer endurance, {heir_name} shelters the bloodline from the surge.",
                },
                consequences_fail = {
                    mutation_triggers = { { type = "mystical", intensity = 0.3 } },
                    narrative = "The shield cracks. Some energy seeps through.",
                },
            },
        },
    },

    {
        id = "gilded_court_intrigue",
        title = "The Gilded Conspiracy",
        narrative = "Whispers in court suggest a cabal of nobles plots to redistrbute power. {heir_name} is invited to join — or oppose.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Infiltrate the cabal",
                description = "Cunning and deception required.",
                check = { primary = { trait = "MEN_CUN", weight = 1.0 }, secondary = { trait = "SOC_DEC", weight = 0.7 }, tertiary = { trait = "SOC_CON", weight = 0.3 }, difficulty = 60 },
                requires = { axis = "PER_CRM", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 2, social = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    narrative = "{heir_name} slips among the conspirators unseen, gathering secrets like coins.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -3 },
                    narrative = "Discovered! {heir_name}'s deception is exposed. Trust is hard to rebuild.",
                },
            },
            {
                label = "Report the conspiracy",
                description = "Loyalty and leadership demonstrated.",
                requires = { axis = "PER_LOY", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    narrative = "{heir_name} reveals the plot to the crown. Loyalty is rewarded handsomely.",
                },
            },
            {
                label = "Join the conspiracy",
                description = "Boldness and ambition drive this path.",
                requires = { axis = "PER_BLD", min = 60 },
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    faction_power_shift = 10,
                    taboo_chance = 0.25,
                    taboo_data = { trigger = "joined_conspiracy", effect = "conspirator_reputation", strength = 70 },
                    narrative = "{heir_name} throws in with the plotters. If this works, the rewards will be immense.",
                },
            },
        },
    },

    {
        id = "twilight_rift",
        title = "The Rift Opens",
        narrative = "A tear in reality appears at the edge of the family's domain. Things move within it. Things that should not be.",
        chance = 0.25,
        cooldown = 12,
        options = {
            {
                label = "Investigate the rift",
                description = "Curiosity and willpower against the unknown.",
                check = { primary = { trait = "MEN_WIL", weight = 1.0 }, secondary = { trait = "MEN_ABS", weight = 0.5 }, personality = { axis = "PER_CUR", weight = 0.3 }, difficulty = 65 },
                consequences = {
                    mutation_triggers = { { type = "mystical", intensity = 0.7 } },
                    cultural_memory_shift = { mental = 4, creative = 2 },
                    narrative = "{heir_name} peers into the rift and survives. What was seen changes everything.",
                },
                consequences_fail = {
                    mutation_triggers = { { type = "mystical", intensity = 0.5 } },
                    cultural_memory_shift = { mental = -3 },
                    narrative = "The rift rejects {heir_name}. Nightmares follow for years.",
                },
            },
            {
                label = "Seal it with force",
                description = "Strength and determination against the unnatural.",
                check = { primary = { trait = "PHY_STR", weight = 0.8 }, secondary = { trait = "MEN_WIL", weight = 0.8 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    narrative = "Through brute will and sinew, {heir_name} forces the rift closed.",
                },
                consequences_fail = {
                    narrative = "The rift resists. It narrows but does not close. Something got through.",
                    mutation_triggers = { { type = "mystical", intensity = 0.3 } },
                },
            },
            {
                label = "Ward the area and leave",
                description = "Sometimes wisdom is knowing not to look.",
                consequences = {
                    narrative = "The rift is marked with warnings. Future generations will deal with it.",
                },
            },
        },
    },

    -- RELIGION-INFLUENCED EVENTS
    {
        id = "heretic_preacher",
        title = "The Heretic's Sermon",
        narrative = "A wandering preacher speaks against the established faith. The people listen — some with fascination, others with rage.",
        chance = 0.3,
        cooldown = 6,
        options = {
            {
                label = "Debate the heretic publicly",
                description = "Eloquence and intellect must prevail.",
                check = { primary = { trait = "SOC_ELO", weight = 1.0 }, secondary = { trait = "MEN_INT", weight = 0.6 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 3, mental = 1 },
                    narrative = "{heir_name} dismantles the heretic's arguments with grace. Faith is strengthened.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The heretic's words prove sharper. Doubt spreads.",
                },
            },
            {
                label = "Silence the preacher",
                description = "Power speaks louder than theology.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    taboo_chance = 0.2,
                    taboo_data = { trigger = "silenced_heretic", effect = "cruelty_toward_faith", strength = 60 },
                    narrative = "The preacher is silenced. Permanently. Not everyone approves.",
                },
            },
            {
                label = "Listen to the sermon",
                description = "Perhaps there is truth in new ideas.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "{heir_name} listens carefully. Not everything old is sacred. Not everything new is heresy.",
                },
            },
        },
    },

    -- CULTURE-INFLUENCED EVENTS
    {
        id = "tradition_challenged",
        title = "The Old Ways Questioned",
        narrative = "Young voices in the family question ancient customs. Change or tradition — one must yield.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Defend tradition",
                description = "Leadership and willpower enforce the old ways.",
                check = { primary = { trait = "SOC_LEA", weight = 0.8 }, secondary = { trait = "MEN_WIL", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "{heir_name} speaks with the weight of ancestors. The customs endure.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "{heir_name}'s words ring hollow. The young are unconvinced.",
                },
            },
            {
                label = "Embrace change",
                description = "Adaptability and vision lead the way forward.",
                requires = { axis = "PER_ADA", min = 45 },
                check = { primary = { trait = "CRE_ING", weight = 0.8 }, secondary = { trait = "SOC_CHA", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = -1 },
                    narrative = "{heir_name} breaks with tradition. The family evolves — but at what cost?",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1, social = -2 },
                    narrative = "The proposed changes fail. Neither old nor new satisfies.",
                },
            },
        },
    },

    -- MULTI-FACTION TENSION EVENTS
    {
        id = "border_dispute_escalation",
        title = "The Disputed Border",
        narrative = "Two factions claim the same stretch of fertile land. Both demand {heir_name}'s support.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Mediate diplomatically",
                description = "Negotiation and social awareness are crucial.",
                check = { primary = { trait = "SOC_NEG", weight = 1.0 }, secondary = { trait = "SOC_AWR", weight = 0.5 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "{heir_name} brokers a peace that satisfies both sides. Diplomacy triumphs.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    add_condition = { type = "war", intensity = 0.3, duration = 2 },
                    narrative = "Negotiations collapse. The dispute escalates to open conflict.",
                },
            },
            {
                label = "Side with the stronger faction",
                description = "Pragmatism over principle.",
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    narrative = "{heir_name} supports the stronger side. Pragmatism is rewarded, but not forgotten by the other.",
                },
            },
            {
                label = "Claim the land yourself",
                description = "Boldness and strength take what diplomacy cannot.",
                requires = { axis = "PER_BLD", min = 65 },
                check = { primary = { trait = "PHY_STR", weight = 0.8 }, secondary = { trait = "SOC_INM", weight = 0.6 }, difficulty = 65 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    faction_power_shift = 8,
                    disposition_changes = { { faction_id = "all", delta = -12 } },
                    narrative = "{heir_name} plants the family banner on the disputed land. Enemies on all sides — but the land is yours.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    narrative = "The bold gambit fails. Neither faction forgets the insult.",
                },
            },
        },
    },

    {
        id = "plague_alchemist",
        title = "The Plague Alchemist",
        narrative = "A mysterious figure arrives claiming a cure for the sickness. The price: your family's rarest texts.",
        chance = 0.35,
        requires_condition = "plague",
        cooldown = 6,
        options = {
            {
                label = "Test the cure",
                description = "Analytical thinking and perception to verify the claim.",
                check = { primary = { trait = "MEN_ANA", weight = 1.0 }, secondary = { trait = "MEN_PER", weight = 0.5 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "{heir_name} tests the cure on willing subjects. It works — partially. Knowledge is preserved.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -1 },
                    narrative = "The cure is a fraud. The alchemist vanishes. Time wasted.",
                },
            },
            {
                label = "Pay the price",
                description = "Give the texts. Save lives.",
                requires = { axis = "PER_LOY", min = 50 },
                consequences = {
                    cultural_memory_shift = { mental = -3, social = 3 },
                    narrative = "The texts are surrendered. The cure spreads. Lives are saved, but knowledge is lost.",
                },
            },
            {
                label = "Seize the cure by force",
                description = "Take everything. Give nothing.",
                requires = { axis = "PER_CRM", min = 60 },
                check = { primary = { trait = "PHY_STR", weight = 0.8 }, secondary = { trait = "SOC_INM", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    taboo_chance = 0.3,
                    taboo_data = { trigger = "seized_cure", effect = "feared_as_tyrant", strength = 65 },
                    narrative = "The cure is taken. The alchemist is cast out. Effective — if brutal.",
                },
                consequences_fail = {
                    narrative = "The alchemist fights back with unexpected ferocity. The cure is destroyed in the scuffle.",
                },
            },
        },
    },

    {
        id = "famine_necessity",
        title = "Necessity's Children",
        narrative = "The famine drives desperate invention. Workers present {heir_name} with new farming techniques — untested, but promising.",
        chance = 0.35,
        requires_condition = "famine",
        cooldown = 6,
        options = {
            {
                label = "Test the techniques",
                description = "Ingenuity and analytical thinking evaluate the approach.",
                check = { primary = { trait = "CRE_ING", weight = 0.8 }, secondary = { trait = "MEN_ANA", weight = 0.6 }, tertiary = { trait = "CRE_INN", weight = 0.3 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 1 },
                    narrative = "{heir_name} oversees the trials. The new methods show promise. Hunger lessens.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The techniques fail. The soil rejects what desperation offered.",
                },
            },
            {
                label = "Invest everything in the new methods",
                description = "Bold commitment. All or nothing.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 4 },
                    faction_power_shift = 5,
                    narrative = "{heir_name} stakes the family's future on innovation. It pays off — barely.",
                },
            },
            {
                label = "Stick to proven methods",
                description = "Tradition over experimentation in dire times.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The old ways endure, if barely. No one starves, but no one thrives either.",
                },
            },
        },
    },
}
