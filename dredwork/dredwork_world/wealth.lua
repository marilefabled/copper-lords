local Math = require("dredwork_core.math")
-- Dark Legacy — Lineage Wealth System
-- Pure Lua module, no Solar2D dependencies
-- Wealth is a lineage-level resource (0-100) that affects matchmaking,
-- event availability, faction disposition, and narrative flavor.

local Wealth = {}

--- Wealth tier definitions
local TIERS = {
    { max = 15,  label = "Destitute",    tone = "dark",    matchmaking_penalty = -15 },
    { max = 30,  label = "Impoverished", tone = "cold",    matchmaking_penalty = -8 },
    { max = 45,  label = "Modest",       tone = "dim",     matchmaking_penalty = 0 },
    { max = 60,  label = "Comfortable",  tone = "neutral", matchmaking_penalty = 0 },
    { max = 75,  label = "Wealthy",      tone = "warm",    matchmaking_penalty = 0 },
    { max = 90,  label = "Elite",        tone = "bright",  matchmaking_penalty = 0 },
    { max = 100, label = "Dynastic",     tone = "gold",    matchmaking_penalty = 0 },
}

--- Wealth change sources and their typical magnitudes
local SOURCE_WEIGHTS = {
    trade       = 1.0,   -- trade route events, economic expansion
    tribute     = 0.8,   -- received from factions
    plunder     = 1.2,   -- war spoils
    investment  = 0.7,   -- arts, infrastructure
    loss        = 1.0,   -- war costs, famine drain, betrayal
    marriage    = 0.5,   -- dowry/alliance economics
    council     = 0.6,   -- council economic actions
    crime       = 0.9,   -- illicit gains
    discovery   = 0.4,   -- discovery bonuses
}

--- Create a new wealth state.
---@param initial number? starting value (default 50)
---@return table wealth state
function Wealth.new(initial)
    return {
        value = initial or 50,
        history = {},  -- { { generation, delta, source, description } }
        peak = initial or 50,
        nadir = initial or 50,
    }
end

--- Get the current wealth tier.
---@param wealth table wealth state
---@return table tier { label, tone, matchmaking_penalty }
function Wealth.get_tier(wealth)
    local v = wealth.value or 50
    for _, tier in ipairs(TIERS) do
        if v <= tier.max then
            return tier
        end
    end
    return TIERS[#TIERS]
end

--- Apply a wealth change.
---@param wealth table wealth state
---@param delta number amount to change (positive = gain, negative = loss)
---@param source string source category (trade, plunder, loss, etc.)
---@param generation number current generation
---@param description string? human-readable reason
function Wealth.change(wealth, delta, source, generation, description)
    -- Apply source weight modifier
    local weight = SOURCE_WEIGHTS[source] or 1.0
    local effective_delta = delta * weight

    wealth.value = Math.clamp(wealth.value + effective_delta, 0, 100)

    -- Track peak and nadir
    if wealth.value > wealth.peak then wealth.peak = wealth.value end
    if wealth.value < wealth.nadir then wealth.nadir = wealth.value end

    -- Record in history
    wealth.history[#wealth.history + 1] = {
        generation = generation,
        delta = effective_delta,
        source = source,
        description = description or source,
    }
    if #wealth.history > 20 then table.remove(wealth.history, 1) end
end

--- Natural decay/drift toward 50 each generation.
--- Wealth tends to normalize — dynasties don't stay rich or poor forever without effort.
---@param wealth table wealth state
---@param generation number current generation
function Wealth.decay(wealth, generation)
    local v = wealth.value
    -- 3% regression toward 50 per generation
    local decay_rate = 0.03
    local new_value = v + (50 - v) * decay_rate
    wealth.value = Math.clamp(new_value, 0, 100)
end

--- Get wealth modifier for matchmaking candidate quality.
--- Wealthy families attract better candidates; destitute families get leftovers.
---@param wealth table wealth state
---@return number modifier (-15 to +10)
function Wealth.matchmaking_modifier(wealth)
    local tier = Wealth.get_tier(wealth)
    if wealth.value >= 75 then
        return math.floor((wealth.value - 60) / 4)  -- +3 to +10
    end
    return tier.matchmaking_penalty
end

--- Get wealth modifier for faction disposition.
--- Rich families are more respected; poor families are pitied or preyed upon.
---@param wealth table wealth state
---@return number disposition modifier
function Wealth.disposition_modifier(wealth)
    if wealth.value >= 80 then return 5 end
    if wealth.value >= 60 then return 2 end
    if wealth.value >= 40 then return 0 end
    if wealth.value >= 20 then return -3 end
    return -8
end

--- Check if a wealth-gated option is available.
---@param wealth table wealth state
---@param min_wealth number? minimum wealth required
---@param max_wealth number? maximum wealth allowed
---@return boolean available
---@return string? reason if not available
function Wealth.check_gate(wealth, min_wealth, max_wealth)
    if min_wealth and wealth.value < min_wealth then
        local tier = Wealth.get_tier(wealth)
        return false, "The bloodline is too " .. tier.label:lower() .. " for this path."
    end
    if max_wealth and wealth.value > max_wealth then
        return false, "The bloodline's wealth makes this unnecessary."
    end
    return true, nil
end

--- Get net wealth change for a specific generation.
---@param wealth table wealth state
---@param generation number
---@return number net delta for that generation
function Wealth.generation_net(wealth, generation)
    local net = 0
    for _, record in ipairs(wealth.history) do
        if record.generation == generation then
            net = net + record.delta
        end
    end
    return net
end

--- Get a narrative description of the current wealth state.
---@param wealth table wealth state
---@return string narrative
function Wealth.describe(wealth)
    local tier = Wealth.get_tier(wealth)
    local descriptions = {
        Destitute    = "The coffers are bare. The bloodline scrapes by on pride alone.",
        Impoverished = "Times are lean. The family name outweighs the family purse.",
        Modest       = "Neither rich nor poor. The bloodline sustains itself adequately.",
        Comfortable  = "The family wants for nothing. A stable, respectable position.",
        Wealthy      = "Gold flows freely. The bloodline commands economic respect.",
        Elite        = "The family's wealth opens doors that power alone cannot.",
        Dynastic     = "A fortune spanning generations. The bloodline defines prosperity.",
    }
    return descriptions[tier.label] or ""
end

return Wealth
