-- Dark Legacy — Personal Events: Loyalty
return {
    {
        id = "shelters_fugitive",
        title = "Blood Protects Blood",
        narrative = "{heir_name} sheltered a disgraced kinsman, refusing all demands to surrender them.",
        trigger_axis = "PER_LOY",
        trigger_min = 70,
        chance = 0.35,
        pick_faction = true,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -5 } },
            cultural_memory_shift = { social = 2 },
            narrative = "A fugitive of the blood was sheltered. The world disapproved, but the family's bond deepened.",
        },
    },
    {
        id = "betrays_ally",
        title = "A Blade in the Dark",
        narrative = "Sold them out without blinking. {heir_name} chose survival over loyalty.",
        trigger_axis = "PER_LOY",
        trigger_max = 25,
        chance = 0.3,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { mental = 2, social = -4 },
            disposition_changes = { { faction_id = "all", delta = -8 } },
            narrative = "An ally was betrayed. The bloodline gained something. It cost something greater.",
        },
    },
    {
        id = "martyrdom_attempt",
        title = "The Shield Arm Shattered",
        narrative = "Found collapsed, shield arm shattered, still breathing. Barely.",
        trigger_axis = "PER_LOY",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            cultural_memory_shift = { social = 5, physical = -3 },
            disposition_changes = { { faction_id = "all", delta = 5 } },
            narrative = "{heir_name} nearly died protecting the family. The scars would never heal, but the bloodline would never forget.",
        },
    },
    -- NEW: MID-HIGH — loyalty as quiet devotion
    {
        id = "remembered_every_name",
        title = "The Heir Who Remembered",
        narrative = "Knew every guard's child by name. Every cook's birthday. Every stable hand's dead wife. {heir_name} remembered all of them.",
        trigger_axis = "PER_LOY",
        trigger_min = 55,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = 2 },
            disposition_changes = { { faction_id = "all", delta = 2 } },
            narrative = "It was not strategy. It was not calculation. {heir_name} simply could not forget the people who served the blood.",
        },
    },
    -- NEW: MID-LOW — self-preservation over bonds
    {
        id = "kept_the_letter",
        title = "The Letter That Was Filed",
        narrative = "A cousin's plea for help arrived. Desperate. Urgent. {heir_name} read it carefully, folded it, and placed it in a drawer. Did nothing.",
        trigger_axis = "PER_LOY",
        trigger_max = 40,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = -2, mental = 1 },
            narrative = "The cousin was never heard from again. {heir_name} never mentioned the letter. The drawer stayed closed.",
        },
    },
    -- NEW: ALT-HIGH — loyalty that costs everything
    {
        id = "took_the_blame",
        title = "It Was Me",
        narrative = "The crime was a servant's. The punishment would have been death. {heir_name} stepped forward. 'It was me.' The court erupted.",
        trigger_axis = "PER_LOY",
        trigger_min = 70,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { social = 3, physical = -1 },
            disposition_changes = { { faction_id = "all", delta = -2 } },
            narrative = "An heir of the blood, claiming a servant's sin. The lords thought it madness. The servants thought it something else entirely.",
        },
    },
}
