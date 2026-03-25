-- dredwork Agency — Entity Needs
-- Entities have needs that rise and fall based on world state.
-- Unmet needs shift goal priorities — a safe general builds legacy, an unsafe one fortifies.

local Math = require("dredwork_core.math")

local Needs = {}

--- Create a fresh needs component.
function Needs.create()
    return {
        safety    = 50,   -- 0 = terrified, 100 = completely secure
        belonging = 50,   -- 0 = isolated, 100 = deeply connected
        purpose   = 50,   -- 0 = directionless, 100 = driven
        comfort   = 50,   -- 0 = suffering, 100 = luxurious
        status    = 50,   -- 0 = nobody, 100 = revered
    }
end

--- Update needs based on entity context (called monthly).
---@param needs table the needs component
---@param context table { has_home, home_comfort, relationship_count, loyalty_avg,
---   is_at_war, has_peril, has_purpose, wealth, legitimacy, unrest }
function Needs.update(needs, context)
    context = context or {}

    -- SAFETY: affected by war, peril, unrest, military strength
    if context.is_at_war or context.has_peril then
        needs.safety = Math.clamp(needs.safety - 3, 0, 100)
    elseif (context.unrest or 0) > 50 then
        needs.safety = Math.clamp(needs.safety - 1, 0, 100)
    else
        needs.safety = Math.clamp(needs.safety + 1, 0, 100)
    end

    -- BELONGING: affected by relationships, court size, loyalty
    local rel_count = context.relationship_count or 0
    if rel_count > 3 then
        needs.belonging = Math.clamp(needs.belonging + 1, 0, 100)
    elseif rel_count == 0 then
        needs.belonging = Math.clamp(needs.belonging - 3, 0, 100)
    end
    if (context.loyalty_avg or 50) > 60 then
        needs.belonging = Math.clamp(needs.belonging + 0.5, 0, 100)
    end

    -- PURPOSE: affected by having active goals, recent deeds
    if context.has_purpose then
        needs.purpose = Math.clamp(needs.purpose + 1, 0, 100)
    else
        needs.purpose = Math.clamp(needs.purpose - 1, 0, 100)
    end

    -- COMFORT: affected by home, wealth
    if context.home_comfort and context.home_comfort > 60 then
        needs.comfort = Math.clamp(needs.comfort + 1, 0, 100)
    elseif context.home_comfort and context.home_comfort < 30 then
        needs.comfort = Math.clamp(needs.comfort - 2, 0, 100)
    end
    if (context.wealth or 0) > 200 then
        needs.comfort = Math.clamp(needs.comfort + 0.5, 0, 100)
    end

    -- STATUS: affected by legitimacy, prestige, heritage
    if (context.legitimacy or 50) > 60 then
        needs.status = Math.clamp(needs.status + 0.5, 0, 100)
    elseif (context.legitimacy or 50) < 30 then
        needs.status = Math.clamp(needs.status - 1, 0, 100)
    end

    -- WEALTH CRISIS: poverty crushes everything
    if context.wealth_crisis then
        needs.safety = Math.clamp(needs.safety - 8, 0, 100)
        needs.comfort = Math.clamp(needs.comfort - 10, 0, 100)
        needs.purpose = Math.clamp(needs.purpose - 5, 0, 100)
    end
end

--- Get the most unmet need (lowest value).
function Needs.get_most_unmet(needs)
    local worst_need, worst_val = "safety", 100
    for need, val in pairs(needs) do
        if type(val) == "number" and val < worst_val then
            worst_need = need
            worst_val = val
        end
    end
    return worst_need, worst_val
end

--- Map unmet needs to goal priority boosts.
---@return table { goal_id = priority_boost }
function Needs.get_goal_boosts(needs)
    local boosts = {}

    -- Low safety → survive, fortify
    if needs.safety < 30 then
        boosts.survive = 20
        boosts.protect_family = 15
    end

    -- Low belonging → build loyalty, find mate
    if needs.belonging < 30 then
        boosts.build_loyalty = 15
        boosts.find_mate = 10
    end

    -- Low purpose → seek knowledge, build legacy, conquer
    if needs.purpose < 30 then
        boosts.seek_knowledge = 10
        boosts.build_legacy = 10
        boosts.conquer = 10
    end

    -- Low comfort → seek comfort, accumulate
    if needs.comfort < 30 then
        boosts.seek_comfort = 15
        boosts.accumulate = 10
    end

    -- Low status → gain power, build legacy
    if needs.status < 30 then
        boosts.gain_power = 15
        boosts.build_legacy = 10
    end

    return boosts
end

return Needs
