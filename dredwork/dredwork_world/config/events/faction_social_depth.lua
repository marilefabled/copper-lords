-- Bloodweight — Faction Events: Social Depth
-- Events testing underused social traits: SOC_EMP, SOC_INF, SOC_LYS, SOC_PAK,
-- SOC_TEA, SOC_HUM, SOC_CRD, SOC_TRU. Faction-gated for narrative context.

return {
    {
        id = "the_hostage_exchange",
        title = "The Hostage's Eyes",
        narrative = "{faction_name} holds a hostage from your court. The exchange is arranged, but the hostage arrives changed — broken in ways that are not visible.",
        chance = 0.25,
        cooldown = 8,
        disposition_max = 10,
        options = {
            {
                label = "Tend to them personally",
                description = "Empathy and pack bonding — rebuild what was broken.",
                check = { primary = { trait = "SOC_EMP", weight = 1.0 }, secondary = { trait = "SOC_PAK", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    narrative = "{heir_name} sat with the hostage for days. No questions. No demands. Just presence. Slowly, the eyes came back to life.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "{heir_name} tried. The hostage flinched at every touch. Some damage cannot be reached by kindness alone.",
                },
            },
            {
                label = "Demand reparations from {faction_name}",
                description = "Make them pay for what they did.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = -1 },
                    narrative = "Gold was paid. It did not heal anything. But the principle was established: the bloodline's people are not to be broken.",
                },
            },
        },
    },

    {
        id = "the_wedding_toast",
        title = "A Toast Between Houses",
        narrative = "A marriage unites your house with {faction_name}. The feast is tense. Ancient grudges simmer beneath the wine. Someone must speak.",
        chance = 0.3,
        cooldown = 8,
        disposition_min = -5,
        options = {
            {
                label = "Make them laugh",
                description = "Humor and influence reach — disarm the room with a well-placed joke.",
                check = { primary = { trait = "SOC_HUM", weight = 1.0 }, secondary = { trait = "SOC_INF", weight = 0.5 }, tertiary = { trait = "SOC_CHA", weight = 0.3 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    narrative = "{heir_name} stood. The room tensed. And then — a joke about the family's own failures. Laughter erupted. The ice broke. For one night, the houses forgot they were enemies.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "_target", delta = -3 } },
                    narrative = "The joke landed poorly. Silence. A cough. The feast continued, colder than before.",
                },
            },
            {
                label = "Give a formal address",
                description = "Dignity over warmth.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    narrative = "The address was correct, appropriate, and instantly forgotten. Some moments call for warmth, not protocol.",
                },
            },
        },
    },

    {
        id = "the_defectors_plea",
        title = "They Want to Join Us",
        narrative = "A delegation from {faction_name} arrives in secret. They want to defect. But can they be trusted?",
        chance = 0.25,
        cooldown = 10,
        disposition_max = 5,
        options = {
            {
                label = "Read their sincerity",
                description = "Trustworthiness assessment and loyalty signals — separate the genuine from the planted.",
                check = { primary = { trait = "SOC_TRU", weight = 0.8 }, secondary = { trait = "SOC_LYS", weight = 0.7 }, tertiary = { trait = "MEN_PER", weight = 0.4 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 2, mental = 1 },
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    narrative = "{heir_name} spent three days with the defectors. Watched how they ate, how they slept, how they spoke to servants. The verdict: genuine. They were accepted. Time would prove it right.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    narrative = "The defectors were accepted. Within months, the betrayal was revealed — planted agents. {heir_name}'s judgment had failed.",
                },
            },
            {
                label = "Send them back",
                description = "The risk is too great.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The delegation was escorted to the border. Whether they were genuine or not, {heir_name} would never know. Safety has its own cost.",
                },
            },
        },
    },

    {
        id = "the_young_lord",
        title = "The Faction Heir Visits",
        narrative = "{faction_name} sends their young heir for a season of fostering. A gesture of trust — or a test. The child is difficult, brilliant, and afraid.",
        chance = 0.3,
        cooldown = 10,
        disposition_min = 10,
        options = {
            {
                label = "Mentor them personally",
                description = "Teaching ability and empathy shape the next generation of another house.",
                check = { primary = { trait = "SOC_TEA", weight = 1.0 }, secondary = { trait = "SOC_EMP", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    narrative = "The child flourished. When they returned to {faction_name}, they carried the bloodline's values in their bones. A generation later, the investment would pay dividends no gold could match.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "_target", delta = -3 } },
                    narrative = "The fostering was difficult. The child returned sullen and resentful. {heir_name}'s teaching failed to reach them.",
                },
            },
            {
                label = "Treat them as any other ward",
                description = "No special attention. Let them find their own way.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    disposition_changes = { { faction_id = "_target", delta = 2 } },
                    narrative = "The child was housed, fed, and educated by tutors. A correct but unremarkable fostering. The diplomatic value was nominal.",
                },
            },
        },
    },

    {
        id = "the_reputation_precedes",
        title = "The Name Arrives First",
        narrative = "Before {heir_name} even speaks, {faction_name}'s envoy bows deeper than protocol requires. The bloodline's reputation has traveled ahead.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Leverage the influence",
                description = "Influence reach and social awareness — press the advantage the name provides.",
                check = { primary = { trait = "SOC_INF", weight = 1.0 }, secondary = { trait = "SOC_AWR", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    narrative = "{heir_name} used the reputation like a blade. Terms were set before negotiations began. The envoy returned knowing they had met a legacy, not just a person.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The reputation promised more than the heir could deliver. The envoy left... reassessing.",
                },
            },
            {
                label = "Downplay the name",
                description = "Let actions speak. Names are inherited — respect is earned.",
                requires = { axis = "PER_PRI", max = 40 },
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    narrative = "The humility was unexpected. And therefore powerful. Sometimes the quietest entrance commands the most attention.",
                },
            },
        },
    },
}
