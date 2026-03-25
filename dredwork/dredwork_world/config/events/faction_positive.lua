-- Dark Legacy — Faction Events: Positive
-- Disposition >= threshold required
return {
    {
        id = "marriage_proposal",
        title = "A Proposal from {faction_name}",
        narrative = "{faction_name} extends an offer of union. They seek to bind their bloodline to yours through marriage. The terms are favorable, the intent transparent.",
        chance = 0.3,
        disposition_min = 20,
        options = {
            {
                label = "Accept the union",
                description = "Strengthen ties through blood. Your heir must marry from their house.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    add_relationship = { type = "ally", strength = 65, reason = "marriage_pact" },
                    mutation_triggers = { { type = "intermarriage", intensity = 0.5 } },
                    arranged_marriage_lock = true,
                    narrative = "The bloodlines were joined. A new alliance forged in marriage. Your heir is betrothed.",
                },
            },
            {
                label = "Decline respectfully",
                description = "We value our independence above all.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    narrative = "The offer was declined with courtesy. {faction_name} accepted, though not without a shadow of disappointment.",
                },
            },
        },
    },
    {
        id = "faction_gift",
        title = "A Gift from {faction_name}",
        narrative = "A rare and precious gift arrives from {faction_name}. No strings attached, they claim.",
        chance = 0.25,
        disposition_min = 30,
        options = {
            {
                label = "Accept graciously",
                description = "A gift is a gift.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 1 },
                    narrative = "The gift was accepted. A gesture of goodwill, or the first link of a chain? Only time would tell.",
                },
            },
            {
                label = "Accept with conditions",
                description = "Nothing is truly free. Make the terms explicit.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The gift was accepted on clear terms. Both sides understood the transaction. Honest, if cold.",
                },
            },
            {
                label = "Refuse the gift",
                description = "We owe no one. We accept nothing.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = -1 },
                    narrative = "The gift was refused. Pride stood taller than diplomacy that day.",
                },
            },
        },
    },
    {
        id = "mutual_defense",
        title = "{faction_name} Proposes a Pact",
        narrative = "An envoy from {faction_name} brings a formal proposal: mutual defense against all threats.",
        chance = 0.2,
        disposition_min = 40,
        options = {
            {
                label = "Accept the pact",
                description = "Together we are stronger.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    add_relationship = { type = "ally", strength = 75, reason = "defense_pact" },
                    cultural_memory_shift = { social = 2 },
                    narrative = "A pact of mutual defense was signed. When one bleeds, both fight.",
                },
            },
            {
                label = "Propose a trade agreement instead",
                description = "Military pacts are chains. Trade is freedom.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 1, mental = 1 },
                    narrative = "The military pact was declined, but a trade agreement was offered in its place. Business over blood.",
                },
            },
            {
                label = "Demand vassalage instead",
                description = "They come to negotiate. We dictate.",
                requires_lineage_power_min = 75,
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    add_relationship = { type = "ally", strength = 90, reason = "subjugation" },
                    cultural_memory_shift = { social = 3 },
                    wealth_change = { delta = 8, source = "tribute" },
                    moral_act = "oppression",
                    narrative = "No pact. No equals. {faction_name} knelt, or they would have burned. The tribute would flow.",
                },
            },
            {
                label = "Decline entirely",
                description = "Alliances are liabilities.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -12 } },
                    narrative = "The pact was refused. {faction_name}'s envoy left with disappointment barely concealed.",
                },
            },
        },
    },
    {
        id = "faction_celebration",
        title = "An Invitation from {faction_name}",
        narrative = "{faction_name} hosts a grand feast and invites your house. Attendance is expected.",
        chance = 0.3,
        disposition_min = 15,
        options = {
            {
                label = "Attend grandly",
                description = "Arrive with entourage and gifts. Make an impression.",
                requires = { axis = "PER_PRI", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 12 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The bloodline arrived in splendor. {faction_name} was impressed. The feast was magnificent.",
                },
            },
            {
                label = "Send a representative",
                description = "We acknowledge the invitation without overcommitting.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    narrative = "A representative attended. Polite. Adequate. Forgettable.",
                },
            },
            {
                label = "Decline the invitation",
                description = "We have our own affairs to attend to.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    narrative = "The invitation was declined. {faction_name} noted the slight.",
                },
            },
        },
    },
    {
        id = "joint_venture",
        title = "{faction_name} Proposes an Expedition",
        narrative = "A joint expedition into unknown territory. The risks are shared. The rewards, divided.",
        chance = 0.2,
        disposition_min = 25,
        options = {
            {
                label = "Lead the expedition",
                description = "We take the vanguard. Greater risk, greater glory.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { physical = 2, creative = 1 },
                    narrative = "The bloodline led the expedition. What was found belonged first to the bold.",
                },
            },
            {
                label = "Contribute resources",
                description = "Fund the venture. Let others take the physical risk.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 1, mental = 1 },
                    narrative = "Gold was committed. The expedition proceeded. Returns trickled back slowly.",
                },
            },
            {
                label = "Propose an alternative venture",
                description = "We have a better idea.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { mental = 2, creative = 2 },
                    narrative = "A counter-proposal was made. More ambitious. More dangerous. More interesting.",
                },
            },
        },
    },
}
