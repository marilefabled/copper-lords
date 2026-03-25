local Math = require("dredwork_core.math")
-- Dark Legacy — Dynamic Morality System
-- Pure Lua module, no Solar2D dependencies
--
-- Morality is dynamic and per-heir. It's NOT a fixed personality axis (PER_CRM is tendency).
-- This tracks ACTUAL ACTS committed — what the heir DID, not what they're inclined to do.
-- A merciful person can commit cruel acts under pressure. A cruel person can show mercy.
--
-- Morality decays toward neutral over time within a reign. Recent acts matter more.
-- The lineage also carries a "moral reputation" that persists across generations.

local Morality = {}

--- Act categories and their moral weight
local ACT_WEIGHTS = {
    -- Positive acts
    mercy           = { weight =  8, category = "virtue" },
    charity         = { weight =  6, category = "virtue" },
    sacrifice       = { weight = 10, category = "virtue" },
    diplomacy       = { weight =  4, category = "virtue" },
    protection      = { weight =  7, category = "virtue" },
    honoring_oath   = { weight =  5, category = "virtue" },
    forgiveness     = { weight =  6, category = "virtue" },

    -- Negative acts
    betrayal        = { weight = -10, category = "sin" },
    cruelty         = { weight =  -8, category = "sin" },
    exploitation    = { weight =  -6, category = "sin" },
    assassination   = { weight = -12, category = "sin" },
    theft           = { weight =  -5, category = "sin" },
    oath_breaking   = { weight =  -7, category = "sin" },
    abandonment     = { weight =  -6, category = "sin" },
    oppression      = { weight =  -9, category = "sin" },

    -- Ambiguous acts (context determines perception)
    pragmatism      = { weight = -2, category = "gray" },
    ruthless_order  = { weight = -3, category = "gray" },
    necessary_evil  = { weight = -4, category = "gray" },
    harsh_justice   = { weight = -1, category = "gray" },
}

--- Moral standing descriptors (dynamic, based on current score)
local STANDING_TIERS = {
    { min =  80, label = "Saintly",      tone = "bright" },
    { min =  60, label = "Righteous",    tone = "warm" },
    { min =  40, label = "Honorable",    tone = "neutral" },
    { min =  20, label = "Pragmatic",    tone = "dim" },
    { min =   0, label = "Compromised",  tone = "cold" },
    { min = -20, label = "Tainted",      tone = "cold" },
    { min = -50, label = "Villainous",   tone = "dark" },
    { min = -100, label = "Monstrous",   tone = "dark" },
}

--- Create a new morality state for an heir.
---@param inherited_reputation number? lineage moral reputation (-100 to 100, default 0)
---@return table morality state
function Morality.new(inherited_reputation)
    return {
        score = inherited_reputation or 0,  -- current moral standing
        acts = {},          -- { { act_id, generation, weight, description } }
        virtues = 0,        -- count of positive acts
        sins = 0,           -- count of negative acts
        gray_acts = 0,      -- count of ambiguous acts
    }
end

--- Record a moral act.
---@param morality table morality state
---@param act_id string act identifier (from ACT_WEIGHTS keys, or custom)
---@param generation number current generation
---@param description string? narrative description
function Morality.record_act(morality, act_id, generation, description)
    local def = ACT_WEIGHTS[act_id]
    local weight = def and def.weight or 0
    local category = def and def.category or "gray"

    morality.acts[#morality.acts + 1] = {
        act_id = act_id,
        generation = generation,
        weight = weight,
        description = description or act_id,
    }
    while #morality.acts > 50 do table.remove(morality.acts, 1) end

    morality.score = Math.clamp(morality.score + weight, -100, 100)

    if category == "virtue" then
        morality.virtues = morality.virtues + 1
    elseif category == "sin" then
        morality.sins = morality.sins + 1
    else
        morality.gray_acts = morality.gray_acts + 1
    end
end

--- Get current moral standing descriptor.
---@param morality table morality state
---@return table tier { label, tone }
function Morality.get_standing(morality)
    local s = morality.score
    for _, tier in ipairs(STANDING_TIERS) do
        if s >= tier.min then
            return tier
        end
    end
    return STANDING_TIERS[#STANDING_TIERS]
end

--- Dynamic decay: morality drifts toward 0 (neutral) within a generation.
--- Recent extreme acts fade in urgency. The world forgets slowly.
---@param morality table morality state
function Morality.decay(morality)
    -- 8% regression toward 0 per generation
    morality.score = morality.score * 0.92
    -- Snap to 0 if negligible
    if math.abs(morality.score) < 1 then morality.score = 0 end
end

--- Compute the lineage moral reputation from the heir's morality.
--- Called at generation end to feed into the next heir's inherited_reputation.
---@param morality table current heir's morality
---@param lineage_reputation number previous lineage reputation
---@return number new lineage reputation
function Morality.update_lineage_reputation(morality, lineage_reputation)
    -- 70% old reputation + 30% this heir's score
    local new_rep = (lineage_reputation or 0) * 0.7 + morality.score * 0.3
    return Math.clamp(new_rep, -100, 100)
end

--- Check if the heir is in "trouble with the law" territory.
--- Low morality score means the bloodline's dark acts have consequences.
---@param morality table morality state
---@return boolean in_trouble
---@return string? severity "minor" | "serious" | "notorious"
function Morality.check_trouble(morality)
    if morality.score >= -10 then return false, nil end
    if morality.score >= -30 then return true, "minor" end
    if morality.score >= -60 then return true, "serious" end
    return true, "notorious"
end

--- Get acts committed during a specific generation.
---@param morality table morality state
---@param generation number
---@return table acts for that generation
function Morality.acts_for_generation(morality, generation)
    local result = {}
    for _, act in ipairs(morality.acts) do
        if act.generation == generation then
            result[#result + 1] = act
        end
    end
    return result
end

--- Get a narrative summary of the heir's moral character.
---@param morality table morality state
---@return string narrative
function Morality.describe(morality)
    local standing = Morality.get_standing(morality)
    local v = morality.virtues
    local s = morality.sins
    local total = v + s + morality.gray_acts

    if total == 0 then
        return "No moral acts of note. An unremarkable conscience."
    end

    local parts = {}
    parts[#parts + 1] = standing.label .. " standing."

    if v > s * 2 then
        parts[#parts + 1] = "A life marked more by mercy than malice."
    elseif s > v * 2 then
        parts[#parts + 1] = "A trail of dark acts follows this heir."
    elseif v > 0 and s > 0 then
        parts[#parts + 1] = "Both virtue and vice live in this blood."
    end

    local in_trouble, severity = Morality.check_trouble(morality)
    if in_trouble then
        local trouble_desc = {
            minor = "Whispers of wrongdoing circle the family name.",
            serious = "The bloodline's crimes are becoming known.",
            notorious = "The family name is spoken with fear and disgust.",
        }
        parts[#parts + 1] = trouble_desc[severity] or ""
    end

    return table.concat(parts, " ")
end

--- Get the faction disposition modifier based on morality.
--- Virtuous families are respected; villainous ones are feared.
---@param morality table morality state
---@return number modifier
function Morality.disposition_modifier(morality)
    if morality.score >= 60 then return 5 end
    if morality.score >= 30 then return 2 end
    if morality.score >= -10 then return 0 end
    if morality.score >= -40 then return -3 end
    return -8
end

return Morality
