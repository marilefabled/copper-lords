-- dredwork Geography — Biome Definitions
-- Environmental constraints and modifiers for regions.
-- Every property here ripples through economy, military, animals, home, strife, and more.

local Biomes = {
    temperate = {
        label = "Temperate Plains",
        upkeep_mod = 1.0,
        rumor_speed = 1.0,
        food_base = 60,           -- base food supply
        military_attrition = 1.0, -- normal attrition
        disease_risk = 0.05,      -- monthly disease chance
        wildlife_growth = 1.0,    -- animal reproduction multiplier
        construction_mod = 1.0,   -- building/repair speed
        tags = { "fertile", "populous", "mild" },
    },
    tundra = {
        label = "Frozen Tundra",
        upkeep_mod = 1.5,
        rumor_speed = 0.7,
        food_base = 25,
        military_attrition = 1.8,  -- harsh winters kill soldiers
        disease_risk = 0.02,       -- cold kills germs too
        wildlife_growth = 0.5,     -- slow breeding
        construction_mod = 0.6,    -- building in frozen ground is hard
        tags = { "harsh", "isolated", "cold", "defensible" },
    },
    desert = {
        label = "Scorched Sands",
        upkeep_mod = 1.3,
        rumor_speed = 0.8,
        food_base = 20,
        military_attrition = 1.5,
        disease_risk = 0.03,
        wildlife_growth = 0.4,
        construction_mod = 0.8,
        tags = { "harsh", "vast", "dry", "trade_route" },
    },
    tropical = {
        label = "Tropical Jungle",
        upkeep_mod = 1.1,
        rumor_speed = 0.9,
        food_base = 70,             -- abundant but perishable
        military_attrition = 1.3,   -- disease and terrain
        disease_risk = 0.12,        -- high disease risk
        wildlife_growth = 2.0,      -- life thrives
        construction_mod = 0.7,     -- jungle reclaims everything
        tags = { "lush", "dangerous", "abundant", "diseased" },
    },
    urban = {
        label = "Urban Sprawl",
        upkeep_mod = 1.2,
        rumor_speed = 2.0,
        food_base = 30,             -- no farmland, imports only
        military_attrition = 0.8,   -- supply lines are short
        disease_risk = 0.08,        -- crowded = disease
        wildlife_growth = 0.3,      -- pests thrive, wildlife doesn't
        construction_mod = 1.5,     -- infrastructure already exists
        tags = { "crowded", "civilized", "trade_hub", "crime_prone" },
    },
    coastal = {
        label = "Coastal Waters",
        upkeep_mod = 1.0,
        rumor_speed = 1.5,          -- port cities spread news fast
        food_base = 55,             -- fishing + farming
        military_attrition = 1.0,
        disease_risk = 0.06,
        wildlife_growth = 1.2,      -- marine + land life
        construction_mod = 1.0,
        tags = { "trade_route", "naval", "exposed", "fish" },
    },
    mountain = {
        label = "Mountain Stronghold",
        upkeep_mod = 1.4,
        rumor_speed = 0.5,          -- isolated peaks
        food_base = 20,
        military_attrition = 1.2,
        disease_risk = 0.02,
        wildlife_growth = 0.6,
        construction_mod = 0.5,     -- rock is hard to work
        tags = { "defensible", "isolated", "mineral_rich", "harsh" },
    },
    steppe = {
        label = "Open Steppe",
        upkeep_mod = 0.8,           -- cheap to live, hard to defend
        rumor_speed = 1.2,          -- nomads carry news
        food_base = 35,             -- herding, not farming
        military_attrition = 0.7,   -- cavalry country
        disease_risk = 0.03,
        wildlife_growth = 1.3,      -- herds
        construction_mod = 0.6,     -- no building materials
        tags = { "vast", "nomadic", "cavalry", "exposed" },
    },
    swamp = {
        label = "Fetid Marshlands",
        upkeep_mod = 1.6,
        rumor_speed = 0.6,
        food_base = 30,
        military_attrition = 2.0,   -- worst terrain for armies
        disease_risk = 0.15,        -- malaria, rot
        wildlife_growth = 1.8,      -- life thrives in the muck
        construction_mod = 0.4,     -- nothing stays built
        tags = { "dangerous", "diseased", "hidden", "defensible" },
    },
    volcanic = {
        label = "Volcanic Wastes",
        upkeep_mod = 1.8,
        rumor_speed = 0.4,
        food_base = 10,
        military_attrition = 2.5,
        disease_risk = 0.04,
        wildlife_growth = 0.2,
        construction_mod = 0.3,
        tags = { "harsh", "mineral_rich", "spiritual", "dangerous" },
    },
}

return Biomes
