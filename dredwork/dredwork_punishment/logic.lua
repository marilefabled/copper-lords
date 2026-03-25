-- dredwork Punishment — Logic
-- Handles incarceration, health decay, and reform.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")
local Archetypes = require("dredwork_punishment.archetypes")

local Logic = {}

--- Sentence a character to a punishment facility.
function Logic.sentence(person_id, facility, years)
    return {
        person_id = person_id,
        facility_type = facility.type,
        years_remaining = years or 25,
        original_sentence = years or 25,
        health_mod = 100, -- Starts healthy
        stigma = 0        -- Increases with sentence length
    }
end

--- Simulate a prisoner's state for one generation (25 years).
function Logic.tick_prisoner(prisoner, facility_def)
    local lines = {}
    
    -- 1. Impact of Facility Brutality
    local health_loss = (facility_def.base_attributes.brutality / 10) * 2
    prisoner.health_mod = Math.clamp(prisoner.health_mod - health_loss, 0, 100)
    
    -- 2. Impact of Reform
    local reform = facility_def.base_attributes.reform_rate or 0
    prisoner.stigma = Math.clamp(prisoner.stigma + (prisoner.original_sentence / 5), 0, 100)
    
    -- 3. Release Check
    prisoner.years_remaining = math.max(0, prisoner.years_remaining - 25)
    
    if prisoner.health_mod <= 0 then
        table.insert(lines, string.format("Prisoner %s has perished in the %s.", prisoner.person_id, facility_def.label))
    elseif prisoner.years_remaining <= 0 then
        table.insert(lines, string.format("Prisoner %s has been released from the %s.", prisoner.person_id, facility_def.label))
    end
    
    return lines
end

--- Calculate the global 'Terror' score based on system brutality.
function Logic.calculate_terror(facility_def, prisoner_count)
    if not facility_def then return 0 end
    return (facility_def.base_attributes.brutality / 100) * prisoner_count * 5
end

return Logic
