-- Dark Legacy — Relationship Type Definitions (Stub)
-- Data-only definitions for future orientation and relationship model.
-- No gameplay changes — this file is a framework stub.
-- Fertility modifier already handled by viability.lua.

local relationship_types = {
    {
        id = "romantic",
        label = "Romantic Union",
        fertility_modifier = 1.0,
        compatibility_modifier = 1.0,
        cultural_acceptance = 1.0,  -- how society reacts
        -- Future: affects heir personality, cultural memory, faction relations
    },
    {
        id = "political",
        label = "Political Marriage",
        fertility_modifier = 0.8,
        compatibility_modifier = 0.6,
        cultural_acceptance = 1.0,
        -- Future: bonus to faction disposition, penalty to heir loyalty
    },
    -- Future relationship types (not yet implemented):
    --
    -- {
    --     id = "rivalry",
    --     label = "Rival Bond",
    --     fertility_modifier = 0.9,
    --     compatibility_modifier = 0.4,
    --     cultural_acceptance = 0.7,
    --     -- Intense competition drives both lineages; volatile offspring
    -- },
    --
    -- {
    --     id = "forbidden",
    --     label = "Forbidden Union",
    --     fertility_modifier = 1.0,
    --     compatibility_modifier = 1.2,
    --     cultural_acceptance = 0.3,
    --     -- High genetic compatibility but severe cultural backlash
    -- },
    --
    -- {
    --     id = "adopted",
    --     label = "Adopted Heir",
    --     fertility_modifier = 0.0,  -- no biological children
    --     compatibility_modifier = 0.0,
    --     cultural_acceptance = 0.8,
    --     -- Heir chosen from outside the bloodline; fresh genetics
    -- },
}

return relationship_types
