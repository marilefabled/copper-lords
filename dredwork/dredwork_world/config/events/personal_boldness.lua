-- Dark Legacy — Personal Events: Boldness
-- 6 events: HIGH, LOW, EXTREME + MID-HIGH, MID-LOW, ALT-HIGH
return {
    {
        id = "reckless_expedition",
        title = "A Reckless Venture",
        narrative = "{heir_name} rode out alone beyond the borders. No counsel sought. No permission given.",
        trigger_axis = "PER_BLD",
        trigger_min = 75,
        chance = 0.4,
        consequence = {
            cultural_memory_shift = { physical = 3, social = -2 },
            mutation_triggers = { { type = "war", intensity = 0.3 } },
            narrative = "{heir_name} returned from the expedition changed — scarred but carrying secrets.",
        },
    },
    {
        id = "cowardice_exposed",
        title = "A Moment of Hesitation",
        narrative = "When the moment came, {heir_name} froze. The entire court saw it.",
        trigger_axis = "PER_BLD",
        trigger_max = 30,
        chance = 0.35,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -3 } },
            cultural_memory_shift = { social = -2 },
            narrative = "When the moment came, {heir_name} froze. The whispers started before the sun set.",
        },
    },
    {
        id = "suicidal_charge",
        title = "Into Impossible Odds",
        narrative = "They said it was impossible. {heir_name} did not care.",
        trigger_axis = "PER_BLD",
        trigger_min = 85,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { physical = 5, social = 2 },
            mutation_triggers = { { type = "war", intensity = 0.5 } },
            taboo_chance = 0.10,
            taboo_data = { trigger = "suicidal_charge", effect = "bloodline_charges_alone", strength = 60 },
            narrative = "Against all reason, {heir_name} charged. Against all odds, they survived. The bloodline will remember.",
        },
    },
    -- NEW: MID-HIGH — courage expressed as instinct, not glory
    {
        id = "first_into_the_fire",
        title = "First Into the Fire",
        narrative = "The granary was burning. The servants stood frozen. {heir_name} was already through the doors before anyone could speak.",
        trigger_axis = "PER_BLD",
        trigger_min = 55,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { physical = 2, social = 1 },
            narrative = "{heir_name} pulled three children from the flames. Refused to let the healers treat the burns until dawn.",
        },
    },
    -- NEW: MID-LOW — caution that isn't quite cowardice
    {
        id = "chose_the_long_road",
        title = "The Long Way Home",
        narrative = "The mountain pass was faster. Everyone knew it. {heir_name} chose the valley road and added three days to the journey.",
        trigger_axis = "PER_BLD",
        trigger_max = 45,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { mental = 1 },
            narrative = "They arrived late. But they arrived alive. The scouts who took the pass did not.",
        },
    },
    -- NEW: ALT-HIGH — boldness as tenderness
    {
        id = "dared_to_grieve",
        title = "The Heir Wept Publicly",
        narrative = "At the memorial, every lord stood in iron composure. {heir_name} knelt and wept openly. The court did not know what to do with that.",
        trigger_axis = "PER_BLD",
        trigger_min = 65,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { social = 2 },
            disposition_changes = { { faction_id = "all", delta = 2 } },
            narrative = "It takes a kind of courage to break in front of the powerful. Some called it weakness. More remembered it as strength.",
        },
    },
}
