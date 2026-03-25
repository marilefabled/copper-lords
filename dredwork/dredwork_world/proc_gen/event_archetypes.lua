-- Dark Legacy — Procedural Event Archetypes
-- Structural blueprints for generated events.
-- Each archetype defines pool, narrative keys, option patterns, and weights.
-- Pure data, zero dependencies.

local archetypes = {}

-- =========================================================================
-- WORLD ARCHETYPES (8)
-- =========================================================================
archetypes.world = {
    {
        id = "proc_border_conflict",
        archetype = "conflict",
        option_patterns = {
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 45 }, consequence_pattern = "military_escalation" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 50 }, consequence_pattern = "knowledge_gain" },
        },
        weight_modifiers = { has_condition_war = 2.0, has_condition_plague = 0.5 },
        chance = 0.35,
    },
    {
        id = "proc_resource_discovery",
        archetype = "discovery",
        option_patterns = {
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 50 }, consequence_pattern = "economic_gain" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "knowledge_gain" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_gain" },
        },
        weight_modifiers = { has_condition_famine = 1.5 },
        chance = 0.30,
    },
    {
        id = "proc_plague_crisis",
        archetype = "crisis",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "merciful",   requires = { axis = "PER_CRM", max = 40 }, consequence_pattern = "faction_friendship" },
            { response_type = "cruel",      requires = { axis = "PER_CRM", min = 60 }, consequence_pattern = "cultural_shift_physical" },
        },
        weight_modifiers = { has_condition_plague = 3.0 },
        requires_condition = "plague",
        chance = 0.40,
    },
    {
        id = "proc_famine_crisis",
        archetype = "crisis",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 55 }, consequence_pattern = "military_escalation" },
            { response_type = "merciful",   requires = { axis = "PER_CRM", max = 35 }, consequence_pattern = "faction_friendship" },
        },
        weight_modifiers = { has_condition_famine = 3.0 },
        requires_condition = "famine",
        chance = 0.40,
    },
    {
        id = "proc_war_turning_point",
        archetype = "conflict",
        option_patterns = {
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 60 }, consequence_pattern = "military_escalation" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
        },
        weight_modifiers = { has_condition_war = 3.0 },
        requires_condition = "war",
        chance = 0.40,
    },
    {
        id = "proc_rare_opportunity",
        archetype = "opportunity",
        option_patterns = {
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 45 }, consequence_pattern = "knowledge_gain" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_gain" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
        },
        weight_modifiers = {},
        chance = 0.25,
    },
    {
        id = "proc_ceremony_tradition",
        archetype = "ceremony",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "cultural_shift_social" },
            { response_type = "aggressive", requires = { axis = "PER_PRI", min = 55 }, consequence_pattern = "cultural_shift_physical" },
            { response_type = "merciful",   requires = { axis = "PER_CRM", max = 40 }, consequence_pattern = "faction_friendship" },
        },
        weight_modifiers = {},
        chance = 0.20,
    },
    {
        id = "proc_mysterious_event",
        archetype = "discovery",
        option_patterns = {
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 55 }, consequence_pattern = "mutation_spike" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "knowledge_gain" },
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 50 }, consequence_pattern = "mutation_spike" },
        },
        weight_modifiers = { era_arcane = 2.0, era_twilight = 1.5 },
        chance = 0.20,
    },
}

-- =========================================================================
-- FACTION ARCHETYPES (6)
-- =========================================================================
archetypes.faction = {
    {
        id = "proc_faction_provocation",
        archetype = "conflict",
        option_patterns = {
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 50 }, consequence_pattern = "faction_hostility" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "clever",     requires = { axis = "PER_ADA", min = 50 }, consequence_pattern = "faction_friendship" },
        },
        weight_modifiers = { faction_hostile = 2.5, faction_neutral = 1.0 },
        chance = 0.30,
    },
    {
        id = "proc_faction_trade_offer",
        archetype = "opportunity",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_gain" },
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 45 }, consequence_pattern = "faction_friendship" },
            { response_type = "aggressive", requires = { axis = "PER_CRM", min = 55 }, consequence_pattern = "faction_hostility" },
        },
        weight_modifiers = { faction_friendly = 2.0 },
        chance = 0.30,
    },
    {
        id = "proc_faction_betrayal",
        archetype = "betrayal",
        option_patterns = {
            { response_type = "cruel",      requires = { axis = "PER_CRM", min = 55 }, consequence_pattern = "faction_hostility" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
            { response_type = "merciful",   requires = { axis = "PER_CRM", max = 35 }, consequence_pattern = "faction_friendship" },
        },
        weight_modifiers = { faction_hostile = 1.5 },
        chance = 0.20,
    },
    {
        id = "proc_faction_alliance_offer",
        archetype = "ceremony",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "faction_friendship" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "aggressive", requires = { axis = "PER_PRI", min = 60 }, consequence_pattern = "faction_hostility" },
        },
        weight_modifiers = { faction_friendly = 2.5 },
        chance = 0.25,
    },
    {
        id = "proc_faction_power_shift",
        archetype = "crisis",
        option_patterns = {
            { response_type = "clever",     requires = { axis = "PER_ADA", min = 50 }, consequence_pattern = "faction_friendship" },
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 55 }, consequence_pattern = "military_escalation" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
        },
        weight_modifiers = { faction_power_high = 1.5, faction_power_low = 1.5 },
        chance = 0.25,
    },
    {
        id = "proc_faction_cultural_clash",
        archetype = "conflict",
        option_patterns = {
            { response_type = "merciful",   requires = { axis = "PER_ADA", min = 50 }, consequence_pattern = "cultural_shift_social" },
            { response_type = "cruel",      requires = { axis = "PER_CRM", min = 60 }, consequence_pattern = "faction_hostility" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
        },
        weight_modifiers = {},
        chance = 0.20,
    },
}

-- =========================================================================
-- LEGACY ARCHETYPES (6)
-- =========================================================================
archetypes.legacy = {
    {
        id = "proc_legacy_ancestral_echo",
        archetype = "ceremony",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "cultural_shift_physical" },
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 45 }, consequence_pattern = "knowledge_gain" },
            { response_type = "aggressive", requires = { axis = "PER_PRI", min = 55 }, consequence_pattern = "cultural_shift_social" },
        },
        weight_modifiers = { high_generation = 1.5 },
        requires_legacy = "strong_reputation",
        chance = 0.25,
    },
    {
        id = "proc_legacy_taboo_test",
        archetype = "crisis",
        option_patterns = {
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
            { response_type = "aggressive", requires = { axis = "PER_BLD", min = 55 }, consequence_pattern = "taboo_formation" },
            { response_type = "clever",     requires = { axis = "PER_ADA", min = 50 }, consequence_pattern = "cultural_shift_mental" },
        },
        weight_modifiers = { has_taboos = 1.5 },
        requires_legacy = "active_taboo",
        chance = 0.25,
    },
    {
        id = "proc_legacy_blind_spot_crisis",
        archetype = "crisis",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
            { response_type = "clever",     requires = { axis = "PER_CUR", min = 50 }, consequence_pattern = "knowledge_gain" },
            { response_type = "cautious",   requires = nil,                            consequence_pattern = "defensive_gain" },
        },
        weight_modifiers = { has_blind_spots = 2.0 },
        requires_legacy = "blind_spot",
        chance = 0.30,
    },
    {
        id = "proc_legacy_old_alliance_strained",
        archetype = "betrayal",
        option_patterns = {
            { response_type = "merciful",   requires = { axis = "PER_LOY", min = 55 }, consequence_pattern = "faction_friendship" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "economic_strain" },
            { response_type = "cruel",      requires = { axis = "PER_CRM", min = 55 }, consequence_pattern = "faction_hostility" },
        },
        weight_modifiers = {},
        requires_legacy = "old_relationship",
        chance = 0.25,
    },
    {
        id = "proc_legacy_reputation_challenge",
        archetype = "conflict",
        option_patterns = {
            { response_type = "aggressive", requires = { axis = "PER_PRI", min = 50 }, consequence_pattern = "military_escalation" },
            { response_type = "clever",     requires = { axis = "PER_ADA", min = 50 }, consequence_pattern = "cultural_shift_social" },
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "defensive_gain" },
        },
        weight_modifiers = {},
        requires_legacy = "strong_reputation",
        chance = 0.25,
    },
    {
        id = "proc_legacy_milestone_reflection",
        archetype = "ceremony",
        option_patterns = {
            { response_type = "pragmatic",  requires = nil,                            consequence_pattern = "cultural_shift_mental" },
            { response_type = "aggressive", requires = { axis = "PER_PRI", min = 50 }, consequence_pattern = "cultural_shift_physical" },
            { response_type = "merciful",   requires = { axis = "PER_CRM", max = 40 }, consequence_pattern = "faction_friendship" },
        },
        weight_modifiers = { high_generation = 2.0 },
        chance = 0.20,
    },
}

return archetypes
