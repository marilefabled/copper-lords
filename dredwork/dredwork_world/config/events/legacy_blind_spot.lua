-- Dark Legacy — Legacy Events: Blind Spot
return {
    {
        id = "blind_spot_revealed",
        title = "A Mirror Held Up",
        narrative = "A visitor speaks plainly what no one in the family can see: your bloodline is blind to its weakness in {blind_spot_category}.",
        requires = "blind_spot",
        chance = 0.2,
        options = {
            {
                label = "Dismiss the outsider",
                description = "What do they know of our legacy?",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The messenger was dismissed. The blind spot remained. Comfortable ignorance is its own reward.",
                },
            },
            {
                label = "Listen and learn",
                description = "Perhaps there is truth in their words.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { creative = 2, mental = 2 },
                    narrative = "For the first time, the family saw what it could not see. The first step toward change.",
                },
            },
            {
                label = "Hire them as an advisor",
                description = "If we cannot see it, we need someone who can.",
                consequences = {
                    cultural_memory_shift = { social = 2, mental = 1 },
                    narrative = "An outsider was brought into the inner circle. Their perspective was unsettling but valuable.",
                },
            },
        },
    },
    {
        id = "blind_spot_crisis",
        title = "The Weakness Strikes",
        narrative = "A crisis exposes the family's blind spot in {blind_spot_category}. What they couldn't see, they couldn't prepare for.",
        requires = "blind_spot",
        chance = 0.2,
        options = {
            {
                label = "Acknowledge the weakness",
                description = "Face it. Finally.",
                consequences = {
                    cultural_memory_shift = { mental = 2, creative = 1 },
                    narrative = "The blind spot was acknowledged. Painful, but necessary. Healing begins with honesty.",
                },
            },
            {
                label = "Blame others",
                description = "This isn't our failure. Someone else caused this.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    cultural_memory_shift = { social = -2 },
                    narrative = "Blame was deflected. The blind spot remained. The pattern would repeat.",
                },
            },
            {
                label = "Hire specialists",
                description = "We can't fix what we can't see. Bring in those who can.",
                consequences = {
                    cultural_memory_shift = { social = 1, mental = 2 },
                    narrative = "Experts were brought in. The blind spot didn't vanish, but the damage was limited.",
                },
            },
        },
    },
    {
        id = "blind_spot_prodigy",
        title = "The Black Sheep Shines",
        narrative = "A family member shows extraordinary talent in {blind_spot_category} — the very area the bloodline has always ignored.",
        requires = "blind_spot",
        chance = 0.15,
        options = {
            {
                label = "Nurture the talent",
                description = "This could be the key to breaking the blind spot.",
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    narrative = "The prodigy was nurtured. A flower growing through concrete. The blind spot, for the first time, showed a crack.",
                },
            },
            {
                label = "Suppress it",
                description = "We are who we are. This doesn't fit.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The talent was suppressed. The prodigy withered. The blind spot held firm.",
                },
            },
            {
                label = "Let them find their own way",
                description = "Neither push nor pull. Let nature decide.",
                requires = { axis = "PER_ADA", min = 40 },
                consequences = {
                    cultural_memory_shift = { creative = 1 },
                    narrative = "The prodigy was left to grow wild. What emerged was unpredictable, but authentic.",
                },
            },
        },
    },
    {
        id = "blind_spot_mockery",
        title = "Laughter in the Courts",
        narrative = "Rivals openly mock the bloodline's weakness in {blind_spot_category}. The jokes cut deeper than swords.",
        requires = "blind_spot",
        chance = 0.2,
        options = {
            {
                label = "Prove them wrong",
                description = "Channel the insult into fuel for change.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    cultural_memory_shift = { physical = 1, creative = 2 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "The mockery was answered with results. Not overnight, but the bloodline began to address its weakness.",
                },
            },
            {
                label = "Ignore the mockery",
                description = "Laughter fades. Legacy endures.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The mockery was ignored. The blind spot remained. But the bloodline's composure was noted.",
                },
            },
            {
                label = "Use it strategically",
                description = "Let them think we're weak. Then surprise them.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "The weakness was allowed to be underestimated. What followed would surprise everyone.",
                },
            },
        },
    },
    {
        id = "blind_spot_extinction_risk",
        title = "The Blind Spot Threatens Survival",
        narrative = "An active threat exploits the exact weakness the family has ignored in {blind_spot_category}. Survival is at stake.",
        requires = "blind_spot",
        requires_condition = "plague",
        chance = 0.2,
        options = {
            {
                label = "Emergency investment",
                description = "Pour everything into fixing the weakness. Now.",
                consequences = {
                    cultural_memory_shift = { physical = -2, mental = 2, creative = 2 },
                    narrative = "Desperate resources were thrown at the weakness. Not elegant, but necessary for survival.",
                },
            },
            {
                label = "Seek outside help",
                description = "We need foreign expertise. Open the doors to new blood.",
                consequences = {
                    mutation_triggers = { { type = "intermarriage", intensity = 0.4 } },
                    cultural_memory_shift = { social = 2, creative = 1 },
                    narrative = "Outsiders were brought in. Their knowledge filled the gaps. New blood, new perspectives.",
                },
            },
            {
                label = "Endure through other strengths",
                description = "We are strong where they are not. Use what we have.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    narrative = "The blind spot remained, but the family's other strengths carried them through the crisis. Barely.",
                },
            },
        },
    },
}
