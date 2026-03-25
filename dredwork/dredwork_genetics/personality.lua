local Math = require("dredwork_core.math")
-- Dark Legacy — Personality Module ("The Eight Fires")
-- 8 axes that exist BENEATH traits. Never shown as numbers.
-- They manifest only through narrative gating, NPC reactions, and lineage direction.

local personality_maps = require("dredwork_genetics.config.personality_maps")
local rng = require("dredwork_core.rng")

local Personality = {}
Personality.__index = Personality

--- Axis IDs for reference
Personality.AXES = {
    "PER_BLD",  -- Boldness
    "PER_CRM",  -- Cruelty / Mercy
    "PER_OBS",  -- Obsession
    "PER_LOY",  -- Loyalty
    "PER_CUR",  -- Curiosity
    "PER_VOL",  -- Volatility
    "PER_PRI",  -- Pride
    "PER_ADA",  -- Adaptability
}

--- Create a new personality with default (50) or specified axis values.
---@param values table|nil optional { [axis_id] = value }
---@return table Personality instance
function Personality.new(values)
    local self = setmetatable({}, Personality)
    self.axes = {}
    values = values or {}

    for _, axis_id in ipairs(Personality.AXES) do
        local v = values[axis_id] or 50
        self.axes[axis_id] = math.floor(Math.clamp(v, 0, 100))
    end

    return self
end

--- Derive a child personality from parents and child's genome.
--- Derive a new personality for a child based on genome and parents.
---@param genome table the child's Genome object
---@param parent_a_personality table Personality object
---@param parent_b_personality table Personality object
---@param engine table|nil the central engine for cultural biases
---@return table Personality instance
function Personality.derive(genome, parent_a_personality, parent_b_personality, engine)
    local values = {}

    for axis_id, _ in pairs(personality_maps.axis_maps) do
        local map = personality_maps.axis_maps[axis_id]

        -- Inherited component: average of parents + noise
        local pa = parent_a_personality.axes[axis_id] or 50
        local pb = parent_b_personality.axes[axis_id] or 50
        local inherited = (pa + pb) / 2 + rng.range(-3, 3)

        -- Trait-derived component
        local trait_sum = 0
        if map and map.trait_inputs then
            for trait_id, weight in pairs(map.trait_inputs) do
                local trait_val = genome:get_value(trait_id) or 50
                trait_sum = trait_sum + (trait_val - 50) * weight
            end
        end
        local trait_derived = 50 + trait_sum

        -- 60/40 split
        local final = (inherited * 0.6) + (trait_derived * 0.4) + rng.range(-2, 2)

        -- INTERCONNECTION: Factor in cultural bias
        if engine then
            local req = { trait_id = axis_id, bias = 0 }
            engine:emit("BIAS_PERSONALITY_GENERATION", req)
            final = final + req.bias
        end

        values[axis_id] = math.floor(Math.clamp(final, 0, 100))
    end

    return Personality.new(values)
end

--- Get an axis value by ID.
---@param axis_id string e.g. "PER_BLD"
---@return number 0-100
function Personality:get_axis(axis_id)
    return self.axes[axis_id] or 50
end

--- Clone this personality.
---@return table Personality
function Personality:clone()
    local copy = {}
    for id, val in pairs(self.axes) do
        copy[id] = val
    end
    return Personality.new(copy)
end

--- Serialize to a plain table for saving.
---@return table
function Personality:to_table()
    local data = {}
    for id, val in pairs(self.axes) do
        data[id] = val
    end
    return data
end

--- Restore from a saved table.
---@param data table { [axis_id] = value }
---@return table Personality
function Personality.from_table(data)
    return Personality.new(data or {})
end

return Personality
