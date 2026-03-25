-- Dark Legacy — Personal Events: Obsession
return {
    {
        id = "obsessive_discovery",
        title = "An Obsession Bears Fruit",
        narrative = "{heir_name} spent months locked away, consumed by a single idea. What emerged was extraordinary.",
        trigger_axis = "PER_OBS",
        trigger_min = 75,
        chance = 0.4,
        consequence = {
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.4 } },
            cultural_memory_shift = { mental = 3, creative = 2 },
            narrative = "{heir_name} emerged from seclusion clutching something that glowed with strange purpose.",
        },
    },
    {
        id = "obsession_fades",
        title = "Half-Finished Works",
        narrative = "Half-finished works littered {heir_name}'s chambers. Nothing held their attention for long.",
        trigger_axis = "PER_OBS",
        trigger_max = 25,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { creative = -3, mental = -2 },
            narrative = "{heir_name} drifted between projects, finishing none. The bloodline's ambitions gathered dust.",
        },
    },
    {
        id = "obsession_madness",
        title = "The Descent",
        narrative = "Stopped sleeping. Stopped eating. {heir_name} could not be reached by any voice.",
        trigger_axis = "PER_OBS",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.8 } },
            cultural_memory_shift = { mental = 5, social = -5, creative = 3 },
            taboo_chance = 0.20,
            taboo_data = { trigger = "obsession_madness", effect = "touched_by_madness", strength = 70 },
            narrative = "Something broke in {heir_name}. What they found in the darkness, they could never fully explain.",
        },
    },
    -- NEW: MID-HIGH — obsession as devotion to craft
    {
        id = "mapped_the_stars",
        title = "The Star Charts",
        narrative = "Every clear night for six months. On the roof. Alone. Charting. Counting. Naming. Sleep was negotiable.",
        trigger_axis = "PER_OBS",
        trigger_min = 60,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { mental = 2, creative = 1 },
            narrative = "The charts were beautiful, meticulous, and possibly useless. But {heir_name} knew every star by name. Sometimes that is enough.",
        },
    },
    -- NEW: MID-LOW — detachment as liberation
    {
        id = "walked_away_clean",
        title = "Dropped It Like Nothing",
        narrative = "The project was worth a fortune. Three years of work. {heir_name} stopped mid-sentence, stood up, and walked out. Never mentioned it again.",
        trigger_axis = "PER_OBS",
        trigger_max = 40,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { creative = -1, mental = -1 },
            narrative = "Unfinished. Abandoned. The advisors were furious. {heir_name} was already thinking about something else. Or nothing at all.",
        },
    },
    -- NEW: ALT-HIGH — obsession expressed as love
    {
        id = "kept_every_letter",
        title = "The Archive of Small Things",
        narrative = "{heir_name} kept everything. Every letter. Every child's drawing. Every fallen leaf pressed between pages. A room full of memory, organized by date.",
        trigger_axis = "PER_OBS",
        trigger_min = 65,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { creative = 2, social = 1 },
            narrative = "Obsession is not always dark. Sometimes it is the refusal to let anything beautiful be forgotten.",
        },
    },
    {
        id = "obsessive_spiral",
        title = "The Unrelenting Mind",
        narrative = "{heir_name} has stopped eating. Stopped sleeping. Every waking moment is consumed by a single pursuit. The court is concerned.",
        trigger_axis = "PER_OBS",
        trigger_min = 70,
        chance = 0.35,
        consequence = {
            cultural_memory_shift = { mental = 3, physical = -3 },
            taboo_chance = 0.15,
            taboo_data = { trigger = "obsessive_collapse", effect = "burned_too_bright", strength = 60 },
            narrative = "The obsession consumed everything — health, relationships, sleep. What remained was either genius or madness. The distinction, as always, depended on whether it worked.",
        },
    },
    {
        id = "obsessive_legacy",
        title = "The Ancestral Fixation",
        narrative = "{heir_name} has become consumed by a long-dead ancestor's unfinished work. Old journals appear. Locked rooms are opened. The past refuses to stay buried.",
        trigger_axis = "PER_OBS",
        trigger_min = 65,
        chance = 0.30,
        requires_generation_min = 10,
        consequence = {
            cultural_memory_shift = { mental = 2, creative = 2 },
            narrative = "The ancestor's work was continued. Whether completing it was tribute or trespass, the bloodline could not agree. But the work was done.",
        },
    },
}
