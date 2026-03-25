-- dredwork Conquest — Control Statuses
-- Definitions for the relationship between conqueror and conquered.

local Statuses = {
    occupation = {
        label = "Military Occupation",
        description = "Total control through force. High unrest, maximum extraction.",
        unrest_base = 60,
        tribute_mult = 1.5,
        autonomy = 0,
        tags = { "oppressive", "vulnerable", "direct_rule" }
    },
    
    vassal = {
        label = "Vassal State",
        description = "Local rulers remain in power but pay tribute and provide military support.",
        unrest_base = 20,
        tribute_mult = 0.6,
        autonomy = 60,
        tags = { "loyal_service", "buffer_state" }
    },
    
    tributary = {
        label = "Tributary Province",
        description = "Loose control focusing purely on wealth extraction.",
        unrest_base = 10,
        tribute_mult = 0.8,
        autonomy = 80,
        tags = { "economic_focus", "loose_grip" }
    },

    integrated = {
        label = "Integrated Province",
        description = "The people consider themselves part of the empire. Low unrest, stable revenue.",
        unrest_base = 5,
        tribute_mult = 1.0,
        autonomy = 20,
        tags = { "stable", "core_territory" }
    }
}

return Statuses
