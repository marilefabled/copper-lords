-- dredwork Strife — Conflict Logic
-- Friction from identity differences, migration, bias dynamics, and inter-group tension.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")

local Logic = {}

--- Calculate the 'Identity Distance' between two entities based on a set of traits.
function Logic.calculate_distance(traits_a, traits_b, focus_traits)
    local distance = 0
    local count = 0
    for _, id in ipairs(focus_traits) do
        local val_a = traits_a[id] or 50
        local val_b = traits_b[id] or 50
        distance = distance + math.abs(val_a - val_b)
        count = count + 1
    end
    return count > 0 and (distance / count) or 0
end

--- Determine the strife level between a subject and a group's bias.
function Logic.calculate_bias_friction(subject_traits, group_bias)
    local friction = 0
    for trait_id, bias in pairs(group_bias) do
        local val = subject_traits[trait_id] or 50
        local diff = math.abs(val - bias.mean)
        friction = friction + (diff * (bias.weight or 1.0))
    end
    return friction
end

--- Calculate the 'Push Factor' for a region (likelihood of people leaving).
function Logic.calculate_push_factor(friction, unrest, scarcity)
    local score = (friction * 0.5) + (unrest * 0.3) + (scarcity * 0.2)
    return Math.clamp(score, 0, 100)
end

--- Determine where migrants might go.
function Logic.choose_migration_target(current_region_id, regions, strife_mod, econ_mod)
    local current_region = regions[current_region_id]
    if not current_region or not current_region.adjacent then return nil end

    local potential_targets = {}
    for adj_id, _ in pairs(current_region.adjacent) do
        local target = regions[adj_id]
        if target then
            local friction = strife_mod and strife_mod:get_regional_friction(adj_id) or 10
            -- Pull factors: low friction, low food price
            local pull = 100 - friction
            if econ_mod then
                local market = econ_mod:get_market(adj_id)
                if market and market.prices and market.prices.food then
                    pull = pull + Math.clamp(20 - market.prices.food, -20, 20)
                end
            end
            table.insert(potential_targets, { id = adj_id, weight = math.max(1, pull) })
        end
    end

    if #potential_targets == 0 then return nil end
    return RNG.weighted_pick(potential_targets)
end

--- Simulate the drift of biases for one tick.
---@param biases table { trait_id = { mean, weight } }
---@param hardening_events table|nil { trait_id = delta } — events that harden biases
function Logic.tick_biases(biases, hardening_events)
    for trait_id, bias in pairs(biases) do
        -- Natural softening (biases fade over time without reinforcement)
        bias.weight = Math.clamp(bias.weight - 0.03, 0.1, 5.0)

        -- Hardening from events (conflict, raids, migration influx)
        if hardening_events and hardening_events[trait_id] then
            bias.weight = Math.clamp(bias.weight + hardening_events[trait_id], 0.1, 5.0)
        end

        -- Mean drifts toward 50 (neutral) very slowly
        bias.mean = bias.mean + (50 - bias.mean) * 0.01
    end
end

--- Calculate inter-group tension between two regions based on their biases.
function Logic.calculate_inter_region_tension(biases_a, biases_b)
    local tension = 0
    local count = 0

    for trait_id, bias_a in pairs(biases_a) do
        local bias_b = biases_b[trait_id]
        if bias_b then
            local diff = math.abs(bias_a.mean - bias_b.mean)
            local combined_weight = (bias_a.weight + bias_b.weight) / 2
            tension = tension + diff * combined_weight
            count = count + 1
        end
    end

    return count > 0 and tension / count or 0
end

--- Simulate a migration event (move population pressure between regions).
---@param from_id string source region
---@param to_id string target region
---@param biases_from table source region biases
---@param biases_to table target region biases
---@return table { tension_delta, narrative }
function Logic.apply_migration(from_id, to_id, biases_from, biases_to)
    local tension_delta = 0
    local narrative = ""

    -- Migrants carry their biases to the new region
    for trait_id, source_bias in pairs(biases_from) do
        if not biases_to[trait_id] then
            -- New trait bias introduced to target region
            biases_to[trait_id] = { mean = source_bias.mean, weight = 0.1 }
            tension_delta = tension_delta + 5
        else
            -- Existing bias shifts slightly toward migrant values
            local target_bias = biases_to[trait_id]
            local diff = math.abs(source_bias.mean - target_bias.mean)
            target_bias.mean = target_bias.mean + (source_bias.mean - target_bias.mean) * 0.05
            -- Diversity increases tension (temporarily)
            if diff > 20 then
                target_bias.weight = Math.clamp(target_bias.weight + 0.1, 0.1, 5.0)
                tension_delta = tension_delta + diff * 0.2
            end
        end
    end

    if tension_delta > 10 then
        narrative = string.format("Migrants from %s arrive in %s. Cultural tensions rise.", from_id, to_id)
    elseif tension_delta > 0 then
        narrative = string.format("Travelers from %s settle in %s. The newcomers are watched warily.", from_id, to_id)
    else
        narrative = string.format("People move from %s to %s. They are absorbed without incident.", from_id, to_id)
    end

    return { tension_delta = tension_delta, narrative = narrative }
end

return Logic
