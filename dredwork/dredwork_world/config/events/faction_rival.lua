-- Dark Legacy — Faction Events: Rival Heir
-- Events where named rival heirs confront the player's heir directly.
-- All require a living rival heir for the target faction (requires_rival = true).
return {
    -- ===================================================================
    -- HOSTILE RIVAL EVENTS (rival_attitude = "hostile" or low rivalry)
    -- ===================================================================
    {
        id = "rival_public_insult",
        title = "{rival_name} Spits at Your Name",
        narrative = "{rival_name} of {faction_name} denounces {heir_name} before a gathered court. Every word drips with contempt. The hall watches, waiting for a response.",
        chance = 0.3,
        requires_rival = true,
        requires_no_condition = "war",
        rival_attitude = "hostile",
        options = {
            {
                label = "Challenge them to single combat",
                description = "Answer insult with steel. End it now.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 3, social = -1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "duel_challenged",
                        description = "Challenged to single combat after a public insult.",
                        rivalry_delta = -15,
                    },
                    narrative = "{heir_name} drew steel before the words finished echoing. {rival_name} had no choice but to answer. The court would remember this.",
                },
            },
            {
                label = "Destroy them with words",
                description = "A sharper blade than any sword.",
                requires = { axis = "PER_CRM", max = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = 3, mental = 1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "humiliated",
                        description = "Humiliated with words before the entire court.",
                        rivalry_delta = -20,
                    },
                    narrative = "{heir_name} spoke calmly, precisely. By the time silence returned, {rival_name}'s reputation lay in tatters. No blade was needed.",
                },
            },
            {
                label = "Walk away in silence",
                description = "Deny them the satisfaction of a reaction.",
                requires = { axis = "PER_PRI", max = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "ignored",
                        description = "Public insult met with cold silence.",
                        rivalry_delta = -5,
                    },
                    narrative = "{heir_name} turned and left without a word. {rival_name} raged at the empty air. Some victories are silent.",
                },
            },
        },
    },
    {
        id = "rival_assassination_order",
        title = "{rival_name}'s Shadow",
        narrative = "A captured spy confesses under duress: {rival_name} of {faction_name} personally ordered your heir's death. This is not faction politics. This is personal.",
        chance = 0.2,
        requires_rival = true,
        rival_rivalry_max = -40,
        options = {
            {
                label = "Hunt {rival_name} personally",
                description = "End the source, not just the symptom.",
                requires = { axis = "PER_BLD", min = 60 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.6, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    cultural_memory_shift = { physical = 4, social = -2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "hunted",
                        description = "Personally hunted after ordering an assassination.",
                        rivalry_delta = -25,
                    },
                    narrative = "{heir_name} rode out with a war party bearing one name. The hunt for {rival_name} became the stuff of legend.",
                },
            },
            {
                label = "Expose them politically",
                description = "Let the world see what {rival_name} truly is.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    faction_power_shift = -15,
                    cultural_memory_shift = { social = 3, mental = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "exposed",
                        description = "Assassination plot exposed to all houses.",
                        rivalry_delta = -10,
                    },
                    narrative = "The confession was read before every court. {rival_name}'s name became synonymous with cowardice. {faction_name} distanced themselves — but the damage was done.",
                },
            },
            {
                label = "Spare them — demand a blood debt",
                description = "They owe you a life now. Collect later.",
                requires = { axis = "PER_CRM", max = 35 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "blood_debt",
                        description = "Spared after assassination attempt. A blood debt is owed.",
                        rivalry_delta = 15,
                    },
                    narrative = "{heir_name} sent a message to {rival_name}: 'You owe me a life.' The debt hung heavier than any blade.",
                },
            },
        },
    },

    -- ===================================================================
    -- WARY RIVAL EVENTS (tense but not yet violent)
    -- ===================================================================
    {
        id = "rival_border_standoff",
        title = "Face to Face with {rival_name}",
        narrative = "At the disputed border, {heir_name} and {rival_name} of {faction_name} meet unexpectedly. Their escorts bristle. Neither retreats. Every word could start a war.",
        chance = 0.3,
        requires_rival = true,
        requires_no_condition = "war",
        rival_attitude = "wary",
        options = {
            {
                label = "Offer to share the road",
                description = "Strength doesn't always mean fighting.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 8 } },
                    cultural_memory_shift = { social = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "parley",
                        description = "Shared the road at a border standoff. Tension eased.",
                        rivalry_delta = 10,
                    },
                    narrative = "{heir_name} stepped forward, unarmed. 'The road is wide enough.' {rival_name} hesitated, then nodded. A small step, but steps matter.",
                },
            },
            {
                label = "Hold ground and stare them down",
                description = "Let them blink first.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { physical = 1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "standoff",
                        description = "Border standoff — neither side backed down.",
                        rivalry_delta = -8,
                    },
                    narrative = "Two heirs, two bloodlines, two refusals to yield. The escorts grew nervous. Eventually, rain broke the standoff. Neither claimed victory.",
                },
            },
            {
                label = "Insult them and ride away",
                description = "Why waste words? Let them stew.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -12 } },
                    cultural_memory_shift = { social = -2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "insult",
                        description = "Insulted at the border crossing and left without parley.",
                        rivalry_delta = -15,
                    },
                    narrative = "{heir_name} spoke a single cutting sentence, wheeled their mount, and rode away. {rival_name}'s face said everything. This would not be forgotten.",
                },
            },
        },
    },
    {
        id = "rival_feast_encounter",
        title = "{rival_name} at the Feast",
        narrative = "A neutral lord's feast brings old enemies to the same table. {rival_name} of {faction_name} sits across from {heir_name}. Wine flows. Words could flow too.",
        chance = 0.25,
        requires_rival = true,
        requires_no_condition = { "war", "famine" },
        rival_attitude = "wary",
        options = {
            {
                label = "Raise a toast to old wounds",
                description = "Acknowledge the past. Perhaps move beyond it.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "toast",
                        description = "Shared a toast at a feast. Old wounds acknowledged.",
                        rivalry_delta = 12,
                    },
                    narrative = "{heir_name} raised a cup to {rival_name}. 'To the scars that made us.' The hall fell silent. Then {rival_name} drank. Barely, but they drank.",
                },
            },
            {
                label = "Watch them carefully, say nothing",
                description = "Learn what you can. Reveal nothing.",
                requires = { axis = "PER_OBS", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "observed",
                        description = "Watched silently at a feast. Learned their habits.",
                        rivalry_delta = 0,
                    },
                    narrative = "{heir_name} ate, drank, and watched. {rival_name}'s tells, their weaknesses, their alliances — all catalogued. The feast was productive, if cold.",
                },
            },
            {
                label = "Confront them about past wrongs",
                description = "No pretending. Not tonight.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    cultural_memory_shift = { social = -1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "confrontation",
                        description = "Confronted at a feast about past wrongs.",
                        rivalry_delta = -10,
                    },
                    narrative = "Wine loosened the words that pride demanded. {heir_name} spoke of old debts. {rival_name} bristled. The neutral lord looked ill. Some wounds are not ready for feasts.",
                },
            },
        },
    },

    -- ===================================================================
    -- NEUTRAL / RESPECTFUL RIVAL EVENTS (opportunities)
    -- ===================================================================
    {
        id = "rival_secret_meeting",
        title = "{rival_name} Requests a Private Word",
        narrative = "A sealed letter, delivered by hand: {rival_name} of {faction_name} wishes to speak privately. No guards, no witnesses. The letter smells faintly of ambition.",
        chance = 0.25,
        requires_rival = true,
        requires_no_condition = "war",
        rival_attitude = "neutral",
        options = {
            {
                label = "Meet them alone",
                description = "Risk it. Great alliances begin with trust.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 12 } },
                    cultural_memory_shift = { social = 2, mental = 1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "secret_meeting",
                        description = "Met privately. Trust was tested and given.",
                        rivalry_delta = 15,
                    },
                    narrative = "{heir_name} came alone. {rival_name} did the same. What was said between them, no chronicle records. But something shifted.",
                },
            },
            {
                label = "Bring hidden guards",
                description = "Trust is earned, not given.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    cultural_memory_shift = { mental = 1 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "cautious_meeting",
                        description = "Met with hidden protection. Cautious but willing.",
                        rivalry_delta = 5,
                    },
                    narrative = "{heir_name} came. So did a dozen unseen blades. {rival_name} noticed — they always notice — but said nothing. The meeting was productive. Almost.",
                },
            },
            {
                label = "Refuse the meeting",
                description = "This reeks of trap.",
                requires = { axis = "PER_LOY", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "snubbed",
                        description = "Refused a private meeting. Trust rejected.",
                        rivalry_delta = -8,
                    },
                    narrative = "The letter was returned unopened. {rival_name}'s offer died in silence. Perhaps wisely. Perhaps not.",
                },
            },
        },
    },
    {
        id = "rival_common_enemy",
        title = "{rival_name} Proposes an Alliance",
        narrative = "A greater threat emerges. {rival_name} of {faction_name} sends word: 'Our quarrel can wait. This enemy will devour us both.' A temporary pact, offered by a rival.",
        chance = 0.2,
        requires_rival = true,
        rival_attitude = "neutral",
        requires_generation_min = 5,
        options = {
            {
                label = "Accept the alliance",
                description = "The enemy of my enemy is useful.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    add_relationship = { type = "ally", strength = 40, reason = "common_enemy" },
                    cultural_memory_shift = { social = 3 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "alliance",
                        description = "Allied against a common enemy. Grudges paused.",
                        rivalry_delta = 20,
                    },
                    narrative = "{heir_name} and {rival_name} clasped hands. It was not friendship. It was necessity. But even necessity can build bridges.",
                },
            },
            {
                label = "Accept, but plan to betray them later",
                description = "Use them, then discard them.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { mental = 2, social = -2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "false_alliance",
                        description = "Accepted alliance with intent to betray.",
                        rivalry_delta = 10,
                    },
                    narrative = "{heir_name} smiled and clasped hands. Behind the smile, a different plan was forming. {rival_name} would learn the cost of trust — eventually.",
                },
            },
            {
                label = "Refuse — we handle our own problems",
                description = "No debts. No dependencies. Ever.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "alliance_rejected",
                        description = "Refused an offer of alliance against a common enemy.",
                        rivalry_delta = -10,
                    },
                    narrative = "'We stand alone,' {heir_name} replied. {rival_name} left in silence. The threat remained. But so did the bloodline's pride.",
                },
            },
        },
    },

    -- ===================================================================
    -- RESPECTFUL / DEVOTED RIVAL EVENTS
    -- ===================================================================
    {
        id = "rival_heir_tribute",
        title = "{rival_name} Brings a Gift",
        narrative = "{rival_name} of {faction_name} arrives bearing tribute — not from their faction, but from themselves. A personal offering. Rare. Unprecedented. The court whispers.",
        chance = 0.25,
        requires_rival = true,
        requires_no_condition = "war",
        rival_attitude = "respectful",
        options = {
            {
                label = "Accept graciously",
                description = "Honor the gesture. Return it in kind.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "tribute_accepted",
                        description = "Accepted a personal tribute with grace.",
                        rivalry_delta = 12,
                    },
                    narrative = "{heir_name} accepted the gift and offered one in return. {rival_name}'s eyes softened. Perhaps enemies are only enemies until they choose not to be.",
                },
            },
            {
                label = "Accept it, but remind them of the past",
                description = "Gifts don't erase history.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "tribute_qualified",
                        description = "Accepted tribute but invoked old grievances.",
                        rivalry_delta = 3,
                    },
                    narrative = "{heir_name} accepted, but spoke: 'A gift does not repay what was taken.' {rival_name} stiffened. The gesture was appreciated. The message received.",
                },
            },
            {
                label = "Refuse the tribute",
                description = "We cannot be bought.",
                requires = { axis = "PER_LOY", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -8 } },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "tribute_refused",
                        description = "Personal tribute refused. Loyalty to old grudges runs deep.",
                        rivalry_delta = -12,
                    },
                    narrative = "{rival_name}'s gift was returned unopened. The court gasped. Some wounds cannot be healed with trinkets.",
                },
            },
        },
    },
    {
        id = "rival_succession_crisis",
        title = "{rival_name}'s House Fractures",
        narrative = "Word reaches {heir_name}: {rival_name} of {faction_name} faces a succession crisis within their own house. They are vulnerable. Perhaps fatally so.",
        chance = 0.2,
        requires_rival = true,
        requires_generation_min = 3,
        options = {
            {
                label = "Strike while they're weak",
                description = "Crush them when they cannot fight back.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    faction_power_shift = -20,
                    cultural_memory_shift = { physical = 3, social = -3 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "betrayal",
                        description = "Attacked during a succession crisis. No mercy shown.",
                        rivalry_delta = -30,
                    },
                    narrative = "When {rival_name} was at their weakest, {heir_name} struck. History would call it decisive. {rival_name} would call it something else entirely.",
                },
            },
            {
                label = "Send aid to stabilize them",
                description = "A weakened rival is dangerous. A grateful one is useful.",
                requires = { axis = "PER_CRM", max = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    cultural_memory_shift = { social = 3 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "aid_given",
                        description = "Sent aid during a succession crisis. A debt of honor.",
                        rivalry_delta = 25,
                    },
                    narrative = "{heir_name} sent soldiers and supplies to {rival_name}'s aid. Not for friendship. For the future. {rival_name} survived — and would remember.",
                },
            },
            {
                label = "Watch and wait",
                description = "Let them solve their own problems. Take notes.",
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    rival_interaction = {
                        rival_faction = "_target",
                        event_type = "observed",
                        description = "Watched a succession crisis unfold without intervening.",
                        rivalry_delta = -3,
                    },
                    narrative = "Scouts reported daily. {heir_name} listened, planned, and did nothing. {rival_name} survived. They noticed who helped — and who watched.",
                },
            },
        },
    },
}
