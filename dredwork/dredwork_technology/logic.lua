-- dredwork Technology — Logic
-- Handles research accumulation, breakthroughs, and field multipliers.

local Math = require("dredwork_core.math")
local Fields = require("dredwork_technology.fields")

local Logic = {}

--- Create a new technology state.
function Logic.create()
    local state = { fields = {} }
    for id, def in pairs(Fields) do
        state.fields[id] = {
            level = 1,
            progress = 0,
            multiplier = def.base_multiplier or 1.0,
            label = def.label,
            progress_per_level = def.progress_per_level or 100,
        }
    end
    return state
end

--- Accumulate progress in a field.
function Logic.add_progress(field_state, amount)
    local lines = {}
    field_state.progress = field_state.progress + amount

    local threshold = field_state.progress_per_level or 100
    if field_state.progress >= threshold then
        field_state.progress = field_state.progress - threshold
        field_state.level = field_state.level + 1
        field_state.multiplier = 1.0 + (field_state.level - 1) * 0.1

        table.insert(lines, string.format("BREAKTHROUGH: %s reached Level %d!", field_state.label, field_state.level))
    end

    return lines
end

--- Step technology for one generation.
function Logic.tick(tech_state, engine_context)
    local lines = {}
    local base_research = 10 + (engine_context.bonus_research or 0)

    if engine_context.is_high_progress then
        base_research = base_research * 1.5
    end

    for id, field in pairs(tech_state.fields) do
        local res = Logic.add_progress(field, base_research)
        for _, l in ipairs(res) do table.insert(lines, l) end
    end

    return lines
end

return Logic
