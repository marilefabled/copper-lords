local Math = require("dredwork_core.math")
-- Dark Legacy — Lineage Power System
-- A 0-100 power score for the player's bloodline that rises and falls
-- based on heir impact, wealth, alliances, genetics, reputation, and more.
-- Pure Lua, zero Solar2D dependencies.

local LineagePower = {}

-- Power tier definitions
LineagePower.tiers = {
    { min = 85, label = "Dominant",    tone = "feared" },
    { min = 70, label = "Ascendant",   tone = "rising" },
    { min = 50, label = "Established", tone = "respected" },
    { min = 30, label = "Fading",      tone = "declining" },
    { min = 15, label = "Diminished",  tone = "weak" },
    { min = 0,  label = "Forgotten",   tone = "extinct" },
}

--- Create a new lineage power tracker.
---@param initial number|nil starting value (default 45)
---@return table lineage_power
function LineagePower.new(initial)
    return {
        value = initial or 45,
        peak = initial or 45,
        nadir = initial or 45,
        history = {},
    }
end

--- Get the tier for a given power value.
---@param lp table lineage_power
---@return table tier { label, tone, min }
function LineagePower.get_tier(lp)
    local v = lp.value or 0
    for _, tier in ipairs(LineagePower.tiers) do
        if v >= tier.min then
            return tier
        end
    end
    return LineagePower.tiers[#LineagePower.tiers]
end

--- Compute lineage power from all available sources.
--- Called once per generation during advance_generation.
---@param context table the full build_context output
---@param lp table lineage_power state
---@return number new_value (clamped 0-100)
function LineagePower.compute(context, lp)
    local sources = {}

    -- 1. Heir Impact (weight 0.20)
    local heir_impact = 50
    if context.heir_ledger_entry and context.heir_ledger_entry.impact_score then
        -- impact_score ranges roughly -100..100, normalize to 0-100
        heir_impact = Math.clamp(50 + context.heir_ledger_entry.impact_score / 2, 0, 100)
    end
    sources.heir_impact = heir_impact

    -- 2. Wealth (weight 0.15)
    local wealth_val = 50
    if context.wealth and context.wealth.value then
        wealth_val = context.wealth.value
    end
    sources.wealth = wealth_val

    -- 2b. Passive wealth bonus/penalty (extreme wealth creates its own power)
    local wealth_bonus = 0
    if wealth_val >= 90 then wealth_bonus = 5
    elseif wealth_val <= 15 then wealth_bonus = -5
    end
    sources.wealth_passive = 50 + wealth_bonus * 5 -- scale to match sources

    -- 3. Alliance Network (weight 0.15)
    local alliance_score = 0
    if context.cultural_memory and context.cultural_memory.relationships then
        local ally_count = 0
        local ally_strength = 0
        for _, rel in ipairs(context.cultural_memory.relationships) do
            if rel.type == "ally" then
                ally_count = ally_count + 1
                ally_strength = ally_strength + (rel.strength or 0)
            end
        end
        if ally_count > 0 then
            alliance_score = math.min(100, ally_count * 15 + ally_strength / ally_count)
        end
    end
    sources.alliances = alliance_score

    -- 4. Trait Peaks (weight 0.10) — avg of top 5 trait values
    local trait_peak_score = 50
    if context.heir_genome then
        local vals = {}
        local trait_defs = nil
        pcall(function()
            trait_defs = require("dredwork_genetics.config.trait_definitions")
        end)
        if trait_defs then
            for _, tdef in ipairs(trait_defs) do
                local v = context.heir_genome:get_value(tdef.id)
                if v then vals[#vals + 1] = v end
            end
        end
        -- Sort descending, take top 5
        table.sort(vals, function(a, b) return a > b end)
        local sum = 0
        local count = math.min(5, #vals)
        for i = 1, count do
            sum = sum + vals[i]
        end
        if count > 0 then
            trait_peak_score = sum / count
        end
    end
    sources.trait_peaks = trait_peak_score

    -- 5. Reputation strength (weight 0.10)
    local rep_score = 50
    if context.cultural_memory and context.cultural_memory.reputation then
        local rep = context.cultural_memory.reputation
        -- A strong identity (not "unknown") is powerful
        if rep.primary and rep.primary ~= "unknown" then
            rep_score = 65
        end
        if rep.secondary and rep.secondary ~= "unknown" then
            rep_score = rep_score + 10
        end
        rep_score = math.min(100, rep_score)
    end
    sources.reputation = rep_score

    -- 6. Discoveries (weight 0.10)
    local disc_score = 0
    if context.discoveries then
        local count = 0
        pcall(function() count = context.discoveries:count() end)
        disc_score = math.min(100, count * 8)
    end
    sources.discoveries = disc_score

    -- 7. Great Works (weight 0.10)
    local gw_score = 0
    if context.great_works then
        local count = 0
        pcall(function() count = context.great_works:count() end)
        gw_score = math.min(100, count * 15)
        -- Bonus for work in progress
        local building = false
        pcall(function() building = context.great_works:is_building() end)
        if building then gw_score = math.min(100, gw_score + 10) end
    end
    sources.great_works = gw_score

    -- 8. Religion zealotry (weight 0.05)
    local rel_score = 0
    if context.religion and context.religion.active then
        rel_score = math.min(100, (context.religion.zealotry or 0))
    end
    sources.religion = rel_score

    -- 9. Morality standing (weight 0.05) — absolute value; saints AND tyrants are powerful
    local moral_score = 0
    if context.morality then
        moral_score = math.min(100, math.abs(context.morality.score or 0))
    end
    sources.morality = moral_score

    -- Weighted sum
    local weights = {
        heir_impact    = 0.25,
        wealth         = 0.15,
        wealth_passive = 0.05,
        alliances      = 0.15,
        trait_peaks    = 0.10,
        reputation     = 0.10,
        discoveries    = 0.10,
        great_works    = 0.10,
        religion       = 0.025,
        morality       = 0.025,
    }

    local raw = 0
    for key, weight in pairs(weights) do
        raw = raw + (sources[key] or 0) * weight
    end

    -- Natural regression: 2% toward 50 per generation
    local current = lp.value or 45
    local regressed = current * 0.98 + 50 * 0.02

    -- Blend: 70% computed, 30% regressed (prevents wild swings)
    local blended = raw * 0.70 + regressed * 0.30
    local final = Math.clamp(math.floor(blended + 0.5), 0, 100)

    -- Track history
    lp.history[#lp.history + 1] = { value = final, generation = context.generation or 0 }
    if #lp.history > 20 then table.remove(lp.history, 1) end
    lp.value = final
    if final > lp.peak then lp.peak = final end
    if final < lp.nadir then lp.nadir = final end

    return final
end

--- Apply a one-time power shift (e.g. heir death, crucible result).
---@param lp table lineage_power
---@param delta number amount to shift (+/-)
function LineagePower.shift(lp, delta)
    lp.value = Math.clamp((lp.value or 45) + delta, 0, 100)
    if lp.value > lp.peak then lp.peak = lp.value end
    if lp.value < lp.nadir then lp.nadir = lp.value end
end

--- Narrative description of current power.
---@param lp table lineage_power
---@return string
function LineagePower.describe(lp, world_name)
    local tier = LineagePower.get_tier(lp)
    local wn = world_name or "Caldemyr"
    local descriptions = {
        Dominant    = "Your bloodline commands fear and respect across all of " .. wn .. ". None dare move against you.",
        Ascendant   = "Your house is rising. Factions take notice. The bold see opportunity.",
        Established = "Your lineage holds its own among the powers of " .. wn .. ". Respected, but not feared.",
        Fading      = "The glory days are behind you. Rivals sense weakness. Options narrow.",
        Diminished  = "Your bloodline clings to relevance. Predators circle.",
        Forgotten   = "The world has moved on. Your name is a whisper, not a command.",
    }
    return descriptions[tier.label] or "Your bloodline endures."
end

--- Check if a power gate passes.
---@param lp table lineage_power
---@param min_power number|nil minimum power required
---@param max_power number|nil maximum power allowed
---@return boolean passed
---@return string|nil reason if failed
function LineagePower.check_gate(lp, min_power, max_power)
    local v = lp.value or 0
    if min_power and v < min_power then
        local tier = LineagePower.get_tier(lp)
        return false, "Your house is too " .. tier.tone .. " (need power " .. min_power .. "+)"
    end
    if max_power and v > max_power then
        return false, "Your house is too powerful for this option"
    end
    return true, nil
end

--- Serialization
function LineagePower.to_table(lp)
    return {
        value = lp.value,
        peak = lp.peak,
        nadir = lp.nadir,
        history = lp.history,
    }
end

function LineagePower.from_table(data)
    if not data then return LineagePower.new() end
    return {
        value = data.value or 45,
        peak = data.peak or data.value or 45,
        nadir = data.nadir or data.value or 45,
        history = data.history or {},
    }
end

return LineagePower
