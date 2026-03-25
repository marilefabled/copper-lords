-- dredwork Heritage — Great Work Archetypes
-- Each type has different costs, decay rates, and systemic impacts.
-- Great works ripple through culture, politics, religion, economy, and more.

local Archetypes = {
    -- PHYSICAL WONDERS
    monument = {
        label = "Great Monument",
        category = "physical",
        impact = { CUL_TRD = 5, prestige = 20 },
        maintenance = 10,
        decay_rate = 2,
        description = "A towering edifice that declares the power of its builders.",
    },
    fortress = {
        label = "Legendary Fortress",
        category = "physical",
        impact = { military_power = 15, prestige = 15, CUL_MAR = 3 },
        maintenance = 15,
        decay_rate = 1,
        description = "An impregnable stronghold that deters enemies and inspires warriors.",
    },
    aqueduct = {
        label = "Great Aqueduct",
        category = "physical",
        impact = { food_supply = 10, prestige = 10, health = 5 },
        maintenance = 8,
        decay_rate = 3,
        description = "An engineering marvel that brings water to the parched and food to the hungry.",
    },

    -- INTANGIBLE LEGACIES
    philosophy = {
        label = "Foundational Philosophy",
        category = "intangible",
        impact = { MEN_INT = 5, progress = 10, CUL_FAI = -5 },
        maintenance = 0,
        decay_rate = 5,
        description = "An intellectual framework that reshapes how people think.",
    },
    codex = {
        label = "Grand Codex of Law",
        category = "intangible",
        impact = { order = 15, corruption_reduction = 5, CUL_HIE = 5 },
        maintenance = 3,
        decay_rate = 4,
        description = "A comprehensive legal code that brings order from chaos.",
    },
    epic = {
        label = "Epic Saga",
        category = "intangible",
        impact = { prestige = 25, CUL_TRD = 3, CUL_HON = 5 },
        maintenance = 0,
        decay_rate = 3,
        description = "A great tale that defines a people's identity for generations.",
    },

    -- POLITICAL / DIPLOMATIC
    treaty = {
        label = "Eternal Treaty",
        category = "political",
        impact = { order = 15, unrest = -10, CUL_OPN = 3 },
        maintenance = 5,
        decay_rate = 10,
        description = "A solemn pact between powers. Fragile, but transformative while it holds.",
    },
    trade_network = {
        label = "Grand Trade Network",
        category = "political",
        impact = { gold_income = 20, CUL_OPN = 5, prestige = 10 },
        maintenance = 12,
        decay_rate = 6,
        description = "A web of commerce that enriches all connected to it.",
    },

    -- RELIGIOUS / SPIRITUAL
    temple = {
        label = "Sacred Temple",
        category = "religious",
        impact = { zeal = 10, CUL_FAI = 8, prestige = 15, CUL_TRD = 3 },
        maintenance = 8,
        decay_rate = 2,
        description = "A house of worship that anchors the faith of a people.",
    },
    relic = {
        label = "Holy Relic",
        category = "religious",
        impact = { zeal = 15, prestige = 20, CUL_FAI = 5 },
        maintenance = 2,
        decay_rate = 1,
        description = "A sacred artifact that draws pilgrims and inspires the faithful.",
    },

    -- CULTURAL / ARTISTIC
    academy = {
        label = "Great Academy",
        category = "cultural",
        impact = { research_bonus = 15, MEN_INT = 3, CUL_TRD = -3 },
        maintenance = 10,
        decay_rate = 4,
        description = "A center of learning that pushes the boundaries of knowledge.",
    },
    library = {
        label = "Grand Library",
        category = "cultural",
        impact = { research_bonus = 10, prestige = 15, MEN_LRN = 3 },
        maintenance = 6,
        decay_rate = 3,
        description = "A repository of all known wisdom, preserved for future generations.",
    },
    arena = {
        label = "Grand Arena",
        category = "cultural",
        impact = { CUL_MAR = 5, prestige = 15, unrest = -5 },
        maintenance = 8,
        decay_rate = 3,
        description = "A theater of competition that channels aggression into spectacle.",
    },
}

return Archetypes
