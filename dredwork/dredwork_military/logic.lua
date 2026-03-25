-- dredwork Military — Simulation Logic
-- Unit readiness, combat strength, attrition, battle resolution, and reinforcement.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")
local Units = require("dredwork_military.units")

local Logic = {}

function Logic.create(type_key, commander_id)
    local template = Units[type_key] or Units.legion
    return {
        type = type_key,
        label = template.label,
        commander_id = commander_id,
        strength = template.base_strength,
        max_strength = template.base_strength,
        readiness = 100,
        morale = 100,
        experience = 0,
        upkeep_cost = template.base_upkeep,
        casualties = 0,
        tags = template.tags or {},
        location_id = nil,
    }
end

function Logic.tick(unit, resources, context, scale)
    local lines = {}
    scale = scale or 1.0
    local attrition_mod = context.attrition_mod or 1.0

    local effective_upkeep = unit.upkeep_cost * scale
    local paid = (resources and resources.gold or 0) >= effective_upkeep

    if paid then
        unit.morale = Math.clamp(unit.morale + (3 * scale), 0, 100)
        if unit.strength < unit.max_strength then
            unit.strength = Math.clamp(unit.strength + math.floor(5 * scale), 0, unit.max_strength)
        end
    else
        unit.morale = Math.clamp(unit.morale - (20 * attrition_mod * scale), 0, 100)
        local loss = math.floor(10 * attrition_mod * scale)
        unit.strength = Math.clamp(unit.strength - loss, 0, unit.max_strength)
        unit.casualties = unit.casualties + loss
        table.insert(lines, string.format("%s suffers desertions.", unit.label))
    end

    if not context.in_war then
        unit.readiness = Math.clamp(unit.readiness - (5 * scale), 20, 100)
    else
        unit.readiness = Math.clamp(unit.readiness + (3 * scale), 0, 100)
        unit.morale = Math.clamp(unit.morale - (2 * scale), 0, 100)
    end

    unit.experience = Math.clamp(unit.experience - (1 * scale), 0, 100)
    return lines
end

function Logic.calculate_power(unit, commander_skills)
    local base = unit.strength * (unit.readiness / 100) * (unit.morale / 100)
    base = base * (1.0 + (unit.experience / 100) * 0.3)
    if commander_skills then
        base = base * (1 + (commander_skills.strategy or 0) / 100)
    end
    return math.floor(base)
end

--- Resolve a battle between two forces.
function Logic.resolve_battle(attacker, defender)
    local att_power = 0
    for _, unit in ipairs(attacker.units or {}) do
        att_power = att_power + Logic.calculate_power(unit, attacker.commander_skills)
    end
    local def_power = 0
    for _, unit in ipairs(defender.units or {}) do
        def_power = def_power + Logic.calculate_power(unit, defender.commander_skills)
    end

    def_power = math.floor(def_power * (defender.terrain_bonus or 1.2))
    att_power = att_power * (0.85 + RNG.random() * 0.3)
    def_power = def_power * (0.85 + RNG.random() * 0.3)

    local winner = att_power > def_power and "attacker" or "defender"
    local margin = math.abs(att_power - def_power)
    local total = att_power + def_power

    local loser_pct = 0.2 + RNG.random() * 0.2
    local winner_pct = 0.05 + RNG.random() * 0.1
    if total > 0 and margin / total < 0.1 then
        loser_pct = loser_pct + 0.1; winner_pct = winner_pct + 0.05
    end

    local att_cas, def_cas = 0, 0
    local w_units = winner == "attacker" and attacker.units or defender.units
    local l_units = winner == "attacker" and defender.units or attacker.units

    for _, unit in ipairs(w_units or {}) do
        local loss = math.floor(unit.strength * winner_pct)
        unit.strength = Math.clamp(unit.strength - loss, 0, unit.max_strength)
        unit.casualties = unit.casualties + loss
        unit.experience = Math.clamp(unit.experience + 10, 0, 100)
        unit.morale = Math.clamp(unit.morale + 5, 0, 100)
        if winner == "attacker" then att_cas = att_cas + loss else def_cas = def_cas + loss end
    end
    for _, unit in ipairs(l_units or {}) do
        local loss = math.floor(unit.strength * loser_pct)
        unit.strength = Math.clamp(unit.strength - loss, 0, unit.max_strength)
        unit.casualties = unit.casualties + loss
        unit.morale = Math.clamp(unit.morale - 20, 0, 100)
        if winner == "attacker" then def_cas = def_cas + loss else att_cas = att_cas + loss end
    end

    local narrative
    if total > 0 and margin / total > 0.3 then
        narrative = winner == "attacker" and "A decisive victory! The enemy is routed." or "The defenders hold firm."
    elseif winner_pct > 0.12 then
        narrative = "Victory, but at terrible cost."
    else
        narrative = "A brutal engagement. Both sides bleed."
    end

    return { winner = winner, attacker_casualties = att_cas, defender_casualties = def_cas, margin = math.floor(margin), narrative = narrative }
end

function Logic.should_disband(unit)
    return unit.strength <= 0 or (unit.morale <= 5 and unit.strength < 20)
end

return Logic
