-- dredwork Crime — Simulation Logic
-- Organization growth, operations, investigation, escalation, and territory.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local Orgs = require("dredwork_crime.organizations")
local Ops = require("dredwork_crime.operations")

local Logic = {}

function Logic.create_org(type_key, location_id)
    local template = Orgs[type_key] or Orgs.street_gang
    local org = {
        type = type_key,
        label = template.label,
        location_id = location_id,
        attributes = {},
        wealth = template.base_attributes.wealth,
        influence = template.base_attributes.influence,
        heat = 0,
        members = RNG.range(5, 20),
        operations_run = 0,
        operations_failed = 0,
        leadership = RNG.range(30, 70),
        territory_control = 0,
        tags = {},
    }
    for k, v in pairs(template.base_attributes) do org.attributes[k] = v end
    for _, tag in ipairs(template.tags) do table.insert(org.tags, tag) end
    return org
end

function Logic.run_operation(org, op_key, context)
    local op = Ops[op_key]
    if not op then return nil end

    for attr, min_val in pairs(op.requirements or {}) do
        if (org.attributes[attr] or 0) < min_val then
            return { success = false, reason = "Inadequate skills", heat_gain = 0 }
        end
    end

    local security = context.regional_security or 20
    local subtlety_bonus = (org.attributes.subtlety or org.attributes.subtlely or 50) * 0.2
    local experience_bonus = math.min(20, org.operations_run * 0.5)
    local leadership_bonus = (org.leadership - 50) * 0.2
    local risk_score = op.risk + security - subtlety_bonus - experience_bonus - leadership_bonus

    local success = RNG.random() * 100 > risk_score
    org.operations_run = org.operations_run + 1

    local result = {
        success = success, op_label = op.label,
        heat_gain = op.heat_gain or 5,
        reward = success and (op.reward or 0) or 0,
        unrest_gain = op.unrest_gain or 0,
        corruption_gain = op.corruption_gain or 0,
    }

    if success then
        org.territory_control = Math.clamp(org.territory_control + 2, 0, 100)
        if result.reward > 40 then org.members = org.members + RNG.range(1, 3) end
    else
        result.heat_gain = result.heat_gain * 2
        result.loss = math.floor(org.wealth * 0.1)
        org.operations_failed = org.operations_failed + 1
        if RNG.chance(0.2) then org.members = math.max(1, org.members - RNG.range(1, 3)) end
    end

    return result
end

--- Run an investigation against a criminal org.
function Logic.investigate(org, investigation_power)
    local subtlety = org.attributes.subtlety or org.attributes.subtlely or 50
    local discovery_chance = Math.clamp((investigation_power - subtlety) / 100 + 0.1, 0.05, 0.8)

    if not RNG.chance(discovery_chance) then
        return { discovered = false, narrative = "The investigation turns up nothing." }
    end

    local evidence = Math.clamp(investigation_power - (org.leadership * 0.5), 0, 100)
    local arrests = 0

    if evidence > 60 then
        arrests = RNG.range(2, math.min(5, org.members))
        org.members = math.max(1, org.members - arrests)
        org.heat = Math.clamp(org.heat + 20, 0, 100)
        org.territory_control = Math.clamp(org.territory_control - 10, 0, 100)
    elseif evidence > 30 then
        arrests = RNG.range(1, 2)
        org.members = math.max(1, org.members - arrests)
        org.heat = Math.clamp(org.heat + 10, 0, 100)
    end

    return {
        discovered = true, evidence_level = math.floor(evidence), arrests = arrests,
        narrative = arrests > 0
            and string.format("Investigation bears fruit. %d arrested.", arrests)
            or "Evidence found, but the leaders remain elusive.",
    }
end

function Logic.tick(org, context)
    local lines = {}

    local heat_decay = org.territory_control > 50 and 5 or 10
    org.heat = Math.clamp(org.heat - heat_decay, 0, 100)

    org.influence = Math.clamp(org.influence + (org.wealth / 100) * 1.5 + (org.territory_control / 100), 0, 100)

    if org.heat < 30 and org.wealth > 30 and RNG.chance(0.3) then
        org.members = org.members + RNG.range(1, 2)
    end

    if RNG.chance(0.05) then
        local old = org.leadership
        org.leadership = Math.clamp(org.leadership + RNG.range(-10, 15), 10, 100)
        if org.leadership > old + 5 then
            table.insert(lines, string.format("New leadership emerges in %s.", org.label))
        end
    end

    if org.heat > 60 then org.territory_control = Math.clamp(org.territory_control - 3, 0, 100) end

    if org.members <= 1 and org.wealth <= 5 then
        table.insert(lines, string.format("%s has collapsed.", org.label))
        org.influence = 0; org.territory_control = 0
    end

    return lines
end

return Logic
