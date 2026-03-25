-- Dark Legacy — Personal Events: Curiosity
return {
    {
        id = "forbidden_knowledge",
        title = "Forbidden Knowledge Uncovered",
        narrative = "{heir_name} unearthed texts that were sealed for a reason. The knowledge within burns.",
        trigger_axis = "PER_CUR",
        trigger_min = 75,
        chance = 0.35,
        consequence = {
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.6 } },
            cultural_memory_shift = { mental = 4, creative = 2 },
            narrative = "{heir_name} read what should not have been read. The bloodline stirs with new patterns.",
        },
    },
    {
        id = "incurious_stagnation",
        title = "The Sealed Relic",
        narrative = "A relic was found. {heir_name} ordered it buried again.",
        trigger_axis = "PER_CUR",
        trigger_max = 25,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { creative = -3, mental = -2 },
            narrative = "An ancient discovery was ignored. The bloodline chose the comfort of ignorance.",
        },
    },
    {
        id = "truth_too_far",
        title = "What Was Found Cannot Be Unfound",
        narrative = "Came back different. No longer slept with the lights off.",
        trigger_axis = "PER_CUR",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
            cultural_memory_shift = { mental = 5, social = -3, creative = 4 },
            taboo_chance = 0.15,
            taboo_data = { trigger = "truth_seekers", effect = "forbidden_seekers", strength = 65 },
            narrative = "{heir_name} found what they were looking for. They wished they hadn't. The bloodline is forever changed.",
        },
    },
    -- NEW: MID-HIGH — curiosity as social disruption
    {
        id = "questioned_the_priest",
        title = "Questions Without End",
        narrative = "{heir_name} asked the holy man a question. Then another. Then another. The priest wept before noon. Not from cruelty. From relentlessness.",
        trigger_axis = "PER_CUR",
        trigger_min = 60,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { mental = 2, social = -1 },
            narrative = "The questions were not hostile. They were genuine. That made them worse. Certainty is fragile when someone truly wants to know.",
        },
    },
    -- NEW: MID-LOW — willful ignorance
    {
        id = "burned_the_books",
        title = "The Library Became Stables",
        narrative = "A library was offered as tribute from a conquered house. {heir_name} had it converted to stables by sundown.",
        trigger_axis = "PER_CUR",
        trigger_max = 40,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { mental = -2, creative = -2 },
            narrative = "Knowledge has no value to those who do not seek it. The horses seemed comfortable.",
        },
    },
    -- NEW: ALT-HIGH — curiosity as bridge-building
    {
        id = "learned_their_tongue",
        title = "Speaking the Enemy's Words",
        narrative = "{heir_name} spent months learning the rival faction's language. Not to spy. To understand what they meant when they prayed.",
        trigger_axis = "PER_CUR",
        trigger_min = 65,
        chance = 0.25,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { mental = 2, social = 2 },
            disposition_changes = { { faction_id = "all", delta = 2 } },
            narrative = "Understanding your enemy does not make them less dangerous. But it makes you something more.",
        },
    },
}
