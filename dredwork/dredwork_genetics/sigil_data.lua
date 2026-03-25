-- Bloodweight — Sigil Data Generator
-- Pure Lua module. No Solar2D dependencies.
-- Reads CulturalMemory + generation → sigil descriptor for Ink Sigil portrait mode.
-- The sigil represents the LINEAGE (not individual heirs) and morphs each generation
-- as cultural memory shifts.

local SigilData = {}

-- Reputation → base curve pattern
local REPUTATION_PATTERNS = {
    warriors  = "rose",
    tyrants   = "rose",
    survivors = "rose",
    scholars  = "lissajous",
    seekers   = "lissajous",
    artisans  = "lissajous",
    diplomats = "spirograph",
    mystics   = "spirograph",
    unknown   = "lissajous",
}

-- Reputation → dominant category key (for coloring)
local REPUTATION_CATEGORIES = {
    warriors  = "physical",
    tyrants   = "physical",
    survivors = "physical",
    scholars  = "mental",
    seekers   = "mental",
    diplomats = "social",
    artisans  = "creative",
    mystics   = "creative",
    unknown   = "mental",
}

-- Category colors for sigil layers
local CATEGORY_COLORS = {
    physical = { 0.70, 0.45, 0.30 },
    mental   = { 0.35, 0.55, 0.75 },
    social   = { 0.55, 0.70, 0.40 },
    creative = { 0.65, 0.40, 0.65 },
}

--- Calculate category priority averages from cultural memory trait_priorities.
---@param priorities table trait_priorities map
---@return table { physical, mental, social, creative } averaged 0-100
local function _category_averages(priorities)
    if not priorities then
        return { physical = 50, mental = 50, social = 50, creative = 50 }
    end

    local sums = { physical = 0, mental = 0, social = 0, creative = 0 }
    local counts = { physical = 0, mental = 0, social = 0, creative = 0 }

    for trait_id, value in pairs(priorities) do
        local prefix = trait_id:sub(1, 3)
        local cat
        if prefix == "PHY" then cat = "physical"
        elseif prefix == "MEN" then cat = "mental"
        elseif prefix == "SOC" then cat = "social"
        elseif prefix == "CRE" then cat = "creative"
        end
        if cat then
            sums[cat] = sums[cat] + (value or 50)
            counts[cat] = counts[cat] + 1
        end
    end

    local result = {}
    for cat, sum in pairs(sums) do
        local count = counts[cat]
        result[cat] = count > 0 and (sum / count) or 50
    end
    return result
end

--- Simple hash function for deterministic randomness.
---@param seed number
---@param offset number
---@return number 0-1
local function _hash(seed, offset)
    local x = math.sin(seed * 12.9898 + offset * 78.233) * 43758.5453
    return x - math.floor(x)
end

--- Generate a complete sigil descriptor from cultural memory.
---@param cultural_memory table CulturalMemory instance (must have trait_priorities, reputation, taboos, relationships)
---@param generation number current generation
---@return table sigil descriptor
function SigilData.generate(cultural_memory, generation)
    if not cultural_memory then return nil end

    generation = generation or 1

    -- Extract reputation
    local rep = "unknown"
    if cultural_memory.reputation and cultural_memory.reputation.primary then
        rep = cultural_memory.reputation.primary
    end

    -- Base pattern from reputation
    local base_pattern = REPUTATION_PATTERNS[rep] or "lissajous"
    local dominant_cat = REPUTATION_CATEGORIES[rep] or "mental"

    -- Category averages from trait priorities
    local cat_avgs = _category_averages(cultural_memory.trait_priorities)

    -- Map category averages to curve parameters (normalized to usable ranges)
    -- physical → a (frequency), mental → b (frequency), social → delta (phase), creative → d (pen distance)
    local a = 1 + math.floor((cat_avgs.physical / 100) * 6) -- 1-7
    local b = 1 + math.floor((cat_avgs.mental / 100) * 5)   -- 1-6
    local delta = (cat_avgs.social / 100) * math.pi * 2       -- 0 to 2pi
    local d = 1 + math.floor((cat_avgs.creative / 100) * 4)  -- 1-5

    -- Prevent degenerate patterns (a == b → circle for lissajous)
    if a == b and base_pattern == "lissajous" then b = b + 1 end

    -- Weathering: increases with generation (0 at gen 1, approaches 1.0 at gen 50+)
    local weathering = math.min(generation / 50, 1.0)

    -- Symmetry: starts at 4, degrades by 1 per taboo (min 1)
    local taboo_count = 0
    if cultural_memory.taboos then
        taboo_count = #cultural_memory.taboos
    end
    local symmetry = math.max(1, 4 - taboo_count)

    -- Seed for deterministic variation
    local seed = a * 1000 + b * 100 + generation

    -- Build curve layers from each non-dominant category
    local layers = {}
    local cats = { "physical", "mental", "social", "creative" }
    for _, cat in ipairs(cats) do
        if cat ~= dominant_cat and cat_avgs[cat] > 40 then
            -- Secondary curves represent other strong categories
            local layer_pattern = base_pattern -- use same family of curves
            local layer_a = 1 + math.floor((cat_avgs[cat] / 100) * 4)
            local layer_b = 1 + math.floor((cat_avgs[cat] / 100) * 3)
            if layer_a == layer_b and layer_pattern == "lissajous" then
                layer_b = layer_b + 1
            end
            layers[#layers + 1] = {
                pattern = layer_pattern,
                params = { a = layer_a, b = layer_b, delta = delta * 0.7, d = d },
                color = CATEGORY_COLORS[cat] or { 0.5, 0.5, 0.5 },
                scale = 0.65 + (cat_avgs[cat] / 100) * 0.2,
                alpha = 0.25 + (cat_avgs[cat] / 100) * 0.2,
            }
        end
    end

    -- Taboo scars: positioned based on hash of taboo data
    local taboo_scars = {}
    if cultural_memory.taboos then
        for i, taboo in ipairs(cultural_memory.taboos) do
            local angle = _hash(seed, i * 7) * math.pi * 2
            local dist = 0.3 + _hash(seed, i * 13) * 0.5
            taboo_scars[#taboo_scars + 1] = {
                x = math.cos(angle) * dist,
                y = math.sin(angle) * dist,
                strength = (taboo.strength or 50) / 100,
            }
        end
    end

    -- Relationship marks: allies = warm dots, enemies = cool dots
    local relationship_marks = {}
    if cultural_memory.relationships then
        for i, rel in ipairs(cultural_memory.relationships) do
            local angle = _hash(seed + 99, i * 11) * math.pi * 2
            local dist = 0.7 + _hash(seed + 99, i * 17) * 0.2
            local color
            if rel.type == "ally" then
                color = { 0.55, 0.70, 0.40 } -- green-ish
            else
                color = { 0.70, 0.25, 0.20 } -- red-ish
            end
            relationship_marks[#relationship_marks + 1] = {
                x = math.cos(angle) * dist,
                y = math.sin(angle) * dist,
                type = rel.type,
                color = color,
            }
        end
    end

    return {
        base_pattern = base_pattern,
        base_params = {
            a = a,
            b = b,
            delta = delta,
            d = d,
        },
        layers = layers,
        weathering = weathering,
        symmetry = symmetry,
        dominant_color_cat = dominant_cat,
        generation = generation,
        seed = seed,
        taboo_scars = taboo_scars,
        relationship_marks = relationship_marks,
    }
end

return SigilData
