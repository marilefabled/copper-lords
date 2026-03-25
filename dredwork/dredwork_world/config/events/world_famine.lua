-- Dark Legacy — World Events: Famine
return {
    {
        id = "famine_spreads",
        title = "The Harvest Fails",
        narrative = "Crops wither in the fields. Stores run low. Hunger gnaws at the foundation of every house.",
        chance = 0.35,
        cooldown = 3,
        requires_no_condition = "famine",
        options = {
            {
                label = "Ration carefully",
                description = "Tighten belts. Endure. Wait for better days.",
                consequences = {
                    add_condition = { type = "famine", intensity = 0.4, duration = 3 },
                    narrative = "The family endured on thin gruel and thinner hope.",
                },
            },
            {
                label = "Raid neighboring stores",
                description = "Take what you need by force.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    add_condition = { type = "famine", intensity = 0.2, duration = 1 },
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                    cultural_memory_shift = { physical = 2, social = -3 },
                    narrative = "Granaries were seized. Bellies filled. But the neighbors remember.",
                },
            },
            {
                label = "Share what little we have",
                description = "Open the stores to the common folk.",
                requires = { axis = "PER_CRM", max = 45 },
                consequences = {
                    add_condition = { type = "famine", intensity = 0.5, duration = 4 },
                    disposition_changes = { { faction_id = "all", delta = 10 } },
                    cultural_memory_shift = { social = 4 },
                    narrative = "The stores were opened. The family starved alongside the people. Songs were written.",
                },
            },
            {
                label = "Implement rationing protocols",
                description = "Your knowledge of rationing ensures no one starves — if discipline holds.",
                requires_discovery = "rationing",
                consequences = {
                    add_condition = { type = "famine", intensity = 0.2, duration = 1 },
                    cultural_memory_shift = { mental = 2, social = 1 },
                    narrative = "Every grain counted. Every mouth measured. The bloodline's knowledge turned famine into mere austerity.",
                },
            },
        },
    },
    {
        id = "famine_cannibalism",
        title = "The Unspeakable Choice",
        narrative = "In the deepest hollows of hunger, dark whispers emerge. The taboo that should never be broken trembles.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "famine",
        requires_generation_min = 5,
        options = {
            {
                label = "Suppress the rumors",
                description = "No. Not this. Never this.",
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "The whispers were silenced. Some things are worse than hunger.",
                },
            },
            {
                label = "Distribute emergency stores",
                description = "Open the last reserves. There will be nothing after this.",
                consequences = {
                    cultural_memory_shift = { social = 3, physical = -2 },
                    narrative = "The last stores were opened. Empty shelves stared back. But the darkness retreated.",
                },
            },
            {
                label = "Do nothing",
                description = "Let nature take its course.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -5 },
                    taboo_chance = 0.20,
                    taboo_data = { trigger = "famine_cruelty", effect = "the_hungry_years", strength = 75 },
                    narrative = "Nothing was done. What happened in the dark corners of the estate was never spoken of again.",
                },
            },
        },
    },
    {
        id = "famine_innovation",
        title = "Seeds of Change",
        narrative = "A new method of farming is proposed. It could end the hunger — or waste what little remains.",
        chance = 0.35,
        cooldown = 3,
        requires_condition = "famine",
        options = {
            {
                label = "Invest in the new method",
                description = "Risk the last resources on innovation.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    remove_condition = "famine",
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "The gamble paid off. New crops rose from barren earth. The famine broke like a fever.",
                },
            },
            {
                label = "Hoard what remains",
                description = "Innovation is for those who can afford to fail.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The stores were locked tight. The family would outlast the famine through will alone.",
                },
            },
            {
                label = "Share the knowledge freely",
                description = "If it works, let everyone benefit.",
                requires = { axis = "PER_CRM", max = 50 },
                consequences = {
                    remove_condition = "famine",
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 4 },
                    narrative = "The knowledge was shared. Famine broke across all lands. The bloodline was remembered as saviors.",
                },
            },
        },
    },
    {
        id = "famine_exodus",
        title = "The Hungry Road",
        narrative = "Refugees stream past the estate. Gaunt, hollow-eyed, carrying nothing. They were someone's people, once. Now they are no one's.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "famine",
        options = {
            {
                label = "Take them in",
                description = "More mouths. But also more hands. And more loyalty.",
                requires = { axis = "PER_CRM", max = 50 },
                consequences = {
                    cultural_memory_shift = { social = 4, physical = -1 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "The gates opened. The hungry shuffled in. They would remember this — and so would their children.",
                },
            },
            {
                label = "Turn them away",
                description = "We cannot feed ourselves. We cannot feed strangers.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The gates stayed closed. The column passed. Some collapsed in view of the walls. The guards were ordered not to look.",
                },
            },
            {
                label = "Recruit the strongest",
                description = "The desperate make loyal soldiers. Offer food for service.",
                requires = { axis = "PER_ADA", min = 45 },
                stat_check = { primary = "SOC_NEG", secondary = "SOC_LEA", difficulty = 45 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = 1 },
                    narrative = "The strongest were culled from the column. Fed, armed, sworn. An army built on desperation serves with terrifying devotion.",
                },
            },
        },
    },
    {
        id = "famine_rot",
        title = "The Rot in the Stores",
        narrative = "Vermin have reached the granary. Half the remaining stores are spoiled. What's left won't last the season.",
        chance = 0.25,
        cooldown = 3,
        requires_condition = "famine",
        options = {
            {
                label = "Purge and salvage",
                description = "Sort every grain. Save what can be saved.",
                stat_check = { primary = "PHY_MET", secondary = "MEN_FOC", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 2, physical = 1 },
                    narrative = "Every grain was inspected. Half was dust. Half was survival. The bloodline learned to count what mattered.",
                },
            },
            {
                label = "Hunt and forage",
                description = "The land still provides — if you know where to look.",
                stat_check = { primary = "PHY_SEN", secondary = "CRE_RES", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, creative = 2 },
                    narrative = "The family ate roots, bark, and creatures they had no names for. It was not pride. It was survival.",
                },
            },
            {
                label = "Trade relics for food",
                description = "The past weighs nothing when the present is starving.",
                consequences = {
                    cultural_memory_shift = { social = 2, creative = -2 },
                    narrative = "Heirlooms were traded for grain. The merchants smiled. The ancestors, had they still spoken, would not have.",
                },
            },
        },
    },
}
