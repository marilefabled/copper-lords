-- dredwork Technology — Fields of Study
-- Each field has a multiplier that scales relevant systems.
-- Progress is accumulated through research; breakthroughs unlock new levels.

local Fields = {
    industry = {
        label = "Industrialization",
        description = "Efficiency in resource extraction and manufacturing.",
        base_multiplier = 1.0,
        progress_per_level = 100,
        impacts = { "economy", "home" },
        -- What it does: multiplies gold income, speeds home construction
    },
    medicine = {
        label = "Life Sciences",
        description = "Understanding of anatomy, disease, and genetics.",
        base_multiplier = 1.0,
        progress_per_level = 120,
        impacts = { "peril", "bonds", "genetics" },
        -- What it does: reduces disease severity, extends lifespan, improves viability
    },
    warfare = {
        label = "Military Science",
        description = "Tactics, logistics, and weapon development.",
        base_multiplier = 1.0,
        progress_per_level = 100,
        impacts = { "military", "conquest" },
        -- What it does: multiplies unit power, reduces attrition
    },
    infrastructure = {
        label = "Civil Engineering",
        description = "Roads, communication, and urban planning.",
        base_multiplier = 1.0,
        progress_per_level = 80,
        impacts = { "geography", "rumor", "home" },
        -- What it does: speeds rumor propagation, reduces travel time, home repair
    },
    agriculture = {
        label = "Agricultural Science",
        description = "Crop yields, livestock management, and irrigation.",
        base_multiplier = 1.0,
        progress_per_level = 90,
        impacts = { "economy", "animals" },
        -- What it does: increases food supply, reduces famine severity
    },
    navigation = {
        label = "Navigation & Cartography",
        description = "Exploration, trade routes, and geographic knowledge.",
        base_multiplier = 1.0,
        progress_per_level = 110,
        impacts = { "geography", "conquest", "economy" },
        -- What it does: reduces travel costs, enables distant trade, exploration
    },
    metallurgy = {
        label = "Metallurgy & Materials",
        description = "Ore processing, alloys, and construction materials.",
        base_multiplier = 1.0,
        progress_per_level = 100,
        impacts = { "military", "home", "heritage" },
        -- What it does: stronger weapons, better buildings, more durable great works
    },
    theology = {
        label = "Theology & Philosophy",
        description = "Religious scholarship, ethics, and metaphysics.",
        base_multiplier = 1.0,
        progress_per_level = 130,
        impacts = { "religion", "culture", "dialogue" },
        -- What it does: increases tolerance, shifts culture, enriches dialogue
    },
    espionage = {
        label = "Espionage & Intelligence",
        description = "Codes, surveillance, and information warfare.",
        base_multiplier = 1.0,
        progress_per_level = 120,
        impacts = { "crime", "rumor", "rivals" },
        -- What it does: better crime detection, faster rumor spread, rival intel
    },
    governance = {
        label = "Political Science",
        description = "Administration, law, and institutional design.",
        base_multiplier = 1.0,
        progress_per_level = 100,
        impacts = { "politics", "punishment", "conquest" },
        -- What it does: reduces corruption, improves legitimacy, better conquest admin
    },
}

return Fields
