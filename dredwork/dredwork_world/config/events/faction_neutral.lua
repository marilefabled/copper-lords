-- Dark Legacy — Faction Events: Neutral
-- Mixed or moderate disposition interactions
return {
    {
        id = "trade_offer",
        title = "{faction_name} Offers an Exchange",
        narrative = "Merchants bearing the sigil of {faction_name} arrive with a proposition. Knowledge for knowledge, resource for resource.",
        chance = 0.35,
        disposition_min = 0,
        faction_type = "artisans",
        options = {
            {
                label = "Accept the trade",
                description = "Fair exchange benefits all.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Trade routes opened between the houses. Prosperity flowed in both directions.",
                },
            },
            {
                label = "Demand better terms",
                description = "We are worth more than they offer.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = -1, mental = 1 },
                    narrative = "{heir_name} demanded more. {faction_name} reconsidered their estimation of your bloodline.",
                },
            },
            {
                label = "Refuse all dealings",
                description = "We stand alone.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -12 } },
                    narrative = "The merchants were turned away. {faction_name}'s sigil gathered dust at the gate.",
                },
            },
        },
    },
    {
        id = "faction_request",
        title = "A Plea from {faction_name}",
        narrative = "{faction_name} sends a messenger. They are weakened and ask for aid. Their motto — \"{faction_motto}\" — rings hollow today.",
        chance = 0.25,
        disposition_min = -10,
        disposition_max = 40,
        options = {
            {
                label = "Send aid freely",
                description = "Help them without condition.",
                requires = { axis = "PER_CRM", max = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    add_relationship = { type = "ally", strength = 50, reason = "aid_given" },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Aid was sent without hesitation. {faction_name} would not forget this kindness.",
                },
            },
            {
                label = "Help them — for a price",
                description = "Generosity with conditions.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 1, mental = 1 },
                    narrative = "Aid was rendered in exchange for future considerations. A pragmatic arrangement.",
                },
            },
            {
                label = "Exploit their weakness",
                description = "They came to us on their knees. Keep them there.",
                requires = { axis = "PER_CRM", min = 65 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    faction_power_shift = -15,
                    cultural_memory_shift = { physical = 2, social = -4 },
                    taboo_chance = 0.2,
                    taboo_data = { trigger = "exploited_weak", effect = "distrust_from_allies", strength = 60 },
                    narrative = "Their weakness was your opportunity. What was theirs is now yours. The world took note.",
                },
            },
        },
    },
    {
        id = "faction_challenge",
        title = "{faction_name} Issues a Challenge",
        narrative = "A formal challenge arrives from {faction_name}. They contest your family's claim to honor, territory, or legacy.",
        chance = 0.3,
        disposition_max = -10,
        faction_type = "warriors",
        options = {
            {
                label = "Accept the challenge",
                description = "Meet them on the field of honor.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 3 },
                    mutation_triggers = { { type = "war", intensity = 0.3 } },
                    narrative = "The challenge was met. Win or lose, the bloodline proved it would not be cowed.",
                },
            },
            {
                label = "Ignore the challenge",
                description = "They are beneath our notice.",
                requires = { axis = "PER_PRI", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    cultural_memory_shift = { social = -2 },
                    narrative = "{heir_name} did not dignify the challenge with a response. The silence spoke volumes.",
                },
            },
            {
                label = "Counter with diplomacy",
                description = "Turn the challenge into an opportunity.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "Where they expected blades, they found words. The challenge dissolved into negotiation.",
                },
            },
        },
    },
    {
        id = "faction_scholar_exchange",
        title = "Scholars of {faction_name}",
        narrative = "Scholars from {faction_name} request an exchange of knowledge. Their archives for yours.",
        chance = 0.25,
        disposition_min = 0,
        disposition_max = 30,
        faction_type = "scholars",
        options = {
            {
                label = "Accept the exchange",
                description = "Knowledge shared is knowledge doubled.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 12 } },
                    mutation_triggers = { { type = "intermarriage", intensity = 0.3 } },
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "Scholars were exchanged. Ideas flowed. Both houses grew wiser.",
                },
            },
            {
                label = "Send our weakest scholars",
                description = "Give them nothing of value. Take everything.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The exchange was one-sided. {faction_name}'s knowledge was absorbed. Little was given in return.",
                },
            },
            {
                label = "Decline the exchange",
                description = "Our knowledge is our own.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    narrative = "The scholars were turned away. {faction_name} remembered the refusal.",
                },
            },
        },
    },
    {
        id = "faction_border_dispute",
        title = "Contested Ground with {faction_name}",
        narrative = "The border between your lands and those of {faction_name} has never been formally drawn. Now both sides claim the same territory.",
        chance = 0.25,
        disposition_min = -20,
        disposition_max = 20,
        options = {
            {
                label = "Compromise",
                description = "Split the territory. Neither side gets everything.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The border was drawn with ink, not blood. Both sides left dissatisfied. That meant it was fair.",
                },
            },
            {
                label = "Claim it all",
                description = "This land is ours. It always was.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { physical = 2 },
                    narrative = "The full claim was pressed. {faction_name} retreated — for now. The border dispute simmered.",
                },
            },
            {
                label = "Joint stewardship",
                description = "Share the land. A radical idea.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = 3, creative = 1 },
                    narrative = "Joint stewardship was proposed and accepted. An experiment in cooperation. The cynics scoffed. The pragmatists nodded.",
                },
            },
        },
    },
}
