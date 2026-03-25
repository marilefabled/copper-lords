-- Dark Legacy — Personal Events: Adaptability
return {
    {
        id = "rigid_refusal",
        title = "The Old Ways",
        narrative = "When advisors proposed change, {heir_name} refused. 'This is how it has always been done.'",
        trigger_axis = "PER_ADA",
        trigger_max = 30,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { creative = -2 },
            narrative = "{heir_name} clung to tradition while the world shifted around them.",
        },
    },
    {
        id = "chameleon_diplomacy",
        title = "A Thousand Faces",
        narrative = "Spoke to warriors as a warrior, to scholars as a scholar. No one could pin down who {heir_name} truly was.",
        trigger_axis = "PER_ADA",
        trigger_min = 75,
        chance = 0.35,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { social = 3 },
            disposition_changes = { { faction_id = "all", delta = 3 } },
            narrative = "{heir_name}'s fluid nature opened doors that had been sealed for generations. Trust, though, was harder to earn.",
        },
    },
    {
        id = "identity_crisis",
        title = "Who Are We Now?",
        narrative = "Changed everything. The banner. The customs. The way the family prayed.",
        trigger_axis = "PER_ADA",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            cultural_memory_shift = { physical = -2, mental = -2, social = -2, creative = -2 },
            narrative = "{heir_name} reshaped the family's identity so completely that even the ancestors wouldn't recognize them.",
        },
    },
    -- NEW: MID-HIGH — adaptability as learning
    {
        id = "learned_their_prayers",
        title = "The Enemy's Prayers",
        narrative = "{heir_name} learned the rival faction's prayers. Not to mock. Not to infiltrate. Just to understand what comfort sounded like in another tongue.",
        trigger_axis = "PER_ADA",
        trigger_min = 60,
        chance = 0.3,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { mental = 1, social = 2 },
            disposition_changes = { { faction_id = "all", delta = 1 } },
            narrative = "The guards heard the heir praying in a foreign language. It was not treason. It was something harder to name.",
        },
    },
    -- NEW: MID-LOW — rigidity under pressure
    {
        id = "purged_foreign_influence",
        title = "Nothing From Outside",
        narrative = "Foreign tapestries torn down. Foreign recipes burned. Foreign names struck from the records. {heir_name} wanted the house pure.",
        trigger_axis = "PER_ADA",
        trigger_max = 35,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { creative = -2, social = -2 },
            disposition_changes = { { faction_id = "all", delta = -3 } },
            narrative = "The house was pure. It was also smaller. Quieter. Some traditions require sacrifice. This one required amputation.",
        },
    },
    -- NEW: ALT-HIGH — adaptability as survival instinct
    {
        id = "ate_the_strange_food",
        title = "Every Dish on the Table",
        narrative = "At the foreign feast, {heir_name} ate everything offered. The things that wriggled. The things that smoked. The things that stared back.",
        trigger_axis = "PER_ADA",
        trigger_min = 65,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { physical = 1, social = 1 },
            disposition_changes = { { faction_id = "all", delta = 2 } },
            narrative = "The hosts were delighted. The guards were horrified. {heir_name} asked for seconds.",
        },
    },
}
