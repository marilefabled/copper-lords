-- Dark Legacy — Viability System
-- Offspring survival, heir death, and fertility adjustments.
-- Pure Lua, zero Solar2D dependencies.
-- Uses dredwork_genetics.rng for all randomness.

local rng = require("dredwork_core.rng")

local Viability = {}

-- Doctrine modifiers (set externally by GeneticsController)
Viability._doctrine_viability_bonus = 0
Viability._doctrine_fertility_bonus = 0       -- added to child count
Viability._doctrine_condition_immunity = nil   -- condition type string to skip

-- Early-generation shield: scaling multiplier on condition-based penalties only.
-- Generations 1-9 get reduced condition damage; trait vulnerabilities stay full.
local GEN_SHIELD = {
    [1] = 0.20, [2] = 0.30, [3] = 0.45, [4] = 0.55,
    [5] = 0.65, [6] = 0.75, [7] = 0.85, [8] = 0.92, [9] = 1.0,
}

local function get_gen_shield(generation)
    if not generation or generation >= 9 then return 1.0 end
    return GEN_SHIELD[generation] or 1.0
end

--- Check if a newborn offspring survives.
-- Base survival ~75-98% depending on vitality, reduced by active conditions.
---@param genome table Genome of the newborn
---@param conditions table array of { type, intensity, remaining_gens } from world_state
---@param generation number|nil current generation (for early-gen shield)
---@return boolean alive
---@return string|nil cause (nil if alive)
---@return number death_chance (0.0-1.0, probability of death)
function Viability.check_offspring(genome, conditions, generation, opts)
    if opts and opts.god_mode then
        return true, nil, 0
    end
    conditions = conditions or {}

    local vitality = (genome:get_value("PHY_VIT") or 50) / 100
    local immune = (genome:get_value("PHY_IMM") or 50) / 100
    local endurance = (genome:get_value("PHY_END") or 50) / 100
    local longevity = (genome:get_value("PHY_LON") or 50) / 100

    local shield = get_gen_shield(generation)

    -- Base survival: 75% + vitality contribution up to 23%
    local survival = 0.75 + vitality * 0.23 + Viability._doctrine_viability_bonus

    -- Condition penalties (reduced by gen shield)
    local cause_weights = {}

    -- Resource Starvation Penalty
    if opts and opts.grain and opts.grain <= 0 then
        local penalty = 0.25 * shield
        survival = survival - penalty
        cause_weights[#cause_weights + 1] = { cause = "starvation", weight = penalty }
    end

    for _, cond in ipairs(conditions) do
        -- Doctrine: condition immunity skips one condition type entirely
        if Viability._doctrine_condition_immunity and cond.type == Viability._doctrine_condition_immunity then
            -- Protected by doctrine — skip this condition's penalty
        else
            local intensity = cond.intensity or 0.5

            if cond.type == "plague" then
                local penalty = intensity * 0.08 * (1 - immune * 0.7) * shield
                survival = survival - penalty
                cause_weights[#cause_weights + 1] = { cause = "plague", weight = penalty }

            elseif cond.type == "famine" then
                local resilience = (vitality + endurance) / 2
                local penalty = intensity * 0.09 * (1 - resilience * 0.5) * shield
                survival = survival - penalty
                cause_weights[#cause_weights + 1] = { cause = "starvation", weight = penalty }

            elseif cond.type == "war" then
                local penalty = intensity * 0.05 * shield
                survival = survival - penalty
                cause_weights[#cause_weights + 1] = { cause = "war_casualty", weight = penalty }
            end
        end
    end

    -- Low longevity adds a small penalty for infants (partial shield in early gens)
    if longevity < 0.3 then
        local trait_shield_off = generation and generation <= 5 and math.max(0.4, shield) or 1.0
        local penalty = (0.3 - longevity) * 0.10 * trait_shield_off
        survival = survival - penalty
        cause_weights[#cause_weights + 1] = { cause = "natural_frailty", weight = penalty }
    end

    -- Floor: higher in early gens to prevent Gen 1 wipeouts
    local floor = (generation and generation <= 3) and 0.55 or 0.25
    if survival < floor then survival = floor end
    -- Cap at 98%
    if survival > 0.98 then survival = 0.98 end

    local death_chance = 1 - survival

    if rng.chance(survival) then
        return true, nil, death_chance
    end

    -- Determine cause: weighted by penalty contribution
    local total_weight = 0
    for _, cw in ipairs(cause_weights) do
        total_weight = total_weight + cw.weight
    end

    if total_weight > 0 then
        local roll = rng.random() * total_weight
        local acc = 0
        for _, cw in ipairs(cause_weights) do
            acc = acc + cw.weight
            if roll <= acc then
                return false, cw.cause, death_chance
            end
        end
    end

    return false, "natural_frailty", death_chance
end

--- Adjust the number of children based on conditions and fertility.
-- Minimum 1 child (eliminates instant fertility-collapse extinction).
---@param genome table Genome of the heir
---@param conditions table array of conditions
---@param base_count number the base child count from count_children (1-3)
---@param generation number|nil current generation (for early-gen shield)
---@return number adjusted count (1-3, minimum 1)
function Viability.adjusted_fertility(genome, conditions, base_count, generation, opts)
    if opts and opts.god_mode then
        return math.max(base_count or 2, 3)
    end
    conditions = conditions or {}
    base_count = base_count or 2

    local fertility = (genome:get_value("PHY_FER") or 50) / 100
    local vitality = (genome:get_value("PHY_VIT") or 50) / 100

    local shield = get_gen_shield(generation)
    local adjusted = base_count
    
    -- Resource Starvation Penalty
    if opts and opts.grain and opts.grain <= 0 then
        -- Complete lack of food guarantees minimum fertility and drops chances of multiple
        if rng.chance(0.60) then
            adjusted = 1
        end
    end

    for _, cond in ipairs(conditions) do
        -- Doctrine: condition immunity skips one condition type
        if Viability._doctrine_condition_immunity and cond.type == Viability._doctrine_condition_immunity then
            -- Protected by doctrine
        else
            local intensity = cond.intensity or 0.5

            if cond.type == "plague" then
                -- Each child has a chance of not being conceived
                local loss_chance = intensity * 0.10 * (1 - fertility * 0.5) * shield
                if rng.chance(loss_chance) then
                    adjusted = adjusted - 1
                end

            elseif cond.type == "famine" then
                local loss_chance = intensity * 0.12 * (1 - vitality * 0.4) * shield
                if rng.chance(loss_chance) then
                    adjusted = adjusted - 1
                end
            end
        end
    end

    -- Very low fertility can cost an additional child (only if still > 1)
    if fertility < 0.25 and adjusted > 1 then
        if rng.chance(0.2) then
            adjusted = adjusted - 1
        end
    end

    -- Very low vitality penalty (only if still > 1)
    if vitality < 0.20 and adjusted > 1 then
        if rng.chance(0.15) then
            adjusted = adjusted - 1
        end
    end

    -- Doctrine: fertility bonus
    adjusted = adjusted + Viability._doctrine_fertility_bonus

    -- Pantheon: fertility bonus
    if opts and opts.pantheon_fertility_bonus then
        adjusted = adjusted + (opts.pantheon_fertility_bonus / 10) -- a +10 bonus from pantheon = +1 child
    end

    -- Floor at 1 child minimum
    if adjusted < 1 then adjusted = 1 end
    -- Early-gen safety: guarantee at least one sibling for succession
    if generation and generation <= 5 and adjusted < 2 then
        adjusted = 2
    end
    -- Cap at 4 (even with bonus)
    if adjusted > 4 then adjusted = 4 end
    return adjusted
end

--- Check if the current heir dies at the start of events phase.
-- Base 2%, scaled by conditions and traits. Cap 35%.
---@param genome table Genome of the heir
---@param personality table Personality of the heir
---@param conditions table array of conditions
---@param generation number current generation
---@return boolean dies
---@return string|nil cause
---@return number death_chance (0.0-1.0)
function Viability.check_heir_death(genome, personality, conditions, generation, opts)
    if opts and opts.god_mode then
        return false, nil, 0
    end
    conditions = conditions or {}

    local vitality = (genome:get_value("PHY_VIT") or 50) / 100
    local longevity = (genome:get_value("PHY_LON") or 50) / 100
    local immune = (genome:get_value("PHY_IMM") or 50) / 100
    local willpower = (genome:get_value("MEN_WIL") or 50) / 100
    local composure = (genome:get_value("MEN_COM") or 50) / 100

    local boldness = personality and (personality:get_axis("PER_BLD") or 50) / 100 or 0.5
    local volatility = personality and (personality:get_axis("PER_VOL") or 50) / 100 or 0.5

    local shield = get_gen_shield(generation)

    -- Base death chance (reduced by doctrine bonus and early-gen grace)
    -- "The Weight": base increases gently after gen 30, reflecting accumulated
    -- genetic burden and the entropy of long bloodlines.
    local base = 0.02
    if generation and generation <= 3 then
        base = 0.01  -- halved for first 3 generations
    elseif generation and generation > 30 then
        -- +0.2% per gen past 30, capping at +7% by gen 65
        local weight_bonus = math.min(0.07, (generation - 30) * 0.002)
        base = base + weight_bonus
    end
    local death_chance = math.max(0.005, base - Viability._doctrine_viability_bonus)

    -- Track cause weights for attribution
    local cause_weights = {}

    -- Condition-based risks (reduced by gen shield)
    for _, cond in ipairs(conditions) do
        -- Doctrine: condition immunity skips one condition type
        if Viability._doctrine_condition_immunity and cond.type == Viability._doctrine_condition_immunity then
            -- Protected by doctrine
        else
            local intensity = cond.intensity or 0.5

            if cond.type == "plague" then
                local risk = intensity * 0.05 * (1 - immune * 0.7) * shield
                death_chance = death_chance + risk
                cause_weights[#cause_weights + 1] = { cause = "plague", weight = risk }

            elseif cond.type == "war" then
                -- Bold heirs are more likely to die in war (they charge in)
                local risk = intensity * 0.08 * (0.5 + boldness * 0.5) * shield
                death_chance = death_chance + risk
                cause_weights[#cause_weights + 1] = { cause = "killed_in_war", weight = risk }

            elseif cond.type == "famine" then
                local frailty = 1 - vitality
                local risk = intensity * 0.04 * (0.3 + frailty * 0.7) * shield
                death_chance = death_chance + risk
                cause_weights[#cause_weights + 1] = { cause = "starvation", weight = risk }
            end
        end
    end

    -- Trait-based vulnerabilities (partial shield in early gens)
    local trait_shield = generation and generation <= 5 and math.max(0.4, shield) or 1.0

    if vitality < 0.25 then
        local risk = (0.25 - vitality) * 0.15 * trait_shield
        death_chance = death_chance + risk
        cause_weights[#cause_weights + 1] = { cause = "natural_frailty", weight = risk }
    end

    if longevity < 0.20 then
        local risk = (0.20 - longevity) * 0.10 * trait_shield
        death_chance = death_chance + risk
        cause_weights[#cause_weights + 1] = { cause = "natural_frailty", weight = risk }
    end

    if willpower < 0.15 and volatility > 0.80 then
        local risk = 0.04 * trait_shield
        death_chance = death_chance + risk
        cause_weights[#cause_weights + 1] = { cause = "madness", weight = risk }
    end

    if composure < 0.15 and volatility > 0.85 then
        local risk = 0.03 * trait_shield
        death_chance = death_chance + risk
        cause_weights[#cause_weights + 1] = { cause = "madness", weight = risk }
    end

    -- Genetic Burden (Phase 2): Extreme purity (>85) is monstrous and unstable
    pcall(function()
        local traits = genome.traits or {}
        for tid, t in pairs(traits) do
            local val = t.value or 0
            if val > 85 then
                local excess = val - 85
                local prefix = tid:sub(1, 3)
                local risk = excess * 0.005 -- e.g. 100 strength = +0.075 risk

                if prefix == "PHY" then
                    death_chance = death_chance + risk
                    cause_weights[#cause_weights + 1] = { cause = "organ_failure", weight = risk }
                elseif prefix == "MEN" then
                    death_chance = death_chance + risk
                    cause_weights[#cause_weights + 1] = { cause = "madness", weight = risk }
                elseif prefix == "CRE" then
                    death_chance = death_chance + risk * 0.5
                    cause_weights[#cause_weights + 1] = { cause = "obsession", weight = risk * 0.5 }
                end
            end
        end
    end)

    -- Cap: stricter in early gens to prevent instant game-overs
    local cap = (generation and generation <= 3) and 0.08 or 0.45
    if death_chance > cap then death_chance = cap end

    -- Build risk factors for UI transparency
    local risk_factors = {
        death_chance = death_chance,
        traits = {
            { id = "PHY_VIT", name = "Vitality", value = math.floor(vitality * 100) },
            { id = "PHY_LON", name = "Longevity", value = math.floor(longevity * 100) },
            { id = "PHY_IMM", name = "Immune Response", value = math.floor(immune * 100) },
            { id = "MEN_WIL", name = "Willpower", value = math.floor(willpower * 100) },
            { id = "MEN_COM", name = "Composure", value = math.floor(composure * 100) },
        },
        cause_weights = cause_weights,
    }

    if not rng.chance(death_chance) then
        return false, nil, death_chance, risk_factors
    end

    -- Heir dies — determine cause
    local total_weight = 0
    for _, cw in ipairs(cause_weights) do
        total_weight = total_weight + cw.weight
    end

    if total_weight > 0 then
        local roll = rng.random() * total_weight
        local acc = 0
        for _, cw in ipairs(cause_weights) do
            acc = acc + cw.weight
            if roll <= acc then
                return true, cw.cause, death_chance, risk_factors
            end
        end
    end

    return true, "natural_frailty", death_chance, risk_factors
end

return Viability
