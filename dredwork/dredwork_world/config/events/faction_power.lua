-- Dark Legacy — Faction Events: Power-Level
-- Events gated by faction power thresholds
return {
    {
        id = "faction_rising_threat",
        title = "{faction_name} Grows Mighty",
        narrative = "{faction_name} has grown powerful beyond measure. Their armies swell. Their coffers overflow. The balance of power shifts.",
        chance = 0.25,
        faction_power_min = 75,
        options = {
            {
                label = "Form a coalition",
                description = "Unite the other houses against the rising threat.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "A coalition was formed. Alone, each house was weak. Together, they could check the rising power.",
                },
            },
            {
                label = "Strike first",
                description = "Before they become unstoppable.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.5, duration = 3 },
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    cultural_memory_shift = { physical = 3, social = -3 },
                    narrative = "The preemptive strike was bold and bloody. Whether it was wise remained to be seen.",
                },
            },
            {
                label = "Ally with the strong",
                description = "If you can't beat them, join them.",
                requires = { axis = "PER_LOY", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    add_relationship = { type = "ally", strength = 55, reason = "aligned_with_power" },
                    cultural_memory_shift = { social = 1 },
                    narrative = "An alliance with the strong. Pragmatic. Perhaps craven. Definitely safe. For now.",
                },
            },
        },
    },
    {
        id = "faction_collapse",
        title = "{faction_name} Crumbles",
        narrative = "{faction_name} is dying. Their power fades. Their people scatter. What remains is ripe for the taking — or the saving.",
        chance = 0.3,
        faction_power_max = 25,
        options = {
            {
                label = "Absorb their people",
                description = "Welcome the refugees. Strengthen the bloodline.",
                consequences = {
                    mutation_triggers = { { type = "intermarriage", intensity = 0.5 } },
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The refugees were welcomed. New blood flowed into old veins. The bloodline grew richer.",
                },
            },
            {
                label = "Loot what remains",
                description = "The dead have no need of treasures.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    faction_power_shift = -20,
                    cultural_memory_shift = { physical = 2, social = -4 },
                    narrative = "What remained of {faction_name} was stripped bare. Efficient. Ruthless. The vultures always come.",
                },
            },
            {
                label = "Prop them up",
                description = "A weak ally is still an ally.",
                requires = { axis = "PER_CRM", max = 55 },
                consequences = {
                    faction_power_shift = 15,
                    disposition_changes = { { faction_id = "_target", delta = 25 } },
                    add_relationship = { type = "ally", strength = 60, reason = "saved_from_collapse" },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Resources were sent. {faction_name} survived. They would not forget who pulled them from the abyss.",
                },
            },
        },
    },
    {
        id = "faction_civil_war",
        title = "Civil War in {faction_name}",
        narrative = "Two factions within {faction_name} tear at each other. The house bleeds from within.",
        chance = 0.25,
        faction_power_min = 30,
        faction_power_max = 50,
        options = {
            {
                label = "Support one side",
                description = "Choose a winner. Gain a friend.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    faction_power_shift = -10,
                    cultural_memory_shift = { social = 1 },
                    narrative = "Support was sent. The chosen side prevailed. A grateful, if weakened, ally emerged.",
                },
            },
            {
                label = "Exploit the chaos",
                description = "While they fight each other, take what you can.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    faction_power_shift = -15,
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 2, social = -3 },
                    narrative = "While {faction_name} tore itself apart, the bloodline grew stronger on the scraps.",
                },
            },
            {
                label = "Mediate",
                description = "End the conflict. Earn the gratitude of both sides.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Mediation was offered and accepted. The civil war ended. Both sides owed a debt to the bloodline.",
                },
            },
        },
    },
    {
        id = "faction_succession",
        title = "A New Leader in {faction_name}",
        narrative = "Power has changed hands in {faction_name}. A new leader sits at their head. All old arrangements are in question.",
        chance = 0.3,
        options = {
            {
                label = "Congratulate the new leader",
                description = "Start fresh. Build a new relationship.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 1 },
                    narrative = "Congratulations were sent. The new leader appreciated the gesture. A fresh start.",
                },
            },
            {
                label = "Test the new leader",
                description = "See what they're made of before committing.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { mental = 2 },
                    narrative = "A small provocation was sent. The new leader's response would tell the bloodline everything it needed to know.",
                },
            },
            {
                label = "Ignore the transition",
                description = "One leader or another. It makes no difference.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The change in leadership was noted and filed away. No response. No acknowledgment. Business as usual.",
                },
            },
        },
    },
    {
        id = "faction_demands_submission",
        title = "{faction_name} Demands You Kneel",
        narrative = "Envoys from {faction_name} arrive with a single demand: acknowledge their superiority. Submit or face consequences.",
        chance = 0.2,
        faction_power_min = 70,
        disposition_max = 0,
        options = {
            {
                label = "Refuse outright",
                description = "We kneel to no one.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.5, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    cultural_memory_shift = { physical = 3, social = 2 },
                    narrative = "The demand was rejected. War followed. But the bloodline stood tall.",
                },
            },
            {
                label = "Negotiate terms",
                description = "Find middle ground. Preserve dignity without inviting destruction.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Negotiation softened the demand. No one knelt. No one fought. A compromise of sorts.",
                },
            },
            {
                label = "Submit",
                description = "Survival first. Pride later.",
                requires = { axis = "PER_PRI", max = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = -4, physical = -2 },
                    taboo_chance = 0.20,
                    taboo_data = { trigger = "submission", effect = "once_we_knelt", strength = 75 },
                    narrative = "The knee was bent. The words were spoken. The bloodline survived. The shame would last longer.",
                },
            },
        },
    },
}
