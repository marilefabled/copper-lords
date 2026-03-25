local Math = require("dredwork_core.math")
-- Dark Legacy — Multi-Stat Check Engine
-- Single source of truth for all stat checks across events, council, crucible.
-- Weighted multi-trait + personality + cultural memory bonus.
-- Pure Lua, zero Solar2D dependencies.

local StatCheck = {}

--- Evaluate a stat check against an heir's genome and personality.
---@param genome table Genome of the heir
---@param check table { primary, secondary, personality, difficulty, cultural_bonus }
---@param personality table|nil Personality instance
---@param cultural_memory table|nil CulturalMemory instance
---@param wild_bonuses table|nil { [trait_category] = flat_bonus } from wild attributes
---@param momentum table|nil momentum data
---@param reliquary_effects table|nil aggregated effects from reliquary
---@param rival_heir table|nil rival heir object for comparative checks
---@param echo_bonuses table|nil { [trait_id] = flat_bonus } from invoked ancestor echo
---@param culture table|nil Culture instance
---@return table { success, score, margin, details, rival_competitor }
function StatCheck.evaluate(genome, check, personality, cultural_memory, wild_bonuses, momentum, reliquary_effects, rival_heir, echo_bonuses, culture, generation, morality)
    if not genome or not check then
        return { success = false, score = 0, margin = 0, details = {} }
    end

    local check_copy = {}
    for k, v in pairs(check) do
        if type(v) == "table" then
            check_copy[k] = {}
            for kk, vv in pairs(v) do check_copy[k][kk] = vv end
        else
            check_copy[k] = v
        end
    end

    -- Culture custom: Trial by Combat
    if culture and culture:has_custom("trial_by_combat") then
        local is_social_check = false
        if check_copy.primary and check_copy.primary.trait:sub(1, 3) == "SOC" then
            is_social_check = true
        end

        if is_social_check then
            -- Replace social trait with a physical one
            if check_copy.primary and check_copy.primary.trait:sub(1, 3) == "SOC" then
                check_copy.primary.trait = "PHY_STR"
            end
            if check_copy.secondary and check_copy.secondary.trait:sub(1, 3) == "SOC" then
                check_copy.secondary.trait = "PHY_VIT"
            end
        end
    end
    check = check_copy

    local total_weight = 0
    local weighted_sum = 0
    local details = {}

    -- Apply Reliquary and Echo trait bonuses directly to the genome's values for this check
    local function get_trait_val(trait_id)
        local base = genome:get_value(trait_id) or 50
        local bonus = 0
        if reliquary_effects and reliquary_effects.trait_bonuses then
            bonus = bonus + (reliquary_effects.trait_bonuses[trait_id] or 0)
        end
        if echo_bonuses and echo_bonuses[trait_id] then
            bonus = bonus + echo_bonuses[trait_id]
        end
        return base + bonus
    end

    -- Derive difficulty: static or rival-based
    local difficulty = check.difficulty or 50
    if rival_heir and rival_heir.genome then
        local r_sum = 0
        local r_weight = 0
        
        if check.primary then
            local r_val = rival_heir.genome[check.primary.trait] or 50
            r_sum = r_sum + r_val * (check.primary.weight or 1.0)
            r_weight = r_weight + (check.primary.weight or 1.0)
        end
        if check.secondary then
            local r_val = rival_heir.genome[check.secondary.trait] or 50
            r_sum = r_sum + r_val * (check.secondary.weight or 0.5)
            r_weight = r_weight + (check.secondary.weight or 0.5)
        end
        
        if r_weight > 0 then
            difficulty = Math.clamp(r_sum / r_weight, 30, 85)
        end
    end

    -- Primary trait
    if check.primary then
        local val = get_trait_val(check.primary.trait)
        local w = check.primary.weight or 1.0
        weighted_sum = weighted_sum + val * w
        total_weight = total_weight + w
        details[#details + 1] = {
            source = check.primary.trait,
            value = val,
            weight = w,
            contribution = val * w,
        }
    end

    -- Secondary trait
    if check.secondary then
        local val = get_trait_val(check.secondary.trait)
        local w = check.secondary.weight or 0.5
        weighted_sum = weighted_sum + val * w
        total_weight = total_weight + w
        details[#details + 1] = {
            source = check.secondary.trait,
            value = val,
            weight = w,
            contribution = val * w,
        }
    end

    -- Tertiary trait (optional)
    if check.tertiary then
        local val = get_trait_val(check.tertiary.trait)
        local w = check.tertiary.weight or 0.3
        weighted_sum = weighted_sum + val * w
        total_weight = total_weight + w
        details[#details + 1] = {
            source = check.tertiary.trait,
            value = val,
            weight = w,
            contribution = val * w,
        }
    end

    -- Normalize to 0-100 scale
    local base_score = 50
    if total_weight > 0 then
        base_score = weighted_sum / total_weight
    end

    -- Personality bonus (never shown numerically, just affects outcome)
    local pers_bonus = 0
    if check.personality and personality then
        local axis_val = personality:get_axis(check.personality.axis)
        if axis_val then
            local w = check.personality.weight or 0.3
            -- Personality contribution: scales 0-100 axis to -10..+10 bonus
            pers_bonus = (axis_val - 50) * w * 0.2
            details[#details + 1] = {
                source = check.personality.axis,
                value = axis_val,
                weight = w,
                contribution = pers_bonus,
                is_personality = true,
            }
        end
    end

    -- Cultural memory bonus: family-valued traits get small boost
    local cm_bonus = 0
    if cultural_memory and check.primary then
        local priority = cultural_memory.trait_priorities
            and cultural_memory.trait_priorities[check.primary.trait]
        if priority and priority > 60 then
            cm_bonus = math.min(5, (priority - 60) * 0.125)
        end
    end

    -- Wild attribute bonuses
    local wild_bonus = 0
    if wild_bonuses and check.primary then
        local prefix = check.primary.trait:sub(1, 3)
        local cat_map = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }
        local cat = cat_map[prefix]
        if cat and wild_bonuses[cat] then
            wild_bonus = wild_bonuses[cat]
        end
    end

    -- Momentum bonus: ascending blood in the check's category gives +5
    local momentum_bonus = 0
    if momentum and check.primary then
        local prefix = check.primary.trait:sub(1, 3)
        local cat_map = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }
        local cat = cat_map[prefix]
        if cat and momentum[cat] then
            local entry = momentum[cat]
            if entry.streak and entry.streak >= 3 and entry.direction == "rising" then
                momentum_bonus = 5
            end
        end
    end

    -- Early-game bonus: new bloodlines get a handicap that fades by Gen 10
    local gen_bonus = 0
    local gen = generation or (check.generation) or nil
    if gen and gen < 10 then
        gen_bonus = math.floor(8 * (10 - gen) / 9)
    end

    -- Moral reputation bonus: virtuous bloodlines find social checks easier,
    -- villainous ones find them harder (reputation precedes you)
    local moral_bonus = 0
    if morality and check.primary then
        local prefix = check.primary.trait:sub(1, 3)
        if prefix == "SOC" then
            local score = morality.score or 0
            -- +5 at saintly, +3 at righteous, -3 at villainous, -5 at monstrous
            if score >= 60 then moral_bonus = 5
            elseif score >= 30 then moral_bonus = 3
            elseif score <= -50 then moral_bonus = -5
            elseif score <= -20 then moral_bonus = -3
            end
        end
    end

    local final_score = math.floor(base_score + pers_bonus + cm_bonus + wild_bonus + momentum_bonus + gen_bonus + moral_bonus)
    final_score = Math.clamp(final_score, 0, 100)
    local margin = final_score - difficulty

    return {
        success = final_score >= difficulty,
        score = final_score,
        margin = margin,
        difficulty = difficulty,
        details = details,
        rival_competitor = rival_heir and rival_heir.name or nil
    }
end

--- Quick single-trait check (convenience wrapper).
---@param genome table
---@param trait_id string
---@param difficulty number
---@return boolean success
function StatCheck.quick_check(genome, trait_id, difficulty)
    local result = StatCheck.evaluate(genome, {
        primary = { trait = trait_id, weight = 1.0 },
        difficulty = difficulty,
    })
    return result.success
end

--- Get a qualitative result description.
---@param result table from evaluate()
---@return string "triumph" | "success" | "failure" | "disaster"
function StatCheck.get_quality(result)
    if result.margin >= 20 then return "triumph"
    elseif result.margin >= 0 then return "success"
    elseif result.margin >= -15 then return "failure"
    else return "disaster"
    end
end

return StatCheck
