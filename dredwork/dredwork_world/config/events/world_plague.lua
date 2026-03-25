-- Dark Legacy — World Events: Plague
return {
    {
        id = "plague_outbreak",
        title = "Plague Sweeps the Land",
        narrative = "A terrible sickness spreads across the realm. Bodies pile in the streets. {heir_name} must decide how the bloodline responds.",
        chance = 0.35,
        cooldown = 3,
        requires_no_condition = "plague",
        options = {
            {
                label = "Seal the borders",
                description = "Isolate the family estates. Reduced exposure, but no friends gained.",
                consequences = {
                    add_condition = { type = "plague", intensity = 0.3, duration = 2 },
                    narrative = "The gates were sealed. Some called it wisdom. Others called it cowardice.",
                },
            },
            {
                label = "Send healers to the afflicted",
                description = "Risk exposure but earn the gratitude of all.",
                requires = { axis = "PER_CRM", max = 60 },
                consequences = {
                    add_condition = { type = "plague", intensity = 0.6, duration = 3 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Healers were sent. Many died. The world remembered the kindness.",
                },
            },
            {
                label = "Strike while they are weak",
                description = "While enemies are crippled by plague, seize what you can.",
                requires = { axis = "PER_CRM", min = 65 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.5, duration = 2 },
                    disposition_changes = { { faction_id = "all", delta = -15 } },
                    cultural_memory_shift = { physical = 3, social = -5 },
                    taboo_chance = 0.3,
                    taboo_data = { trigger = "exploited_plague", effect = "distrust_in_crisis", strength = 85 },
                    narrative = "While the sick choked, your soldiers marched. The world will not forget.",
                },
            },
            {
                label = "Apply the Plague Lore",
                description = "Ancient knowledge of disease, passed down through the bloodline, reveals a cure.",
                requires_discovery = "plague_lore",
                consequences = {
                    narrative = "The bloodline's knowledge of plague proved its worth. What killed others merely inconvenienced your house.",
                    cultural_memory_shift = { mental = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                },
            },
        },
    },
    {
        id = "plague_mutation",
        title = "The Sickness Evolves",
        narrative = "The plague has changed. What worked before no longer protects. The dead pile higher than before.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "plague",
        options = {
            {
                label = "Tighten the quarantine",
                description = "Seal everything. No one in, no one out.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    narrative = "The doors were sealed again, tighter this time. Inside, the air grew stale with fear.",
                },
            },
            {
                label = "Study the mutation",
                description = "Send scholars to understand the change.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    mutation_triggers = { { type = "plague", intensity = 0.3 } },
                    narrative = "The scholars studied the sickness as it evolved. What they learned would be written in blood and ink.",
                },
            },
            {
                label = "Accept the culling",
                description = "The weak will die. The strong will remain.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 4, social = -4 },
                    mutation_triggers = { { type = "plague", intensity = 0.5 } },
                    narrative = "The bloodline endured by letting the weak fall. The survivors were harder. Colder.",
                },
            },
            {
                label = "Deploy field medicine",
                description = "Your knowledge of healing turns the tide. The plague bows to science.",
                requires_discovery = "field_medicine",
                consequences = {
                    remove_condition = "plague",
                    cultural_memory_shift = { mental = 3, social = 2 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    narrative = "Where others saw only death, the bloodline saw a puzzle — and solved it. The plague receded.",
                },
            },
        },
    },
    {
        id = "plague_cure",
        title = "A Cure Whispered",
        narrative = "Rumors of a cure drift from the far reaches. It could end the suffering — if it can be found.",
        chance = 0.30,
        cooldown = 2,
        requires_condition = "plague",
        options = {
            {
                label = "Send an expedition",
                description = "Risk lives to find the cure.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    remove_condition = "plague",
                    cultural_memory_shift = { physical = 2, social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "The expedition returned with the cure. The plague broke. Songs were sung.",
                },
            },
            {
                label = "Ignore the rumors",
                description = "Rumors are dangerous. We endure.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The rumors were dismissed. The plague would end on its own terms, not on the word of strangers.",
                },
            },
            {
                label = "Sell the rumor to rivals",
                description = "Let them waste their resources chasing ghosts.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    cultural_memory_shift = { mental = 2, social = -3 },
                    narrative = "The rumor was sold as truth. Rival houses spent themselves chasing shadows.",
                },
            },
        },
    },
}
