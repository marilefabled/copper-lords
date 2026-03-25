-- Dark Legacy — World Events: Discovery
return {
    {
        id = "new_lands_found",
        title = "Beyond the Known Map",
        narrative = "Scouts report uncharted territory beyond the borders. Uncatalogued. Unoccupied. Unpriced.",
        chance = 0.2,
        options = {
            {
                label = "Colonize immediately",
                description = "Plant our banner. Claim what is unclaimed.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    cultural_memory_shift = { physical = 3, creative = 1 },
                    mutation_triggers = { { type = "intermarriage", intensity = 0.3 } },
                    narrative = "Settlers were sent. A new territory bore the bloodline's name.",
                },
            },
            {
                label = "Send scholars first",
                description = "Understand before you conquer.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "Scholars mapped every valley, cataloged every plant. Knowledge before conquest.",
                },
            },
            {
                label = "Ignore the reports",
                description = "We have enough territory. Enough problems.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The new lands were left alone. Others would find them eventually.",
                },
            },
        },
    },
    {
        id = "ancient_ruin",
        title = "The Ruin Beneath",
        narrative = "Deep excavation reveals structures older than any known civilization. Symbols that no living person can read.",
        chance = 0.2,
        options = {
            {
                label = "Excavate fully",
                description = "Dig deeper. Learn what was hidden.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.4 } },
                    cultural_memory_shift = { mental = 3, creative = 3 },
                    narrative = "The ruins yielded their secrets slowly. Each chamber was stranger than the last.",
                },
            },
            {
                label = "Strip the resources",
                description = "Whatever is down there, it's worth something on the surface.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "The ruins were looted for materials. Efficient, if not respectful. The scholars wept.",
                },
            },
            {
                label = "Seal it permanently",
                description = "Some doors should stay closed.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    taboo_chance = 0.10,
                    taboo_data = { trigger = "sealed_ruins", effect = "buried_knowledge", strength = 50 },
                    narrative = "The entrance was sealed with stone and prayer. What lay beneath would remain there.",
                },
            },
        },
    },
    {
        id = "first_contact",
        title = "Strangers from Beyond",
        narrative = "An unknown people appear at the borders. They speak a language no one recognizes. They carry tools of unfamiliar craft.",
        chance = 0.3,
        once_per_run = true,
        requires_generation_min = 10,
        options = {
            {
                label = "Welcome them",
                description = "New blood. New ideas. New possibilities.",
                consequences = {
                    mutation_triggers = { { type = "intermarriage", intensity = 0.7 } },
                    cultural_memory_shift = { social = 3, creative = 3 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "The strangers were welcomed. Their blood mixed with the bloodline. The genetic ledger noted the new entries without comment.",
                },
            },
            {
                label = "Drive them away",
                description = "Unknown means dangerous.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -2 },
                    narrative = "The strangers were turned away by force. They left. But their campfires still glowed on the horizon.",
                },
            },
            {
                label = "Study them from a distance",
                description = "Learn what they know without risking contamination.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 4, creative = 2 },
                    narrative = "Observers were sent. What they reported back changed the bloodline's understanding of the world.",
                },
            },
        },
    },
    {
        id = "discovery_curse",
        title = "The Discovery's Price",
        narrative = "The breakthrough was magnificent. But something changed. Workers near the site fall ill. Livestock behave strangely. The discovery is not free.",
        chance = 0.25,
        requires_generation_min = 5,
        options = {
            {
                label = "Contain and study the effects",
                description = "Understand the cost before paying it.",
                stat_check = { primary = "MEN_FOC", secondary = "MEN_ANA", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 1 },
                    narrative = "The side effects were catalogued. Some were managed. Some were accepted. Knowledge, it turned out, was not free — but it was worth the price.",
                },
            },
            {
                label = "Destroy the discovery",
                description = "Some doors should not be opened. Close this one.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    taboo_chance = 0.20,
                    taboo_data = { trigger = "destroyed_discovery", effect = "fear_of_progress", strength = 60 },
                    narrative = "The research was burned. The site was sealed. A taboo was filed where a discovery should have been.",
                },
            },
            {
                label = "Press forward regardless",
                description = "Every advance has a price. Pay it.",
                requires = { axis = "PER_OBS", min = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 4, physical = -3 },
                    mutation_triggers = { { type = "discovery_fallout", intensity = 0.5 } },
                    narrative = "The work continued. The price was paid in strange ailments and stranger dreams. But the discovery changed everything.",
                },
            },
        },
    },
    {
        id = "discovery_theft",
        title = "The Stolen Secret",
        narrative = "Word has spread. A rival house has learned of the bloodline's most recent breakthrough — and they want it. Badly.",
        chance = 0.30,
        options = {
            {
                label = "Trade it for alliance",
                description = "Knowledge shared is leverage gained.",
                stat_check = { primary = "SOC_NEG", secondary = "MEN_CUN", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    narrative = "The secret was shared — on terms. The rival house received knowledge. The bloodline received loyalty. Both sides calculated they had won.",
                },
            },
            {
                label = "Guard it fiercely",
                description = "This is ours. Let them innovate on their own.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "Walls were raised. Lips were sealed. The secret stayed safe. The neighbors grew resentful.",
                },
            },
            {
                label = "Spread it freely",
                description = "Let everyone benefit. Progress should not be hoarded.",
                requires = { axis = "PER_CRM", max = 45 },
                consequences = {
                    cultural_memory_shift = { social = 4, creative = 1 },
                    disposition_changes = { { faction_id = "all", delta = 10 } },
                    narrative = "The knowledge was given to all. The bloodline's name became synonymous with generosity. Whether this was wisdom or naivety, the future would decide.",
                },
            },
        },
    },
}
