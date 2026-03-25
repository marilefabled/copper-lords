-- Dark Legacy — World Events: Era-Specific
return {
    {
        id = "myth_godfall",
        title = "A God Dies",
        narrative = "The sky cracks. A pillar of light falls beyond the horizon. When it fades, the world feels lighter. Emptier.",
        chance = 0.3,
        requires_era = "ancient",
        once_per_run = true,
        options = {
            {
                label = "Mourn the fallen god",
                description = "Honor what was lost. The old ways demand it.",
                consequences = {
                    cultural_memory_shift = { social = 3, creative = 2 },
                    narrative = "The bloodline mourned. Rituals were performed. The god's name was carved into the family shrine.",
                },
            },
            {
                label = "Harvest the divine remnants",
                description = "A god's corpse holds power beyond measure.",
                requires = { axis = "PER_OBS", min = 55 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.8 } },
                    cultural_memory_shift = { creative = 4, mental = 3 },
                    taboo_chance = 0.25,
                    taboo_data = { trigger = "harvested_god", effect = "god_thieves", strength = 80 },
                    narrative = "What was taken from the divine corpse changed the bloodline forever. Power has a price.",
                },
            },
            {
                label = "Record the event",
                description = "Future generations must know what happened here.",
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 1 },
                    narrative = "Every detail was recorded. The chronicle of the godfall would be studied for a hundred generations.",
                },
            },
        },
    },
    {
        id = "iron_forge_breakthrough",
        title = "The New Alloy",
        narrative = "The forges burn hotter than ever before. A new metal emerges — stronger, lighter, hungry for purpose.",
        chance = 0.3,
        requires_era = "iron",
        once_per_run = true,
        options = {
            {
                label = "Weaponize it",
                description = "Stronger steel means stronger armies.",
                consequences = {
                    cultural_memory_shift = { physical = 4 },
                    mutation_triggers = { { type = "war", intensity = 0.3 } },
                    narrative = "New weapons were forged. The enemy would learn to fear the bloodline's steel.",
                },
            },
            {
                label = "Build tools and infrastructure",
                description = "Plows and bridges outlast swords.",
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    narrative = "The new alloy built bridges, plows, and aqueducts. The land flourished under innovation.",
                },
            },
            {
                label = "Trade the secret",
                description = "Sell the knowledge. Let everyone benefit — for a price.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "The secret of the new alloy was sold. Gold flowed in. Alliances strengthened. But the advantage was lost.",
                },
            },
        },
    },
    {
        id = "dark_last_light",
        title = "The Water Runs Black",
        narrative = "The clean water sources fail, one by one. What remains runs dark and foul. Thirst will kill faster than any army.",
        chance = 0.35,
        requires_era = "dark",
        options = {
            {
                label = "Fight for the remaining wells",
                description = "Water is life. Take it by force.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    cultural_memory_shift = { physical = 3 },
                    narrative = "War over water. The most basic conflict. The most brutal.",
                },
            },
            {
                label = "Purify through innovation",
                description = "The scholars say they can clean the water. It will take time.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 4, creative = 2 },
                    narrative = "Filtration methods were devised. Clean water flowed again. Innovation conquered despair.",
                },
            },
            {
                label = "Ration mercilessly",
                description = "The strong drink. The weak wait.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -4 },
                    narrative = "Water was rationed by worth, not need. The strong survived. The rest were forgotten.",
                },
            },
        },
    },
    {
        id = "arcane_wild_magic",
        title = "The World Unravels",
        narrative = "Magic erupts without warning. Buildings twist. Rivers flow upward. Reality itself seems uncertain.",
        chance = 0.35,
        requires_era = "arcane",
        options = {
            {
                label = "Contain it",
                description = "Build wards. Establish boundaries. Control the chaos.",
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.3 } },
                    narrative = "Wards were raised. The wild magic was tamed — barely. The effort was immense.",
                },
            },
            {
                label = "Channel the power",
                description = "Let the chaos flow through us. Shape it.",
                requires = { axis = "PER_OBS", min = 55 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
                    cultural_memory_shift = { creative = 5, mental = 3, physical = -3 },
                    narrative = "The wild magic was channeled through the bloodline. Power surged. Bodies changed. Nothing was the same.",
                },
            },
            {
                label = "Flee the affected areas",
                description = "Retreat. Survive. Let the magic burn itself out.",
                requires = { axis = "PER_ADA", min = 40 },
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The family retreated to safe ground. The wild magic raged without them. Eventually, it subsided.",
                },
            },
        },
    },
    {
        id = "gilded_decadence",
        title = "The Rot Beneath the Gold",
        narrative = "Prosperity has bred corruption. Officials take bribes openly. Justice is for sale. The foundation crumbles beneath gilded walls.",
        chance = 0.3,
        requires_era = "gilded",
        options = {
            {
                label = "Purge the corrupt",
                description = "Root out the rot. No matter the cost.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -3 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "The purge was thorough and bloody. The corrupt were removed. Trust was another matter.",
                },
            },
            {
                label = "Join the corruption",
                description = "If you can't beat them, profit from them.",
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    taboo_chance = 0.15,
                    taboo_data = { trigger = "joined_corruption", effect = "gilded_rot", strength = 60 },
                    narrative = "The family joined the game. Gold flowed. Honor drained. The ancestors stirred in their graves.",
                },
            },
            {
                label = "Reform the system",
                description = "Change the rules. Build something better.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "New laws were written. New systems established. Reform is slow, but it endures.",
                },
            },
        },
    },
    {
        id = "twilight_the_final_question",
        title = "The Stars Go Out",
        narrative = "One by one, the stars vanish. The sky grows darker each night. Something is ending. Something fundamental.",
        chance = 0.4,
        requires_era = "twilight",
        once_per_run = true,
        options = {
            {
                label = "Prepare for the end",
                description = "Build shelters. Store food. Preserve knowledge.",
                consequences = {
                    cultural_memory_shift = { physical = 3, mental = 3 },
                    narrative = "Preparations were made. Whether the end came or not, the bloodline would face it ready.",
                },
            },
            {
                label = "Rage against the dying light",
                description = "We will not go quietly.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 4, creative = 2 },
                    mutation_triggers = { { type = "era_shift", intensity = 0.5 } },
                    narrative = "The bloodline refused to accept the darkness. They burned brighter than ever, defiant.",
                },
            },
            {
                label = "Seek transcendence",
                description = "If the physical world ends, perhaps we can become something beyond it.",
                requires = { axis = "PER_OBS", min = 55 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
                    cultural_memory_shift = { mental = 5, creative = 5, physical = -5 },
                    narrative = "The bloodline reached for something beyond flesh and bone. What they found, no mortal words could describe.",
                },
            },
        },
    },
    {
        id = "era_transition_omen",
        title = "Signs of Change",
        narrative = "The world shivers. Ancient markers crack. Animals migrate without reason. An era is ending.",
        chance = 0.35,
        options = {
            {
                label = "Prepare for what comes",
                description = "Change is coming. Be ready.",
                consequences = {
                    cultural_memory_shift = { mental = 2, physical = 2 },
                    narrative = "The signs were heeded. When the change came, the bloodline was ready. Or as ready as anyone could be.",
                },
            },
            {
                label = "Resist the change",
                description = "We will hold to what we know.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    narrative = "The family clung to the old ways as the world shifted around them. Stubborn. Resolute. Perhaps foolish.",
                },
            },
            {
                label = "Embrace the unknown",
                description = "New eras bring new opportunities.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    mutation_triggers = { { type = "era_shift", intensity = 0.3 } },
                    narrative = "Arms were opened to the unknown. The bloodline bent like a reed in the wind, and did not break.",
                },
            },
        },
    },
}
