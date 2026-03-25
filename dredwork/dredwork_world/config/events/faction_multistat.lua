-- Dark Legacy — Multi-stat Faction Events
-- Events using faction relations, multi-trait checks, and personality gating.

return {
    {
        id = "faction_duel_challenge",
        title = "A Champion's Challenge",
        narrative = "A champion of a rival faction demands single combat with {heir_name}. Refusing means disgrace.",
        chance = 0.3,
        cooldown = 8,
        disposition_max = -20,
        options = {
            {
                label = "Accept the duel",
                description = "Strength and reflexes determine the outcome.",
                check = { primary = { trait = "PHY_STR", weight = 1.0 }, secondary = { trait = "PHY_REF", weight = 0.7 }, tertiary = { trait = "PHY_BLD", weight = 0.3 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 4 },
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    narrative = "{heir_name} defeats the champion in single combat. Even enemies offer grudging respect.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    narrative = "{heir_name} falls to the champion's blade. Alive, but humiliated.",
                },
            },
            {
                label = "Send a champion in your stead",
                description = "Leadership and cunning find a way.",
                requires = { axis = "PER_BLD", max = 50 },
                check = { primary = { trait = "SOC_LEA", weight = 0.8 }, secondary = { trait = "MEN_CUN", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "{heir_name} selects a champion wisely. Victory is achieved — by proxy.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "Your champion falls. The shame is twice compounded.",
                },
            },
            {
                label = "Refuse and bear the disgrace",
                description = "Pragmatism over pride.",
                consequences = {
                    cultural_memory_shift = { social = -3 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "{heir_name} refuses the duel. Cowardice, they call it. But {heir_name} is alive.",
                },
            },
        },
    },

    {
        id = "faction_spy_network",
        title = "The Shadow Network",
        narrative = "Your agents have uncovered a rival faction's spy network operating within your household.",
        chance = 0.25,
        cooldown = 10,
        disposition_max = 0,
        options = {
            {
                label = "Root out the spies",
                description = "Perception and cunning expose the hidden.",
                check = { primary = { trait = "MEN_PER", weight = 1.0 }, secondary = { trait = "MEN_CUN", weight = 0.7 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    narrative = "Every spy is found. Every secret recovered. The rival faction's network is shattered.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -1 },
                    narrative = "Some spies escape. They know you're looking now.",
                },
            },
            {
                label = "Feed them false information",
                description = "Deception and cunning turn the network into a weapon.",
                check = { primary = { trait = "SOC_DEC", weight = 1.0 }, secondary = { trait = "MEN_CUN", weight = 0.6 }, difficulty = 55 },
                requires = { axis = "PER_CRM", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 2, social = 2 },
                    narrative = "The spies carry home carefully crafted lies. Your enemies will act on fiction.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The deception is too transparent. The spies see through it.",
                },
            },
            {
                label = "Ignore it — maintain the peace",
                description = "Sometimes ignorance is diplomacy.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    narrative = "You know they're watching. They know you know. An uneasy détente settles.",
                },
            },
        },
    },

    {
        id = "faction_marriage_proposal",
        title = "An Unexpected Proposal",
        narrative = "A powerful faction sends an envoy with a marriage proposal for {heir_name}'s sibling — binding the bloodlines together.",
        chance = 0.25,
        cooldown = 8,
        disposition_min = -10,
        options = {
            {
                label = "Accept the union",
                description = "Diplomacy strengthens through blood ties. Your heir must marry from their house.",
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    add_relationship = { type = "ally", strength = 60, reason = "marriage_pact" },
                    arranged_marriage_lock = true,
                    narrative = "The marriage is sealed. Two bloodlines intertwine. Your heir is betrothed.",
                },
            },
            {
                label = "Negotiate better terms",
                description = "Negotiation and social awareness extract more value.",
                check = { primary = { trait = "SOC_NEG", weight = 1.0 }, secondary = { trait = "SOC_AWR", weight = 0.5 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    faction_power_shift = 5,
                    add_relationship = { type = "ally", strength = 50, reason = "marriage_pact" },
                    narrative = "{heir_name} secures concessions before agreeing. The union proceeds on your terms.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    narrative = "Your demands are seen as insulting. The proposal is withdrawn.",
                },
            },
            {
                label = "Refuse the proposal",
                description = "The bloodline remains pure.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    narrative = "The envoy departs in cold fury. Your pride is intact, but so is their grudge.",
                },
            },
        },
    },

    {
        id = "faction_trade_blockade",
        title = "The Blockade",
        narrative = "A rival faction blocks trade routes critical to your family's prosperity.",
        chance = 0.3,
        cooldown = 8,
        disposition_max = -30,
        options = {
            {
                label = "Break the blockade by force",
                description = "Strength and strategy overwhelm the obstruction.",
                check = { primary = { trait = "PHY_STR", weight = 0.7 }, secondary = { trait = "MEN_STR", weight = 0.8 }, tertiary = { trait = "SOC_CON", weight = 0.3 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    narrative = "{heir_name} smashes through the blockade. Goods flow again — over broken barricades.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    add_condition = { type = "famine", intensity = 0.3, duration = 2 },
                    narrative = "The assault fails. The blockade tightens. Scarcity looms.",
                },
            },
            {
                label = "Find alternate trade routes",
                description = "Resourcefulness and ingenuity forge new paths.",
                check = { primary = { trait = "CRE_RES", weight = 1.0 }, secondary = { trait = "MEN_SPA", weight = 0.5 }, tertiary = { trait = "CRE_TIN", weight = 0.3 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3 },
                    narrative = "New routes are carved through wilderness. The blockade becomes irrelevant.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The alternate routes prove impractical. The family tightens its belt.",
                },
            },
            {
                label = "Pay the tribute demanded",
                description = "Submit to keep the peace.",
                consequences = {
                    faction_power_shift = -5,
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    narrative = "Gold buys passage. Your coffers are lighter, but goods flow again.",
                },
            },
        },
    },

    {
        id = "faction_cultural_clash",
        title = "Clash of Cultures",
        narrative = "Your family's customs offend a neighboring faction. Their ambassador demands you abandon the tradition — or face consequences.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Stand firm on tradition",
                description = "Willpower and leadership defend your culture.",
                check = { primary = { trait = "MEN_WIL", weight = 0.8 }, secondary = { trait = "SOC_LEA", weight = 0.6 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    narrative = "{heir_name} refuses to bend. The custom endures — and so does the enmity.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    narrative = "Your defiance is seen as weakness disguised as stubbornness.",
                },
            },
            {
                label = "Compromise — adapt the tradition",
                description = "Cultural sensitivity and empathy bridge the divide.",
                check = { primary = { trait = "SOC_CUL", weight = 1.0 }, secondary = { trait = "SOC_EMP", weight = 0.5 }, tertiary = { trait = "CRE_FLV", weight = 0.3 }, difficulty = 50 },
                requires = { axis = "PER_ADA", min = 40 },
                consequences = {
                    cultural_memory_shift = { social = 3, creative = 1 },
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    narrative = "The tradition evolves. Both cultures find common ground.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The compromise satisfies no one. Both sides feel cheated.",
                },
            },
            {
                label = "Abandon the custom entirely",
                description = "Peace at any cultural cost.",
                consequences = {
                    cultural_memory_shift = { social = -3 },
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    taboo_chance = 0.3,
                    taboo_data = { trigger = "culture_abandoned", effect = "distrust_of_outsider_influence", strength = 60 },
                    narrative = "The old custom dies. The faction is pleased. Your ancestors are not.",
                },
            },
        },
    },
}
