-- Dark Legacy — Cultural Memory Thresholds
-- Decay rates, taboo rules, blind spot rules, relationship decay.
-- All values from the spec. Pure data, no logic.

local cultural_thresholds = {}

-- How much the most recent heir's traits influence family priorities
cultural_thresholds.heir_weight = 0.05

-- Trait priority decay rate toward baseline (50) per generation
cultural_thresholds.trait_priority_decay = 0.04

-- Taboo strength decay per generation (2%)
cultural_thresholds.taboo_decay_rate = 0.02

-- Taboo is considered active above this strength
cultural_thresholds.taboo_active_threshold = 10

-- Taboo is removed when strength falls below this
cultural_thresholds.taboo_remove_threshold = 10

-- Relationship strength decay per generation (3%)
cultural_thresholds.relationship_decay_rate = 0.03

-- Relationship is removed when strength falls below this
cultural_thresholds.relationship_remove_threshold = 5

-- Blind spot: if any category average priority exceeds this,
-- the lowest category becomes a blind spot
cultural_thresholds.blind_spot_dominant_threshold = 70

-- Reputation archetypes by dominant category
cultural_thresholds.reputation_archetypes = {
    physical = "warriors",
    mental   = "scholars",
    social   = "diplomats",
    creative = "artisans",
}

-- Reputation sub-archetypes (secondary flavor, future expansion)
cultural_thresholds.reputation_modifiers = {
    high_cruelty = "tyrants",
    high_loyalty = "blood-bound",
    high_curiosity = "seekers",
    high_pride = "dynasts",
}

-- Cultural memory shift difficulty:
-- Number of consecutive counter-selection generations needed to meaningfully shift
cultural_thresholds.shift_generations_needed = 3

-- Penalty multiplier for choosing "against the blood" options
cultural_thresholds.against_blood_penalty = 0.75

return cultural_thresholds
