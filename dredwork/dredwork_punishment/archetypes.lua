-- dredwork Punishment — Archetypes
-- Definitions for justice systems and incarceration methods.

local Archetypes = {
    dungeon = {
        label = "Stone Dungeons",
        description = "Dark, damp, and inescapable. High brutality, low upkeep.",
        base_attributes = {
            security = 80,
            brutality = 90,
            reform_rate = -10, -- People come out worse
            maintenance = 10
        },
        tags = { "medieval", "fear_based", "unhealthy" }
    },
    
    work_camp = {
        label = "Penal Labor Camp",
        description = "Punishment through forced contribution. Medium brutality, generates resources.",
        base_attributes = {
            security = 60,
            brutality = 60,
            reform_rate = 0,
            maintenance = -20 -- Actually saves money/produces value
        },
        tags = { "industrial", "productive", "exhausting" }
    },
    
    reform_center = {
        label = "Re-education Center",
        description = "Focus on psychological alignment. Low brutality, high reform.",
        base_attributes = {
            security = 70,
            brutality = 10,
            reform_rate = 40,
            maintenance = 80
        },
        tags = { "futuristic", "psychological", "expensive" }
    }
}

return Archetypes
