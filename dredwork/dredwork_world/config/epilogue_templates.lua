-- Dark Legacy — Epilogue Templates
-- Template pools for post-extinction world narratives.

local epilogue_templates = {

    -- Openings by tone
    openings = {
        tragic = {
            "The {lineage_name} fell, and the world barely noticed.",
            "In the end, the bloodline simply... stopped.",
            "The last whisper of {lineage_name} faded before anyone could mourn.",
            "So brief was the {lineage_name} dynasty that history nearly forgot them entirely.",
        },
        epic = {
            "When the {lineage_name} line ended after {generation} generations, the world held its breath.",
            "The fall of {lineage_name} sent ripples across every faction and era.",
            "For {generation} generations, {lineage_name} shaped the world. Now the world must find its own way.",
            "The {lineage_name} legacy towered over {era_name}, and its absence left a void.",
        },
        ironic = {
            "In a twist the ancestors themselves might have savored, the {lineage_name} line ended as it began — struggling.",
            "The blood that conquered so much could not conquer its own nature.",
            "Perhaps the {lineage_name} bloodline was always destined to burn itself out.",
            "The very traits that made {lineage_name} great were the ones that doomed them.",
        },
        forgotten = {
            "The {lineage_name} came and went. Few took notice.",
            "In the great chronicle of the world, the {lineage_name} are a footnote.",
            "The world turned, indifferent to the end of {lineage_name}.",
            "No songs were written. No monuments erected. {lineage_name} simply ceased.",
        },
    },

    -- Faction echoes by disposition
    faction_echoes = {
        ally = {
            "{faction_name} mourned the loss of their old allies, though the grief was tempered by time.",
            "The halls of {faction_name} grew quieter without the {lineage_name} at their side.",
            "{faction_name} honored the pact one last time, placing a stone where the bloodline ended.",
        },
        enemy = {
            "{faction_name} raised a glass when the news arrived. The old enemy was gone at last.",
            "For {faction_name}, the extinction of {lineage_name} was validation of everything they believed.",
            "The shadow of {lineage_name} no longer fell across {faction_name}'s ambitions.",
        },
        neutral = {
            "{faction_name} observed the fall of {lineage_name} with the detachment of distant neighbors.",
            "To {faction_name}, the end of {lineage_name} was a curiosity, nothing more.",
            "{faction_name} continued as they always had, barely noting the extinction.",
        },
    },

    -- Cultural residue: what outlasted the bloodline
    cultural_residue = {
        taboos = {
            "The taboos the {lineage_name} created outlived them. Other families still avoid what the {lineage_name} forbade.",
            "Long after the blood dried, the old rules persisted. No one remembered why, but no one dared break them.",
            "Some superstitions born of {lineage_name}'s trauma became the unwritten laws of the land.",
        },
        milestones = {
            "The achievements of {lineage_name} became the standard by which future dynasties measured themselves.",
            "Stories of {lineage_name}'s accomplishments persisted, growing taller with each retelling.",
            "What {lineage_name} built endured, even if the builders did not.",
        },
        legends = {
            "The legends of {lineage_name}'s greatest heirs became myths, told by firelight.",
            "In the centuries that followed, children were named after {lineage_name}'s legendary scions.",
            "The deeds of {lineage_name}'s finest became the tales that inspired a new age.",
        },
    },

    -- Closers by cause of death category
    closers = {
        plague = {
            "The plague took what war and time could not.",
            "In the end, no amount of resilience could outlast the sickness.",
            "Disease cares nothing for legacy.",
        },
        war = {
            "Steel and fire wrote the final chapter.",
            "They died as they lived — in conflict.",
            "The battlefield claimed what the bloodline could not protect.",
        },
        famine = {
            "Hunger is patient. It waited for the bloodline to weaken, and then it struck.",
            "When the harvests failed, so did the blood.",
            "Starvation does not care how strong the ancestors were.",
        },
        natural_frailty = {
            "The body simply failed. No drama. No glory. Just silence.",
            "In the quiet of a cold morning, the bloodline ended.",
            "Nature has no malice. It simply moves on.",
        },
        heir_death = {
            "With the heir went everything. The bloodline had no second chance.",
            "One death. That was all it took to undo generations of survival.",
            "The chain broke at its weakest link, and the dynasty crumbled.",
        },
        no_children = {
            "The womb was empty. The bloodline had nothing left to give.",
            "No children. No legacy. Just the weight of what came before.",
            "The cruelest extinction: not defeat, but absence.",
        },
        madness = {
            "The mind broke before the body. Legacy dissolved into chaos.",
            "Madness is the reward of those who feel too deeply.",
            "In the end, the heir could not bear the weight of the blood.",
        },
    },
}

return epilogue_templates
