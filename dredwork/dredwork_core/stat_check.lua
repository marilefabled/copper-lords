-- dredwork Core — Multi-Trait Stat Check
-- Weighted trait resolution with personality modifiers, cultural bonuses, and quality tiers.
-- Ported from Bloodweight's stat_check.lua, decoupled from all external systems.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local StatCheck = {}

--- Quality tiers for check results.
StatCheck.TIERS = {
    TRIUMPH  = "triumph",   -- margin >= 20
    SUCCESS  = "success",   -- margin >= 0
    FAILURE  = "failure",   -- margin >= -15
    DISASTER = "disaster",  -- margin < -15
}

--- Evaluate a stat check.
---@param params table {
---   traits: table { {id, weight}, ... } — traits to check and their weights
---   difficulty: number — target to beat (0-100)
---   get_trait_value: function(trait_id) → number — accessor for trait values
---   personality: table|nil { axis, value } — personality bonus context
---   bonuses: table|nil { {source, value}, ... } — flat bonuses from any source
---   variance: number|nil — random variance range (default 10)
--- }
---@return table { score, difficulty, margin, tier, breakdown }
function StatCheck.evaluate(params)
    local traits = params.traits or {}
    local difficulty = params.difficulty or 50
    local get_value = params.get_trait_value
    local variance = params.variance or 10

    -- 1. Weighted trait average
    local total_weight = 0
    local weighted_sum = 0
    local breakdown = {}

    for _, entry in ipairs(traits) do
        local val = get_value and get_value(entry.id) or 50
        local w = entry.weight or 1.0
        weighted_sum = weighted_sum + val * w
        total_weight = total_weight + w
        table.insert(breakdown, { trait = entry.id, value = val, weight = w })
    end

    local base_score = total_weight > 0 and (weighted_sum / total_weight) or 50

    -- 2. Personality bonus (±10 range)
    local personality_bonus = 0
    if params.personality and params.personality.value then
        local axis_val = params.personality.value
        personality_bonus = Math.clamp((axis_val - 50) / 5, -10, 10)
    end

    -- 3. External bonuses (culture, wild attributes, momentum, etc.)
    local flat_bonus = 0
    if params.bonuses then
        for _, b in ipairs(params.bonuses) do
            flat_bonus = flat_bonus + (b.value or 0)
        end
    end

    -- 4. Random variance
    local roll = RNG.range(-variance, variance)

    -- 5. Final score
    local score = Math.clamp(base_score + personality_bonus + flat_bonus + roll, 0, 100)
    local margin = score - difficulty

    -- 6. Determine tier
    local tier
    if margin >= 20 then
        tier = StatCheck.TIERS.TRIUMPH
    elseif margin >= 0 then
        tier = StatCheck.TIERS.SUCCESS
    elseif margin >= -15 then
        tier = StatCheck.TIERS.FAILURE
    else
        tier = StatCheck.TIERS.DISASTER
    end

    return {
        score = math.floor(score),
        difficulty = difficulty,
        margin = math.floor(margin),
        tier = tier,
        breakdown = breakdown,
        personality_bonus = personality_bonus,
        flat_bonus = flat_bonus,
        roll = roll,
    }
end

--- Evaluate against a rival (difficulty = rival's weighted trait score).
---@param params table Same as evaluate, plus rival_get_value function
---@return table Same as evaluate
function StatCheck.evaluate_vs_rival(params)
    local rival_get = params.rival_get_trait_value
    if rival_get then
        local rival_sum, rival_weight = 0, 0
        for _, entry in ipairs(params.traits or {}) do
            rival_sum = rival_sum + (rival_get(entry.id) or 50) * (entry.weight or 1.0)
            rival_weight = rival_weight + (entry.weight or 1.0)
        end
        params.difficulty = rival_weight > 0 and (rival_sum / rival_weight) or 50
    end
    return StatCheck.evaluate(params)
end

return StatCheck
