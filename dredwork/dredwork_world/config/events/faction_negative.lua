-- Dark Legacy — Faction Events: Negative
-- Hostile faction interactions
return {
    {
        id = "faction_betrayal",
        title = "Treachery from {faction_name}",
        narrative = "Word reaches {heir_name}: {faction_name} has broken their word. Agreements lie in ashes. {rumor_1}",
        chance = 0.35,
        disposition_max = -20,
        options = {
            {
                label = "Exact vengeance",
                description = "They will learn the cost of betrayal.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.5, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    add_relationship = { type = "enemy", strength = 80, reason = "betrayal" },
                    taboo_chance = 0.5,
                    taboo_data = { trigger = "betrayed_by_faction", effect = "will_never_ally_with_{faction_id}", strength = 85 },
                    cultural_memory_shift = { physical = 3, social = -3 },
                    narrative = "Vengeance was swift and terrible. {faction_name} learned that betrayal has a price written in blood.",
                },
            },
            {
                label = "Swallow the insult",
                description = "Survival is more important than pride.",
                requires = { axis = "PER_PRI", max = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = -2 },
                    narrative = "The betrayal went unanswered. Some called it wisdom. Others whispered 'weakness'.",
                },
            },
            {
                label = "Seek justice through others",
                description = "Turn the other houses against them.",
                requires = { axis = "PER_CRM", max = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    faction_power_shift = -10,
                    cultural_memory_shift = { social = 2 },
                    narrative = "Word of the betrayal was spread. {faction_name}'s reputation suffered. Justice came, slow but certain.",
                },
            },
            {
                label = "Crush them utterly",
                description = "No justice. No mercy. Annihilation.",
                requires_lineage_power_min = 80,
                consequences = {
                    add_condition = { type = "war", intensity = 0.8, duration = 3 },
                    disposition_changes = { { faction_id = "_target", delta = -50 } },
                    faction_power_shift = -25,
                    add_relationship = { type = "enemy", strength = 95, reason = "annihilation" },
                    taboo_chance = 0.7,
                    taboo_data = { trigger = "crushed_faction", effect = "dynasty_of_fear", strength = 90 },
                    cultural_memory_shift = { physical = 5, social = -5 },
                    moral_act = "cruelty",
                    narrative = "The full weight of the bloodline fell upon {faction_name}. What remained was barely a faction. A message, written in ruins.",
                },
            },
        },
    },
    {
        id = "assassination_attempt",
        title = "A Blade in the Dark",
        narrative = "An assassin bearing {faction_name}'s seal was caught in the family quarters. The intent was clear.",
        chance = 0.2,
        disposition_max = -50,
        faction_type = "diplomats",
        options = {
            {
                label = "Hunt the conspirators",
                description = "Find everyone involved. Leave no shadow unsearched.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    cultural_memory_shift = { physical = 3, mental = 2 },
                    narrative = "The hunt was relentless. Those responsible were found and dealt with. The message was clear.",
                },
            },
            {
                label = "Increase security",
                description = "Triple the guard. Trust no one outside the blood.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    narrative = "Security was tripled. The family fortress became impenetrable. But the walls felt like a prison.",
                },
            },
            {
                label = "Send one back",
                description = "Return the message. In kind.",
                requires = { axis = "PER_CRM", min = 65 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    cultural_memory_shift = { physical = 2, social = -4 },
                    taboo_chance = 0.30,
                    taboo_data = { trigger = "sent_assassin", effect = "deals_in_shadows", strength = 70 },
                    narrative = "An assassin was sent in return. What happened next, only the shadows know.",
                },
            },
        },
    },
    {
        id = "faction_slander",
        title = "Lies from {faction_name}",
        narrative = "Vicious lies about the bloodline spread through every court. The source: {faction_name}.",
        chance = 0.3,
        disposition_max = -15,
        faction_type = "diplomats",
        options = {
            {
                label = "Counter with truth",
                description = "Set the record straight. Let facts defeat fiction.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = 2, mental = 1 },
                    narrative = "The truth was spoken clearly and widely. The lies crumbled — mostly. Some mud always sticks.",
                },
            },
            {
                label = "Respond with force",
                description = "Words are answered with steel in this family.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { physical = 2, social = -2 },
                    narrative = "The response was not diplomatic. {faction_name} learned that some families answer slander with swords.",
                },
            },
            {
                label = "Rise above it",
                description = "The name speaks for itself. We need not stoop.",
                requires = { axis = "PER_PRI", max = 55 },
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "Silence was the response. Dignified silence. The world noticed the contrast.",
                },
            },
        },
    },
    {
        id = "economic_warfare",
        title = "{faction_name} Blocks the Roads",
        narrative = "Trade routes are closed. Markets refuse your merchants. {faction_name} wages war with gold instead of steel.",
        chance = 0.25,
        disposition_max = -30,
        faction_type = "artisans",
        options = {
            {
                label = "Break through by force",
                description = "Open the roads ourselves.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.3, duration = 2 },
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { physical = 3 },
                    narrative = "The blockade was broken by force. Trade flowed again — over the bodies of those who tried to stop it.",
                },
            },
            {
                label = "Find new trade routes",
                description = "If the old roads are closed, carve new ones.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    narrative = "New routes were found. The blockade became irrelevant. Innovation defeats obstruction.",
                },
            },
            {
                label = "Submit to their terms",
                description = "Survival demands compromise.",
                requires = { axis = "PER_PRI", max = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = -3 },
                    narrative = "Terms were accepted. Humiliating terms. But the markets reopened.",
                },
            },
        },
    },
    {
        id = "border_raid",
        title = "Raiders from {faction_name}",
        narrative = "Armed raiders bearing the colors of {faction_name} strike at your borders. Livestock taken. Buildings burned.",
        chance = 0.3,
        disposition_max = -25,
        faction_type = "warriors",
        options = {
            {
                label = "Retaliate in force",
                description = "Strike back harder. Make them regret it.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 3 },
                    mutation_triggers = { { type = "war", intensity = 0.3 } },
                    narrative = "Retaliation was swift and devastating. The raiders would not return soon.",
                },
            },
            {
                label = "Demand ransom for damages",
                description = "Put a price on their aggression.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = 1, mental = 1 },
                    narrative = "A formal demand for reparations was sent. Whether it would be honored was another matter.",
                },
            },
            {
                label = "Fortify the border",
                description = "Build walls. Plant watchtowers. Never again.",
                consequences = {
                    cultural_memory_shift = { physical = 2 },
                    narrative = "The border was fortified. Stone and iron replaced empty fields. Let them try again.",
                },
            },
        },
    },
    {
        id = "vulture_extortion",
        title = "{faction_name} Senses Weakness",
        narrative = "With the bloodline's coffers near empty, {faction_name} has arrived with a 'protective' offer that looks very much like extortion.",
        chance = 0.5,
        requires_wealth_max = 25,
        options = {
            {
                label = "Pay their price",
                description = "It is better to be poor than broken.",
                consequences = {
                    wealth_change = { delta = -10, source = "loss", description = "Extorted by {faction_name}" },
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = -3 },
                    narrative = "The gold was handed over. {faction_name} smiled and left... for now. The bloodline's pride felt the weight.",
                },
            },
            {
                label = "Refuse and resist",
                description = "We may be poor, but we are not prey.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    lineage_power_shift = -5,
                    add_condition = { type = "war", intensity = 0.3, duration = 2 },
                    narrative = "The refusal was met with cold silence. {faction_name} withdrew, but the tension in the air is thick enough to cut.",
                },
            },
        },
    },
    {
        id = "political_vulture",
        title = "{faction_name} Challenges Your Authority",
        narrative = "The bloodline's name no longer commands the respect it once did. {faction_name} is publicly questioning your house's right to lead.",
        chance = 0.5,
        requires_lineage_power_max = 30,
        faction_type = "diplomats",
        options = {
            {
                label = "Counter with diplomacy",
                description = "Words must bridge the gap that power cannot.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The challenge was met with honeyed words and careful negotiation. The crisis was averted, but the foundation remains shaky.",
                },
            },
            {
                label = "Reassert dominance through blood",
                description = "Make an example of a dissident.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    lineage_power_shift = 10,
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                    moral_act = { act_id = "harsh_justice", description = "Brutally suppressed dissenters" },
                    narrative = "A message was sent in iron and shadow. Dissent was silenced, and the name of the bloodline carries a new, darker weight.",
                },
            },
        },
    },
    {
        id = "vassal_rebellion",
        title = "Open Rebellion",
        narrative = "Sensing the bloodline's diminished power, a lesser branch aligned with {faction_name} has raised their banners in open defiance.",
        chance = 0.5,
        requires_lineage_power_max = 20,
        options = {
            {
                label = "Crush the rebellion",
                description = "There is only one punishment for treason.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.6, duration = 3 },
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    lineage_power_shift = 8,
                    cultural_memory_shift = { physical = 4, social = -2 },
                    narrative = "The banners were torn down. The rebel leaders were executed. The bloodline's grip tightened, but the cost in blood was high.",
                },
            },
            {
                label = "Grant them autonomy",
                description = "Let them go. The bloodline cannot afford this war.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    lineage_power_shift = -12,
                    wealth_change = { delta = -10, source = "loss", description = "Loss of vassal tribute" },
                    cultural_memory_shift = { social = 2, physical = -2 },
                    narrative = "The rebels were granted their freedom. The bloodline was diminished, a shadow of its former self.",
                },
            },
            {
                label = "Assassinate the leaders",
                description = "Cut off the head, and the body will die.",
                requires = { axis = "PER_CRM", min = 65 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -40 } },
                    lineage_power_shift = 5,
                    cultural_memory_shift = { mental = 3, social = -3 },
                    moral_act = { act_id = "murder", description = "Assassinated rebel leaders" },
                    taboo_chance = 0.4,
                    taboo_data = { trigger = "rebel_assassination", effect = "rules_by_terror", strength = 80 },
                    narrative = "The rebellion ended not on a battlefield, but in the dark. The leaders died screaming, and the rest scattered.",
                },
            },
        },
    },
    {
        id = "the_debt_collectors",
        title = "The Debt Collectors",
        narrative = "Agents from {faction_name} have arrived. The bloodline's debts are due, and the coffers are empty. They demand ancestral relics as payment.",
        chance = 0.5,
        requires_wealth_max = 15,
        options = {
            {
                label = "Surrender the relics",
                description = "A humiliating defeat, but the debt is paid.",
                consequences = {
                    wealth_change = { delta = 15, source = "investment", description = "Forced liquidation of relics" },
                    lineage_power_shift = -10,
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    cultural_memory_shift = { creative = -4, physical = -2, mental = -2, social = -2 },
                    narrative = "The ancestral swords and crowns were loaded into carts. {faction_name} rode away with the bloodline's pride.",
                },
            },
            {
                label = "Refuse payment",
                description = "We owe them nothing. Let them try to take it.",
                requires = { axis = "PER_PRI", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -30 } },
                    lineage_power_shift = 5,
                    cultural_memory_shift = { physical = 2, social = -2 },
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    narrative = "The collectors were sent back empty-handed. {faction_name} will not forget this insult, and swords are already being sharpened.",
                },
            },
            {
                label = "Offer a marriage pact instead",
                description = "Trade blood instead of gold.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    add_relationship = { type = "ally", strength = 50, reason = "debt_marriage" },
                    arranged_marriage_lock = true,
                    cultural_memory_shift = { social = 3 },
                    narrative = "A son or daughter was pledged to {faction_name}. The debt was forgiven, but the bloodline's future was sold.",
                },
            },
        },
    },
}
