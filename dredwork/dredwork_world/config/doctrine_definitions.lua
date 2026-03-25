-- Dark Legacy — Doctrine Definitions
-- ~15 permanent dynasty modifiers available at generation milestones.

local doctrine_definitions = {
    {
        id = "blood_of_iron",
        title = "Blood of Iron",
        description = "Physical traits are favored in breeding. Creative expression suffers.",
        category = "physical",
        requires_reputation = { "warriors", "tyrants" },
        modifiers = {
            physical_inheritance_bias = 10,
            creative_inheritance_bias = -5,
        },
    },
    {
        id = "the_long_memory",
        title = "The Long Memory",
        description = "Taboos and relationships endure across more generations.",
        category = "cultural",
        requires_taboo_count = 3,
        modifiers = {
            taboo_decay_multiplier = 0.5,
            relationship_decay_multiplier = 0.5,
        },
    },
    {
        id = "selective_breeding",
        title = "Selective Breeding",
        description = "An additional mate candidate appears during matchmaking.",
        category = "mental",
        requires_reputation = { "scholars", "mystics" },
        modifiers = {
            extra_candidates = 1,
        },
    },
    {
        id = "endurance_doctrine",
        title = "Endurance Doctrine",
        description = "All offspring and heirs are hardier. Viability improves.",
        category = "physical",
        modifiers = {
            viability_bonus = 0.05,
        },
    },
    {
        id = "burning_ambition",
        title = "The Burning Ambition",
        description = "Mutation rate increases, but mutations trend positive.",
        category = "mental",
        requires_reputation = { "warriors", "scholars" },
        modifiers = {
            mutation_rate_multiplier = 1.15,
            mutation_positive_bias = 0.15,
        },
    },
    {
        id = "mercy_of_blood",
        title = "Mercy of the Blood",
        description = "Black sheep heirs find warmer reception. Compatibility improved.",
        category = "social",
        modifiers = {
            black_sheep_compatibility_bonus = 20,
        },
    },
    {
        id = "fortress_bloodline",
        title = "Fortress Bloodline",
        description = "The lineage grows resistant to one condition type.",
        category = "physical",
        requires_generation_min = 20,
        modifiers = {
            condition_immunity = true,
        },
    },
    {
        id = "nomadic_blood",
        title = "Nomadic Blood",
        description = "Intermarriage is less disruptive. Faction relations improve on marriage.",
        category = "social",
        modifiers = {
            intermarriage_pressure_multiplier = 0.5,
            marriage_disposition_bonus = 10,
        },
    },
    {
        id = "scholars_legacy",
        title = "Scholar's Legacy",
        description = "Mental traits are favored in breeding. Physical traits suffer slightly.",
        category = "mental",
        requires_reputation = { "scholars", "seekers" },
        modifiers = {
            mental_inheritance_bias = 10,
            physical_inheritance_bias = -3,
        },
    },
    {
        id = "silver_tongue",
        title = "Silver Tongue",
        description = "Social traits are favored. All faction dispositions improve slightly each generation.",
        category = "social",
        requires_reputation = { "diplomats" },
        modifiers = {
            social_inheritance_bias = 8,
            faction_disposition_drift = 2,
        },
    },
    {
        id = "makers_mark",
        title = "The Maker's Mark",
        description = "Creative traits are favored. Innovation drives the bloodline forward.",
        category = "creative",
        requires_reputation = { "artisans" },
        modifiers = {
            creative_inheritance_bias = 10,
            mutation_positive_bias = 0.05,
        },
    },
    {
        id = "blood_purity",
        title = "Blood Purity",
        description = "Reduced mutation rate. The bloodline resists change.",
        category = "cultural",
        modifiers = {
            mutation_rate_multiplier = 0.75,
        },
    },
    {
        id = "adaptive_legacy",
        title = "Adaptive Legacy",
        description = "Cultural memory shifts faster. The family reinvents itself more readily.",
        category = "cultural",
        modifiers = {
            cultural_shift_speed = 1.5,
        },
    },
    {
        id = "ancestral_vigor",
        title = "Ancestral Vigor",
        description = "Fertility is enhanced. More children are born each generation.",
        category = "physical",
        modifiers = {
            fertility_bonus = 1,
        },
    },
    {
        id = "mystic_veil",
        title = "The Mystic Veil",
        description = "Hidden traits occasionally reveal themselves. One blind spot is pierced.",
        category = "creative",
        requires_reputation = { "mystics", "seekers", "artisans" },
        modifiers = {
            blind_spot_pierce = true,
        },
    },
    -- Religious doctrines (Phase 6 expansion)
    {
        id = "doctrine_divine_mandate",
        title = "Divine Mandate",
        description = "The family's religion is codified into law. Tenets become unbreakable. Zealotry cannot decay below 40.",
        category = "religious",
        requires_generation_min = 10,
        modifiers = {
            zealotry_floor = 40,
            religion_locked = true,
        },
    },
    {
        id = "doctrine_secular_rule",
        title = "Secular Rule",
        description = "Religion is separated from governance. Schism pressure is halved but zealotry bonuses are weaker.",
        category = "religious",
        modifiers = {
            schism_pressure_multiplier = 0.5,
            zealotry_bonus_multiplier = 0.7,
        },
    },
    -- Cultural doctrines
    {
        id = "doctrine_immutable_customs",
        title = "Immutable Customs",
        description = "Cultural customs are permanently locked. High rigidity bonuses but the family cannot adapt.",
        category = "cultural",
        requires_generation_min = 15,
        modifiers = {
            culture_locked = true,
            rigidity_floor = 60,
        },
    },
    -- Faction doctrines
    {
        id = "doctrine_eternal_alliance",
        title = "Eternal Alliance",
        description = "One faction alliance is sealed permanently. Disposition cannot decay below 50.",
        category = "faction",
        requires_reputation = { "diplomats" },
        modifiers = {
            permanent_alliance = true,
            alliance_disposition_floor = 50,
        },
    },
    {
        id = "doctrine_eternal_enmity",
        title = "Eternal Enmity",
        description = "One faction enmity is sealed permanently. The family can never forgive.",
        category = "faction",
        requires_reputation = { "warriors", "tyrants" },
        modifiers = {
            permanent_enmity = true,
            enmity_disposition_ceiling = -50,
        },
    },
}

return doctrine_definitions
