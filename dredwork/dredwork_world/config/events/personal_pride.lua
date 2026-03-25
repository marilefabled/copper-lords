-- Dark Legacy — Personal Events: Pride
return {
    {
        id = "demands_tribute",
        title = "The Heir Demands Tribute",
        narrative = "{heir_name} sent envoys to the lesser houses, demanding tribute as acknowledgment of the bloodline's supremacy.",
        trigger_axis = "PER_PRI",
        trigger_min = 70,
        chance = 0.35,
        pick_faction = true,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -5 } },
            cultural_memory_shift = { social = -2 },
            narrative = "Tribute was demanded. Some paid in gold. Others paid in silent resentment.",
        },
    },
    {
        id = "self_effacing_leader",
        title = "The Quiet Hand",
        narrative = "The realm prospered and nobody knew whose hand guided it.",
        trigger_axis = "PER_PRI",
        trigger_max = 25,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = 2, mental = 1 },
            narrative = "{heir_name} led from the shadows. No monuments. No songs. Just results.",
        },
    },
    {
        id = "monument_to_self",
        title = "The Tower That Touched the Sky",
        narrative = "Built a tower so tall it could be seen from every house. {heir_name}'s name was carved into every stone.",
        trigger_axis = "PER_PRI",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            cultural_memory_shift = { creative = 3, social = -4 },
            disposition_changes = { { faction_id = "all", delta = -5 } },
            narrative = "A monument to ego. The world marveled, then resented. The tower stood, indifferent to their opinions.",
        },
    },
    -- NEW: MID-HIGH — pride as performance
    {
        id = "refused_to_kneel",
        title = "The Heir Did Not Kneel",
        narrative = "At the summit, every lord knelt for the opening rite. {heir_name} stood. The silence was deafening.",
        trigger_axis = "PER_PRI",
        trigger_min = 60,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = -1 },
            disposition_changes = { { faction_id = "all", delta = -3 } },
            narrative = "It was not defiance. It was simply that {heir_name} did not believe anyone in that room outranked the blood.",
        },
    },
    -- NEW: MID-LOW — humility that unnerves
    {
        id = "wore_rags_to_court",
        title = "Dressed Like a Servant",
        narrative = "{heir_name} arrived at the grand feast in a servant's clothes. Sat at the lowest table. Ate the same food. Said nothing.",
        trigger_axis = "PER_PRI",
        trigger_max = 40,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = 1 },
            narrative = "The lords did not know if it was a statement or a joke. {heir_name} offered no explanation. The ambiguity was itself a kind of power.",
        },
    },
    -- NEW: ALT-HIGH — pride channeled into legacy
    {
        id = "commissioned_the_chronicle",
        title = "Every Generation, Recorded",
        narrative = "{heir_name} hired seven scribes. Every ancestor. Every battle. Every marriage. Nothing would be forgotten. Nothing would be small.",
        trigger_axis = "PER_PRI",
        trigger_min = 65,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { creative = 2, mental = 1 },
            narrative = "The chronicle grew thick as a door. Whether anyone would read it was beside the point. It existed. The blood was documented.",
        },
    },
}
