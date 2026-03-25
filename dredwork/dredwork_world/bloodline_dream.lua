-- Dark Legacy — Bloodline's Dream (Emergent Goals)
-- Based on cultural memory trajectory, projects an "ideal heir" target.
-- The dream persists for 5 generations. Achievement = massive reward.
-- Expiry = dream mutates into something unexpected.
-- Pure Lua, zero Solar2D dependencies.

local BloodlineDream = {}

local rng = require("dredwork_core.rng")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

local CATEGORIES = { "physical", "mental", "social", "creative" }
local PREFIX_TO_CAT = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }
local DREAM_DURATION = 5

-- Build name lookup
local trait_names = {}
for _, def in ipairs(trait_definitions) do
    trait_names[def.id] = def.name
end

-- Narrative templates per category
local dream_narratives = {
    physical = {
        "The blood dreams of a warrior of legendary %s.",
        "The bloodline reaches for physical perfection — %s calls.",
        "Across the generations, the body yearns for greater %s.",
    },
    mental = {
        "The blood dreams of a mind with peerless %s.",
        "The bloodline reaches for intellectual transcendence — %s calls.",
        "The ancestors whisper of a mind that masters %s.",
    },
    social = {
        "The blood dreams of a voice that commands through %s.",
        "The bloodline reaches for social dominion — %s calls.",
        "The family yearns for an heir whose %s reshapes the world.",
    },
    creative = {
        "The blood dreams of a creator with unmatched %s.",
        "The bloodline reaches for creative brilliance — %s calls.",
        "Something in the blood yearns for an heir of transcendent %s.",
    },
}

local fulfillment_narratives = {
    "THE DREAM IS REALIZED. The bloodline has achieved what the ancestors envisioned.",
    "What the blood dreamed, the blood has become.",
    "Across generations, the bloodline reached — and finally grasped what it sought.",
}

local expiry_narratives = {
    "The dream fades. The blood reaches for something else.",
    "The bloodline's ambition redirects. A new dream stirs in the blood.",
    "What the ancestors wanted was not to be. The blood shifts its gaze.",
}

--- Get category averages from cultural memory priorities.
---@param cultural_memory table
---@return table { physical = N, mental = N, ... }
local function get_priority_averages(cultural_memory)
    local avgs = {}
    for _, cat in ipairs(CATEGORIES) do
        local sum, count = 0, 0
        for id, priority in pairs(cultural_memory.trait_priorities or {}) do
            local prefix = id:sub(1, 3)
            if PREFIX_TO_CAT[prefix] == cat then
                sum = sum + priority
                count = count + 1
            end
        end
        avgs[cat] = count > 0 and (sum / count) or 50
    end
    return avgs
end

--- Find the highest-priority trait in a category.
---@param cultural_memory table
---@param category string
---@return string trait_id, number priority_value
local function find_top_trait(cultural_memory, category)
    local best_id, best_val = nil, -1
    for id, priority in pairs(cultural_memory.trait_priorities or {}) do
        local prefix = id:sub(1, 3)
        if PREFIX_TO_CAT[prefix] == category then
            if priority > best_val then
                best_val = priority
                best_id = id
            end
        end
    end
    return best_id, best_val
end

--- Generate a new dream from cultural memory trends.
---@param cultural_memory table
---@param generation number
---@param exclude_trait string|nil trait_id to avoid repeating
---@param exclude_category string|nil category to avoid repeating
---@return table dream { trait_id, trait_name, category, target_value, description, start_generation, deadline_generation, status }
function BloodlineDream.generate(cultural_memory, generation, exclude_trait, exclude_category)
    if not cultural_memory then return nil end

    local avgs = get_priority_averages(cultural_memory)

    -- Find highest-trending category, excluding recent one
    local best_cat, best_avg = nil, -1
    for _, cat in ipairs(CATEGORIES) do
        if cat ~= exclude_category and avgs[cat] > best_avg then
            best_avg = avgs[cat]
            best_cat = cat
        end
    end
    -- Fallback: if excluding left nothing, allow all
    if not best_cat then
        for _, cat in ipairs(CATEGORIES) do
            if avgs[cat] > best_avg then
                best_avg = avgs[cat]
                best_cat = cat
            end
        end
    end

    if not best_cat then return nil end

    -- Find top trait in that category, excluding recent one
    local trait_id, trait_priority = find_top_trait(cultural_memory, best_cat)
    if trait_id == exclude_trait then
        -- Pick second-best trait in category
        local second_id, second_val = nil, -1
        for id, priority in pairs(cultural_memory.trait_priorities or {}) do
            local prefix = id:sub(1, 3)
            if PREFIX_TO_CAT[prefix] == best_cat and id ~= exclude_trait then
                if priority > second_val then
                    second_val = priority
                    second_id = id
                end
            end
        end
        if second_id then
            trait_id = second_id
            trait_priority = second_val
        end
        -- If no second trait exists, keep the original (same trait is better than no dream)
    end
    if not trait_id then return nil end

    -- Target = current priority + 15, clamped to 100
    local target = math.min(100, math.floor(trait_priority + 15))

    -- Generate description
    local pool = dream_narratives[best_cat] or dream_narratives.physical
    local template = pool[rng.range(1, #pool)]
    local description = string.format(template, trait_names[trait_id] or trait_id)

    return {
        trait_id = trait_id,
        trait_name = trait_names[trait_id] or trait_id,
        category = best_cat,
        target_value = target,
        description = description,
        start_generation = generation,
        deadline_generation = generation + DREAM_DURATION,
        status = "active",
    }
end

--- Check if current heir fulfills the dream.
---@param dream table
---@param heir_genome table Genome instance
---@return boolean fulfilled, string narrative
function BloodlineDream.check_fulfillment(dream, heir_genome)
    if not dream or not heir_genome then return false, "" end
    if dream.status ~= "active" then return false, "" end

    local current_val = heir_genome:get_value(dream.trait_id) or 0
    if current_val >= dream.target_value then
        local narrative = fulfillment_narratives[rng.range(1, #fulfillment_narratives)]
        return true, narrative
    end

    return false, ""
end

--- Mutate a dream that expired unfulfilled (picks a different category and trait).
---@param dream table the expired dream
---@param cultural_memory table
---@param generation number
---@return table new dream
function BloodlineDream.mutate(dream, cultural_memory, generation)
    if not cultural_memory then return nil end

    local exclude_trait = dream and dream.trait_id or nil
    local exclude_category = dream and dream.category or nil

    return BloodlineDream.generate(cultural_memory, generation, exclude_trait, exclude_category)
end

--- Get consequence definition for dream fulfillment.
---@param dream table
---@return table consequence
function BloodlineDream.get_fulfillment_consequences(dream)
    if not dream then return {} end
    return {
        cultural_memory_shift = { [dream.category] = 5 },
        mutation_pressure_delta = -10,
        milestone_id = "dream_fulfilled",
    }
end

--- Get display text for hub/advance screen.
---@param dream table
---@param current_heir_genome table Genome instance
---@param current_generation number
---@return table|nil { text, progress_pct, gens_remaining, color_key }
function BloodlineDream.get_display(dream, current_heir_genome, current_generation)
    if not dream or dream.status ~= "active" then return nil end

    local current_val = 0
    if current_heir_genome then
        current_val = current_heir_genome:get_value(dream.trait_id) or 0
    end

    local progress = math.min(1.0, current_val / dream.target_value)
    local remaining = dream.deadline_generation - current_generation

    local color_key = "dim_gold"
    if progress >= 0.9 then
        color_key = "gold"
    elseif remaining <= 1 then
        color_key = "red"
    end

    return {
        text = dream.description,
        progress_pct = progress,
        gens_remaining = remaining,
        color_key = color_key,
    }
end

--- Get expiry narrative.
---@return string
function BloodlineDream.get_expiry_narrative()
    return expiry_narratives[rng.range(1, #expiry_narratives)]
end

--- Serialize dream for save/load.
---@param dream table
---@return table|nil
function BloodlineDream.to_table(dream)
    return dream
end

--- Deserialize dream from save.
---@param data table
---@return table|nil
function BloodlineDream.from_table(data)
    return data
end

return BloodlineDream
