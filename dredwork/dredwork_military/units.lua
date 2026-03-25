-- dredwork Military — Unit Archetypes
-- Definitions for various military forces across eras.

local Units = {
    -- Ancient/Medieval Legions
    legion = {
        label = "Heavy Legion",
        base_strength = 80,
        mobility = 40,
        base_upkeep = 60,
        tags = { "disciplined", "infantry", "slow" }
    },
    
    scouts = {
        label = "Border Scouts",
        base_strength = 20,
        mobility = 90,
        base_upkeep = 15,
        tags = { "recon", "light", "fast" }
    },

    -- Futuristic Peacekeepers
    drone_swarm = {
        label = "Tactical Swarm",
        base_strength = 60,
        mobility = 95,
        base_upkeep = 40,
        tags = { "automated", "fragile", "fast" }
    },

    orbital_guard = {
        label = "Orbital Guard",
        base_strength = 100,
        mobility = 10,
        base_upkeep = 150,
        tags = { "elite", "defensive", "heavy" }
    }
}

return Units
