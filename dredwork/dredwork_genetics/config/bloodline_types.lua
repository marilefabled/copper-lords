-- Dark Legacy — Bloodline Type Definitions (Stub)
-- Data-only definitions for future non-human bloodline expansion.
-- No gameplay changes — this file is a framework stub.

local bloodline_types = {
    human = {
        id = "human",
        label = "Human",
        trait_ranges = { min = 0, max = 100 },
        mutation_modifier = 1.0,
        fertility_modifier = 1.0,
        longevity_modifier = 1.0,
        personality_bias = {},  -- no bias
        -- Future: appearance tags, unique events, special mechanics
    },
    -- Future bloodline types (not yet implemented):
    --
    -- fae = {
    --     id = "fae",
    --     label = "Fae-Touched",
    --     trait_ranges = { min = 0, max = 110 },  -- creative can exceed 100
    --     mutation_modifier = 1.3,  -- more volatile genetics
    --     fertility_modifier = 0.7,  -- lower fertility
    --     longevity_modifier = 1.5,  -- longer-lived
    --     personality_bias = { PER_CUR = 15, PER_ADA = 10 },
    -- },
    --
    -- dragon_touched = {
    --     id = "dragon_touched",
    --     label = "Dragon-Touched",
    --     trait_ranges = { min = 0, max = 100 },
    --     mutation_modifier = 0.8,  -- stable genetics
    --     fertility_modifier = 0.5,  -- rare offspring
    --     longevity_modifier = 2.0,  -- very long-lived
    --     personality_bias = { PER_PRI = 20, PER_OBS = 15 },
    -- },
    --
    -- undying = {
    --     id = "undying",
    --     label = "The Undying",
    --     trait_ranges = { min = 0, max = 100 },
    --     mutation_modifier = 0.5,  -- very stable
    --     fertility_modifier = 0.3,  -- extremely rare offspring
    --     longevity_modifier = 5.0,  -- near-immortal
    --     personality_bias = { PER_OBS = 20, PER_CRM = 10 },
    -- },
}

return bloodline_types
