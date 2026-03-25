-- dredwork Peril — Archetypes
-- Definitions for diseases and natural disasters.

local Archetypes = {
    -- DISEASES
    plague = {
        label = "Great Plague",
        category = "disease",
        infectivity = 15, -- % chance to spread per day
        lethality = 40,    -- % chance to kill an infected person per month
        duration = 360,    -- days
        impacts = { gold_loss = 20, unrest = 30 },
        tags = { "epidemic", "fear", "fatal" }
    },
    consumption = {
        label = "White Consumption",
        category = "disease",
        infectivity = 2,
        lethality = 10,
        duration = 1080, -- Long term (3 years)
        impacts = { gold_loss = 5 },
        tags = { "chronic", "slow" }
    },

    -- DISASTERS
    flood = {
        label = "Great Flood",
        category = "disaster",
        duration = 30, -- 1 month
        impacts = { home_damage = 40, food_scarcity = 50, gold_loss = 100 },
        tags = { "environmental", "sudden", "destructive" }
    },
    famine = {
        label = "The Scorched Earth",
        category = "disaster",
        duration = 180, -- 6 months
        impacts = { food_scarcity = 80, unrest = 40, gold_loss = 20 },
        tags = { "economic", "prolonged", "hunger" }
    },
    fire = {
        label = "City Fire",
        category = "disaster",
        duration = 7, -- 1 week
        impacts = { home_damage = 80, gold_loss = 50 },
        tags = { "sudden", "urban" }
    }
}

return Archetypes
