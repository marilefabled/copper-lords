-- dredwork Heritage — Simulation Logic
-- Handles legendary figures, great works, and historical memory.

local Math = require("dredwork_core.math")
local Archetypes = require("dredwork_heritage.archetypes")

local Logic = {}

--- Create a record for a Historical Figure.
function Logic.create_figure(person, deed_label, significance)
    return {
        id = person.id,
        name = person.name or "Anonymous",
        deed = deed_label,
        significance = significance or 50, -- 0 to 100
        generation = 0, -- Set by init
        is_remembered = true
    }
end

--- Create a Great Work.
function Logic.create_work(type_key, label, creator_name)
    local def = Archetypes[type_key] or Archetypes.monument
    return {
        type = type_key,
        label = label,
        creator = creator_name,
        condition = 100,
        impact = def.impact,
        is_active = true
    }
end

--- Simulate historical decay for one generation.
function Logic.tick(state, resources)
    local lines = {}
    
    -- 1. Great Works Decay
    for i = #state.great_works, 1, -1 do
        local work = state.great_works[i]
        local def = Archetypes[work.type]
        
        -- Upkeep check
        local paid = (resources and resources.gold or 0) >= (def.maintenance or 0)
        if not paid then
            work.condition = Math.clamp(work.condition - (def.decay_rate or 5), 0, 100)
        end
        
        if work.condition <= 0 then
            work.is_active = false
            table.insert(lines, string.format("The Great Work '%s' has fallen into ruin and lost its influence.", work.label))
        end
    end
    
    -- 2. Figure Memory Fade
    for _, figure in ipairs(state.legends) do
        figure.significance = Math.clamp(figure.significance - 5, 0, 100)
        if figure.significance <= 0 then
            figure.is_remembered = false
        end
    end
    
    return lines
end

return Logic
