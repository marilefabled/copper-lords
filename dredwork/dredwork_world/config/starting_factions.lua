-- Dark Legacy — Starting Factions
-- 5 initial rival houses. Pure data, no logic.

local starting_factions = {}

starting_factions.houses = {
    {
        id = "house_mordthen",
        name = "House Mordthen",
        motto = "The debt is paid in iron.",
        category_scores = { physical = 70, mental = 50, social = 45, creative = 35 },
        personality = {
            PER_BLD = 80, PER_CRM = 70, PER_PRI = 65,
            PER_OBS = 50, PER_LOY = 45, PER_CUR = 30,
            PER_VOL = 55, PER_ADA = 35,
        },
        traits = {
            PHY_HGT = 75, PHY_BLD = 80, PHY_STR = 75,
            PHY_SKN = 85, PHY_HAI = 90, PHY_EYE = 80, PHY_HTX = 85, PHY_FSH = 80,
        },
        reputation = { primary = "warriors", secondary = "tyrants" },
        power = 60,
        status = "active",
        disposition = -10,
    },
    {
        id = "house_pallwick",
        name = "House Pallwick",
        motto = "We keep the receipts.",
        category_scores = { physical = 40, mental = 70, social = 55, creative = 50 },
        personality = {
            PER_BLD = 35, PER_CRM = 40, PER_PRI = 50,
            PER_OBS = 75, PER_LOY = 40, PER_CUR = 80,
            PER_VOL = 30, PER_ADA = 70,
        },
        traits = {
            PHY_HGT = 65, PHY_BLD = 30, PHY_AGI = 70,
            PHY_SKN = 15, PHY_HAI = 10, PHY_EYE = 15, PHY_HTX = 10, PHY_FSH = 45,
        },
        reputation = { primary = "scholars", secondary = "seekers" },
        power = 60,
        status = "active",
        disposition = 5,
    },
    {
        id = "house_sablecourt",
        name = "House Sablecourt",
        motto = "The contract is the blade.",
        category_scores = { physical = 45, mental = 55, social = 70, creative = 40 },
        personality = {
            PER_BLD = 45, PER_CRM = 65, PER_PRI = 55,
            PER_OBS = 40, PER_LOY = 25, PER_CUR = 50,
            PER_VOL = 35, PER_ADA = 75,
        },
        traits = {
            PHY_HGT = 55, PHY_BLD = 45, PHY_REF = 75,
            PHY_SKN = 35, PHY_HAI = 30, PHY_EYE = 45, PHY_HTX = 35, PHY_FSH = 70,
        },
        reputation = { primary = "diplomats", secondary = "tyrants" },
        power = 60,
        status = "active",
        disposition = 15,
    },
    {
        id = "house_cinderwell",
        name = "House Cinderwell",
        motto = "Even ash has a price.",
        category_scores = { physical = 35, mental = 55, social = 50, creative = 70 },
        personality = {
            PER_BLD = 40, PER_CRM = 35, PER_PRI = 50,
            PER_OBS = 70, PER_LOY = 50, PER_CUR = 75,
            PER_VOL = 65, PER_ADA = 55,
        },
        traits = {
            PHY_HGT = 60, PHY_BLD = 40, CRE_AES = 75,
            PHY_SKN = 60, PHY_HAI = 50, PHY_EYE = 60, PHY_HTX = 65, PHY_FSH = 35,
        },
        reputation = { primary = "artisans", secondary = "seekers" },
        power = 60,
        status = "active",
        disposition = 10,
    },
    {
        id = "house_graith",
        name = "House Graith",
        motto = "We were here before the ledger.",
        category_scores = { physical = 60, mental = 50, social = 55, creative = 45 },
        personality = {
            PER_BLD = 60, PER_CRM = 50, PER_PRI = 65,
            PER_OBS = 45, PER_LOY = 80, PER_CUR = 35,
            PER_VOL = 40, PER_ADA = 40,
        },
        traits = {
            PHY_HGT = 70, PHY_BLD = 75, PHY_VIT = 75,
            PHY_SKN = 50, PHY_HAI = 70, PHY_EYE = 40, PHY_HTX = 40, PHY_FSH = 60,
        },
        reputation = { primary = "warriors", secondary = "blood-bound" },
        power = 60,
        status = "active",
        disposition = 0,
    },
}

-- Templates for emergent replacement houses when active count drops below 3
starting_factions.emergent_templates = {
    {
        name_prefix = "House",
        category_bias = "physical",
        personality_bias = { PER_BLD = 70, PER_CRM = 60 },
        reputation_primary = "warriors",
    },
    {
        name_prefix = "Order of the",
        category_bias = "mental",
        personality_bias = { PER_CUR = 70, PER_OBS = 65 },
        reputation_primary = "scholars",
    },
    {
        name_prefix = "The",
        category_bias = "social",
        personality_bias = { PER_ADA = 70, PER_PRI = 55 },
        reputation_primary = "diplomats",
    },
    {
        name_prefix = "Guild of",
        category_bias = "creative",
        personality_bias = { PER_CUR = 65, PER_OBS = 60 },
        reputation_primary = "artisans",
    },
}

return starting_factions
