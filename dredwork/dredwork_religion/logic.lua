-- dredwork Religion — Logic
-- Handles religious evolution, zeal, and conversion mechanics.

local Math = require("dredwork_core.math")
local Beliefs = require("dredwork_religion.beliefs")

local Logic = {}

--- Create a new religion state.
function Logic.create(type_key)
    local template = Beliefs[type_key] or Beliefs.animism
    return {
        type = type_key,
        label = template.label,
        attributes = {
            zeal = template.base_attributes.zeal,
            tolerance = template.base_attributes.tolerance,
            tradition = template.base_attributes.tradition
        },
        influence = 50, -- 0 to 100
        tags = template.tags
    }
end

--- Simulate religious drift for one generation.
function Logic.tick(religion, context)
    local lines = {}
    
    -- Zeal slowly regresses toward 50 unless events happen
    religion.attributes.zeal = Math.clamp(religion.attributes.zeal + (50 - religion.attributes.zeal) * 0.1, 0, 100)
    
    -- Influence changes based on zeal
    if religion.attributes.zeal > 70 then
        religion.influence = Math.clamp(religion.influence + 5, 0, 100)
        table.insert(lines, string.format("%s is spreading rapidly due to high fervor.", religion.label))
    end
    
    return lines
end

--- Calculate unrest modifier based on tolerance and diversity.
function Logic.get_unrest_modifier(religion, diversity_score)
    local mod = 0
    if diversity_score > 30 then
        -- High diversity + Low tolerance = Unrest
        mod = (diversity_score - 30) * (1 - religion.attributes.tolerance / 100) * 0.5
    end
    return mod
end

return Logic
