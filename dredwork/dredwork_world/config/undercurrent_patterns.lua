-- Dark Legacy — Undercurrent Pattern Definitions
-- ~20 patterns that detect sustained genetic/cultural/world trends.

local trait_definitions = require("dredwork_genetics.config.trait_definitions")

-- Helper: compute average for a category from a genome
local PREFIX_TO_CAT = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }
local function category_avg(genome, cat_key)
    local prefix = ({ physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" })[cat_key]
    if not prefix or not genome then return 50 end
    local sum, count = 0, 0
    for _, def in ipairs(trait_definitions) do
        if def.id:sub(1, 3) == prefix then
            local t = genome:get_trait(def.id)
            if t then
                sum = sum + t:get_value()
                count = count + 1
            end
        end
    end
    return count > 0 and (sum / count) or 50
end

local patterns = {}

-- TRAIT DRIFT PATTERNS (8): category averages rising or falling for 3+ gens
local drift_defs = {
    { id = "phy_ascending", cat = "physical", dir = "up", title = "The Iron Thread", threshold = 3 },
    { id = "phy_declining", cat = "physical", dir = "down", title = "Withering Sinew", threshold = 3 },
    { id = "men_ascending", cat = "mental", dir = "up", title = "Sharpening Minds", threshold = 3 },
    { id = "men_declining", cat = "mental", dir = "down", title = "Scholars' Twilight", threshold = 3 },
    { id = "soc_ascending", cat = "social", dir = "up", title = "Rising Voices", threshold = 3 },
    { id = "soc_declining", cat = "social", dir = "down", title = "The Silence Grows", threshold = 3 },
    { id = "cre_ascending", cat = "creative", dir = "up", title = "The Maker's Pulse", threshold = 3 },
    { id = "cre_declining", cat = "creative", dir = "down", title = "Beauty Fades", threshold = 3 },
}

for _, d in ipairs(drift_defs) do
    patterns[#patterns + 1] = {
        id = d.id,
        title = d.title,
        threshold = d.threshold,
        severity_map = { [3] = "whisper", [5] = "murmur", [7] = "roar" },
        narratives = {
            whisper = "A quiet shift stirs beneath the blood.",
            murmur = "The pattern is undeniable now. The bloodline is changing.",
            roar = "Generation after generation, the blood speaks louder.",
        },
        check = function(gameState)
            local genome = gameState.current_heir
            if not genome then return false end
            local avg = category_avg(genome, d.cat)
            local prev = gameState._undercurrent_prev_avgs and gameState._undercurrent_prev_avgs[d.cat] or 50
            if d.dir == "up" then
                return avg > prev + 1
            else
                return avg < prev - 1
            end
        end,
    }
end

-- PERSONALITY EXTREME PATTERNS (4)
local pers_defs = {
    { id = "sustained_cruelty", axis = "PER_CRM", dir = "high", title = "The Blood Darkens", threshold = 3 },
    { id = "sustained_mercy", axis = "PER_CRM", dir = "low", title = "The Gentle Line", threshold = 3 },
    { id = "unbroken_loyalty", axis = "PER_LOY", dir = "high", title = "Bound by Blood", threshold = 3 },
    { id = "volatile_legacy", axis = "PER_VOL", dir = "high", title = "Fire in the Veins", threshold = 3 },
}

for _, p in ipairs(pers_defs) do
    patterns[#patterns + 1] = {
        id = p.id,
        title = p.title,
        threshold = p.threshold,
        severity_map = { [3] = "whisper", [5] = "murmur", [7] = "roar" },
        narratives = {
            whisper = "A tendency crystallizes in the heir's bearing.",
            murmur = "Generations confirm what one hinted. This is who they are.",
            roar = "The axis of the family's soul has been forged. It will not bend easily.",
        },
        check = function(gameState)
            local pers = gameState.heir_personality
            if not pers then return false end
            local val = pers:get_axis(p.axis) or 50
            if p.dir == "high" then return val > 75
            else return val < 25
            end
        end,
    }
end

-- CULTURAL TENSION PATTERNS (4): family values diverging from heir reality
local tension_defs = {
    { id = "phy_tension", cat = "physical", title = "Hollow Warriors", threshold = 3 },
    { id = "men_tension", cat = "mental", title = "Fools' Wisdom", threshold = 3 },
    { id = "soc_tension", cat = "social", title = "Empty Crowns", threshold = 3 },
    { id = "cre_tension", cat = "creative", title = "Lost Artistry", threshold = 3 },
}

for _, t in ipairs(tension_defs) do
    patterns[#patterns + 1] = {
        id = t.id,
        title = t.title,
        threshold = t.threshold,
        severity_map = { [3] = "whisper", [5] = "murmur", [7] = "roar" },
        narratives = {
            whisper = "What the family values, the blood no longer delivers.",
            murmur = "The gap between reputation and reality widens dangerously.",
            roar = "The family's identity is a lie written in fading ink.",
        },
        check = function(gameState)
            local genome = gameState.current_heir
            local memory = gameState.cultural_memory
            if not genome or not memory then return false end
            -- Get average priority for this category
            local prefix = ({ physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" })[t.cat]
            if not prefix then return false end
            local prio_sum, prio_count = 0, 0
            for id, val in pairs(memory.trait_priorities) do
                if id:sub(1, 3) == prefix then
                    prio_sum = prio_sum + val
                    prio_count = prio_count + 1
                end
            end
            local prio_avg = prio_count > 0 and (prio_sum / prio_count) or 50
            local actual_avg = category_avg(genome, t.cat)
            -- Tension: family values category highly (>65) but heir is weak (<45)
            return prio_avg > 65 and actual_avg < 45
        end,
    }
end

-- WORLD PRESSURE PATTERNS (4)
local world_defs = {
    { id = "plague_adaptation", condition = "plague", trait = "PHY_IMM", title = "Hardened by Plague", threshold = 3 },
    { id = "war_weakness", condition = "war", trait = "PHY_STR", dir = "falling", title = "Broken by War", threshold = 3 },
    { id = "famine_resilience", condition = "famine", trait = "PHY_VIT", title = "Starving Strong", threshold = 3 },
    { id = "peace_softening", condition = "none", trait = "PHY_END", dir = "falling", title = "The Soft Years", threshold = 4 },
}

for _, w in ipairs(world_defs) do
    patterns[#patterns + 1] = {
        id = w.id,
        title = w.title,
        threshold = w.threshold,
        severity_map = { [3] = "whisper", [4] = "murmur", [6] = "roar" },
        narratives = {
            whisper = "The world shapes the blood in ways the ancestor cannot see.",
            murmur = "Pressure and genetics intertwine. The family adapts — or breaks.",
            roar = "The world has rewritten the bloodline. This is evolution, not choice.",
        },
        check = function(gameState)
            local genome = gameState.current_heir
            if not genome then return false end
            local conditions = {}
            if gameState._world_conditions then
                conditions = gameState._world_conditions
            end
            local has_condition = false
            if w.condition == "none" then
                has_condition = #conditions == 0
            else
                for _, c in ipairs(conditions) do
                    if c.type == w.condition then has_condition = true; break end
                end
            end
            if not has_condition then return false end
            local trait = genome:get_trait(w.trait)
            if not trait then return false end
            local val = trait:get_value()
            if w.dir == "falling" then
                return val < 40
            else
                return val > 60
            end
        end,
    }
end

return patterns
