-- Dark Legacy — Consequence Patterns
-- Reusable consequence structures for procedural events.
-- These are templates that get scaled by consequence_scaler.
-- Pure data, zero dependencies.

local patterns = {}

-- Each pattern returns a consequence table matching the EventEngine format.
-- "scale" fields will be multiplied by the scaler's multiplier.

patterns.military_escalation = {
    narrative = "The bloodline's martial strength is tested.",
    mutation_triggers = {
        { type = "war", intensity = 0.4 },
    },
    cultural_memory_shift = { physical = 3, mental = 1, social = -1, creative = -1 },
    disposition_changes = {
        { faction_id = "all", delta = -2 },
    },
    taboo_chance = 0.05,
    taboo_data = {
        trigger = "proc_military_escalation",
        effect = "bloodline_craves_conflict",
        strength = 60,
    },
    -- Scale targets: intensity, shift values, disposition delta
    _scale_fields = { "mutation_triggers.1.intensity", "cultural_memory_shift", "disposition_changes.1.delta" },
}

patterns.defensive_gain = {
    narrative = "The {lineage_name} fortify their position.",
    cultural_memory_shift = { physical = 1, mental = 1, social = 0, creative = 0 },
    -- Mild positive, low risk
    _scale_fields = { "cultural_memory_shift" },
}

patterns.knowledge_gain = {
    narrative = "New understanding spreads through the {lineage_name} holdings.",
    cultural_memory_shift = { physical = 0, mental = 3, social = 1, creative = 1 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.economic_gain = {
    narrative = "Resources flow into the {lineage_name} coffers.",
    cultural_memory_shift = { physical = 0, mental = 1, social = 1, creative = 1 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.economic_strain = {
    narrative = "The cost is steep. The {lineage_name} reserves thin.",
    cultural_memory_shift = { physical = 0, mental = 0, social = -1, creative = -1 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.faction_hostility = {
    narrative = "A new enemy is made.",
    disposition_changes = {
        { faction_id = "_target", delta = -10 },
    },
    cultural_memory_shift = { physical = 1, mental = 0, social = -2, creative = 0 },
    add_relationship = { type = "enemy", strength = 50, reason = "proc_event_hostility" },
    _scale_fields = { "disposition_changes.1.delta", "cultural_memory_shift", "add_relationship.strength" },
}

patterns.faction_friendship = {
    narrative = "Bonds are strengthened.",
    disposition_changes = {
        { faction_id = "_target", delta = 8 },
    },
    cultural_memory_shift = { physical = 0, mental = 0, social = 2, creative = 0 },
    add_relationship = { type = "ally", strength = 45, reason = "proc_event_friendship" },
    _scale_fields = { "disposition_changes.1.delta", "cultural_memory_shift", "add_relationship.strength" },
}

patterns.cultural_shift_physical = {
    narrative = "The bloodline's physical legacy is reshaped.",
    cultural_memory_shift = { physical = 4, mental = -1, social = 0, creative = -1 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.cultural_shift_mental = {
    narrative = "The bloodline's intellectual identity shifts.",
    cultural_memory_shift = { physical = -1, mental = 4, social = 0, creative = 0 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.cultural_shift_social = {
    narrative = "The bloodline's social standing transforms.",
    cultural_memory_shift = { physical = 0, mental = 0, social = 4, creative = -1 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.cultural_shift_creative = {
    narrative = "The bloodline's creative expression evolves.",
    cultural_memory_shift = { physical = -1, mental = 0, social = 0, creative = 4 },
    _scale_fields = { "cultural_memory_shift" },
}

patterns.mutation_spike = {
    narrative = "Something in the blood stirs. The {lineage_name} genetics shift unpredictably.",
    mutation_triggers = {
        { type = "mystical_proximity", intensity = 0.8 },
    },
    cultural_memory_shift = { physical = 0, mental = 1, social = 0, creative = 1 },
    _scale_fields = { "mutation_triggers.1.intensity", "cultural_memory_shift" },
}

patterns.taboo_formation = {
    narrative = "A line has been crossed. The family will not forget.",
    taboo_chance = 0.35,
    taboo_data = {
        trigger = "proc_taboo_event",
        effect = "bloodline_carries_scar",
        strength = 70,
    },
    cultural_memory_shift = { physical = 0, mental = 1, social = -1, creative = 0 },
    _scale_fields = { "taboo_data.strength", "cultural_memory_shift" },
}

return patterns
