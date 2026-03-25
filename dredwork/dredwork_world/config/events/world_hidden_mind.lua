-- Bloodweight — World Events: The Hidden Mind
-- Events testing underused mental traits: MEN_MEM, MEN_PAT, MEN_LRN, MEN_ITU,
-- MEN_PLA, MEN_STH, MEN_DEC. Also touches SOC_TEA, SOC_CRD.
-- These create narrative variety for intellectual/perceptive heirs.

return {
    {
        id = "the_cipher_wall",
        title = "The Ancestor's Cipher",
        narrative = "Behind a collapsed wall in the keep, a hidden chamber. The walls are covered in symbols — a cipher left by a forgotten ancestor.",
        chance = 0.25,
        cooldown = 12,
        options = {
            {
                label = "Decode the cipher",
                description = "Pattern recognition and memory will unravel the ancestor's message.",
                check = { primary = { trait = "MEN_PAT", weight = 1.0 }, secondary = { trait = "MEN_MEM", weight = 0.7 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 1 },
                    lineage_power_shift = 3,
                    narrative = "{heir_name} spent weeks in the chamber. The cipher broke. What the ancestor had hidden was not treasure — it was a warning. And now the bloodline knows.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -1 },
                    narrative = "The symbols refused to yield. {heir_name} emerged frustrated, the ancestor's message still locked in stone.",
                },
            },
            {
                label = "Seal the chamber",
                description = "Some things are hidden for a reason.",
                consequences = {
                    narrative = "The wall was rebuilt. The cipher remains. Perhaps a future heir will have the mind for it.",
                },
            },
        },
    },

    {
        id = "the_traitors_tell",
        title = "Something Wrong at Court",
        narrative = "Nothing is overtly wrong. But {heir_name} notices a pattern — guards rotated oddly, a servant's routes changed, a window left open on cold nights.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Trust your gut",
                description = "Intuition and decisiveness — act before the threat crystallizes.",
                check = { primary = { trait = "MEN_ITU", weight = 1.0 }, secondary = { trait = "MEN_DEC", weight = 0.6 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "The conspiracy was real. {heir_name}'s instinct saved the family. The traitors were found with packed bags and sharpened knives.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "False alarm. Loyal servants were accused and humiliated. {heir_name}'s instincts were wrong this time. Trust was damaged.",
                },
            },
            {
                label = "Investigate carefully",
                description = "Watch. Wait. Learn the shape of it.",
                check = { primary = { trait = "MEN_PER", weight = 0.8 }, secondary = { trait = "MEN_PAT", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "Patient observation revealed the full picture. The conspiracy was deeper than expected. But now every thread was visible.",
                },
                consequences_fail = {
                    narrative = "The investigation found nothing conclusive. The unease lingered.",
                },
            },
            {
                label = "Dismiss the feeling",
                description = "Paranoia is a disease of leadership.",
                consequences = {
                    narrative = "The feeling was suppressed. Whether it was right or wrong, {heir_name} will never know.",
                },
            },
        },
    },

    {
        id = "the_new_doctrine",
        title = "A Heresy of Thought",
        narrative = "A traveling philosopher arrives with ideas that contradict everything the family has believed. Not about faith — about governance, justice, the nature of rule.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Absorb the new ideas",
                description = "Mental plasticity determines whether old beliefs can be rebuilt.",
                check = { primary = { trait = "MEN_PLA", weight = 1.0 }, secondary = { trait = "MEN_LRN", weight = 0.6 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 1 },
                    narrative = "{heir_name} sat with the philosopher for seven days. When the conversations ended, the family's doctrine had evolved. Not broken — evolved. Some truths survive integration.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -1 },
                    narrative = "{heir_name} tried to embrace the new thinking but could not release the old. The philosopher departed, disappointed.",
                },
            },
            {
                label = "Debate and dismantle",
                description = "Test the ideas with the sharpest analytical tools available.",
                check = { primary = { trait = "MEN_ANA", weight = 0.8 }, secondary = { trait = "MEN_INT", weight = 0.5 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The debate lasted three days. Some ideas fell. Others held. {heir_name} kept the ones that survived.",
                },
                consequences_fail = {
                    narrative = "The philosopher was sharper. {heir_name} lost the argument and gained nothing but frustration.",
                },
            },
            {
                label = "Banish the philosopher",
                description = "Dangerous ideas are a plague of their own.",
                requires = { axis = "PER_ADA", max = 35 },
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    disposition_changes = { { faction_id = "all", delta = -2 } },
                    narrative = "The philosopher was escorted to the border. The ideas, however, had already been heard.",
                },
            },
        },
    },

    {
        id = "the_breaking_point",
        title = "The Weight of Command",
        narrative = "Crisis upon crisis. Famine reports. Border incursions. A servant's suicide. The heir has not slept in days. The mind begins to bend.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Hold the line",
                description = "Stress threshold and composure determine if the mind holds.",
                check = { primary = { trait = "MEN_STH", weight = 1.0 }, secondary = { trait = "MEN_COM", weight = 0.6 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "{heir_name} did not break. Every decision was correct, or close enough. The mind held because it was built to bear weight that would crush others.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -3, social = -2 },
                    narrative = "{heir_name} broke. Not violently — quietly. Decisions stopped. The court found the heir staring at a wall, whispering numbers that meant nothing.",
                },
            },
            {
                label = "Delegate everything and withdraw",
                description = "Survival means knowing your limits.",
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The heir withdrew. The advisors managed. The crises were handled — competently, if not brilliantly. {heir_name} returned after a week, diminished but intact.",
                },
            },
        },
    },

    {
        id = "the_apprentice",
        title = "The Slow Pupil",
        narrative = "A promising young scholar has been assigned to {heir_name}'s tutelage. Brilliant, but struggling. The question is not what they know — it is whether they can be taught.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Teach them personally",
                description = "Teaching ability and crowd reading — understanding how another mind works.",
                check = { primary = { trait = "SOC_TEA", weight = 1.0 }, secondary = { trait = "SOC_CRD", weight = 0.5 }, tertiary = { trait = "MEN_LRN", weight = 0.3 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2, mental = 1 },
                    narrative = "{heir_name} found the key. Not lectures — questions. The apprentice flourished. Years later, they would serve the family with a devotion that money cannot buy.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The teaching failed. Not for lack of knowledge — for lack of patience, or understanding. Some minds cannot reach other minds.",
                },
            },
            {
                label = "Assign them to the library",
                description = "Let the books do the teaching.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The apprentice disappeared into the stacks. Whether they emerged wiser or merely older was never determined.",
                },
            },
        },
    },

    {
        id = "the_crowd_turns",
        title = "The Market Square Riot",
        narrative = "What began as a tax protest has become a mob. The market square is full of angry faces. {heir_name} arrives without guards.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Read the crowd and speak",
                description = "Crowd reading and humor can defuse what force cannot.",
                check = { primary = { trait = "SOC_CRD", weight = 1.0 }, secondary = { trait = "SOC_HUM", weight = 0.6 }, tertiary = { trait = "SOC_ELO", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "{heir_name} found the leaders in the crowd. Made eye contact. Said something that made one of them laugh. The laughter spread. The tension broke. No blood was spilled.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "The crowd did not laugh. The stones started flying. {heir_name} retreated with a bruised face and a bruised reputation.",
                },
            },
            {
                label = "Send the guards",
                description = "Order must be restored. The method is secondary.",
                consequences = {
                    cultural_memory_shift = { physical = 1, social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "The guards dispersed the mob. Order was restored. The resentment was not.",
                },
            },
        },
    },
}
