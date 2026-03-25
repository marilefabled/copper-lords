-- Dark Legacy — Personal Events: Volatility
return {
    {
        id = "volatile_outburst",
        title = "A Storm Erupts",
        narrative = "{heir_name} erupted during negotiations. Words were said that cannot be unsaid.",
        trigger_axis = "PER_VOL",
        trigger_min = 70,
        chance = 0.45,
        pick_faction = true,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -8 } },
            cultural_memory_shift = { social = -3 },
            narrative = "{heir_name} erupted during negotiations. Words were said that cannot be unsaid.",
        },
    },
    {
        id = "emotionless_response",
        title = "The Empty Gaze",
        narrative = "Showed nothing. Not grief. Not rage. Nothing.",
        trigger_axis = "PER_VOL",
        trigger_max = 25,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { social = -2 },
            narrative = "When tragedy struck, {heir_name} showed nothing. The court was more unsettled by the silence than they would have been by tears.",
        },
    },
    {
        id = "berserker_rage",
        title = "The Red Fury",
        narrative = "Destroyed the great hall with bare hands. No one could stop it. No one dared try.",
        trigger_axis = "PER_VOL",
        trigger_min = 90,
        chance = 0.2,
        consequence = {
            disposition_changes = { { faction_id = "all", delta = -12 } },
            cultural_memory_shift = { physical = 3, social = -5, creative = -3 },
            taboo_chance = 0.20,
            taboo_data = { trigger = "berserker_rage", effect = "blood_rage", strength = 70 },
            narrative = "An explosion of pure violence. The great hall was destroyed. The bloodline's reputation would carry the scar.",
        },
    },
    -- NEW: MID-HIGH — volatility as beauty, not destruction
    {
        id = "wept_at_beauty",
        title = "Tears During the Ceremony",
        narrative = "A song was played. {heir_name} began weeping. Not grief. Not pain. The music simply reached something no wall could protect.",
        trigger_axis = "PER_VOL",
        trigger_min = 55,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { creative = 2 },
            narrative = "The court did not know what to do. An heir of the blood, crying over a song. Some were embarrassed. Some envied the capacity to feel that deeply.",
        },
    },
    -- NEW: MID-LOW — composure under pressure
    {
        id = "stone_during_triumph",
        title = "Victory Without Celebration",
        narrative = "A great victory was won. The court erupted in celebration. {heir_name} gave a single nod. Then retired to their chambers. Alone.",
        trigger_axis = "PER_VOL",
        trigger_max = 40,
        chance = 0.3,
        consequence = {
            cultural_memory_shift = { mental = 1, social = -1 },
            narrative = "The celebration continued without them. The servants whispered that the heir felt nothing. The heir simply felt it privately.",
        },
    },
    -- NEW: ALT-HIGH — volatility as passion, not violence
    {
        id = "embraced_then_vanished",
        title = "The Embrace and the Door",
        narrative = "Held the advisor close. Whispered something no one else could hear. Then walked out into the rain and did not return for three days.",
        trigger_axis = "PER_VOL",
        trigger_min = 65,
        chance = 0.25,
        consequence = {
            cultural_memory_shift = { social = -1, creative = 1 },
            narrative = "{heir_name} lived at the mercy of their own feelings. The intensity was terrifying. It was also, unmistakably, alive.",
        },
    },
}
