-- Dark Legacy — Cross-Run Echo Templates
-- Template pools for referencing past dynasties in new runs.

local cross_run_templates = {

    whispers = {
        "In ages past, the {past_lineage} walked these same halls...",
        "The {past_faction} still speaks of the {past_lineage} in hushed tones.",
        "The ghost of {past_lineage} lingers in the stones of this place.",
        "Once, the {past_lineage} stood where you stand now. They lasted {past_gens} generations.",
        "The land remembers {past_lineage}. Will this bloodline fare better?",
        "Old bones beneath the earth. The {past_lineage} were here before you.",
        "There is an echo in the blood. {past_lineage} once ruled here.",
        "The {past_lineage} left their mark. {past_gens} generations of weight still press on this soil.",
    },

    faction_memories = {
        "Your arrival stirs old memories of the {past_lineage} among the {past_faction}.",
        "The {past_faction} eye your house warily. The last dynasty did not end well.",
        "The {past_faction} recall the {past_lineage}. They were {past_reputation}.",
        "There is recognition in the {past_faction}'s gaze. They have seen bloodlines rise and fall before.",
    },

    ghost_events = {
        -- These are event templates, not direct text
        {
            title = "Echoes of the Fallen",
            narrative = "The locals speak of a family that once reached generation {past_gens}. The {past_lineage}, they were called. {past_reputation} to the bone.",
            options = {
                {
                    label = "Learn from their mistakes",
                    consequences = { { type = "cultural_shift", category = "mental", amount = 3 } },
                },
                {
                    label = "Their fate is not ours",
                    consequences = { { type = "cultural_shift", category = "physical", amount = 2 } },
                },
            },
        },
        {
            title = "A Predecessor's Grave",
            narrative = "Your heir discovers a weathered marker. Here lies the line of {past_lineage}, extinct after {past_gens} generations of {past_reputation} ambition.",
            options = {
                {
                    label = "Pay respects",
                    consequences = { { type = "disposition_all", amount = 3 } },
                },
                {
                    label = "Ignore it",
                    consequences = {},
                },
            },
        },
        {
            title = "The Old Dynasty's Relic",
            narrative = "A merchant offers a trinket said to belong to the {past_lineage}. 'Powerful blood,' he says. 'But not powerful enough.'",
            options = {
                {
                    label = "Purchase the relic",
                    consequences = { { type = "mutation_trigger", trigger = "mystical", intensity = 0.3 } },
                },
                {
                    label = "Leave it",
                    consequences = {},
                },
            },
        },
    },
}

return cross_run_templates
