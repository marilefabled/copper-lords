-- dredwork Animals — Species Definitions
-- Every species interacts with religion (sacred), economy (food/trade),
-- military (war animals), home (pets/pests), and strife (fear/comfort).

local Species = {
    --------------------------------------------------------------------------
    -- PETS (High bonding, low wildness)
    --------------------------------------------------------------------------
    hound = {
        label = "Loyal Hound",
        category = "pet",
        wildness = 5,
        danger = 10,
        maintenance = 5,
        comfort_bonus = 8,
        traits = { "loyal", "protective", "companion" },
        biomes = { temperate = 1.0, tundra = 0.8, steppe = 1.0 },
    },
    cat = {
        label = "House Cat",
        category = "pet",
        wildness = 30,
        danger = 0,
        maintenance = 2,
        comfort_bonus = 5,
        traits = { "independent", "pest_hunter" },
        pest_control = 3,  -- reduces rat density
        biomes = { temperate = 1.0, urban = 1.5, desert = 0.8 },
    },
    exotic_falcon = {
        label = "Exotic Falcon",
        category = "pet",
        wildness = 40,
        danger = 15,
        maintenance = 20,
        comfort_bonus = 3,
        prestige_bonus = 10,
        traits = { "prestige", "hunter", "rare" },
        biomes = { desert = 1.2, steppe = 1.5, mountain = 1.0 },
    },
    songbird = {
        label = "Songbird",
        category = "pet",
        wildness = 15,
        danger = 0,
        maintenance = 1,
        comfort_bonus = 4,
        traits = { "decorative", "calming" },
        biomes = { tropical = 1.5, temperate = 1.0 },
    },
    warhorse = {
        label = "War Horse",
        category = "pet",
        wildness = 20,
        danger = 20,
        maintenance = 15,
        comfort_bonus = 0,
        military_bonus = 10,  -- boosts cavalry
        traits = { "military", "mount", "prestige" },
        biomes = { temperate = 1.0, steppe = 1.5 },
    },

    --------------------------------------------------------------------------
    -- WILDLIFE (Regional populations, high wildness)
    --------------------------------------------------------------------------
    wolves = {
        label = "Wolf Pack",
        category = "wildlife",
        wildness = 90,
        danger = 60,
        reproduction = 15,
        fear_radius = 20,    -- affects strife/bias when density high
        biomes = { tundra = 1.5, temperate = 1.0, mountain = 1.2 },
    },
    bears = {
        label = "Great Bear",
        category = "wildlife",
        wildness = 85,
        danger = 80,
        reproduction = 5,
        fear_radius = 30,
        sacred_potential = true,  -- can become sacred to faiths
        biomes = { tundra = 1.3, temperate = 1.0, mountain = 1.0 },
    },
    great_ape = {
        label = "Great Ape",
        category = "wildlife",
        wildness = 80,
        danger = 40,
        reproduction = 5,
        sacred_potential = true,
        biomes = { tropical = 1.5, temperate = 0.3 },
    },
    deer = {
        label = "Wild Deer",
        category = "wildlife",
        wildness = 70,
        danger = 5,
        reproduction = 25,
        food_value = 8,     -- huntable for food
        biomes = { temperate = 1.5, tundra = 0.8, mountain = 0.7 },
    },
    hawks = {
        label = "Hawks",
        category = "wildlife",
        wildness = 75,
        danger = 10,
        reproduction = 10,
        pest_control = 5,   -- natural rat killers
        biomes = { steppe = 1.5, mountain = 1.3, desert = 1.0 },
    },
    boar = {
        label = "Wild Boar",
        category = "wildlife",
        wildness = 80,
        danger = 45,
        reproduction = 20,
        food_value = 10,
        biomes = { temperate = 1.2, swamp = 1.0 },
    },
    serpent = {
        label = "Serpent",
        category = "wildlife",
        wildness = 95,
        danger = 50,
        reproduction = 30,
        sacred_potential = true,
        biomes = { tropical = 2.0, desert = 1.5, swamp = 1.5 },
    },
    elephant = {
        label = "Great Elephant",
        category = "wildlife",
        wildness = 60,
        danger = 30,
        reproduction = 3,
        military_bonus = 20,  -- war elephants
        sacred_potential = true,
        biomes = { tropical = 1.5, steppe = 0.5 },
    },

    --------------------------------------------------------------------------
    -- PESTS (Negative impact, high reproduction)
    --------------------------------------------------------------------------
    rats = {
        label = "Common Rats",
        category = "pest",
        wildness = 100,
        danger = 5,
        reproduction = 40,
        impacts = { home_decay = 5, food_loss = 10 },
        disease_carrier = true,
        biomes = { urban = 2.0, temperate = 1.0, swamp = 1.5 },
    },
    locusts = {
        label = "Swarm Locusts",
        category = "pest",
        wildness = 100,
        danger = 0,
        reproduction = 80,
        impacts = { food_loss = 50 },
        biomes = { desert = 2.0, steppe = 1.5, tropical = 1.0 },
    },
    crows = {
        label = "Murder of Crows",
        category = "pest",
        wildness = 70,
        danger = 5,
        reproduction = 30,
        impacts = { food_loss = 5 },
        omen_value = true,  -- religious significance
        biomes = { temperate = 1.5, urban = 1.0, swamp = 1.2 },
    },
    termites = {
        label = "Termite Colony",
        category = "pest",
        wildness = 100,
        danger = 0,
        reproduction = 60,
        impacts = { home_decay = 15 },
        biomes = { tropical = 2.0, temperate = 0.5, swamp = 1.5 },
    },
    mosquitoes = {
        label = "Mosquito Swarm",
        category = "pest",
        wildness = 100,
        danger = 0,
        reproduction = 70,
        disease_carrier = true,
        impacts = { home_decay = 0, food_loss = 0 },
        biomes = { swamp = 2.5, tropical = 2.0, coastal = 1.0 },
    },
}

return Species
