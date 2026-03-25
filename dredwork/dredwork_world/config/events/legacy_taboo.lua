-- Dark Legacy — Legacy Events: Taboo
return {
    {
        id = "taboo_tested",
        title = "The Weight of the Past",
        narrative = "An opportunity arises that your ancestors would have refused. The taboo against \"{taboo_effect}\" echoes through the bloodline.",
        requires = "active_taboo",
        chance = 0.25,
        options = {
            {
                label = "Honor the ancestors. Refuse.",
                description = "The dead have spoken. We obey.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The taboo held. The ancestors' will endured another generation.",
                },
            },
            {
                label = "Break the chain. Defy the dead.",
                description = "We are not our ancestors. The world has changed.",
                requires = { axis = "PER_ADA", min = 60 },
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "The chain was broken. For the first time in generations, the bloodline turned away from its past.",
                },
            },
        },
    },
    {
        id = "taboo_opportunity",
        title = "The Perfect Chance",
        narrative = "Everything aligns perfectly for an action the ancestors forbade. The taboo against \"{taboo_effect}\" is the only thing standing in the way.",
        requires = "active_taboo",
        chance = 0.2,
        options = {
            {
                label = "Obey the taboo",
                description = "The ancestors knew what they were doing. We trust them.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The opportunity passed. The taboo held firm. Somewhere, the ancestors nodded.",
                },
            },
            {
                label = "Find a loophole",
                description = "Honor the letter of the taboo, not the spirit.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "A clever interpretation was found. Technically, the taboo was not violated. Technically.",
                },
            },
            {
                label = "Defy it openly",
                description = "Announce to the world that this taboo is dead.",
                requires = { axis = "PER_ADA", min = 70 },
                consequences = {
                    cultural_memory_shift = { social = -3, creative = 2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "The taboo was publicly defied. The ancestors' will was broken. Freedom — or recklessness?",
                },
            },
        },
    },
    {
        id = "taboo_echo",
        title = "History Repeats",
        narrative = "The exact circumstances that created the taboo against \"{taboo_effect}\" have emerged again. The bloodline stands at the same crossroads.",
        requires = "active_taboo",
        chance = 0.15,
        requires_generation_min = 15,
        options = {
            {
                label = "Same response as before",
                description = "The ancestors chose this path. We walk it again.",
                consequences = {
                    cultural_memory_shift = { social = 2 },
                    narrative = "History repeated. The same choice was made. The taboo deepened its roots in the blood.",
                },
            },
            {
                label = "Choose the opposite",
                description = "This time, we choose differently.",
                consequences = {
                    cultural_memory_shift = { creative = 2, social = -2 },
                    narrative = "A different path was chosen. The echo of the past diverged. The taboo weakened.",
                },
            },
            {
                label = "Forge a new path entirely",
                description = "Neither the ancestors' choice nor its opposite. Something new.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    narrative = "A third way was found. Neither obedience nor rebellion. Innovation.",
                },
            },
        },
    },
    {
        id = "taboo_inheritance",
        title = "The Heir Questions",
        narrative = "The new heir asks about the taboo against \"{taboo_effect}\". Why do we avoid this? What happened? The {doctrine_name} doctrine offers no clear answer.",
        requires = "active_taboo",
        chance = 0.2,
        options = {
            {
                label = "Explain the history",
                description = "Tell them everything. Let them understand the weight.",
                consequences = {
                    cultural_memory_shift = { mental = 1, social = 1 },
                    narrative = "The full story was told. The heir listened. The weight settled onto new shoulders.",
                },
            },
            {
                label = "Refuse to explain",
                description = "Some things are obeyed, not understood.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The question was shut down. The taboo became mysterious, feared without understanding.",
                },
            },
            {
                label = "Let them discover for themselves",
                description = "The truth is in the archives. If they want to know, they'll find it.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The heir was left to find the truth alone. What they discovered shaped their understanding of the family forever.",
                },
            },
        },
    },
    {
        id = "taboo_collision",
        title = "Contradictions in the Blood",
        narrative = "Two ancient taboos pull in opposite directions. To honor one, the other must be broken. The ancestors argue from beyond the grave — even as the bloodline dreams of {dream_trait}.",
        requires = "multiple_taboos",
        chance = 0.15,
        options = {
            {
                label = "Honor the older taboo",
                description = "Seniority matters, even among the dead.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The older taboo prevailed. The newer one cracked. The ancestors' hierarchy was maintained.",
                },
            },
            {
                label = "Honor the newer taboo",
                description = "Recent wounds bleed hotter.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The newer taboo won. The older one weakened. The past receded.",
                },
            },
            {
                label = "Break both",
                description = "If they can't agree, neither binds us.",
                requires = { axis = "PER_ADA", min = 75 },
                consequences = {
                    cultural_memory_shift = { creative = 3, social = -4 },
                    narrative = "Both taboos were shattered. The ancestors' will was declared null. The bloodline stood alone, unbound.",
                },
            },
        },
    },
}
