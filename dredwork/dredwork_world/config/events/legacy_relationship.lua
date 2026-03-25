-- Dark Legacy — Legacy Events: Relationship
return {
    {
        id = "ancestral_debt",
        title = "An Ancient Debt Called",
        narrative = "A messenger arrives bearing a contract older than living memory. Your ancestors owe a debt that has never been paid.",
        requires = "old_relationship",
        chance = 0.2,
        options = {
            {
                label = "Honor the debt",
                description = "Our word endures across generations.",
                requires = { axis = "PER_LOY", min = 40 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "The ancient debt was honored. The world remembered that this bloodline keeps its promises.",
                },
            },
            {
                label = "Reject the claim",
                description = "The dead cannot bind the living.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "The debt was rejected. The messenger left with cold eyes. Some oaths should not be broken.",
                },
            },
        },
    },
    {
        id = "ally_in_peril",
        title = "An Ally Faces Destruction",
        narrative = "An ancient ally of the bloodline teeters on the edge of annihilation. They beg for aid. The bond stretches across generations. The {zealotry_label} faith demands a response.",
        requires = "old_relationship_ally",
        chance = 0.2,
        options = {
            {
                label = "Rush to their aid",
                description = "The bond is sacred. We ride.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    cultural_memory_shift = { social = 3, physical = 2 },
                    narrative = "The bloodline rode to war for an ancient ally. The bond held. The cost was blood.",
                },
            },
            {
                label = "Send supplies only",
                description = "Help from a distance. Minimize risk.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "Supplies were sent. Not soldiers. A measured response. Disappointing, but pragmatic.",
                },
            },
            {
                label = "Exploit their weakness",
                description = "An ally's fall is an opportunity.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -5 },
                    taboo_chance = 0.30,
                    taboo_data = { trigger = "betrayed_ally", effect = "betrayed_an_ally", strength = 85 },
                    narrative = "The ally was abandoned. Worse — their weakness was exploited. A dark day for the bloodline's honor.",
                },
            },
        },
    },
    {
        id = "enemy_olive_branch",
        title = "The Enemy Extends Peace",
        narrative = "An ancient enemy of the bloodline sends an envoy bearing white flags. They seek peace. After all these generations.",
        requires = "old_relationship_enemy",
        chance = 0.2,
        options = {
            {
                label = "Accept the peace",
                description = "End the feud. Begin again.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Peace was accepted. The ancient feud ended. Not with a bang, but with a handshake.",
                },
            },
            {
                label = "Reject the peace",
                description = "The blood remembers. Some wounds never heal.",
                consequences = {
                    cultural_memory_shift = { social = -1 },
                    narrative = "The olive branch was cast aside. The feud continued. The ancestors' hatred endured.",
                },
            },
            {
                label = "Demand reparations",
                description = "Peace has a price. They owe us.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = 1, mental = 1 },
                    narrative = "Reparations were demanded. The enemy balked, then paid. Peace, purchased at a premium.",
                },
            },
        },
    },
    {
        id = "relationship_test",
        title = "Caught Between Allies",
        narrative = "Two allied houses demand the bloodline choose between them. Both claim priority. Both threaten consequences.",
        requires = "old_relationship_ally",
        chance = 0.15,
        options = {
            {
                label = "Honor the older alliance",
                description = "Seniority. Tradition. The oldest bond holds.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The older alliance was honored. The newer ally seethed. Some bonds are deeper than others.",
                },
            },
            {
                label = "Honor the newer alliance",
                description = "The newer bond is warmer. More relevant.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The newer ally was chosen. The older one withdrew in cold silence. History revised.",
                },
            },
            {
                label = "Refuse to choose",
                description = "We are allied with both. Deal with it.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -1, mental = 2 },
                    narrative = "Both demands were refused. The bloodline stood alone between two angry allies. Principles have a price.",
                },
            },
        },
    },
    {
        id = "relationship_forgotten",
        title = "The Fading Bond",
        narrative = "An old relationship with a house has grown faint with time. Soon, it will be as if it never existed.",
        requires = "old_relationship",
        chance = 0.2,
        options = {
            {
                label = "Rekindle the bond",
                description = "Send envoys. Renew the oath.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The old bond was renewed. What was fading was given new life. Some relationships are worth preserving.",
                },
            },
            {
                label = "Let it fade",
                description = "All things end. Even alliances.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The bond faded into memory. Neither side mourned. Some things simply run their course.",
                },
            },
            {
                label = "Formally end it",
                description = "A clean break. No lingering obligations.",
                consequences = {
                    cultural_memory_shift = { mental = 1, social = -1 },
                    narrative = "The relationship was formally dissolved. Clean. Final. Both sides walked away free.",
                },
            },
        },
    },
}
