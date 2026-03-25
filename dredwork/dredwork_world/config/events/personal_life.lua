-- Bloodweight — Personal Life Events
-- Rich autonomous events that fire based on personality axes.
-- These expand the chronicler's palette with domestic, philosophical, and visceral moments.
-- 24 events across all 8 personality axes (3 per axis).

return {
    -- ═══════════════════════════════════════════════════════════════════
    -- BOLDNESS
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "swam_the_black_river",
        title = "The Black River Crossing",
        narrative = "The bridge was gone. The army waited for engineers. {heir_name} stripped off the armor and swam.",
        trigger_axis = "PER_BLD",
        trigger_min = 65,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { physical = 2 },
            narrative = "The current was lethal. The water was freezing. {heir_name} reached the other side and stood dripping, waving the army forward. Half of them followed. It was enough.",
        },
    },
    {
        id = "hid_during_the_siege",
        title = "Found in the Cellar",
        narrative = "When the walls were breached, the servants searched for {heir_name}. Found them in the wine cellar. Behind the barrels.",
        trigger_axis = "PER_BLD",
        trigger_max = 30,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { social = -3, mental = 1 },
            disposition_changes = { { faction_id = "all", delta = -4 } },
            narrative = "The heir survived. The family's pride did not. Generations would whisper about the barrels.",
        },
    },
    {
        id = "climbed_the_tower_alone",
        title = "The Tower at Dawn",
        narrative = "No rope. No reason. {heir_name} climbed the ruined tower before sunrise, alone, and sat at the top watching the world wake up.",
        trigger_axis = "PER_BLD",
        trigger_min = 55,
        chance = 0.25,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { creative = 1, physical = 1 },
            narrative = "Asked why, {heir_name} said nothing. Some acts of courage are not for anyone else. They are simply proof that you are still alive.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- CRUELTY / MERCY
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "forgave_the_assassin",
        title = "The Assassin's Pardon",
        narrative = "The blade missed by an inch. The assassin was captured, trembling. {heir_name} looked at them for a long time. Then unlocked the chains.",
        trigger_axis = "PER_CRM",
        trigger_max = 30,
        chance = 0.2,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { social = 3 },
            disposition_changes = { { faction_id = "all", delta = 3 } },
            narrative = "The assassin vanished into the night. The court called it madness. The heir called it the only thing they could live with.",
        },
    },
    {
        id = "burned_the_fields",
        title = "Salt and Ash",
        narrative = "The enemy sued for peace. {heir_name} accepted the surrender, then burned their fields anyway. 'So they remember.'",
        trigger_axis = "PER_CRM",
        trigger_min = 70,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { physical = 2, social = -4 },
            disposition_changes = { { faction_id = "all", delta = -8 } },
            moral_act = { act_id = "cruelty", description = "Burned surrendered enemy's fields" },
            narrative = "Peace came. But the smoke rose for weeks. The surrendered house would never forget. Neither would anyone else.",
        },
    },
    {
        id = "paid_the_widows",
        title = "Gold for the Fallen",
        narrative = "After the battle, {heir_name} personally visited every household that lost someone. Left gold. Said nothing.",
        trigger_axis = "PER_CRM",
        trigger_max = 40,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { social = 2 },
            disposition_changes = { { faction_id = "all", delta = 2 } },
            narrative = "It did not bring anyone back. It was not meant to. Some debts cannot be paid. {heir_name} paid them anyway.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- LOYALTY
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "refused_the_crown",
        title = "The Crown Refused",
        narrative = "They offered {heir_name} leadership of the coalition. Greater power. Greater reach. The answer was immediate: no. The bloodline comes first.",
        trigger_axis = "PER_LOY",
        trigger_min = 70,
        chance = 0.2,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { social = 1, mental = 1 },
            narrative = "The coalition found another leader. {heir_name} returned home to tend to the family's walls. The lords thought it foolish. The bloodline endured.",
        },
    },
    {
        id = "sold_the_secret",
        title = "Information Has a Price",
        narrative = "A rival offered gold for a family secret. {heir_name} named a higher number. The deal was struck before sunset.",
        trigger_axis = "PER_LOY",
        trigger_max = 30,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { social = -3, mental = 1 },
            disposition_changes = { { faction_id = "all", delta = -4 } },
            narrative = "The gold was spent quickly. The secret, once sold, could never be reclaimed. Trust is a resource that does not regenerate.",
        },
    },
    {
        id = "walked_into_exile",
        title = "Followed Them Into Nothing",
        narrative = "When the disgraced advisor was exiled, {heir_name} walked out beside them. No announcement. No return date. Just boots on the road.",
        trigger_axis = "PER_LOY",
        trigger_min = 80,
        chance = 0.2,
        cooldown = 12,
        consequence = {
            cultural_memory_shift = { social = 3, physical = -1 },
            disposition_changes = { { faction_id = "all", delta = -2 } },
            narrative = "They returned together, months later, changed by the road. The court could not decide if it was loyalty or insanity. Perhaps both.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- OBSESSION
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "rebuilt_the_ruin",
        title = "Stone by Stone",
        narrative = "{heir_name} found an ancient ruin on the estate. Began rebuilding it. Alone. By hand. The project consumed three seasons.",
        trigger_axis = "PER_OBS",
        trigger_min = 65,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { creative = 2, physical = 1 },
            narrative = "The ruin stood again, imperfect but real. No one understood why it mattered. {heir_name} never explained.",
        },
    },
    {
        id = "forgot_the_childs_name",
        title = "The Name Forgotten",
        narrative = "So deep in the work that {heir_name} forgot their own child's name. Asked a servant. The servant stared.",
        trigger_axis = "PER_OBS",
        trigger_min = 80,
        chance = 0.2,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { mental = 2, social = -3 },
            narrative = "The work was extraordinary. The cost was invisible — measured in missed years and hollow stares across the dinner table.",
        },
    },
    {
        id = "gave_up_the_masterwork",
        title = "Walked Away at the Summit",
        narrative = "The masterwork was nearly complete. Months of labor. {heir_name} looked at it, set down the tools, and left the workshop forever.",
        trigger_axis = "PER_OBS",
        trigger_max = 30,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { creative = -2 },
            narrative = "An almost-masterwork gathered dust. The servants were forbidden from touching it. It became a monument to what focus might have been.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- CURIOSITY
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "opened_the_tomb",
        title = "The Ancestor's Tomb",
        narrative = "The tomb was sealed for a reason. The priests begged. The elders refused. {heir_name} brought a crowbar.",
        trigger_axis = "PER_CUR",
        trigger_min = 70,
        chance = 0.25,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { mental = 3, creative = 1 },
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.3 } },
            narrative = "Inside: nothing terrible. Just bones and a letter no one had read in centuries. What it said changed the family's understanding of itself.",
        },
    },
    {
        id = "refused_the_map",
        title = "Terra Incognita Declined",
        narrative = "A cartographer arrived with maps of unknown lands. {heir_name} paid them, thanked them, and filed the maps in a locked drawer.",
        trigger_axis = "PER_CUR",
        trigger_max = 35,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { mental = -1 },
            narrative = "The unknown remained unknown. The family stayed within its borders. Safety is a kind of prison, but the walls are comfortable.",
        },
    },
    {
        id = "tasted_the_poison",
        title = "A Measured Sip",
        narrative = "A bottle of suspected poison was brought to {heir_name} for identification. They uncorked it and drank.",
        trigger_axis = "PER_CUR",
        trigger_min = 80,
        chance = 0.15,
        cooldown = 12,
        consequence = {
            cultural_memory_shift = { mental = 2, physical = -1 },
            narrative = "It was poison. Not lethal at that dose, but {heir_name} was ill for a week. 'Now I know what it tastes like,' they said, and the physicians despaired.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- PRIDE
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "rewrote_the_histories",
        title = "The Revised Chronicle",
        narrative = "{heir_name} commissioned a new history of the bloodline. The embarrassments were removed. The victories were expanded. The truth became optional.",
        trigger_axis = "PER_PRI",
        trigger_min = 70,
        chance = 0.25,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { creative = 1, social = -1 },
            narrative = "The new chronicle was beautiful and mostly fictional. Future generations would read it as fact. History belongs to those who write it.",
        },
    },
    {
        id = "served_the_meal",
        title = "The Heir in the Kitchen",
        narrative = "Harvest festival. {heir_name} dismissed the servants and served every dish personally. Washed the plates afterward.",
        trigger_axis = "PER_PRI",
        trigger_max = 30,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { social = 2 },
            disposition_changes = { { faction_id = "all", delta = 3 } },
            narrative = "The lords did not know what to make of it. The servants wept. {heir_name} scrubbed the pots and said nothing about it the next day.",
        },
    },
    {
        id = "challenged_the_bard",
        title = "The Song Corrected",
        narrative = "A bard sang a ballad about the bloodline. Minor inaccuracies. {heir_name} interrupted mid-verse to correct the genealogy. In front of the entire court.",
        trigger_axis = "PER_PRI",
        trigger_min = 60,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { social = -1, creative = 1 },
            narrative = "The bard was mortified. The court was amused. {heir_name} was satisfied. The corrected version was, admittedly, more accurate.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- VOLATILITY
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "laughed_at_the_funeral",
        title = "Laughter in the Crypt",
        narrative = "Mid-eulogy. The silence of the crypt. And then {heir_name} started laughing. Not cruelly. Not madly. Just... laughing.",
        trigger_axis = "PER_VOL",
        trigger_min = 70,
        chance = 0.2,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { social = -2, creative = 1 },
            narrative = "Some walked out. Some joined in. The dead would have understood, or not. It didn't matter. {heir_name}'s grief had found its own shape.",
        },
    },
    {
        id = "unmoved_by_birth",
        title = "The Child Held at Arm's Length",
        narrative = "The firstborn was placed in {heir_name}'s arms. The court waited for the expected joy. Nothing came. A nod. A glance. The child was handed to the nurse.",
        trigger_axis = "PER_VOL",
        trigger_max = 25,
        chance = 0.25,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { social = -2 },
            narrative = "The child would grow up wondering. Was it coldness? Was it fear? The truth was simpler: {heir_name} felt everything. They just felt it later. Alone.",
        },
    },
    {
        id = "smashed_the_heirloom",
        title = "The Shattered Goblet",
        narrative = "The goblet had been in the family for eleven generations. {heir_name} threw it against the wall mid-argument. The room went silent.",
        trigger_axis = "PER_VOL",
        trigger_min = 75,
        chance = 0.2,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { creative = -1, social = -2 },
            narrative = "Eleven generations of memory in a thousand pieces on the floor. The argument was forgotten by morning. The goblet was not.",
        },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- ADAPTABILITY
    -- ═══════════════════════════════════════════════════════════════════
    {
        id = "adopted_enemy_customs",
        title = "The Enemy's Feast",
        narrative = "After the conquest, {heir_name} adopted the defeated people's harvest festival. Celebrated it in full. The conquered wept — not from grief, but recognition.",
        trigger_axis = "PER_ADA",
        trigger_min = 70,
        chance = 0.25,
        cooldown = 10,
        pick_faction = true,
        consequence = {
            cultural_memory_shift = { social = 3, creative = 1 },
            disposition_changes = { { faction_id = "all", delta = 3 } },
            narrative = "The old guard fumed. The conquered people stood a little taller. {heir_name} understood that victory without integration is just delayed rebellion.",
        },
    },
    {
        id = "refused_new_weapons",
        title = "The Ancestral Blade",
        narrative = "New forging techniques produced superior weapons. {heir_name} ordered the old blades kept. 'My grandfather's sword was good enough for him.'",
        trigger_axis = "PER_ADA",
        trigger_max = 30,
        chance = 0.25,
        cooldown = 8,
        consequence = {
            cultural_memory_shift = { physical = -1, creative = -1 },
            narrative = "The old blades were beautiful. They were also inferior. Tradition is a heavy thing to carry into battle.",
        },
    },
    {
        id = "learned_to_farm",
        title = "Dirt Under Noble Nails",
        narrative = "Famine threatened. Rather than delegate, {heir_name} went into the fields. Learned the planting. Broke the soil alongside the peasants for a full season.",
        trigger_axis = "PER_ADA",
        trigger_min = 60,
        chance = 0.25,
        cooldown = 10,
        consequence = {
            cultural_memory_shift = { physical = 1, social = 1 },
            narrative = "An heir of the blood, knee-deep in mud, learning what grows and what dies. The harvest was modest. The lesson was not.",
        },
    },
}
