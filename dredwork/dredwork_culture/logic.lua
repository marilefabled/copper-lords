-- dredwork Culture — Logic
-- Handles cultural evolution, drift, and societal norms.

local Math = require("dredwork_core.math")
local Values = require("dredwork_culture.values")

local Logic = {}

--- Create a new culture state.
function Logic.create(initial_values)
    local state = { axes = {} }
    for _, def in pairs(Values) do
        state.axes[def.id] = initial_values and initial_values[def.id] or 50
    end
    return state
end

--- Simulate cultural drift for one generation.
function Logic.tick(culture, events)
    local lines = {}
    for id, value in pairs(culture.axes) do
        -- Find the matching definition for drift rate
        local drift_rate = 0.05
        for _, def in pairs(Values) do
            if def.id == id then drift_rate = def.drift_rate or 0.05; break end
        end
        local drift = (50 - value) * drift_rate
        culture.axes[id] = Math.clamp(value + drift, 0, 100)
    end
    return lines
end

--- Calculate how much a personality axis is biased by culture.
--- Uses the personality_bias mappings defined in values.lua.
function Logic.get_personality_bias(culture, trait_id)
    local bias = 0
    for _, def in pairs(Values) do
        if def.personality_bias and def.personality_bias[trait_id] then
            local axis_val = culture.axes[def.id] or 50
            bias = bias + (axis_val - 50) * def.personality_bias[trait_id]
        end
    end
    return bias
end

return Logic
