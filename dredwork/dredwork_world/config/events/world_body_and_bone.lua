-- Bloodweight — World Events: Body & Bone
-- Events that test the underused physical traits: PHY_LON, PHY_BON, PHY_LUN,
-- PHY_IMM, PHY_REC, PHY_PAI, PHY_SEN, PHY_ADP, PHY_MET, PHY_COR, PHY_AGI.
-- These create stat check variety and chronicle flavor for physical heirs.

return {
    {
        id = "the_mountain_pass",
        title = "The Passage Above the Clouds",
        narrative = "The only safe route has been severed. The remaining path crosses a mountain where the air itself is a weapon.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Lead the crossing",
                description = "Lung capacity and bone strength will determine who survives the altitude.",
                check = { primary = { trait = "PHY_LUN", weight = 1.0 }, secondary = { trait = "PHY_BON", weight = 0.6 }, tertiary = { trait = "PHY_END", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    narrative = "{heir_name} led the column through air thin enough to kill. Not everyone made it. But the bloodline did.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    narrative = "The altitude broke them. {heir_name} collapsed before the summit. The retreat cost lives and time.",
                },
            },
            {
                label = "Find another way",
                description = "Patience. There is always another route.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The long way around. Weeks lost, but no lives. Sometimes the mountain wins by being climbed.",
                },
            },
        },
    },

    {
        id = "the_plague_ward",
        title = "The Ward of the Dying",
        narrative = "Plague has reached the estate. The healers have fallen. Someone must enter the ward and tend the sick.",
        chance = 0.25,
        cooldown = 10,
        requires_condition = "plague",
        options = {
            {
                label = "Enter the ward personally",
                description = "Immune resistance and recovery speed will determine survival.",
                check = { primary = { trait = "PHY_IMM", weight = 1.0 }, secondary = { trait = "PHY_REC", weight = 0.7 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = 2 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "{heir_name} walked among the dying and did not fall. The bloodline's immune strength held. The people remembered.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -3 },
                    narrative = "{heir_name} fell ill within days. Survived — barely — but the weakness lingered for years.",
                },
            },
            {
                label = "Send physicians with instructions",
                description = "Lead from a safe distance.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "Instructions were given. The physicians did what they could. The heir remained untouched. Unscathed. Uninvolved.",
                },
            },
        },
    },

    {
        id = "the_night_hunt",
        title = "The Hunt in Darkness",
        narrative = "A beast has been killing livestock for weeks. The trackers have failed. {heir_name} proposes hunting it by moonlight, when it feeds.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Hunt by senses alone",
                description = "Acute senses and agility in darkness will decide this.",
                check = { primary = { trait = "PHY_SEN", weight = 1.0 }, secondary = { trait = "PHY_AGI", weight = 0.6 }, tertiary = { trait = "PHY_REF", weight = 0.3 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 3 },
                    narrative = "{heir_name} heard it before seeing it. Moved through darkness as if born to it. The beast fell. The estate slept soundly.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -1 },
                    narrative = "The darkness won. {heir_name} returned empty-handed, cut by branches and humbled by the night.",
                },
            },
            {
                label = "Set traps instead",
                description = "Patience over predation.",
                check = { primary = { trait = "PHY_COR", weight = 0.8 }, secondary = { trait = "MEN_PAT", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The traps were elegant. The beast was caught by dawn. {heir_name}'s hands built what instinct could not.",
                },
                consequences_fail = {
                    narrative = "The beast avoided every trap. It was almost insulting.",
                },
            },
        },
    },

    {
        id = "the_famine_march",
        title = "The Starving Column",
        narrative = "Refugees arrive — thousands — with nothing. The march to the feeding stations is three days on empty stomachs.",
        chance = 0.25,
        cooldown = 10,
        options = {
            {
                label = "March with them",
                description = "Metabolism and pain tolerance will be tested.",
                check = { primary = { trait = "PHY_MET", weight = 1.0 }, secondary = { trait = "PHY_PAI", weight = 0.6 }, difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = 2 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "{heir_name} ate nothing for three days. Marched at the front. The body held because it was built to endure scarcity. The people followed because someone walked beside them.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2 },
                    narrative = "{heir_name} collapsed on the second day. Was carried the rest of the way. The gesture was remembered, but so was the weakness.",
                },
            },
            {
                label = "Organize supply wagons",
                description = "Logistics over symbolism.",
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "Wagons were dispatched. Efficient. Impersonal. The refugees ate. They did not know the heir's name.",
                },
            },
        },
    },

    {
        id = "the_broken_bridge",
        title = "The Collapse",
        narrative = "The stone bridge gives way during a crossing. Bodies in the river. Survivors clinging to wreckage. {heir_name} is on the far bank.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Dive in and pull them out",
                description = "Recovery rate and physical adaptability determine how many are saved.",
                check = { primary = { trait = "PHY_REC", weight = 0.8 }, secondary = { trait = "PHY_ADP", weight = 0.7 }, tertiary = { trait = "PHY_STR", weight = 0.4 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 3, social = 1 },
                    narrative = "{heir_name} went into the water seven times. Pulled out five. The sixth drowned in their arms. The seventh was already gone. Five is still five.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -1, social = -1 },
                    narrative = "The current was too strong. {heir_name} was pulled from the water, coughing and broken. The dead were counted at dawn.",
                },
            },
            {
                label = "Direct rescue from shore",
                description = "Organize. Delegate. Survive to lead.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "Ropes were thrown. Orders given. Some were saved. {heir_name} stayed dry. The decision was correct. It still felt wrong.",
                },
            },
        },
    },

    {
        id = "the_endurance_trial",
        title = "Three Days Without Rest",
        narrative = "A border crisis demands constant attention. Three days of negotiations, marching, and decisions. No sleep. No respite.",
        chance = 0.3,
        cooldown = 8,
        options = {
            {
                label = "Push through on willpower",
                description = "Longevity reserves and pain tolerance sustain the body beyond its limits.",
                check = { primary = { trait = "PHY_LON", weight = 0.8 }, secondary = { trait = "PHY_PAI", weight = 0.6 }, tertiary = { trait = "MEN_COM", weight = 0.4 }, difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 2, mental = 1 },
                    narrative = "{heir_name} did not sleep for seventy-two hours. Made decisions that held. The body was built for endurance the mind could not explain.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -2, social = -1 },
                    narrative = "{heir_name} collapsed on the second night. The negotiations continued without them. The border was settled by lesser hands.",
                },
            },
            {
                label = "Rotate command with advisors",
                description = "Share the burden. Accept the dilution.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The advisors handled it. Competently. The heir slept. The crisis passed. Nobody wrote a song about delegation.",
                },
            },
        },
    },
}
