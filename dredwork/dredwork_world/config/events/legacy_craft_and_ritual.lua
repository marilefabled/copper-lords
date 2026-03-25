-- Bloodweight — Legacy Events: Craft & Ritual
-- Events testing underused creative traits: CRE_EXP, CRE_AES, CRE_IMP,
-- CRE_MEC, CRE_ARC, CRE_RIT, CRE_FLV, CRE_NAR, CRE_SYM.
-- These give creative heirs mechanical expression and chronicle flavor.

return {
    {
        id = "the_family_ritual",
        title = "The Rite Forgotten",
        narrative = "An ancient family rite has been lost to time. Only fragments remain — symbols carved into the chapel floor, a melody hummed by the eldest servants.",
        chance = 0.25,
        cooldown = 12,
        requires_generation_min = 10,
        options = {
            {
                label = "Reconstruct the ritual",
                description = "Ritual design and symbolic thinking — rebuild meaning from fragments.",
                check = { primary = { trait = "CRE_RIT", weight = 1.0 }, secondary = { trait = "CRE_SYM", weight = 0.7 }, tertiary = { trait = "MEN_MEM", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 1 },
                    lineage_power_shift = 3,
                    narrative = "{heir_name} wove the fragments into a whole. When the rite was performed, the chapel hummed with something older than stone. The ancestors approved.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The reconstruction felt hollow. The words were wrong, or the intent was missing. The ancestors remained silent.",
                },
            },
            {
                label = "Create a new tradition",
                description = "The old is gone. Honor it by building something new.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 2 },
                    narrative = "A new rite was born. Not the ancestor's — but the bloodline's own. Whether it would endure was for future generations to decide.",
                },
            },
        },
    },

    {
        id = "the_feast_of_memory",
        title = "The Ancestral Feast",
        narrative = "Every generation, the family prepares a meal from the founding recipe. The ingredients are rare. The preparation is exact. The meaning is everything.",
        chance = 0.3,
        cooldown = 10,
        options = {
            {
                label = "Prepare the feast personally",
                description = "Flavor sense and aesthetic sensibility — the meal is a message.",
                check = { primary = { trait = "CRE_FLV", weight = 1.0 }, secondary = { trait = "CRE_AES", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 2, social = 1 },
                    narrative = "The meal was perfect. Each flavor carried a generation. The court ate in silence — the kind of silence that is not empty but full. {heir_name} understood that food is memory made edible.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The proportions were wrong. The meal was edible but meaningless. A ceremony without weight. The ancestors would have been polite about it.",
                },
            },
            {
                label = "Let the cooks handle it",
                description = "It is a meal, not a sacrament.",
                consequences = {
                    narrative = "The feast was competent. Pleasant. Forgettable. Sometimes a meal is just a meal.",
                },
            },
        },
    },

    {
        id = "the_siege_machine",
        title = "The Engine of War",
        narrative = "The enemy fortress is impregnable by conventional means. The engineers are stumped. {heir_name} asks to see the blueprints.",
        chance = 0.3,
        cooldown = 8,
        requires_condition = "war",
        options = {
            {
                label = "Design a new siege engine",
                description = "Mechanical aptitude and architectural thinking — build what has never existed.",
                check = { primary = { trait = "CRE_MEC", weight = 1.0 }, secondary = { trait = "CRE_ARC", weight = 0.6 }, tertiary = { trait = "MEN_SPA", weight = 0.3 }, difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { creative = 3, physical = 1 },
                    narrative = "{heir_name}'s design was ugly, impractical, and terrifying. It worked on the third attempt. The wall fell. The engineers stared at the plans for weeks afterward, trying to understand how the heir had seen what they could not.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The engine collapsed during testing. The siege continued by conventional means. Innovation is not a guarantee.",
                },
            },
            {
                label = "Starve them out",
                description = "Time is the only engine that never fails.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The siege lasted eight months. The fortress fell to hunger, not ingenuity. Effective. Brutal. Uncreative.",
                },
            },
        },
    },

    {
        id = "the_bards_challenge",
        title = "A War of Words",
        narrative = "A rival house's bard sings a mocking ballad about the bloodline. It spreads through every tavern. The insult demands a response — but not with steel.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Commission a devastating reply",
                description = "Narrative instinct and expression — craft a counter-ballad that will bury the original.",
                check = { primary = { trait = "CRE_NAR", weight = 1.0 }, secondary = { trait = "CRE_EXP", weight = 0.6 }, tertiary = { trait = "SOC_HUM", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = 1 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "The counter-ballad was savage, witty, and true. Within a month, the original was forgotten. The new song was about {heir_name}'s house — and it was glorious.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1, social = -1 },
                    narrative = "The counter-ballad was clumsy. It made the original seem sharper by comparison. Sometimes silence is better than a weak retort.",
                },
            },
            {
                label = "Ignore it",
                description = "Songs die. Names don't.",
                consequences = {
                    narrative = "The ballad ran its course. A season later, no one remembered the words. Ignoring an insult is its own kind of power.",
                },
            },
            {
                label = "Kill the bard",
                description = "Some insults are answered in the old way.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    cultural_memory_shift = { social = -3 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    moral_act = { act_id = "cruelty", description = "Killed a bard for a song" },
                    narrative = "The bard died. The song became immortal. Martyrs always sing louder from the grave.",
                },
            },
        },
    },

    {
        id = "the_crumbling_keep",
        title = "The Wall That Speaks",
        narrative = "The oldest wall of the ancestral keep is failing. Engineers say it must be replaced. But the wall holds carvings from the founding generation.",
        chance = 0.25,
        cooldown = 12,
        options = {
            {
                label = "Redesign the wall to preserve the carvings",
                description = "Architectural eye and aesthetic sense — engineering as art.",
                check = { primary = { trait = "CRE_ARC", weight = 1.0 }, secondary = { trait = "CRE_AES", weight = 0.6 }, tertiary = { trait = "CRE_CRA", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3 },
                    lineage_power_shift = 2,
                    narrative = "The new wall was a masterwork — the old carvings integrated into a structure that was stronger and more beautiful than either could have been alone. {heir_name} understood that the past is not a burden. It is a foundation.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1 },
                    narrative = "The integration failed. The carvings cracked during the rebuilding. Some of the founding generation's marks were lost forever.",
                },
            },
            {
                label = "Replace it entirely",
                description = "Nostalgia is not structural integrity.",
                consequences = {
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The new wall was strong, plain, and devoid of memory. The carvings were catalogued and stored in a box. No one ever opened it.",
                },
            },
        },
    },

    {
        id = "the_broken_ceremony",
        title = "The Rite Interrupted",
        narrative = "Mid-ceremony, a storm destroys the altar. The crowd panics. The rite is incomplete. The symbols lie scattered.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "Improvise the ending",
                description = "Improvisation and symbolic thinking — finish the rite from memory and instinct.",
                check = { primary = { trait = "CRE_IMP", weight = 1.0 }, secondary = { trait = "CRE_SYM", weight = 0.6 }, tertiary = { trait = "MEN_COM", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = 1 },
                    narrative = "{heir_name} gathered the scattered symbols. Rebuilt the altar from storm-broken wood. Finished the rite by firelight, improvising words that felt older than any scripture. The crowd wept. The rite was complete — different, but complete.",
                },
                consequences_fail = {
                    cultural_memory_shift = { creative = -1, social = -1 },
                    narrative = "The improvisation faltered. The words felt wrong. The crowd dispersed, uncertain. An incomplete rite is worse than none at all.",
                },
            },
            {
                label = "Postpone until the altar is rebuilt",
                description = "Ritual demands precision. Redo it properly.",
                consequences = {
                    narrative = "The rite was postponed. Rebuilt. Performed correctly weeks later. By then, the moment had passed. Rituals live in their timing.",
                },
            },
        },
    },
}
