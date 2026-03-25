-- Bloodweight — Nemesis Events
-- Personal rivalry events that fire against the player's most hostile faction.
-- These use {rival_name} and {faction_name} substitution vars.
-- Requires: nemesis faction (disposition <= -40, rival heir alive).
return {
    -- 1. The rival sends a personal challenge
    {
        id = "nemesis_personal_challenge",
        title = "A Challenge from {rival_name}",
        narrative = "A messenger arrives bearing the personal seal of {rival_name}. Not the banner of {faction_name} — their own mark. The message is brief: meet them at the border stones, alone. Heir against heir. The bloodlines settle this themselves.",
        chance = 0.35,
        cooldown = 6,
        disposition_max = -40,
        requires_rival = true,
        options = {
            {
                label = "Accept the duel",
                description = "Honor demands it. Your blood against theirs.",
                stat_check = { primary = "PHY_STR", secondary = "MEN_WIL", difficulty = 55 },
                consequences = {
                    narrative = "{rival_name} fell to one knee. Not dead — they were too proud to die easily — but broken enough. {faction_name} remembered this day.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = 10 } },
                    lineage_power_shift = 5,
                    cultural_memory_shift = { physical = 3 },
                    rival_interaction = { rival_faction = "_target", event_type = "duel_loss", description = "Lost a personal duel to {heir_name}", rivalry_delta = -15 },
                },
                consequences_fail = {
                    narrative = "{rival_name} stood over {heir_name} and whispered something no chronicle recorded. When {heir_name} returned, they would not speak of what was said.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                    lineage_power_shift = -5,
                    cultural_memory_shift = { physical = -2 },
                    rival_interaction = { rival_faction = "_target", event_type = "duel_victory", description = "Defeated {heir_name} in personal combat", rivalry_delta = 15 },
                },
            },
            {
                label = "Send a champion in your place",
                description = "Let someone else bleed for the bloodline's pride.",
                consequences = {
                    narrative = "{rival_name} spat on the ground when the champion appeared. 'I asked for blood, not servants.' The duel was fought, but the insult of substitution cut deeper than any blade.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -8 } },
                    cultural_memory_shift = { social = -2 },
                    rival_interaction = { rival_faction = "_target", event_type = "refused_duel", description = "{heir_name} sent a proxy", rivalry_delta = 10 },
                },
            },
            {
                label = "Refuse — let them stew",
                description = "Denying them the fight is its own weapon.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    narrative = "No reply was sent. {rival_name} waited at the border stones for three days. When they finally left, something had changed in them — the hatred deepened into something quieter and more dangerous.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -15 } },
                    rival_interaction = { rival_faction = "_target", event_type = "ignored", description = "{heir_name} refused to acknowledge the challenge", rivalry_delta = 20 },
                },
            },
        },
    },

    -- 2. The rival attempts to poach a court member
    {
        id = "nemesis_court_theft",
        title = "{rival_name}'s Offer",
        narrative = "One of your court members comes forward, pale-faced, holding a letter. {rival_name} has offered them land, title, and protection — if they defect to {faction_name}. The letter is elegantly written. The offer is generous. The court member looks at you and waits.",
        chance = 0.30,
        cooldown = 8,
        disposition_max = -30,
        requires_rival = true,
        options = {
            {
                label = "Match the offer — keep their loyalty",
                description = "Gold buys what fear cannot.",
                consequences = {
                    narrative = "The counter-offer was accepted. The court member stayed — but everyone knew their price now. {rival_name}'s true weapon was not the letter, but the doubt it planted.",
                    resource_change = { { type = "gold", delta = -8 } },
                    cultural_memory_shift = { social = 1 },
                },
            },
            {
                label = "Let them go — and send a message back",
                description = "Loyalty cannot be bought. Demonstrate that.",
                requires = { axis = "PER_CRM", max = 40 },
                consequences = {
                    narrative = "The court member left with their letter and their shame. You sent nothing back to {rival_name}. The silence said enough.",
                    cultural_memory_shift = { social = -1 },
                    rival_interaction = { rival_faction = "_target", event_type = "court_theft", description = "Successfully poached a court member", rivalry_delta = 5 },
                },
            },
            {
                label = "Execute the traitor publicly",
                description = "Make an example. Let {rival_name} see what their meddling costs.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    narrative = "The court member's body was displayed at the gates. {rival_name} received the message — along with the unread letter, returned blood-stained. {faction_name} went quiet for a while after that.",
                    moral_act = { act_id = "cruelty", description = "Executed a court member for considering defection" },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 5 } },
                    cultural_memory_shift = { social = -3 },
                    rival_interaction = { rival_faction = "_target", event_type = "intimidation", description = "{heir_name} executed their agent", rivalry_delta = -10 },
                },
            },
        },
    },

    -- 3. The rival's bloodline produces something exceptional
    {
        id = "nemesis_heir_prodigy",
        title = "The Prodigy of {faction_name}",
        narrative = "Word reaches you: {rival_name}'s child has demonstrated extraordinary ability. The other houses speak of it in whispers — a prodigy, they say. A once-in-a-generation talent born to your greatest enemy. Your own bloodline watches you for a reaction.",
        chance = 0.25,
        cooldown = 10,
        disposition_max = -25,
        requires_rival = true,
        options = {
            {
                label = "Invest heavily in your own heir's education",
                description = "If they breed greatness, so will you.",
                consequences = {
                    narrative = "Tutors were summoned. Resources diverted. Your heir would not be outshone — not by {rival_name}'s brood, not by anyone. Whether the investment would pay was a question for the next generation.",
                    resource_change = { { type = "lore", delta = -5 }, { type = "gold", delta = -5 } },
                    cultural_memory_shift = { mental = 3 },
                },
            },
            {
                label = "Propose a marriage alliance",
                description = "If you can't outbreed them, absorb them.",
                stat_check = { primary = "SOC_CHA", secondary = "SOC_NEG", difficulty = 65 },
                consequences = {
                    narrative = "Against all expectation, {rival_name} accepted. Perhaps they saw the same advantage you did. The marriage would bind the bloodlines — but which would consume the other remained to be seen.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = 25 } },
                    cultural_memory_shift = { social = 4 },
                    rival_interaction = { rival_faction = "_target", event_type = "marriage_proposal", description = "Marriage alliance proposed and accepted", rivalry_delta = -30 },
                },
                consequences_fail = {
                    narrative = "{rival_name} returned the proposal with a single word written across it. The word was unprintable, but the meaning was clear.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                    rival_interaction = { rival_faction = "_target", event_type = "rejected_marriage", description = "Marriage proposal rejected contemptuously", rivalry_delta = 10 },
                },
            },
            {
                label = "Dismiss it — bloodlines prove themselves over generations, not moments",
                description = "One prodigy means nothing against the weight of legacy.",
                consequences = {
                    narrative = "You said nothing. Your court took the cue. The prodigy would either burn bright and die young, or prove their worth against time itself. Either way, your bloodline had endured worse than a talented rival.",
                },
            },
        },
    },

    -- 4. The rival sabotages a critical moment
    {
        id = "nemesis_sabotage",
        title = "Sabotage at {rival_name}'s Hand",
        narrative = "The crucible was rigged. The trade deal was poisoned. The alliance was undermined. Evidence points to {rival_name} — not {faction_name} as a whole, but them personally. This was not politics. This was personal.",
        chance = 0.30,
        cooldown = 5,
        disposition_max = -50,
        requires_rival = true,
        options = {
            {
                label = "Expose them publicly",
                description = "Drag their treachery into the light. Let every house see what they are.",
                stat_check = { primary = "SOC_AWR", secondary = "MEN_ANA", difficulty = 50 },
                consequences = {
                    narrative = "The evidence was presented at open court. {rival_name}'s denials rang hollow. {faction_name} lost standing with every house that witnessed the exposure.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -5 }, { faction_id = "all", delta = 5 } },
                    lineage_power_shift = 3,
                    rival_interaction = { rival_faction = "_target", event_type = "exposed", description = "Sabotage exposed publicly by {heir_name}", rivalry_delta = 20 },
                },
                consequences_fail = {
                    narrative = "The evidence was thin. {rival_name} turned the accusation into a performance — feigned outrage, wounded dignity. Your bloodline looked paranoid.",
                    lineage_power_shift = -3,
                    cultural_memory_shift = { social = -2 },
                },
            },
            {
                label = "Retaliate in kind — sabotage their next venture",
                description = "An eye for an eye. Let the shadow war begin.",
                stat_check = { primary = "MEN_CUN", secondary = "SOC_MAN", difficulty = 55 },
                consequences = {
                    narrative = "The counter-sabotage was elegant. {rival_name}'s harvest rotted, their forge cracked, their allies received interesting letters. The shadow war had begun in earnest.",
                    rival_interaction = { rival_faction = "_target", event_type = "counter_sabotage", description = "Retaliation sabotage", rivalry_delta = 10 },
                    cultural_memory_shift = { mental = 2 },
                },
                consequences_fail = {
                    narrative = "The agents were caught. {rival_name} displayed them at their gates — a mirror of your own methods. The war of shadows favored neither side.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                    moral_act = { act_id = "scheming", description = "Failed sabotage attempt against rival house" },
                },
            },
            {
                label = "Absorb the loss. Patience is the longest blade.",
                description = "Let them think they've won. The bloodline remembers.",
                consequences = {
                    narrative = "Nothing was said. Nothing was done. {rival_name} waited for the retaliation that never came — and the waiting was worse than any revenge.",
                    cultural_memory_shift = { mental = 1 },
                },
            },
        },
    },

    -- 5. The rival makes an unexpected peace offering
    {
        id = "nemesis_peace_offering",
        title = "An Olive Branch from {rival_name}",
        narrative = "{rival_name} arrives unannounced, unarmed, bearing gifts. No emissaries, no banners — just them, standing at your gate. 'Enough,' they say. 'Our grandfathers started this. We don't have to finish it.' The court holds its breath.",
        chance = 0.20,
        cooldown = 12,
        disposition_max = -30,
        disposition_min = -70,
        requires_rival = true,
        options = {
            {
                label = "Accept the peace",
                description = "End the feud. There are worse enemies than {rival_name}.",
                consequences = {
                    narrative = "Hands were clasped. Wine was poured. Neither side smiled, but neither reached for a blade. It was not friendship — it was exhaustion wearing the mask of wisdom. But it held.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = 30 } },
                    lineage_power_shift = 3,
                    rival_interaction = { rival_faction = "_target", event_type = "peace_accepted", description = "Peace offering accepted", rivalry_delta = -25 },
                },
            },
            {
                label = "Accept — but demand reparations first",
                description = "Peace has a price. Make sure they pay it.",
                stat_check = { primary = "SOC_NEG", difficulty = 50 },
                consequences = {
                    narrative = "{rival_name} paid. Gold, steel, and a public acknowledgment of past wrongs. The peace was bought, not earned — but bought things last longer than most people think.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = 20 } },
                    resource_change = { { type = "gold", delta = 10 }, { type = "steel", delta = 5 } },
                    rival_interaction = { rival_faction = "_target", event_type = "peace_with_cost", description = "Paid reparations for peace", rivalry_delta = -15 },
                },
                consequences_fail = {
                    narrative = "{rival_name} looked at the list of demands and their face hardened. 'I came here to end a war, not to be humiliated.' They left. The feud continued.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                    rival_interaction = { rival_faction = "_target", event_type = "peace_rejected", description = "Peace overture rejected due to excessive demands", rivalry_delta = 15 },
                },
            },
            {
                label = "Reject them — this ends when one house falls",
                description = "Some feuds can only end in blood.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    narrative = "{rival_name} nodded slowly, as if they had expected this. 'Then we continue.' They turned and walked back through the gate without looking back. The next time you saw them, it was across a battlefield.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -20 } },
                    cultural_memory_shift = { physical = 2 },
                    rival_interaction = { rival_faction = "_target", event_type = "peace_refused", description = "{heir_name} refused peace — chose continued war", rivalry_delta = 25 },
                },
            },
        },
    },

    -- 6. The rival's house is crumbling — exploit or assist?
    {
        id = "nemesis_falling",
        title = "The Fall of {rival_name}",
        narrative = "{faction_name} is collapsing. Their holdings burn. Their allies scatter. {rival_name} has sent no messengers, asked for no aid. But you can see them from the walls — alone on the road, watching their world end. Your oldest enemy, brought low.",
        chance = 0.30,
        cooldown = 10,
        faction_power_max = 25,
        disposition_max = -25,
        requires_rival = true,
        options = {
            {
                label = "Finish them",
                description = "They would have done the same. End the house.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    narrative = "It was quick. Not clean — these things never are — but quick. {faction_name} fell to the last. {rival_name} died as they lived: defiant, proud, and utterly alone. The feud was over. The silence that followed was not peace.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = -40 } },
                    faction_power_shift = -20,
                    moral_act = { act_id = "cruelty", description = "Destroyed a weakened rival house" },
                    lineage_power_shift = 5,
                    cultural_memory_shift = { physical = 2, social = -3 },
                },
            },
            {
                label = "Offer aid — on your terms",
                description = "A saved enemy becomes a bound servant. There are worse investments.",
                consequences = {
                    narrative = "{rival_name} accepted the aid. They had no choice. The debt was enormous, the terms crushing, and both sides knew it. But they lived. Whether gratitude or resentment grew from that debt would take a generation to learn.",
                    disposition_changes = { { faction_id = "{faction_id}", delta = 35 } },
                    resource_change = { { type = "gold", delta = -10 }, { type = "grain", delta = -8 } },
                    rival_interaction = { rival_faction = "_target", event_type = "saved", description = "{heir_name} saved the house from destruction", rivalry_delta = -40 },
                },
            },
            {
                label = "Do nothing. Watch.",
                description = "Let the world settle its own accounts.",
                consequences = {
                    narrative = "You watched from the walls as {faction_name} burned. {rival_name} never looked up. Perhaps they knew you were there. Perhaps they no longer cared. The fire burned for three days.",
                    cultural_memory_shift = { mental = 1 },
                },
            },
        },
    },
}
