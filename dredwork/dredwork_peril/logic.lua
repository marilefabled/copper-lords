-- dredwork Peril — Simulation Logic
-- Handles disease spread, disaster impacts, and recovery.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")
local Archetypes = require("dredwork_peril.archetypes")

local Logic = {}

--- Start a new peril event.
function Logic.start_peril(type_key, location_id)
    local def = Archetypes[type_key] or Archetypes.plague
    return {
        type = type_key,
        label = def.label,
        category = def.category,
        location_id = location_id,
        days_remaining = def.duration,
        severity = 50, -- 0 to 100
        active_infections = def.category == "disease" and 1 or 0,
        is_active = true
    }
end

--- Step a disease for one day.
function Logic.tick_disease_daily(peril, context)
    local def = Archetypes[peril.type]
    
    -- Spread logic
    if peril.active_infections > 0 then
        local spread_chance = (def.infectivity / 100) * (context.population_density or 1.0)
        if RNG.chance(spread_chance) then
            peril.active_infections = peril.active_infections + 1
        end
    end
    
    peril.days_remaining = peril.days_remaining - 1
    if peril.days_remaining <= 0 then
        peril.is_active = false
    end
end

--- Step a disaster for one day.
function Logic.tick_disaster_daily(peril)
    peril.days_remaining = peril.days_remaining - 1
    if peril.days_remaining <= 0 then
        peril.is_active = false
    end
end

--- Calculate the monthly impact of active perils.
function Logic.calculate_monthly_impact(active_perils)
    local impacts = {
        gold_loss = 0,
        unrest_gain = 0,
        home_damage = 0,
        food_scarcity = 0
    }
    
    for _, peril in ipairs(active_perils) do
        local def = Archetypes[peril.type]
        if peril.is_active and def.impacts then
            -- Scale impact by severity
            local scale = peril.severity / 100
            impacts.gold_loss = impacts.gold_loss + (def.impacts.gold_loss or 0) * scale
            impacts.unrest_gain = impacts.unrest_gain + (def.impacts.unrest or 0) * scale
            impacts.home_damage = impacts.home_damage + (def.impacts.home_damage or 0) * scale
            impacts.food_scarcity = impacts.food_scarcity + (def.impacts.food_scarcity or 0) * scale
        end
    end
    
    return impacts
end

return Logic
