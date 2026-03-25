-- dredwork Home — Archetypes
-- Definitions for different types of dwellings across eras.

local Templates = {
    -- Starting dwelling — you have nothing
    hovel = {
        label = "Rented Room",
        base_upkeep = 5,
        base_attributes = {
            comfort = 25,
            security = 15,
            luxury = 5,
            space = 15,
            condition = 60
        },
        tags = { "cramped", "cheap", "anonymous" }
    },

    -- Medieval/Ancient Era
    castle = {
        label = "Stone Keep",
        base_upkeep = 50,
        base_attributes = {
            comfort = 30,
            security = 90,
            luxury = 40,
            space = 80,
            condition = 100
        },
        tags = { "fortified", "ancestral", "cold" }
    },
    
    manor = {
        label = "Gentry Manor",
        base_upkeep = 30,
        base_attributes = {
            comfort = 70,
            security = 40,
            luxury = 60,
            space = 60,
            condition = 100
        },
        tags = { "prestigious", "social", "vulnerable" }
    },

    -- Futuristic/Sci-Fi Era
    stasis_pod = {
        label = "Stasis Pod",
        base_upkeep = 10,
        base_attributes = {
            comfort = 20,
            security = 95,
            luxury = 10,
            space = 5,
            condition = 100
        },
        tags = { "automated", "cramped", "efficient" }
    },

    orbital_penthouse = {
        label = "Orbital Penthouse",
        base_upkeep = 100,
        base_attributes = {
            comfort = 90,
            security = 60,
            luxury = 95,
            space = 70,
            condition = 100
        },
        tags = { "elite", "high_tech", "fragile" }
    }
}

return Templates
