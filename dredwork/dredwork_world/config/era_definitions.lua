-- Dark Legacy — Era Definitions
-- 6 eras with ambient pressure, valued categories, generation spans, and transitions.
-- Pure data, no logic.

local era_definitions = {}

era_definitions.eras = {
    ancient = {
        key = "ancient",
        name = "The Opening Ledger",
        description = "When the first accounts were opened and the bloodlines were young.",
        ambient_pressure = { { type = "mystical_proximity", intensity = 0.3 } },
        valued_categories = { "physical", "creative" },
        bonus_categories = { "physical" },
        mutation_bias = "physical",
        discovery_rate = 1.0,
        min_generations = 12,
        max_generations = 20,
        transition_pressure_threshold = 60,
        transitions = { "iron", "arcane" },
    },
    iron = {
        key = "iron",
        name = "The Red Tithe",
        description = "Forges burn. Empires clash. Blood waters the fields of {realm}.",
        ambient_pressure = { { type = "war", intensity = 0.4 } },
        valued_categories = { "physical", "mental" },
        bonus_categories = { "physical", "mental" },
        mutation_bias = "physical",
        discovery_rate = 1.0,
        min_generations = 15,
        max_generations = 25,
        transition_pressure_threshold = 70,
        transitions = { "dark", "gilded" },
    },
    dark = {
        key = "dark",
        name = "The Collection",
        description = "Plague crawls across {realm}. Famine follows. The debts come due.",
        ambient_pressure = {
            { type = "plague", intensity = 0.3 },
            { type = "famine", intensity = 0.3 },
        },
        valued_categories = { "physical", "social" },
        bonus_categories = { "physical" },
        mutation_bias = "physical",
        discovery_rate = 0.7,
        min_generations = 10,
        max_generations = 18,
        transition_pressure_threshold = 55,
        transitions = { "gilded", "arcane" },
    },
    arcane = {
        key = "arcane",
        name = "The Thinning",
        description = "The veil between worlds thins. Mutation saturates the air. Nothing is stable.",
        ambient_pressure = { { type = "mystical_proximity", intensity = 0.6 } },
        valued_categories = { "mental", "creative" },
        bonus_categories = { "creative", "mental" },
        mutation_bias = "creative",
        discovery_rate = 1.5,
        min_generations = 15,
        max_generations = 25,
        transition_pressure_threshold = 75,
        transitions = { "iron", "twilight" },
    },
    gilded = {
        key = "gilded",
        name = "The Gilt Lie",
        description = "Prosperity masks insolvency. Art flourishes. Daggers hide behind every smile.",
        ambient_pressure = {},
        valued_categories = { "social", "creative" },
        bonus_categories = { "social", "creative" },
        mutation_bias = "social",
        discovery_rate = 1.2,
        min_generations = 15,
        max_generations = 25,
        transition_pressure_threshold = 65,
        transitions = { "arcane", "twilight" },
    },
    twilight = {
        key = "twilight",
        name = "The Final Audit",
        description = "The world exhales its last. Old powers stir. The final reckoning approaches.",
        ambient_pressure = {
            { type = "mystical_proximity", intensity = 0.5 },
            { type = "famine", intensity = 0.2 },
        },
        valued_categories = { "mental", "creative" },
        bonus_categories = { "mental" },
        mutation_bias = "mental",
        discovery_rate = 1.0,
        min_generations = 20,
        max_generations = 40,
        transition_pressure_threshold = 999, -- endgame era, no natural transition
        transitions = {},
    },
}

-- Era transition chance scaling: once past min_generations and above pressure threshold,
-- chance increases by this amount per generation
era_definitions.transition_chance_per_gen = 0.08

-- Starting era for each selection in new game
era_definitions.starting_era_map = {
    ancient = "ancient",
    iron = "iron",
    dark = "dark",
    arcane = "arcane",
}

return era_definitions
