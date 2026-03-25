-- Dark Legacy — Apotheosis (The Eternal Project)
-- Defines the multi-generational win condition for the game.

local Apotheosis = {
    discovery_id = "eternal_pattern",
    required_holding_type = "temple",
    required_trait = "MEN_ABS",
    required_trait_min = 90,
    resource_costs = {
        gold = 80,
        lore = 70,
        grain = 40
    },
    crucible_trial_id = "the_ascension"
}

return Apotheosis
