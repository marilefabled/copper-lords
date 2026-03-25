-- Dark Legacy — Mutation Tables
-- Trigger types, pressure values, magnitude ranges, and bias rules.
-- All values from the spec. Pure data, no logic.

local mutation_tables = {}

-- Base mutation chance per trait per generation (2%)
mutation_tables.base_mutation_chance = 0.02

-- Mutation magnitude range
mutation_tables.magnitude_min = 5
mutation_tables.magnitude_max = 20

-- Dominance flip chance when mutation occurs
mutation_tables.dominance_flip_chance = 0.10

-- Dominance assignment probabilities for new alleles by category
mutation_tables.dominance_by_category = {
    physical = 0.60,
    mental   = 0.50,
    social   = 0.40,
    creative = 0.45,
}

-- Mutation triggers: each adds to cumulative mutation_pressure
-- negative_bias: probability that a mutation in this context goes negative
mutation_tables.triggers = {
    era_shift = {
        pressure_min = 15,
        pressure_max = 25,
        negative_bias = nil, -- direction biased toward new-era-relevant traits (handled in logic)
        description = "Major era transition. Applied once at the boundary.",
        targeted_categories = nil, -- all categories affected
    },
    famine = {
        pressure_min = 5,
        pressure_max = 10,
        negative_bias = nil,
        description = "Per-generation during active famine.",
        targeted_categories = { "physical" },
    },
    plague = {
        pressure_min = 10,
        pressure_max = 15,
        negative_bias = nil,
        description = "Per-generation during active plague.",
        targeted_traits = { "PHY_IMM", "PHY_VIT", "PHY_LON", "PHY_REC" },
    },
    war = {
        pressure_min = 5,
        pressure_max = 10,
        negative_bias = nil,
        description = "Per-generation during active war.",
        targeted_categories = { "physical", "mental" },
        targeted_traits = { "MEN_COM", "MEN_WIL", "PHY_STR", "PHY_END", "PHY_REF" },
    },
    intermarriage = {
        pressure_min = 10,
        pressure_max = 20,
        negative_bias = nil, -- 50/50, greatest diversity injection
        description = "Per foreign bloodline introduced.",
        targeted_categories = nil, -- all categories
    },
    mystical_proximity = {
        pressure_min = 5,
        pressure_max = 15,
        negative_bias = nil, -- fully random, can exceed normal bounds temporarily
        description = "Exposure to mystical forces.",
        targeted_categories = nil,
        affects_hidden_more = true,
    },
    inbreeding = {
        pressure_min = 15,
        pressure_max = 30,
        negative_bias = 0.70, -- 70% chance negative, 30% positive
        description = "Genetic proximity between parents. High pressure, negative bias.",
        targeted_categories = nil, -- all categories
    },
}

-- Mutation pressure decay rate per generation (20%)
mutation_tables.pressure_decay_rate = 0.20

return mutation_tables
