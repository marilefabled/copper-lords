local Math = require("dredwork_core.math")
-- Dark Legacy — Faction Genetics
-- Gives rival factions actual genetic profiles that evolve over generations.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

local ok_seeds, faction_genetic_seeds = pcall(require, "dredwork_world.config.faction_genetic_seeds")
if not ok_seeds then faction_genetic_seeds = {} end

local FactionGenetics = {}

-- Category prefix lookup
local PREFIX_TO_CAT = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }

--- Initialize trait averages on a faction from its category_scores.
-- Maps category_scores (0-100) to per-trait averages in the 35-75 range.
---@param faction table Faction instance (must have id, category_scores)
function FactionGenetics.init(faction)
    local averages = {}
    local seeds = faction_genetic_seeds[faction.id] or {}

    for _, def in ipairs(trait_definitions) do
        local prefix = def.id:sub(1, 3)
        local cat = PREFIX_TO_CAT[prefix]
        if cat and faction.category_scores[cat] then
            -- Map category score (0-100) to trait average range (35-75)
            local cat_score = faction.category_scores[cat]
            local base = 35 + (cat_score / 100) * 40 -- 35-75 range

            -- Apply seed override if exists
            if seeds[def.id] then
                base = seeds[def.id]
            end

            -- Small per-trait variance
            averages[def.id] = Math.clamp(math.floor(base + rng.range(-3, 3)), 20, 85)
        end
    end

    faction.trait_averages = averages
end

--- Evolve faction trait averages per generation based on era and conditions.
-- Dominant category traits creep up, weak category traits drift down.
---@param faction table Faction instance with trait_averages
---@param era_key string current era identifier
---@param generation number current generation
function FactionGenetics.evolve(faction, era_key, generation)
    if not faction.trait_averages then return end

    local dominant_cat = nil
    local dominant_score = 0
    local weakest_cat = nil
    local weakest_score = 999

    for cat, score in pairs(faction.category_scores or {}) do
        if score > dominant_score then
            dominant_cat = cat
            dominant_score = score
        end
        if score < weakest_score then
            weakest_cat = cat
            weakest_score = score
        end
    end

    -- Era-specific category boosts
    local era_boosts = {
        ancient = "physical",
        iron = "physical",
        dark = "mental",
        arcane = "creative",
        gilded = "social",
        twilight = "mental",
    }
    local era_favored = era_boosts[era_key]

    for id, avg in pairs(faction.trait_averages) do
        local prefix = id:sub(1, 3)
        local cat = PREFIX_TO_CAT[prefix]

        if cat == dominant_cat then
            -- Dominant category creeps up
            avg = avg + rng.range(0, 1) * 1.5
        elseif cat == weakest_cat then
            -- Weak category drifts down
            avg = avg - rng.range(0, 1) * 0.8
        end

        -- Era pressure
        if cat == era_favored then
            avg = avg + rng.range(0, 1) * 0.5
        end

        faction.trait_averages[id] = Math.clamp(avg, 15, 90)
    end
end

--- Get the faction's trait averages as a baseline for mate generation.
---@param faction table Faction instance with trait_averages
---@return table trait_id → average_value
function FactionGenetics.get_mate_baseline(faction)
    return faction.trait_averages or {}
end

return FactionGenetics
