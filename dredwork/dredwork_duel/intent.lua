-- dredwork Duel — AI Intent Generation & Visibility
-- Generates opponent plans, handles counter-logic, and information asymmetry.
-- Ported from 5 Steps Ahead. Uses dredwork RNG instead of love.math.random.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Intent = {}

local CATEGORY_KEYS = { "strike", "defense", "evasion", "movement", "disruption" }
local CATEGORY_NAMES = {
    strike = "Strike", defense = "Defense", evasion = "Evasion",
    movement = "Movement", disruption = "Disruption",
}

local function hasTrait(traits, name)
    for _, t in ipairs(traits or {}) do if t == name then return true end end
    return false
end

local function weighted_category(bias)
    local total = 0
    for _, key in ipairs(CATEGORY_KEYS) do total = total + (bias[key] or 0) end
    if total <= 0 then return "Strike" end

    local r = RNG.random() * total
    local acc = 0
    for _, key in ipairs(CATEGORY_KEYS) do
        acc = acc + (bias[key] or 0)
        if r <= acc then return CATEGORY_NAMES[key] end
    end
    return "Strike"
end

--- Generate a 5-move plan for an AI combatant.
---@param combatant table { traits, bias, stats }
---@param moves_data table { categoryMoves }
---@return table plan (array of 5 move IDs)
function Intent.generate_plan(combatant, moves_data)
    local plan = {}
    local cats = moves_data.categoryMoves
    for i = 1, 5 do
        local cat = weighted_category(combatant.bias or {})
        local pool = cats[cat] or cats.Strike
        plan[i] = RNG.pick(pool)
    end

    if hasTrait(combatant.traits, "Unorthodox") and RNG.chance(0.65) then
        local a, b = RNG.range(1, 5), RNG.range(1, 5)
        plan[a], plan[b] = plan[b], plan[a]
    end

    return plan
end

--- Counter a specific move.
local function counter_move(move_id, moves_data)
    local m = moves_data.defs[move_id]
    if not m then return RNG.pick(moves_data.pool) end

    if m.category == "Strike" then
        if m.tags and m.tags.low then return RNG.pick({"stomp", "guard_low", "sidestep"}) end
        if m.tags and m.tags.heavy then return RNG.pick({"retreat", "guard_low", "guard_high"}) end
        return RNG.pick({"duck", "parry", "guard_high"})
    elseif m.category == "Defense" then return RNG.pick({"feint", "delay", "clinch_attempt"})
    elseif m.category == "Evasion" then return RNG.pick({"advance", "mid_punch", "clinch_attempt"})
    elseif m.category == "Movement" then return RNG.pick({"low_kick", "clinch_attempt", "stomp"})
    elseif m.category == "Disruption" then return RNG.pick({"advance", "mid_punch", "bait"})
    end
    return RNG.pick(moves_data.pool)
end

--- Rewrite plan with foresight (boss mechanic: adapts after seeing opponent's plan).
function Intent.rewrite_with_foresight(combatant, opponent_plan, moves_data, current_plan)
    if not hasTrait(combatant.traits, "SeesFuture") then return current_plan end

    local rewritten = {}
    for i = 1, 5 do
        local chance = hasTrait(combatant.traits, "Prophet") and 0.9 or 0.6
        if RNG.chance(chance) then
            rewritten[i] = counter_move(opponent_plan[i], moves_data)
        else
            rewritten[i] = current_plan[i]
        end
    end
    return rewritten
end

--- Reveal what an opponent intends (information asymmetry).
---@param reader_stats table { focus, read }
---@param combatant table { traits, stats }
---@param combatant_unit table fighter state (for stance context)
---@param plan table 5-move plan
---@param moves_data table
---@return table revealed (array of { mode, text, truthful })
function Intent.reveal_intent(reader_stats, combatant, combatant_unit, plan, moves_data)
    local defs = moves_data.defs
    local revealed = {}
    local threat_labels = {"High Damage","Control","Bait","Pressure","Reliable","Counter","Timing","Block","Reposition"}
    local categories = {"Strike","Defense","Evasion","Movement","Disruption"}

    for i = 1, 5 do
        local m = defs[plan[i]]
        local score = (reader_stats.focus or 0) + (reader_stats.read or 0) - (combatant.stats and combatant.stats.deception or 0)

        if combatant_unit and combatant_unit.stance == "Pressured" then score = score + 1
        elseif combatant_unit and combatant_unit.stance == "Defensive" then score = score + 0.25
        elseif combatant_unit and combatant_unit.stance == "Aggressive" then score = score - 0.2 end

        local exactChance = Math.clamp(0.08 + score * 0.09, 0, 0.8)
        local categoryChance = Math.clamp(0.24 + score * 0.08, 0.10, 0.85)
        local threatChance = Math.clamp(0.28 + score * 0.06, 0.10, 0.90)

        if hasTrait(combatant.traits, "Telegraphed") then exactChance = exactChance + 0.12; categoryChance = categoryChance + 0.08 end
        if hasTrait(combatant.traits, "Unorthodox") then exactChance = exactChance - 0.04 end
        if hasTrait(combatant.traits, "Veiled") then exactChance = 0; categoryChance = categoryChance - 0.08; threatChance = threatChance + 0.05 end

        local roll = RNG.random()
        local mode
        if roll < exactChance then mode = "exact"
        elseif roll < exactChance + categoryChance then mode = "category"
        elseif roll < exactChance + categoryChance + threatChance then mode = "threat"
        else mode = "hidden" end

        if hasTrait(combatant.traits, "Veiled") and mode == "exact" then
            mode = RNG.chance(0.6) and "threat" or "category"
        end

        local item = { mode = mode, truthful = true }
        if mode == "exact" then item.text = m and m.name or "?"
        elseif mode == "category" then item.text = m and m.category or "?"
        elseif mode == "threat" then item.text = m and m.threat or "?"
        else item.text = "???" end

        -- Misdirection: lie about revealed intent
        if hasTrait(combatant.traits, "Misdirection") and mode ~= "hidden" and RNG.chance(0.25) then
            item.truthful = false
            if mode == "exact" then
                local alt; repeat alt = RNG.pick(moves_data.pool) until alt ~= plan[i]
                item.text = defs[alt] and defs[alt].name or "?"
            elseif mode == "category" then
                local alt = m.category; while alt == m.category do alt = RNG.pick(categories) end
                item.text = alt
            else
                item.text = RNG.pick(threat_labels)
            end
        end

        revealed[i] = item
    end

    return revealed
end

return Intent
