-- Bloodweight — World Events: Resource Scarcity Crises
-- Fires when a resource hits 0, forcing desperate choices.
return {
    -- ═══════════════════════════════════════════════════════
    -- GRAIN = 0: THE STARVING
    -- ═══════════════════════════════════════════════════════
    {
        id = "scarcity_grain_crisis",
        title = "The Empty Granary",
        narrative = "The granaries echo. Not a kernel remains. The youngest children cry in the night, and the servants have begun to eye the seed stock.",
        chance = 0.85,
        cooldown = 5,
        requires_resource_max = { type = "grain", value = 0 },
        requires_no_condition = "famine",
        options = {
            {
                label = "Buy grain at ruinous prices",
                description = "Gold buys bread. Gold buys survival. Gold buys time.",
                requires_resources = { type = "gold", min = 15 },
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -15, reason = "Emergency grain purchases" },
                        { type = "grain", delta = 10, reason = "Purchased at famine prices" },
                    },
                    narrative = "The merchants descended like crows, and the family paid triple for grain that should have cost nothing. But the children stopped crying.",
                },
            },
            {
                label = "Slaughter the livestock",
                description = "Meat now. No milk, no wool, no draught animals later.",
                consequences = {
                    resource_change = { type = "grain", delta = 6, reason = "Butchered livestock" },
                    cultural_memory_shift = { physical = -2 },
                    lineage_power_shift = -3,
                    narrative = "The animals screamed. The family ate. But next season there would be nothing to pull the plows.",
                },
            },
            {
                label = "Demand tribute from a house",
                description = "Those who call themselves allies can prove it with bushels.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    resource_change = { type = "grain", delta = 8, reason = "Extorted grain" },
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    moral_act = { act_id = "exploitation", description = "Extorted grain from rival houses during famine" },
                    narrative = "Riders were sent with a simple message: feed us, or face us. The grain arrived. So did the resentment.",
                },
            },
            {
                label = "Let the weak starve",
                description = "The bloodline cannot afford sentiment. Feed only those who matter.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    resource_change = { type = "grain", delta = 3, reason = "Rationed to essential personnel" },
                    cultural_memory_shift = { physical = 2, social = -5 },
                    moral_act = { act_id = "cruelty", description = "Let the weak starve to preserve the bloodline" },
                    taboo_chance = 0.30,
                    taboo_data = { trigger = "starvation_cruelty", effect = "the_hungry_years", strength = 65 },
                    narrative = "The old, the sick, the useless — they were given nothing. The bloodline survived. Something else did not.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- STEEL = 0: THE ARMORY IS EMPTY
    -- ═══════════════════════════════════════════════════════
    {
        id = "scarcity_steel_crisis",
        title = "The Bare Armory",
        narrative = "The weapon racks stand empty. The last sword was reforged from a plowshare three harvests ago. The family is naked before its enemies.",
        chance = 0.80,
        cooldown = 5,
        requires_resource_max = { type = "steel", value = 0 },
        options = {
            {
                label = "Commission emergency forging",
                description = "Hire every smith in the region. Pay whatever they demand.",
                requires_resources = { type = "gold", min = 18 },
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -18, reason = "Emergency smithing contracts" },
                        { type = "steel", delta = 8, reason = "Rush-forged weapons" },
                    },
                    narrative = "The forges burned day and night. The gold vanished, but blades appeared — crude, ugly, and sufficient.",
                },
            },
            {
                label = "Strip the holdings",
                description = "Tear iron from gates, fences, and ornaments. The holdings suffer, but the armory fills.",
                consequences = {
                    resource_change = { type = "steel", delta = 5, reason = "Salvaged iron" },
                    lineage_power_shift = -5,
                    cultural_memory_shift = { creative = -2 },
                    narrative = "The gates were unhinged. The decorative ironwork was melted. The holdings looked naked, but the armory had teeth again.",
                },
            },
            {
                label = "Beg arms from a rival",
                description = "Humble the bloodline's pride. Ask a rival house for weapons.",
                requires = { axis = "PER_PRI", max = 60 },
                consequences = {
                    resource_change = { type = "steel", delta = 6, reason = "Borrowed weapons" },
                    disposition_changes = { { faction_id = "strongest", delta = 5 } },
                    lineage_power_shift = -8,
                    narrative = "The heir knelt before a rival and asked for swords. They were given — with a smile that promised the debt would be collected.",
                },
            },
            {
                label = "Train with wooden weapons",
                description = "Sharpen the mind if the blade is absent. Discipline over steel.",
                requires = { axis = "PER_ADA", min = 50 },
                stat_check = {
                    primary = { trait = "MEN_FOC", weight = 1.0 },
                    secondary = { trait = "PHY_AGI", weight = 0.5 },
                    difficulty = 40,
                },
                consequences = {
                    cultural_memory_shift = { physical = 3, mental = 2 },
                    narrative = "Wooden swords against wooden shields. The family fought with sticks and learned to fight with everything.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = -1 },
                    lineage_power_shift = -3,
                    narrative = "The wooden drills devolved into farce. Without real weapons, the family's martial traditions withered.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- LORE = 0: THE DARK AGE
    -- ═══════════════════════════════════════════════════════
    {
        id = "scarcity_lore_crisis",
        title = "The Last Candle",
        narrative = "The libraries are empty. The scholars have fled or died. The family's children cannot read the names on their own ancestors' tombs.",
        chance = 0.80,
        cooldown = 5,
        requires_resource_max = { type = "lore", value = 0 },
        options = {
            {
                label = "Fund a scholar's return",
                description = "Gold lures knowledge back. Pay a sage to restore the archives.",
                requires_resources = { type = "gold", min = 15 },
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -15, reason = "Scholar recruitment" },
                        { type = "lore", delta = 8, reason = "Rebuilt archive" },
                    },
                    narrative = "A wandering scholar was found and fed. Slowly, painfully, the candles were relit and the ink flowed again.",
                },
            },
            {
                label = "Preserve oral tradition",
                description = "What the scrolls forget, the elders remember. Gather the old and listen.",
                requires = { axis = "PER_LOY", min = 45 },
                consequences = {
                    resource_change = { type = "lore", delta = 4, reason = "Oral histories transcribed" },
                    cultural_memory_shift = { social = 3 },
                    narrative = "The elders spoke and the young ones listened. Half of it was lies. The other half was older than the stones.",
                },
            },
            {
                label = "Raid a rival's library",
                description = "They have scrolls. We have swords. The equation is simple.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    resource_change = { type = "lore", delta = 7, reason = "Plundered knowledge" },
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                    moral_act = { act_id = "theft", description = "Raided a rival house's library" },
                    narrative = "The riders returned with armloads of scrolls and a trail of burning buildings. Knowledge, like grain, can be stolen.",
                },
            },
            {
                label = "Embrace the darkness",
                description = "Let the old knowledge die. The blood carries what matters. Everything else is ash.",
                requires = { axis = "PER_VOL", min = 55 },
                consequences = {
                    cultural_memory_shift = { mental = -4, physical = 3 },
                    mutation_triggers = { { type = "ignorance", intensity = 0.3 } },
                    lineage_power_shift = -5,
                    narrative = "The last books were fed to the fire. The family watched them burn and felt nothing. Some chains are made of paper.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- GOLD = 0: THE DEBTORS
    -- ═══════════════════════════════════════════════════════
    {
        id = "scarcity_gold_crisis",
        title = "The Creditors Arrive",
        narrative = "The coffers are dust. The merchants refuse credit. The servants speak of leaving, and worse — the rival houses smell weakness.",
        chance = 0.85,
        cooldown = 5,
        requires_resource_max = { type = "gold", value = 0 },
        options = {
            {
                label = "Sell surplus grain",
                description = "Empty the granaries to fill the coffers. Hunger can wait; insolvency cannot.",
                requires_resources = { type = "grain", min = 12 },
                consequences = {
                    resource_change = {
                        { type = "grain", delta = -12, reason = "Emergency grain sale" },
                        { type = "gold", delta = 10, reason = "Grain sold at desperation prices" },
                    },
                    narrative = "The grain wagons rolled to market. The family would eat less, but the creditors were silenced.",
                },
            },
            {
                label = "Pawn the family steel",
                description = "Melt down swords for coin. Every blade sold is a future battle lost.",
                requires_resources = { type = "steel", min = 8 },
                consequences = {
                    resource_change = {
                        { type = "steel", delta = -8, reason = "Weapons pawned" },
                        { type = "gold", delta = 10, reason = "Steel liquidated" },
                    },
                    cultural_memory_shift = { physical = -2 },
                    narrative = "Ancestral blades became ingots. Ingots became coin. The family was richer and weaker in the same breath.",
                },
            },
            {
                label = "Accept a faction's patronage",
                description = "A rival offers gold — with strings that stretch for generations.",
                consequences = {
                    resource_change = { type = "gold", delta = 15, reason = "Faction patronage" },
                    disposition_changes = { { faction_id = "strongest", delta = 15 } },
                    lineage_power_shift = -10,
                    narrative = "The gold arrived in velvet bags, each one stamped with another house's seal. The family was saved. The family was owned.",
                },
            },
            {
                label = "Default and dare them",
                description = "Refuse to pay. Let them come. Pride is the last currency that cannot be spent.",
                requires = { axis = "PER_PRI", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -12 } },
                    cultural_memory_shift = { social = -3, physical = 2 },
                    lineage_power_shift = 5,
                    narrative = "The creditors were turned away at the gate. The family had nothing — and nothing to lose. The world took note.",
                },
            },
        },
    },
}
