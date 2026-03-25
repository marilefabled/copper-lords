-- Dark Legacy — Peril Assessment
-- Evaluates danger level for the current heir given active conditions.
-- Pure Lua, zero Solar2D dependencies.
-- Returns narrative warning lines (never numbers).

local Peril = {}

-- Same gen shield as viability.lua
local GEN_SHIELD = {
    [1] = 0.20, [2] = 0.30, [3] = 0.45, [4] = 0.55,
    [5] = 0.65, [6] = 0.75, [7] = 0.85, [8] = 0.92, [9] = 1.0,
}

local function get_gen_shield(generation)
    if not generation or generation >= 9 then return 1.0 end
    return GEN_SHIELD[generation] or 1.0
end

--- Assess the peril facing the current heir.
-- Mirrors the rebalanced viability formulas to estimate threat.
---@param genome table Genome of the heir
---@param personality table|nil Personality of the heir
---@param conditions table array of { type, intensity, remaining_gens }
---@param generation number current generation
---@return table|nil { level = "elevated"|"severe"|"dire", lines = {"..."} } or nil if safe
function Peril.assess(genome, personality, conditions, generation)
    if not genome then return nil end
    conditions = conditions or {}

    local vitality = (genome:get_value("PHY_VIT") or 50) / 100
    local immune = (genome:get_value("PHY_IMM") or 50) / 100
    local endurance = (genome:get_value("PHY_END") or 50) / 100
    local longevity = (genome:get_value("PHY_LON") or 50) / 100
    local fertility = (genome:get_value("PHY_FER") or 50) / 100

    local shield = get_gen_shield(generation)

    -- Estimate offspring survival penalty
    local offspring_penalty = 0
    -- Estimate heir death risk (above base 2%)
    local heir_risk = 0
    -- Track active threats
    local threats = {}

    for _, cond in ipairs(conditions) do
        local intensity = cond.intensity or 0.5

        if cond.type == "plague" then
            offspring_penalty = offspring_penalty + intensity * 0.12 * (1 - immune * 0.7) * shield
            heir_risk = heir_risk + intensity * 0.08 * (1 - immune * 0.7) * shield
            threats[#threats + 1] = "plague"

        elseif cond.type == "famine" then
            local resilience = (vitality + endurance) / 2
            offspring_penalty = offspring_penalty + intensity * 0.09 * (1 - resilience * 0.5) * shield
            local frailty = 1 - vitality
            heir_risk = heir_risk + intensity * 0.04 * (0.3 + frailty * 0.7) * shield
            threats[#threats + 1] = "famine"

        elseif cond.type == "war" then
            offspring_penalty = offspring_penalty + intensity * 0.05 * shield
            local boldness = personality and (personality:get_axis("PER_BLD") or 50) / 100 or 0.5
            heir_risk = heir_risk + intensity * 0.08 * (0.5 + boldness * 0.5) * shield
            threats[#threats + 1] = "war"
        end
    end

    -- Trait-based vulnerabilities (these kill even without conditions)
    if vitality < 0.25 then
        heir_risk = heir_risk + (0.25 - vitality) * 0.15
        threats[#threats + 1] = "frailty"
    end
    if longevity < 0.20 then
        heir_risk = heir_risk + (0.20 - longevity) * 0.10
        threats[#threats + 1] = "short_lived"
    end

    -- Determine danger level from combined risk
    local combined = offspring_penalty + heir_risk
    local level = nil
    if combined >= 0.18 then
        level = "dire"
    elseif combined >= 0.10 then
        level = "severe"
    elseif combined >= 0.05 then
        level = "elevated"
    end

    if not level then return nil end

    -- Build narrative warning lines
    local lines = {}

    local has_plague = false
    local has_famine = false
    local has_war = false
    for _, t in ipairs(threats) do
        if t == "plague" then has_plague = true end
        if t == "famine" then has_famine = true end
        if t == "war" then has_war = true end
    end

    -- Plague + heir vulnerability
    if has_plague and immune < 0.3 then
        lines[#lines + 1] = "The plague hunts for the weak. Your heir has no defense."
    elseif has_plague then
        lines[#lines + 1] = "Plague stalks the land. The children are at risk."
    end

    -- Famine + vitality
    if has_famine and vitality < 0.3 then
        lines[#lines + 1] = "Famine grips the land, and the blood runs thin."
    elseif has_famine then
        lines[#lines + 1] = "Famine threatens. Offspring may not survive."
    end

    -- War
    if has_war then
        lines[#lines + 1] = "War rages. No one is safe."
    end

    -- Combined threats
    if has_plague and has_famine then
        lines[#lines + 1] = "Plague and famine together. Few children survive both."
    end

    -- Low fertility warning
    if fertility < 0.25 then
        lines[#lines + 1] = "The bloodline's fertility wanes."
    end

    -- Trait-based frailty (no conditions needed)
    local has_frailty = false
    local has_short_lived = false
    for _, t in ipairs(threats) do
        if t == "frailty" then has_frailty = true end
        if t == "short_lived" then has_short_lived = true end
    end

    if has_frailty and not has_famine then
        if vitality < 0.15 then
            lines[#lines + 1] = "The heir's body is failing. Vitality dangerously low."
        else
            lines[#lines + 1] = "The blood runs thin. The heir's constitution is fragile."
        end
    end

    if has_short_lived then
        lines[#lines + 1] = "Short-lived blood. This heir may not see the next generation."
    end

    -- Low vitality general (offspring risk)
    if vitality < 0.25 and not has_famine and not has_frailty then
        lines[#lines + 1] = "The blood runs thin. Offspring may not survive."
    end

    -- Cap at 3 lines
    while #lines > 3 do
        lines[#lines] = nil
    end

    -- If no specific lines generated, add a generic one
    if #lines == 0 then
        if level == "dire" then
            lines[1] = "This generation faces grave peril."
        elseif level == "severe" then
            lines[1] = "Danger looms over the bloodline."
        else
            lines[1] = "The conditions are threatening."
        end
    end

    return { level = level, lines = lines }
end

return Peril
