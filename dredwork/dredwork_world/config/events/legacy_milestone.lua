-- Dark Legacy — Legacy Events: Milestone
-- Events that fire at exact generation numbers. Once per run, 100% chance.
return {
    {
        id = "first_generation",
        title = "The Founding",
        narrative = "The first generation. Everything begins here. Every choice from this point forward will echo through eternity.",
        requires = "strong_reputation",
        requires_generation_exact = 1,
        once_per_run = true,
        chance = 1.0,
        options = {
            {
                label = "Build on strength",
                description = "The bloodline begins with iron and muscle.",
                consequences = {
                    cultural_memory_shift = { physical = 5 },
                    narrative = "The founding was marked by strength. The bloodline began with clenched fists.",
                },
            },
            {
                label = "Build on wisdom",
                description = "Knowledge is the truest foundation.",
                consequences = {
                    cultural_memory_shift = { mental = 5 },
                    narrative = "The founding was marked by wisdom. The bloodline began with open books.",
                },
            },
            {
                label = "Build on words",
                description = "Alliances and diplomacy will carry us further than swords.",
                consequences = {
                    cultural_memory_shift = { social = 5 },
                    narrative = "The founding was marked by diplomacy. The bloodline began with extended hands.",
                },
            },
            {
                label = "Build on vision",
                description = "Create something no one has seen before.",
                consequences = {
                    cultural_memory_shift = { creative = 5 },
                    narrative = "The founding was marked by vision. The bloodline began with dreams made real.",
                },
            },
        },
    },
    {
        id = "tenth_generation",
        title = "A Decade of Blood",
        narrative = "Ten generations. The bloodline has survived longer than most. The weight of a decade of choices presses down.",
        requires = "strong_reputation",
        requires_generation_exact = 10,
        once_per_run = true,
        chance = 1.0,
        options = {
            {
                label = "Celebrate the milestone",
                description = "Honor what we've built. Let the world know we endure.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Ten generations celebrated. The bloodline endured. The world took notice.",
                },
            },
            {
                label = "Reflect on the past",
                description = "Look back. Learn from what came before.",
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 1 },
                    narrative = "The past was examined. Lessons were drawn. The bloodline grew wiser from its own history.",
                },
            },
            {
                label = "Look forward",
                description = "The past is done. What comes next?",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    cultural_memory_shift = { physical = 2, creative = 2 },
                    narrative = "Eyes forward. The bloodline refused to rest on its laurels. The next decade would be different.",
                },
            },
        },
    },
    {
        id = "quarter_century",
        title = "Twenty-Five Generations",
        narrative = "A quarter century of bloodline. The family is ancient now. The weight of history is immense.",
        requires = "strong_reputation",
        requires_generation_exact = 25,
        once_per_run = true,
        chance = 1.0,
        options = {
            {
                label = "Grand celebration",
                description = "A festival to dwarf all others.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 4, creative = 2 },
                    narrative = "The celebration lasted a season. Every house attended. The bloodline's endurance was legend.",
                },
            },
            {
                label = "Codify the family laws",
                description = "Write down everything. Enshrine the rules.",
                consequences = {
                    cultural_memory_shift = { mental = 4, social = 2 },
                    narrative = "The family laws were formally codified. What was tradition became doctrine.",
                },
            },
            {
                label = "Declare dominance",
                description = "We have endured longer than any rival. Acknowledge our supremacy.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "Dominance was declared. Not all agreed. But none could deny the bloodline's longevity.",
                },
            },
        },
    },
    {
        id = "half_century",
        title = "Fifty Generations",
        narrative = "Half a century of blood. The family is a force of nature now. An institution. Almost elemental.",
        requires = "strong_reputation",
        requires_generation_exact = 50,
        once_per_run = true,
        chance = 1.0,
        options = {
            {
                label = "The great reckoning",
                description = "Examine every taboo. Weaken them all. Start fresh.",
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 3 },
                    narrative = "Every taboo was examined. Some were released. The weight lightened. The bloodline breathed.",
                },
            },
            {
                label = "Build a grand monument",
                description = "Something that will outlast even this bloodline.",
                consequences = {
                    cultural_memory_shift = { creative = 5, social = 2 },
                    narrative = "A monument was built. Not to any one heir, but to the bloodline itself. It would stand forever.",
                },
            },
            {
                label = "Blood covenant",
                description = "Bind the family with an unbreakable oath.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    cultural_memory_shift = { social = 5 },
                    narrative = "A blood covenant was sworn. The family bound itself to itself. Unbreakable. Eternal.",
                },
            },
        },
    },
    {
        id = "the_centennial",
        title = "One Hundred Generations",
        narrative = "One hundred generations. The bloodline has become something more than a family. It is an idea. A force. A question that has been asking itself for a hundred lifetimes.",
        requires = "strong_reputation",
        requires_generation_exact = 100,
        once_per_run = true,
        chance = 1.0,
        options = {
            {
                label = "Transcendence",
                description = "We have become something beyond mortal.",
                consequences = {
                    mutation_triggers = { { type = "mystical_proximity", intensity = 1.0 } },
                    cultural_memory_shift = { mental = 10, creative = 10, physical = -5 },
                    narrative = "The centennial was marked by transformation. The bloodline transcended its mortal origins.",
                },
            },
            {
                label = "The final question",
                description = "What was the point of all of this?",
                consequences = {
                    cultural_memory_shift = { mental = 5, creative = 5 },
                    narrative = "The question was asked. No answer came. Perhaps that was the answer.",
                },
            },
            {
                label = "One more generation",
                description = "Keep going. Just one more.",
                consequences = {
                    cultural_memory_shift = { physical = 5, social = 5 },
                    narrative = "The bloodline chose to continue. Not out of purpose, but out of habit. And that was enough.",
                },
            },
        },
    },
}
