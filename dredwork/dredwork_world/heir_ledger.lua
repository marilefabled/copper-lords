local Math = require("dredwork_core.math")
-- Dark Legacy — Heir Ledger: Contribution tracking per generation
-- Pure Lua module, no Solar2D dependencies

local HeirLedger = {}

--- Score categories and their weight in the composite score
local SCORE_WEIGHTS = {
    cultural_shift  = 0.20,  -- how much they moved the cultural needle
    reputation      = 0.15,  -- reputation archetype shifts
    alliances       = 0.15,  -- relationships gained or strengthened
    conditions      = 0.10,  -- conditions weathered or caused
    traits          = 0.15,  -- peak trait contributions vs lineage average
    dream_progress  = 0.10,  -- progress toward bloodline dream
    wealth_impact   = 0.10,  -- net wealth change (when wealth system exists)
    morality        = 0.05,  -- net moral acts (when morality system exists)
}

--- Descriptors for heir impact rating
local IMPACT_TIERS = {
    { min = 80, label = "Legendary",   tone = "gold" },
    { min = 60, label = "Exalted",     tone = "bright" },
    { min = 40, label = "Formidable",  tone = "warm" },
    { min = 20, label = "Capable",     tone = "neutral" },
    { min = 0,  label = "Mediocre",    tone = "dim" },
    { min = -20, label = "Wretched",    tone = "cold" },
    { min = -100, label = "Accursed",   tone = "dark" },
}

--- Compute cultural shift score from memory deltas.
---@param deltas table { physical=n, mental=n, social=n, creative=n }
---@return number score 0-100
local function score_cultural_shift(deltas)
    if not deltas then return 50 end
    local total = 0
    for _, v in pairs(deltas) do
        total = total + math.abs(v)
    end
    -- Each point of absolute shift is worth ~5 score points, capped at 100
    return math.min(100, total * 5)
end

--- Compute trait contribution score: how the heir's peaks compare to lineage average.
---@param heir table heir data with traits
---@param trait_priorities table cultural memory trait priorities
---@return number score 0-100
local function score_traits(heir, trait_priorities)
    if not heir or not heir.traits then return 50 end
    local above = 0
    local count = 0
    for trait_id, trait in pairs(heir.traits) do
        local baseline = trait_priorities and trait_priorities[trait_id] or 50
        local val = trait:get_value()
        if val > baseline then
            above = above + (val - baseline)
        end
        count = count + 1
    end
    if count == 0 then return 50 end
    -- Average excess per trait, scaled to 0-100
    return math.min(100, 50 + (above / count) * 3)
end

--- Compute alliance score from disposition changes.
---@param disposition_deltas table { {faction_id, delta}, ... }
---@return number score 0-100
local function score_alliances(disposition_deltas)
    if not disposition_deltas then return 50 end
    local net = 0
    for _, change in ipairs(disposition_deltas) do
        net = net + (change.delta or 0)
    end
    -- Center on 50, each point of net disposition = 2 score points
    return Math.clamp(50 + net * 2, 0, 100)
end

--- Compute conditions score: weathering negative conditions is positive.
---@param conditions_weathered number count of negative conditions active during reign
---@param conditions_caused number count of conditions the heir's choices triggered
---@return number score 0-100
local function score_conditions(conditions_weathered, conditions_caused)
    -- Weathering conditions is good (resilience), causing them is neutral/bad
    local w = conditions_weathered or 0
    local c = conditions_caused or 0
    return Math.clamp(50 + w * 10 - c * 15, 0, 100)
end

--- Compute dream progress score.
---@param dream_delta number how much closer to dream fulfillment (-1 to 1)
---@return number score 0-100
local function score_dream(dream_delta)
    if not dream_delta then return 50 end
    return Math.clamp(50 + dream_delta * 50, 0, 100)
end

--- Create a ledger entry for one heir/generation.
---@param params table
---@return table entry
function HeirLedger.record(params)
    local entry = {
        generation     = params.generation or 0,
        heir_name      = params.heir_name or "Unknown",
        legend_title   = params.legend_title,
        era            = params.era or "unknown",
        
        -- Visual reproduction data
        genome_data    = params.genome_data, -- table from Serializer.genome_to_table
        personality_data = params.personality_data, -- table from personality:to_table()

        -- Sub-scores (each 0-100, higher = more positive contribution)
        cultural_shift = score_cultural_shift(params.cultural_deltas),
        reputation     = params.reputation_score or 50,
        alliances      = score_alliances(params.disposition_deltas),
        conditions     = score_conditions(params.conditions_weathered, params.conditions_caused),
        traits         = score_traits(params.heir, params.trait_priorities),
        dream_progress = score_dream(params.dream_delta),
        wealth_impact  = params.wealth_score or 50,
        morality       = params.morality_score or 50,

        -- Raw event tracking
        events_faced    = params.events_faced or 0,
        council_actions = params.council_actions or 0,
        acts = params.acts or {},  -- { "honored_debt", "betrayed_ally", "invested_arts" }

        -- Epitaph: one-line memorial generated at succession
        epitaph = params.epitaph,
    }

    -- Composite impact score (weighted sum centered on 50)
    local composite = 0
    for key, weight in pairs(SCORE_WEIGHTS) do
        composite = composite + (entry[key] or 50) * weight
    end
    entry.impact_score = math.floor(composite)

    -- Impact rating descriptor
    entry.impact_rating = "Forgettable"
    entry.impact_tone = "dim"
    for _, tier in ipairs(IMPACT_TIERS) do
        if entry.impact_score >= tier.min then
            entry.impact_rating = tier.label
            entry.impact_tone = tier.tone
            break
        end
    end

    return entry
end

--- Add an entry to the lineage ledger history.
---@param ledger table array of entries (persistent)
---@param entry table from HeirLedger.record()
function HeirLedger.append(ledger, entry)
    ledger[#ledger + 1] = entry
end

--- Update the most recent entry with additional data (e.g. epitaph, legend).
---@param ledger table array of entries
---@param fields table key-value pairs to merge into the last entry
function HeirLedger.update_last(ledger, fields)
    if not ledger or #ledger == 0 or not fields then return end
    local last = ledger[#ledger]
    for k, v in pairs(fields) do
        last[k] = v
    end
end

--- Get the entry for a specific generation.
---@param ledger table array of entries
---@param generation number
---@return table|nil entry
function HeirLedger.get(ledger, generation)
    for _, entry in ipairs(ledger) do
        if entry.generation == generation then
            return entry
        end
    end
    return nil
end

--- Get summary statistics across the full lineage.
---@param ledger table array of entries
---@return table stats
function HeirLedger.summary(ledger)
    if not ledger or #ledger == 0 then
        return { count = 0, avg_impact = 0, best = nil, worst = nil }
    end

    local total = 0
    local best, worst
    for _, entry in ipairs(ledger) do
        total = total + entry.impact_score
        if not best or entry.impact_score > best.impact_score then
            best = entry
        end
        if not worst or entry.impact_score < worst.impact_score then
            worst = entry
        end
    end

    return {
        count = #ledger,
        avg_impact = math.floor(total / #ledger),
        best = best,
        worst = worst,
        total_impact = total,
    }
end

--- Get a narrative description of an heir's contribution.
---@param entry table ledger entry
---@return string narrative
function HeirLedger.describe(entry)
    if not entry then return "" end

    local parts = {}
    parts[#parts + 1] = entry.heir_name .. " (Gen " .. entry.generation .. ")"
    parts[#parts + 1] = "Impact: " .. entry.impact_rating .. " (" .. entry.impact_score .. ")"

    -- Highlight strongest and weakest contributions
    local best_cat, best_val = nil, 0
    local worst_cat, worst_val = nil, 100
    for key, _ in pairs(SCORE_WEIGHTS) do
        local val = entry[key] or 50
        if val > best_val then best_cat, best_val = key, val end
        if val < worst_val then worst_cat, worst_val = key, val end
    end

    if best_cat then
        local labels = {
            cultural_shift = "cultural transformation",
            reputation = "reputation building",
            alliances = "alliance forging",
            conditions = "crisis weathering",
            traits = "genetic excellence",
            dream_progress = "dream pursuit",
            wealth_impact = "wealth generation",
            morality = "moral standing",
        }
        parts[#parts + 1] = "Strongest: " .. (labels[best_cat] or best_cat)
        if worst_cat and worst_cat ~= best_cat then
            parts[#parts + 1] = "Weakest: " .. (labels[worst_cat] or worst_cat)
        end
    end

    return table.concat(parts, " | ")
end

--- Get the top N heirs by impact score.
---@param ledger table array of entries
---@param n number how many to return (default 5)
---@return table array of entries, sorted best to worst
function HeirLedger.top(ledger, n)
    n = n or 5
    if not ledger or #ledger == 0 then return {} end

    local sorted = {}
    for _, entry in ipairs(ledger) do
        sorted[#sorted + 1] = entry
    end
    table.sort(sorted, function(a, b)
        return a.impact_score > b.impact_score
    end)

    local result = {}
    for i = 1, math.min(n, #sorted) do
        result[i] = sorted[i]
    end
    return result
end

--- Get the bottom N heirs by impact score.
---@param ledger table array of entries
---@param n number how many to return (default 5)
---@return table array of entries, sorted worst to best
function HeirLedger.bottom(ledger, n)
    n = n or 5
    if not ledger or #ledger == 0 then return {} end

    local sorted = {}
    for _, entry in ipairs(ledger) do
        sorted[#sorted + 1] = entry
    end
    table.sort(sorted, function(a, b)
        return a.impact_score < b.impact_score
    end)

    local result = {}
    for i = 1, math.min(n, #sorted) do
        result[i] = sorted[i]
    end
    return result
end

return HeirLedger
