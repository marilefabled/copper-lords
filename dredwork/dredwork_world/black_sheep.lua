-- Dark Legacy — Black Sheep Detection
-- Flags heirs who dramatically contradict the family's cultural memory.
-- A warrior dynasty that produces a creative genius. A merciful lineage
-- that births a monster. Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local BlackSheep = {}

-- Category keys for comparison
local CATEGORIES = { "physical", "mental", "social", "creative" }

-- Category prefix mapping
local prefix_to_category = {
    PHY = "physical",
    MEN = "mental",
    SOC = "social",
    CRE = "creative",
}

-- Narrative fragments for different contrast types
local narratives = {
    creative_in_warrior_family = {
        "This one sees beauty where the bloodline sees only battle.",
        "The family breeds warriors. This child builds worlds.",
        "Where ancestors wielded swords, this heir wields imagination.",
    },
    mental_in_warrior_family = {
        "A scholar born to warriors. The blood does not understand.",
        "This one thinks when the family demands action.",
    },
    physical_in_scholar_family = {
        "Brute strength in a lineage of thinkers. An anomaly.",
        "The family prizes intellect. This child prizes power.",
    },
    social_in_artisan_family = {
        "A diplomat born to makers. The forge holds no interest.",
        "This heir speaks where the bloodline builds.",
    },
    cruel_in_merciful_family = {
        "Cruelty stirs in a lineage known for mercy. The family recoils.",
        "Where the bloodline heals, this one would harm.",
    },
    merciful_in_cruel_family = {
        "Mercy — impossible in this bloodline, yet here it is.",
        "This heir shows compassion. The family calls it weakness.",
    },
    bold_in_cautious_family = {
        "Reckless courage in a line of careful survivors.",
        "This one charges forward. The ancestors would disapprove.",
    },
    cautious_in_bold_family = {
        "Hesitation. The bloodline has never known it before.",
        "Where the family charges, this heir holds back.",
    },
    generic_contrast = {
        "This one is different. The blood knows it.",
        "Something changed. The ancestors would not recognize this heir.",
        "A break in the pattern. The family has never seen this before.",
    },
}

--- Get the average trait values per category for a genome.
---@param genome table
---@return table { physical=N, mental=N, social=N, creative=N }
local function get_category_averages(genome)
    local sums = { physical = 0, mental = 0, social = 0, creative = 0 }
    local counts = { physical = 0, mental = 0, social = 0, creative = 0 }

    local all_traits = genome.traits or {}
    for _, trait in pairs(all_traits) do
        local cat = trait.category
        if cat and sums[cat] then
            sums[cat] = sums[cat] + trait:get_value()
            counts[cat] = counts[cat] + 1
        end
    end

    local avgs = {}
    for _, cat in ipairs(CATEGORIES) do
        avgs[cat] = counts[cat] > 0 and (sums[cat] / counts[cat]) or 50
    end
    return avgs
end

--- Get the family's trait priority averages per category.
---@param cultural_memory table
---@return table { physical=N, mental=N, social=N, creative=N }
local function get_priority_averages(cultural_memory)
    local sums = { physical = 0, mental = 0, social = 0, creative = 0 }
    local counts = { physical = 0, mental = 0, social = 0, creative = 0 }

    if cultural_memory and cultural_memory.trait_priorities then
        for id, priority in pairs(cultural_memory.trait_priorities) do
            local prefix = id:sub(1, 3)
            local cat = prefix_to_category[prefix]
            if cat then
                sums[cat] = sums[cat] + priority
                counts[cat] = counts[cat] + 1
            end
        end
    end

    local avgs = {}
    for _, cat in ipairs(CATEGORIES) do
        avgs[cat] = counts[cat] > 0 and (sums[cat] / counts[cat]) or 50
    end
    return avgs
end

--- Find the dominant and weakest categories.
---@param avgs table { physical=N, ... }
---@return string dominant category key
---@return string weakest category key
local function find_extremes(avgs)
    local best_cat, best_val = nil, -1
    local worst_cat, worst_val = nil, 999

    for _, cat in ipairs(CATEGORIES) do
        if avgs[cat] > best_val then
            best_val = avgs[cat]
            best_cat = cat
        end
        if avgs[cat] < worst_val then
            worst_val = avgs[cat]
            worst_cat = cat
        end
    end

    return best_cat, worst_cat
end

--- Pick a narrative for the contrast type.
---@param contrast string
---@return string
local function pick_narrative(contrast)
    local pool = narratives[contrast] or narratives.generic_contrast
    return pool[rng.range(1, #pool)]
end

--- Detect if an heir is a black sheep.
---@param heir_genome table
---@param heir_personality table
---@param cultural_memory table
---@return table|nil { is_black_sheep=true, contrast, magnitude, narrative } or nil
function BlackSheep.detect(heir_genome, heir_personality, cultural_memory)
    if not heir_genome or not cultural_memory then return nil end

    local heir_avgs = get_category_averages(heir_genome)
    local family_avgs = get_priority_averages(cultural_memory)

    -- Find heir's strongest category
    local heir_best, _ = find_extremes(heir_avgs)
    -- Find family's weakest category
    local _, family_worst = find_extremes(family_avgs)
    -- Find family's strongest category
    local family_best, _ = find_extremes(family_avgs)

    local magnitude = 0
    local contrast = "generic_contrast"

    -- Check if heir excels in family's weakest area
    if heir_best == family_worst then
        local heir_strength = heir_avgs[heir_best]
        local family_weakness = family_avgs[family_worst]
        local diff = heir_strength - family_weakness

        -- Normalize to 0-1 scale (diff of 30+ is very strong contrast)
        magnitude = math.min(diff / 40, 1.0)

        -- Determine specific contrast type
        if heir_best == "creative" and family_best == "physical" then
            contrast = "creative_in_warrior_family"
        elseif heir_best == "mental" and family_best == "physical" then
            contrast = "mental_in_warrior_family"
        elseif heir_best == "physical" and family_best == "mental" then
            contrast = "physical_in_scholar_family"
        elseif heir_best == "social" and family_best == "creative" then
            contrast = "social_in_artisan_family"
        end
    end

    -- Also check personality contradictions
    if heir_personality and cultural_memory.reputation then
        local rep = cultural_memory.reputation.primary or ""
        local cruelty = heir_personality:get_axis("PER_CRM") or 50
        local boldness = heir_personality:get_axis("PER_BLD") or 50

        if rep == "tyrants" or rep == "warriors" then
            if cruelty <= 20 then
                local pers_mag = (50 - cruelty) / 50
                if pers_mag > magnitude then
                    magnitude = pers_mag
                    contrast = "merciful_in_cruel_family"
                end
            end
        elseif rep == "healers" or rep == "scholars" then
            if cruelty >= 80 then
                local pers_mag = (cruelty - 50) / 50
                if pers_mag > magnitude then
                    magnitude = pers_mag
                    contrast = "cruel_in_merciful_family"
                end
            end
        end

        -- Boldness contrast
        local family_boldness_trend = family_avgs.physical or 50
        if boldness >= 80 and family_boldness_trend < 40 then
            local pers_mag = (boldness - family_boldness_trend) / 60
            if pers_mag > magnitude then
                magnitude = pers_mag
                contrast = "bold_in_cautious_family"
            end
        elseif boldness <= 20 and family_boldness_trend > 60 then
            local pers_mag = (family_boldness_trend - boldness) / 60
            if pers_mag > magnitude then
                magnitude = pers_mag
                contrast = "cautious_in_bold_family"
            end
        end
    end

    -- Threshold: only trigger if magnitude > 0.6
    if magnitude <= 0.6 then
        return nil
    end

    return {
        is_black_sheep = true,
        contrast = contrast,
        magnitude = magnitude,
        narrative = pick_narrative(contrast),
    }
end

--- Get cultural memory shift multiplier for a black sheep heir.
-- If the player chooses a black sheep, cultural memory shifts 2x.
---@param black_sheep_data table|nil result from detect()
---@return number multiplier (1.0 if not black sheep, 2.0 if black sheep)
function BlackSheep.get_shift_multiplier(black_sheep_data)
    if black_sheep_data and black_sheep_data.is_black_sheep then
        return 2.0
    end
    return 1.0
end

return BlackSheep
