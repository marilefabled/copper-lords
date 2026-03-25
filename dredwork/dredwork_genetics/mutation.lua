local Math = require("dredwork_core.math")
-- Dark Legacy — Mutation Engine
-- Mutation is NOT random by default — it is driven by world pressure.
-- Pressure accumulates from era shifts, famine, plague, war, intermarriage,
-- mystical proximity, and inbreeding.

local rng = require("dredwork_core.rng")
local mutation_tables = require("dredwork_genetics.config.mutation_tables")

local Mutation = {}

-- Doctrine modifiers (set externally by GeneticsController before apply)
Mutation._doctrine_rate_multiplier = 1.0    -- multiplied into effective chance
Mutation._doctrine_positive_bias = 0.0      -- added to positive direction chance (0.0-0.5)
Mutation._doctrine_intermarriage_mult = 1.0 -- multiplied into intermarriage trigger intensity

--- Create a new mutation pressure tracker.
---@return table pressure object
function Mutation.new_pressure()
    return {
        value = 0,            -- cumulative pressure (0-200+ range)
        active_triggers = {},  -- list of active trigger types
    }
end

--- Apply a specific mutation immediately (used for Blood Rites).
---@param genome table
---@param trait_id string
---@param delta number
---@param trigger_name string|nil
function Mutation.force_mutation(genome, trait_id, delta, trigger_name)
    local trait = genome:get_trait(trait_id)
    if not trait then return end

    -- Apply to alleles to ensure it passes down
    local current_value = trait:get_value()
    local new_value = Math.clamp(current_value + delta, 0, 100)
    
    trait.alleles = { { value = new_value, dominant = true }, { value = new_value, dominant = true } }
    trait:set_value(new_value)

    genome.mutations = genome.mutations or {}
    genome.mutations[#genome.mutations + 1] = {
        trait_id = trait_id,
        trait_name = trait_id, -- Simplification for forced mutations
        delta = delta,
        trigger = trigger_name or "Blood Sacrifice",
        category = trait.category,
    }
end

--- Add pressure from a trigger event.
---@param pressure table pressure object
---@param trigger_type string key from mutation_tables.triggers
---@param intensity number|nil optional multiplier (default 1.0)
---@return table pressure (modified in place)
function Mutation.add_trigger(pressure, trigger_type, intensity)
    intensity = intensity or 1.0
    local trigger = mutation_tables.triggers[trigger_type]
    if not trigger then return pressure end

    -- Apply doctrine intermarriage multiplier
    if trigger_type == "intermarriage" then
        intensity = intensity * Mutation._doctrine_intermarriage_mult
    end

    local added = rng.range(trigger.pressure_min, trigger.pressure_max) * intensity
    pressure.value = pressure.value + added

    -- Track active triggers for bias calculation
    pressure.active_triggers[#pressure.active_triggers + 1] = trigger_type

    return pressure
end

--- Apply mutation to a child genome based on current pressure.
---@param genome table Genome object (modified in place)
---@param pressure table pressure object
---@return table genome (modified), table list of mutations that occurred
function Mutation.apply(genome, pressure)
    local mutations = {}
    local base_chance = mutation_tables.base_mutation_chance

    for id, trait in pairs(genome.traits) do
        local effective_chance = (base_chance + (pressure.value / 1000)) * Mutation._doctrine_rate_multiplier

        if rng.chance(effective_chance) then
            local magnitude = rng.range(
                mutation_tables.magnitude_min,
                mutation_tables.magnitude_max
            )
            local direction = Mutation._determine_direction(pressure, trait)
            local shift = magnitude * direction

            trait:set_value(trait:get_value() + shift)

            -- 10% chance mutation flips allele dominance
            if trait.alleles and rng.chance(0.1) then
                local idx = rng.range(1, 2)
                trait.alleles[idx].dominant = not trait.alleles[idx].dominant
            end

            mutations[#mutations + 1] = {
                trait_id = id,
                shift = shift,
                new_value = trait:get_value(),
            }
        end
    end

    return genome, mutations
end

--- Decay mutation pressure by 20% per generation.
---@param pressure table pressure object
---@return table pressure (modified)
function Mutation.decay(pressure)
    pressure.value = pressure.value * 0.8
    pressure.active_triggers = {}
    return pressure
end

--- Determine mutation direction based on trigger biases.
---@param pressure table
---@param trait table Trait
---@return number +1 or -1
function Mutation._determine_direction(pressure, trait)
    -- Check active triggers for bias
    for _, trigger_type in ipairs(pressure.active_triggers) do
        local trigger = mutation_tables.triggers[trigger_type]
        if trigger and trigger.negative_bias then
            if rng.chance(trigger.negative_bias) then
                return -1
            end
        end
    end
    -- Default: 50/50 + doctrine positive bias
    local positive_chance = 0.5 + Mutation._doctrine_positive_bias
    return rng.chance(positive_chance) and 1 or -1
end

--- Serialize pressure to a plain table for saving.
---@param pressure table
---@return table
function Mutation.pressure_to_table(pressure)
    return {
        value = pressure.value,
        active_triggers = pressure.active_triggers,
    }
end

--- Restore pressure from a saved table.
---@param data table
---@return table pressure object
function Mutation.pressure_from_table(data)
    return {
        value = (data and data.value) or 0,
        active_triggers = (data and data.active_triggers) or {},
    }
end

return Mutation
