-- Dark Legacy — World Events: Mystical
return {
    {
        id = "mystical_surge",
        title = "The Veil Thins",
        narrative = "Strange lights dance at the edges of perception. The air hums with unseen power. Something ancient stirs — and it knows the bloodline craves {dream_trait}.",
        chance = 0.25,
        cooldown = 3,
        requires_generation_min = 3,
        options = {
            {
                label = "Investigate the source",
                description = "Send scholars and scouts to study the phenomenon.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.7 } },
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "The family delved into the unknown. What they found changed them.",
                },
            },
            {
                label = "Ward the estates",
                description = "Seal the doors. Burn the incense. Keep the strangeness out.",
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.2 } },
                    narrative = "Wards were raised. The strangeness passed. Mostly.",
                },
            },
            {
                label = "Embrace the power",
                description = "Open yourself to whatever comes.",
                requires = { axis = "PER_OBS", min = 60 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
                    cultural_memory_shift = { creative = 5, physical = -3 },
                    taboo_chance = 0.2,
                    taboo_data = { trigger = "embraced_unknown", effect = "drawn_to_mystical", strength = 70 },
                    narrative = "The power was embraced. The bloodline was forever altered.",
                },
            },
        },
    },
    {
        id = "mystical_artifact",
        title = "The Glowing Stone",
        narrative = "Workers unearthed something that should not exist. It pulses with light and warmth. It whispers.",
        chance = 0.20,
        cooldown = 3,
        options = {
            {
                label = "Destroy it",
                description = "Some things are better left undiscovered.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The artifact was shattered. The whispers stopped. The light died. But the memory of what it said lingered.",
                },
            },
            {
                label = "Study it carefully",
                description = "Knowledge is never dangerous in the right hands.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } },
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "The artifact was studied. Its secrets yielded slowly, each one stranger than the last.",
                },
            },
            {
                label = "Gift it to a rival house",
                description = "Let them deal with its whispers.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The artifact was given away. A generous gift — or a clever trap. Time would tell.",
                },
            },
        },
    },
    {
        id = "mystical_prophecy",
        title = "The Seer Speaks",
        narrative = "A wandering seer arrives at the gates. Their eyes are white. Their voice is not their own. They invoke the {doctrine_name} doctrine and speak of what is to come.",
        chance = 0.25,
        cooldown = 3,
        requires_era = "arcane",
        options = {
            {
                label = "Heed the prophecy",
                description = "Prepare for what was foretold.",
                requires = { axis = "PER_ADA", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 2, creative = 2 },
                    narrative = "The prophecy was heeded. Whether it was wisdom or folly, only the future could say.",
                },
            },
            {
                label = "Execute the seer",
                description = "False prophets are dangerous. Silence them.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 1, social = -3 },
                    taboo_chance = 0.15,
                    taboo_data = { trigger = "killed_seer", effect = "silenced_prophecy", strength = 65 },
                    narrative = "The seer was silenced. The words, however, had already been heard. They could not be unheard.",
                },
            },
            {
                label = "Ignore and send away",
                description = "We make our own future.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The seer was turned away. The future arrived anyway, indifferent to whether anyone had been warned.",
                },
            },
        },
    },
    {
        id = "mystical_calling",
        title = "The Mystic Calling",
        narrative = "A child of the bloodline wakes screaming in a language no one speaks. Their hands glow. The servants flee.",
        chance = 0.30,
        cooldown = 3,
        requires_era = "arcane",
        options = {
            {
                label = "Train the gift",
                description = "Find tutors. Channel whatever this is before it consumes them.",
                requires = { axis = "PER_CUR", min = 45 },
                stat_check = { primary = "MEN_FOC", secondary = "CRE_IMP", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 4, mental = 2 },
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.6 } },
                    narrative = "The gift was shaped, not suppressed. What the child became was neither scholar nor sorcerer, but something the bloodline had no word for.",
                },
            },
            {
                label = "Suppress the gift",
                description = "Bind their hands. Douse the glow. This family has enough burdens.",
                consequences = {
                    cultural_memory_shift = { mental = 1, social = 2 },
                    taboo_chance = 0.15,
                    taboo_data = { trigger = "suppressed_gift", effect = "fear_of_the_arcane", strength = 60 },
                    narrative = "The glow faded. The child grew quiet. But in every generation after, someone in the bloodline dreamed of light pouring from their palms.",
                },
            },
            {
                label = "Exile the child",
                description = "Send them away. Whatever they are, they are not ours.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -3 },
                    narrative = "The child was sent into the wilds. Whether they perished or flourished, the bloodline never learned. Some doors, once closed, stay closed.",
                },
            },
        },
    },
    {
        id = "mystical_convergence",
        title = "The Convergence",
        narrative = "Every ley line, every current of unseen force, pulls toward a single point beneath the estate. The ground hums. The animals won't come near.",
        chance = 0.20,
        once_per_run = true,
        options = {
            {
                label = "Dig",
                description = "Whatever waits below, it's waited long enough.",
                requires = { axis = "PER_BLD", min = 50 },
                stat_check = { primary = "MEN_COM", secondary = "PHY_STR", difficulty = 60 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.9 } },
                    cultural_memory_shift = { creative = 5, mental = 3, physical = -2 },
                    narrative = "They dug. What they found was not treasure, nor weapon, nor curse. It was a question — and the bloodline would spend generations trying to answer it.",
                },
            },
            {
                label = "Seal the site",
                description = "Build a cairn. Post guards. Let no one touch it.",
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The site was sealed. The humming stopped. Eventually. The guards insisted they heard singing from below, but guards always say that.",
                },
            },
            {
                label = "Build a shrine",
                description = "If it calls, let us answer with reverence.",
                requires = { axis = "PER_OBS", min = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = 2 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "A shrine was raised. Pilgrims came. The bloodline became stewards of something they did not understand — and were respected for it.",
                },
            },
        },
    },
    {
        id = "mystical_haunting",
        title = "The Dead Heir's Voice",
        narrative = "A voice speaks from the walls at night. It knows names. It knows debts. It claims to be an ancestor — and it is angry.",
        chance = 0.25,
        cooldown = 3,
        requires_generation_min = 8,
        options = {
            {
                label = "Listen to its grievances",
                description = "The dead have long memories. Perhaps it speaks truth.",
                requires = { axis = "PER_ADA", min = 40 },
                stat_check = { primary = "MEN_WIL", secondary = "SOC_EMP", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 1 },
                    narrative = "The voice spoke of broken promises and forgotten oaths. When the living honored those debts, the voice fell silent — satisfied, if not at peace.",
                },
            },
            {
                label = "Perform an exorcism",
                description = "The dead should stay dead.",
                stat_check = { primary = "MEN_FOC", secondary = "CRE_RIT", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 2, mental = 1 },
                    narrative = "Ritual smoke and ancient words drove the voice away. Whether it was truly an ancestor or something wearing an ancestor's face, no one could say.",
                },
            },
            {
                label = "Ignore it",
                description = "Walls don't talk. This is nothing.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The voice was ignored. It grew louder for a time, then quieter, then silent. The servants never fully trusted the east wing again.",
                },
            },
        },
    },
}
