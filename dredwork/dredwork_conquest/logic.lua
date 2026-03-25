-- dredwork Conquest — Logic
-- Empire building: seizure, resistance, assimilation, rebellion, and governance.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")
local Statuses = require("dredwork_conquest.status")

local Logic = {}

function Logic.seize_region(region_id, faction_id, status_key)
    local status = Statuses[status_key] or Statuses.occupation
    return {
        region_id = region_id,
        conqueror_id = faction_id,
        status = status_key,
        resistance = 50,
        years_held = 0,
        tribute_extracted = 0,
        is_rebellious = false,
        assimilation = 0,         -- 0-100: how culturally integrated the territory is
        garrison_strength = 0,     -- cached from military queries
        governor_competence = 50,  -- governance quality
        population_loyalty = 30,   -- distinct from resistance (long-term)
    }
end

--- Simulate the state of a conquered region for one tick.
function Logic.tick(record, context)
    local lines = {}
    local status = Statuses[record.status]
    local scale = context.scale or 1.0

    record.years_held = record.years_held + scale

    -- 1. Military presence dampens resistance
    local mil_presence = context.military_presence or 0
    record.garrison_strength = mil_presence

    -- Target resistance based on status + military + governance
    local target_res = status.unrest_base
    if mil_presence > 100 then
        target_res = target_res - (mil_presence / 10)
    end
    -- Good governance reduces resistance
    target_res = target_res - (record.governor_competence - 50) * 0.2

    record.resistance = Math.clamp(
        record.resistance + (target_res - record.resistance) * 0.05 * scale,
        0, 100
    )

    -- 2. Assimilation (slow, requires low resistance)
    if record.resistance < 40 and not record.is_rebellious then
        local assimilation_rate = 0.5 * scale
        -- Better governance speeds assimilation
        assimilation_rate = assimilation_rate + (record.governor_competence - 50) * 0.01
        record.assimilation = Math.clamp(record.assimilation + assimilation_rate, 0, 100)
    elseif record.is_rebellious then
        -- Rebellion reverses assimilation
        record.assimilation = Math.clamp(record.assimilation - 2 * scale, 0, 100)
    end

    -- 3. Population loyalty (long-term relationship, distinct from resistance)
    if record.resistance < 30 then
        record.population_loyalty = Math.clamp(record.population_loyalty + 0.3 * scale, 0, 100)
    elseif record.resistance > 60 then
        record.population_loyalty = Math.clamp(record.population_loyalty - 0.5 * scale, 0, 100)
    end

    -- 4. Rebellion check
    if record.resistance > 75 and RNG.chance(0.15 * scale) then
        record.is_rebellious = true
        record.population_loyalty = Math.clamp(record.population_loyalty - 15, 0, 100)
        table.insert(lines, string.format("REBELLION in %s! The people rise against occupation!", record.region_id))
    end

    -- Rebellion suppression (if garrison is strong enough)
    if record.is_rebellious and mil_presence > 150 and RNG.chance(0.3) then
        record.is_rebellious = false
        record.resistance = Math.clamp(record.resistance - 20, 0, 100)
        table.insert(lines, string.format("The rebellion in %s has been suppressed.", record.region_id))
    end

    -- 5. Status transitions
    -- Occupation → Vassal (if assimilation > 40)
    if record.status == "occupation" and record.assimilation > 40 and record.resistance < 30 then
        record.status = "vassal"
        table.insert(lines, string.format("%s transitions from occupation to vassal status.", record.region_id))
    end
    -- Vassal → Integrated (if assimilation > 80)
    if record.status == "vassal" and record.assimilation > 80 and record.population_loyalty > 60 then
        record.status = "integrated"
        table.insert(lines, string.format("%s is now fully integrated into the realm.", record.region_id))
    end

    -- 6. Integration Progress
    if not record.is_rebellious and record.status == "occupation" and record.resistance < 40 then
        table.insert(lines, string.format("The occupation of %s is stabilizing.", record.region_id))
    end

    return lines
end

function Logic.calculate_tribute(record, market_wealth)
    local status = Statuses[record.status]
    local base = market_wealth * 0.5
    local resistance_penalty = (100 - record.resistance) / 100
    local loyalty_bonus = record.population_loyalty / 200 -- up to 50% extra from loyalty

    local total = base * status.tribute_mult * resistance_penalty * (1 + loyalty_bonus)
    -- Rebellious territories pay nothing
    if record.is_rebellious then total = 0 end

    record.tribute_extracted = record.tribute_extracted + total
    return math.floor(total)
end

--- Assign a governor (affects governance quality).
function Logic.set_governor(record, competence)
    record.governor_competence = Math.clamp(competence or 50, 0, 100)
end

return Logic
