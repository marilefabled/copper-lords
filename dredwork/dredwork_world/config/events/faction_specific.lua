-- Dark Legacy — Faction Events: Type-Specific
-- Events gated by faction's reputation primary (warriors, scholars, diplomats, artisans)
return {
    {
        id = "warrior_duel",
        title = "Trial by Combat with {faction_name}",
        narrative = "A champion of {faction_name} challenges your house to single combat. Honor demands an answer.",
        chance = 0.25,
        faction_type = "warriors",
        options = {
            {
                label = "Accept the duel",
                description = "Send our champion. Let steel decide.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { physical = 4 },
                    mutation_triggers = { { type = "war", intensity = 0.2 } },
                    narrative = "The duel was fought. Blood was shed. Honor was satisfied, regardless of the outcome.",
                },
            },
            {
                label = "Refuse the duel",
                description = "We don't play their games.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { social = -2 },
                    narrative = "The duel was refused. {faction_name} sneered. Warriors respect only other warriors.",
                },
            },
            {
                label = "Propose an alternative contest",
                description = "If they insist on a test, let us choose the arena.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    cultural_memory_shift = { mental = 2, creative = 1 },
                    narrative = "A different contest was proposed. The warriors were confused, then intrigued. Respect was earned through cleverness.",
                },
            },
        },
    },
    {
        id = "scholar_debate",
        title = "The Great Debate with {faction_name}",
        narrative = "The scholars of {faction_name} propose a formal intellectual contest. Knowledge against knowledge. Theory against theory.",
        chance = 0.25,
        faction_type = "scholars",
        options = {
            {
                label = "Engage fully",
                description = "Meet them on the field of ideas.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { mental = 4, creative = 1 },
                    narrative = "The debate raged for days. Ideas clashed like swords. Both houses emerged sharper.",
                },
            },
            {
                label = "Defer respectfully",
                description = "We are not scholars. We need not pretend.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = 1 },
                    narrative = "The debate was declined. The scholars shrugged. Not everyone appreciates the life of the mind.",
                },
            },
            {
                label = "Cheat",
                description = "Steal their arguments. Plant false data. Win at any cost.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { mental = 2 },
                    taboo_chance = 0.10,
                    taboo_data = { trigger = "cheated_scholars", effect = "intellectual_fraud", strength = 50 },
                    narrative = "The debate was won through deception. The victory was hollow, but the result stood.",
                },
            },
        },
    },
    {
        id = "diplomat_intrigue",
        title = "The Web of {faction_name}",
        narrative = "A scheme by {faction_name} is discovered. They've been manipulating alliances behind your back.",
        chance = 0.25,
        faction_type = "diplomats",
        options = {
            {
                label = "Expose the plot",
                description = "Drag their schemes into the light.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The intrigue was exposed. {faction_name}'s web of lies unraveled before all.",
                },
            },
            {
                label = "Play along",
                description = "Pretend you don't know. Use their scheme against them.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 1 },
                    narrative = "The scheme was allowed to play out — with subtle redirections. The puppet masters found their strings cut.",
                },
            },
            {
                label = "Blackmail them",
                description = "Hold the knowledge over their heads.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { mental = 2, social = -2 },
                    taboo_chance = 0.15,
                    taboo_data = { trigger = "blackmail", effect = "deals_in_leverage", strength = 55 },
                    narrative = "The information was held. A quiet word was spoken. {faction_name} now owed a debt of silence.",
                },
            },
        },
    },
    {
        id = "artisan_commission",
        title = "{faction_name} Seeks a Patron",
        narrative = "The artisans of {faction_name} request funding for a masterwork. It would honor both houses — if it succeeds.",
        chance = 0.25,
        faction_type = "artisans",
        options = {
            {
                label = "Fund the masterwork",
                description = "Beauty deserves patronage.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 12 } },
                    cultural_memory_shift = { creative = 4, social = 1 },
                    narrative = "The masterwork was funded. What emerged was a thing of breathtaking beauty. Both names were carved upon it.",
                },
            },
            {
                label = "Demand it for free",
                description = "We are their betters. They should be grateful for the attention.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { creative = 1, social = -3 },
                    narrative = "The demand was made. The artisans complied, bitterly. Art made under compulsion is never quite as beautiful.",
                },
            },
            {
                label = "Collaborate as equals",
                description = "Work alongside them. Create something together.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { creative = 5, social = 2 },
                    narrative = "The collaboration was extraordinary. Two houses, one vision. The masterwork surpassed all expectations.",
                },
            },
        },
    },
    {
        id = "blood_bound_test",
        title = "A Test of Loyalty from {faction_name}",
        narrative = "{faction_name} demands proof of the alliance. A test of loyalty — or a trap. Hard to tell the difference.",
        chance = 0.25,
        disposition_min = 10,
        options = {
            {
                label = "Prove our loyalty",
                description = "Pass the test. Strengthen the bond.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The test was passed. The bond deepened. {faction_name} would remember this loyalty.",
                },
            },
            {
                label = "Refuse the test",
                description = "We owe no proof. Our word should suffice.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = -1 },
                    narrative = "The test was refused on principle. Trust given under pressure is not trust at all.",
                },
            },
            {
                label = "Turn the test around",
                description = "If loyalty must be proven, let them prove theirs first.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -3 } },
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The counter-demand was unexpected. {faction_name} was caught off guard. The dynamic shifted.",
                },
            },
        },
    },
}
