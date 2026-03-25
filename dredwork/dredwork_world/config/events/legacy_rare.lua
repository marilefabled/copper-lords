-- Dark Legacy — Legacy Events: Rare
-- Once-per-run, low-probability story events with major consequences.
return {
    {
        id = "twins_born",
        title = "Twins of the Blood",
        narrative = "A rare event: twins are born to the bloodline. One strong, one frail. Both carry the name.",
        requires = "strong_reputation",
        once_per_run = true,
        chance = 0.05,
        options = {
            {
                label = "Favor the strong twin",
                description = "Strength ensures survival.",
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    narrative = "The strong twin was chosen. The weak twin was... set aside. The bloodline hardened.",
                },
            },
            {
                label = "Favor the weak twin",
                description = "The underdog may surprise us all.",
                consequences = {
                    cultural_memory_shift = { mental = 2, creative = 2 },
                    narrative = "The weak twin was chosen. Against all expectation. The bloodline took a different path.",
                },
            },
            {
                label = "Raise them together",
                description = "Both carry the blood. Both deserve a chance.",
                requires = { axis = "PER_LOY", min = 40 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    narrative = "Both twins were raised as equals. The family grew richer for the complexity.",
                },
            },
        },
    },
    {
        id = "the_stranger",
        title = "A Stranger Knows",
        narrative = "A figure appears at the gates. They know the family's hidden history — things that were never written down.",
        requires = "strong_reputation",
        once_per_run = true,
        requires_generation_min = 15,
        chance = 0.08,
        options = {
            {
                label = "Listen to them",
                description = "What do they know? How do they know it?",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 4, creative = 2 },
                    narrative = "The stranger spoke. What they knew was impossible. And yet, every word rang true.",
                },
            },
            {
                label = "Turn them away",
                description = "Some knowledge is dangerous. Keep them out.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The stranger was turned away. They left without protest. The family will never know what they missed.",
                },
            },
            {
                label = "Imprison them",
                description = "They know too much. They cannot leave.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 1, social = -3 },
                    narrative = "The stranger was imprisoned. What they knew died with them in a cell. Or did it?",
                },
            },
        },
    },
    {
        id = "the_dream",
        title = "The Ancestor Speaks",
        narrative = "In the deep hours of night, the heir dreams of a long-dead ancestor. The ancestor speaks. The message is clear.",
        requires = "strong_reputation",
        once_per_run = true,
        requires_generation_min = 20,
        chance = 0.08,
        options = {
            {
                label = "Follow the ancestor's guidance",
                description = "The dead know things the living cannot.",
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 2 },
                    narrative = "The dream was followed. The ancestor's wisdom proved true. The bloodline strengthened.",
                },
            },
            {
                label = "Reject the vision",
                description = "Dreams are not prophecy. We make our own way.",
                consequences = {
                    cultural_memory_shift = { creative = 2, mental = 1 },
                    narrative = "The dream was dismissed. The heir chose their own path. The ancestors fell silent.",
                },
            },
            {
                label = "Write it down",
                description = "Record the vision. Let future generations decide its meaning.",
                consequences = {
                    cultural_memory_shift = { mental = 2, creative = 2 },
                    narrative = "The dream was transcribed. A strange addition to the family archive. Its meaning would be debated for generations.",
                },
            },
        },
    },
    {
        id = "the_offer",
        title = "A Deal in the Dark",
        narrative = "Something inhuman offers the bloodline power beyond measure. The price is unnamed. The smile is wrong.",
        requires = "strong_reputation",
        once_per_run = true,
        requires_generation_min = 10,
        chance = 0.10,
        options = {
            {
                label = "Accept the offer",
                description = "Power is power. The source doesn't matter.",
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
                    cultural_memory_shift = { physical = 5, mental = 5, social = -5, creative = 5 },
                    taboo_chance = 0.80,
                    taboo_data = { trigger = "dark_deal", effect = "dark_pact", strength = 95 },
                    narrative = "The deal was struck. Power flooded the bloodline. The price would come later. It always does.",
                },
            },
            {
                label = "Refuse",
                description = "No. Whatever this is, we want no part of it.",
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    narrative = "The offer was refused. The thing with the wrong smile departed. The bloodline slept uneasily for a generation.",
                },
            },
            {
                label = "Bargain",
                description = "We don't accept or refuse. We negotiate.",
                requires = { axis = "PER_CUR", min = 50 },
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } },
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "A counter-offer was made. The thing paused. Then smiled wider. 'Interesting,' it said.",
                },
            },
        },
    },
    {
        id = "the_reckoning",
        title = "The Reckoning",
        narrative = "Everything the bloodline has built stands before it like a mirror. Every choice. Every sacrifice. Every sin. The question is simple: was it worth it?",
        requires = "strong_reputation",
        requires_generation_min = 30,
        chance = 0.10,
        options = {
            {
                label = "We are what we must be",
                description = "Accept everything. No regrets.",
                consequences = {
                    cultural_memory_shift = { physical = 2, social = 2 },
                    narrative = "The bloodline accepted itself. All of it. The darkness and the light. The weight settled. It felt lighter.",
                },
            },
            {
                label = "We can be more",
                description = "The past does not define the future.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 3 },
                    narrative = "A declaration of evolution. The past was acknowledged but not enshrined. The future was open.",
                },
            },
            {
                label = "We are nothing",
                description = "None of it mattered. Let go of everything.",
                requires = { axis = "PER_PRI", max = 35 },
                consequences = {
                    cultural_memory_shift = { physical = -3, social = -3, mental = 3, creative = 3 },
                    narrative = "Everything was released. Identity. Pride. History. What remained was raw potential. And silence.",
                },
            },
        },
    },
    {
        id = "bloodline_echo",
        title = "The Weight Speaks",
        narrative = "The heir wakes in the night, speaking in a voice not their own. The words are instructions — precise, urgent, impossible. They describe a place the heir has never been.",
        once_per_run = true,
        chance = 0.04,
        requires_generation_min = 15,
        options = {
            {
                label = "Follow the instructions",
                description = "The blood remembers what the mind forgets.",
                stat_check = { primary = "MEN_ITU", secondary = "MEN_WIL", difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 4, creative = 3 },
                    mutation_triggers = { { type = "ancestral_echo", intensity = 0.7 } },
                    narrative = "The heir followed. The place existed. What was found there had been waiting for precisely this bloodline, for precisely this generation.",
                },
            },
            {
                label = "Record and study the words",
                description = "Transcribe everything. Context will come later.",
                stat_check = { primary = "MEN_MEM", secondary = "CRE_NAR", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "The words were transcribed by candlelight. Scholars would argue their meaning for generations. The heir never spoke in that voice again.",
                },
            },
            {
                label = "Ignore it",
                description = "Dreams are dreams. The living have work to do.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The voice was dismissed. The dreams stopped. Whatever message the ancestors had sent died in the silence between sleeping and waking.",
                },
            },
        },
    },
    {
        id = "bloodline_convergence",
        title = "The Trait Convergence",
        narrative = "Scholars of the blood notice something extraordinary: every dominant trait in this generation's heir mirrors the founding ancestor. The odds are impossible. The weight of history has bent probability itself.",
        once_per_run = true,
        chance = 0.03,
        requires_generation_min = 25,
        options = {
            {
                label = "Celebrate the convergence",
                description = "This is destiny. The bloodline has come full circle.",
                consequences = {
                    cultural_memory_shift = { mental = 2, social = 3, creative = 2 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    narrative = "The convergence was proclaimed. Allies marveled. Enemies trembled. The bloodline, it seemed, was favored by forces beyond comprehension.",
                },
            },
            {
                label = "Study the pattern",
                description = "Coincidence or causation? The answer matters.",
                stat_check = { primary = "MEN_PAT", secondary = "MEN_ANA", difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 5 },
                    narrative = "The scholars found patterns within patterns — spirals in the trait data that suggested the bloodline was not random, but resonant. The implications were staggering.",
                },
            },
            {
                label = "Dismiss it as coincidence",
                description = "Numbers are numbers. Superstition is beneath us.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The scholars were sent away. The coincidence was noted, filed, and forgotten. Perhaps that was wise. Perhaps it was not.",
                },
            },
        },
    },
}
