-- Dark Legacy — Personal Events: Cruelty / Mercy
return {
    {
        id = "cruel_judgment",
        title = "A Merciless Judgment",
        narrative = "{heir_name} passed a sentence that left the court in silence. The punishment fit no crime that anyone could name.",
        trigger_axis = "PER_CRM",
        trigger_min = 75,
        chance = 0.35,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -6 } },
            cultural_memory_shift = { social = -3, physical = 1 },
            taboo_chance = 0.15,
            taboo_data = { trigger = "cruel_judgment", effect = "feared_by_vassals", strength = 50 },
            narrative = "{heir_name}'s judgment was swift and terrible. Fear settled over the court like frost.",
        },
    },
    {
        id = "mercy_exploited",
        title = "Mercy Repaid with Steel",
        narrative = "The prisoner {heir_name} released returned with an army.",
        trigger_axis = "PER_CRM",
        trigger_max = 25,
        chance = 0.35,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { social = -3 },
            disposition_changes = { { faction_id = "all", delta = -5 } },
            mutation_triggers = { { type = "war", intensity = 0.2 } },
            narrative = "The prisoner was shown mercy. Mercy was not returned. The bloodline paid in blood.",
        },
    },
    {
        id = "atrocity_committed",
        title = "What Cannot Be Written",
        narrative = "What {heir_name} did that day cannot be written. The witnesses refuse to speak of it.",
        trigger_axis = "PER_CRM",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -15 } },
            cultural_memory_shift = { physical = 2, social = -5 },
            taboo_chance = 0.50,
            taboo_data = { trigger = "atrocity", effect = "house_of_cruelty", strength = 90 },
            narrative = "An unspeakable act. The world recoiled. The bloodline was stained forever.",
        },
    },
    -- NEW: MID-LOW — mercy as quiet strength
    {
        id = "nursed_the_dying",
        title = "Hands in the Plague Ward",
        narrative = "Three weeks in the dying ward. No gloves. No mask. {heir_name} held their hands until they stopped shaking.",
        trigger_axis = "PER_CRM",
        trigger_max = 35,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = 3 },
            disposition_changes = { { faction_id = "all", delta = 3 } },
            narrative = "The heir walked among the dying and did not flinch. Some said it was foolish. The dying said nothing. They just held on.",
        },
    },
    -- NEW: MID-HIGH — cruelty as cold precision
    {
        id = "the_quiet_punishment",
        title = "The Silence",
        narrative = "No shout. No strike. {heir_name} simply stopped speaking to them. For months. The offender eventually begged for any punishment but this.",
        trigger_axis = "PER_CRM",
        trigger_min = 60,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { mental = 2, social = -1 },
            narrative = "The silence was worse than any blade. The court learned that {heir_name}'s cruelty required no violence at all.",
        },
    },
    -- NEW: ALT-LOW — mercy with consequences the heir accepts
    {
        id = "fed_the_enemys_children",
        title = "Bread for the Other Side",
        narrative = "War orphans from the losing side arrived starving. {heir_name} fed them from the family stores. The generals were furious.",
        trigger_axis = "PER_CRM",
        trigger_max = 40,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { social = 2, physical = -1 },
            disposition_changes = { { faction_id = "all", delta = 1 } },
            narrative = "It cost grain the army needed. It gained nothing strategically. {heir_name} did it anyway.",
        },
    },
}
