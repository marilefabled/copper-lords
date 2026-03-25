-- Dark Legacy — Legacy Events: Reputation
return {
    {
        id = "reputation_questioned",
        title = "Your Name Precedes You",
        narrative = "The world knows your bloodline as {reputation_primary}. A young heir asks: is that all we are?",
        requires = "strong_reputation",
        chance = 0.2,
        options = {
            {
                label = "We are what we are. Embrace it.",
                description = "Our reputation is earned. Strengthen it.",
                consequences = {
                    cultural_memory_shift = {},
                    narrative = "The family doubled down on its identity. The {reputation_primary} name grew stronger.",
                },
            },
            {
                label = "Perhaps it is time for change.",
                description = "The bloodline can evolve. It must.",
                requires = { axis = "PER_ADA", min = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 2, mental = 2, physical = -1, social = -1 },
                    narrative = "A seed of doubt was planted. Change is slow in ancient bloodlines, but it begins with a question.",
                },
            },
        },
    },
    {
        id = "reputation_reward",
        title = "The Name Opens Doors",
        narrative = "The bloodline's reputation as {reputation_primary} opens doors that would be closed to lesser names.",
        requires = "strong_reputation",
        chance = 0.2,
        options = {
            {
                label = "Leverage the reputation",
                description = "Use the name to gain advantage.",
                consequences = {
                    cultural_memory_shift = { social = 2, mental = 1 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "The name was traded like currency. Doors opened. Deals were struck. Reputation is wealth.",
                },
            },
            {
                label = "Remain humble",
                description = "The name speaks for itself. No need to flaunt it.",
                requires = { axis = "PER_PRI", max = 45 },
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "Humility in the face of fame. The world respected the restraint more than they would have respected the boasting.",
                },
            },
            {
                label = "Demand more",
                description = "We deserve even greater recognition.",
                requires = { axis = "PER_PRI", min = 60 },
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "More was demanded. More was given — reluctantly. The line between reputation and arrogance blurred.",
                },
            },
        },
    },
    {
        id = "reputation_curse",
        title = "The Weight of the Name",
        narrative = "The bloodline's fame as {reputation_primary} becomes a burden. Expectations crush. Every action is measured against legend.",
        requires = "strong_reputation",
        chance = 0.15,
        options = {
            {
                label = "Fake it",
                description = "Maintain appearances. No one needs to know the strain.",
                consequences = {
                    cultural_memory_shift = { social = -1, mental = -1 },
                    narrative = "The facade held. Behind it, the family strained under the weight of their own legend.",
                },
            },
            {
                label = "Admit the weakness",
                description = "We are not always what our name suggests.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2, mental = 1 },
                    narrative = "The admission was shocking and refreshing. The world respected honesty more than perfection.",
                },
            },
            {
                label = "Redefine the reputation",
                description = "We were {reputation_primary}. Now we become something new.",
                requires = { axis = "PER_ADA", min = 60 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = 1, physical = -1 },
                    narrative = "The old reputation was shed like a skin. What emerged was unfamiliar but alive with possibility.",
                },
            },
            {
                label = "Draw strength from the Long Memory",
                description = "Your doctrine reminds you: the bloodline has weathered worse. Memory is armor.",
                requires_doctrine = "the_long_memory",
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 1 },
                    narrative = "The Long Memory held. Every scar, every triumph, every lesson — they were not just history. They were strength.",
                },
            },
        },
    },
    {
        id = "reputation_legend",
        title = "The Story Becomes Legend",
        narrative = "The bloodline's history has become myth. Bards sing of {reputation_primary} ancestors who may not have existed as described.",
        requires = "strong_reputation",
        chance = 0.1,
        requires_generation_min = 20,
        options = {
            {
                label = "Commission a true history",
                description = "Set the record straight. Facts over fiction.",
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "Historians were commissioned. The true story was recorded. Less glamorous, but honest.",
                },
            },
            {
                label = "Correct the myths",
                description = "Some of these stories are dangerous. Fix them.",
                consequences = {
                    cultural_memory_shift = { mental = 2, social = 1 },
                    narrative = "The worst myths were corrected. The best were left to grow. A curated legacy.",
                },
            },
            {
                label = "Add to the legend",
                description = "Why correct a myth when you can make it bigger?",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 2, social = -1 },
                    taboo_chance = 0.10,
                    taboo_data = { trigger = "embellished_legend", effect = "lives_in_myth", strength = 45 },
                    narrative = "New chapters were added to the legend. Grander. More heroic. Less true. But what is truth to a good story?",
                },
            },
        },
    },
    {
        id = "reputation_contrast",
        title = "The Heir Defies the Name",
        narrative = "The new heir is nothing like the bloodline's reputation as {reputation_primary}. They are something else entirely.",
        requires = "strong_reputation",
        chance = 0.15,
        options = {
            {
                label = "Suppress the difference",
                description = "The name must be maintained. Force them into the mold.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The heir was reshaped. Forced into a role they were not born for. The name endured. The person suffered.",
                },
            },
            {
                label = "Celebrate the difference",
                description = "Evolution, not decline. The bloodline grows.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = 1 },
                    narrative = "The difference was celebrated. A new chapter. The old reputation bent to accommodate the new reality.",
                },
            },
            {
                label = "Let the world decide",
                description = "We know who we are. Let others figure it out.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "No announcement was made. The world watched the heir and drew its own conclusions.",
                },
            },
        },
    },
}
