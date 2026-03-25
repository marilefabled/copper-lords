-- Bloodweight — Combat Moves (v2)
-- 14 combat moves with counter relationships, personality gates,
-- terrain weights, and era-influenced selection.
-- Pure Lua, zero Solar2D dependencies.

local Moves = {}

-- ═══════════════════════════════════════════════════════
-- MOVE DEFINITIONS
-- ═══════════════════════════════════════════════════════

local DEFS = {
    -- === CORE TRIANGLE ===
    strike = {
        id = "strike", label = "Strike",
        power_stat = "power", speed_stat = "speed",
        base_damage = 12, stamina_cost = 8,
        counters = "feint", countered_by = "counter",
        tags = { "direct", "force" },
    },
    counter = {
        id = "counter", label = "Counter",
        power_stat = "cunning", speed_stat = "cunning",
        base_damage = 14, stamina_cost = 10,
        counters = "strike", countered_by = "feint",
        tags = { "read", "punish" },
    },
    feint = {
        id = "feint", label = "Feint",
        power_stat = "cunning", speed_stat = "speed",
        base_damage = 8, stamina_cost = 6,
        counters = "counter", countered_by = "strike",
        tags = { "deception", "setup" },
    },

    -- === GRAPPLE TRIANGLE ===
    grab = {
        id = "grab", label = "Grab",
        power_stat = "grit", speed_stat = "power",
        base_damage = 10, stamina_cost = 12,
        counters = "dodge", countered_by = "shove",
        tags = { "control", "close" },
    },
    dodge = {
        id = "dodge", label = "Dodge",
        power_stat = "speed", speed_stat = "speed",
        base_damage = 0, stamina_cost = 5,
        counters = "shove", countered_by = "grab",
        tags = { "evasion", "distance" },
    },
    shove = {
        id = "shove", label = "Shove",
        power_stat = "power", speed_stat = "grit",
        base_damage = 8, stamina_cost = 9,
        counters = "grab", countered_by = "dodge",
        tags = { "force", "positioning" },
    },

    -- === DESPERATION ===
    clinch = {
        id = "clinch", label = "Clinch",
        power_stat = "grit", speed_stat = "grit",
        base_damage = 4, stamina_cost = 3,
        counters = "dodge", countered_by = "shove",
        tags = { "stall", "close", "desperation" },
    },
    dirty = {
        id = "dirty", label = "Dirty",
        power_stat = "cunning", speed_stat = "speed",
        base_damage = 16, stamina_cost = 7,
        counters = "grab", countered_by = "counter",
        tags = { "foul", "surprise" },
        gate_dirty = true,
    },

    -- === V2: OVERCOMMIT ===
    lunge = {
        id = "lunge", label = "Lunge",
        power_stat = "power", speed_stat = "speed",
        base_damage = 18, stamina_cost = 14,
        counters = "dodge", countered_by = "brace",
        tags = { "overcommit", "force", "risky" },
        gate_aggression = 55,
    },
    brace = {
        id = "brace", label = "Brace",
        power_stat = "grit", speed_stat = "grit",
        base_damage = 3, stamina_cost = 4,
        counters = "lunge", countered_by = "feint",
        tags = { "defensive", "absorb" },
        damage_reduction = 0.5,
    },

    -- === V2: CRUELTY ===
    gouge = {
        id = "gouge", label = "Gouge",
        power_stat = "power", speed_stat = "cunning",
        base_damage = 15, stamina_cost = 11,
        counters = "clinch", countered_by = "counter",
        tags = { "cruel", "close", "foul" },
        gate_cruel = true,
    },
    headbutt = {
        id = "headbutt", label = "Headbutt",
        power_stat = "grit", speed_stat = "power",
        base_damage = 14, stamina_cost = 10,
        counters = "clinch", countered_by = "dodge",
        tags = { "desperate", "close", "force" },
        self_damage = 3,
    },

    -- === V2: PSYCHOLOGICAL ===
    taunt = {
        id = "taunt", label = "Taunt",
        power_stat = "cunning", speed_stat = "cunning",
        base_damage = 0, stamina_cost = 4,
        counters = "brace", countered_by = "strike",
        tags = { "psychological", "debuff" },
        debuff = { aggression = 15, volatility = 10 },
    },
    disarm = {
        id = "disarm", label = "Disarm",
        power_stat = "speed", speed_stat = "cunning",
        base_damage = 5, stamina_cost = 8,
        counters = "strike", countered_by = "grab",
        tags = { "technical", "control" },
        strips_weapon = true,
    },
}

-- Ordered ID list for iteration
local ALL_IDS = {
    "strike", "counter", "feint",
    "grab", "dodge", "shove",
    "clinch", "dirty",
    "lunge", "brace", "gouge", "headbutt", "taunt", "disarm",
}

-- ═══════════════════════════════════════════════════════
-- TERRAIN WEIGHT MODIFIERS
-- ═══════════════════════════════════════════════════════

local TERRAIN_WEIGHTS = {
    border_stones = { dodge = 6, shove = 4, lunge = -4 },
    courtyard     = { strike = 3, counter = 3, feint = 2 },
    throne_room   = { taunt = 8, feint = 5, counter = 4, grab = -6, dirty = -8 },
    pit           = { dirty = 10, gouge = 8, headbutt = 6, dodge = -6, disarm = -4 },
    battlefield   = { lunge = 6, strike = 4, shove = 4, clinch = -6, taunt = -8 },
    wilderness    = { grab = 4, shove = 4, clinch = 4, disarm = -4, taunt = -6 },
}

-- ═══════════════════════════════════════════════════════
-- ERA WEIGHT MODIFIERS
-- ═══════════════════════════════════════════════════════

local ERA_WEIGHTS = {
    ancient  = { strike = 6, grab = 6, headbutt = 6, shove = 4, feint = -4, disarm = -6, taunt = -6 },
    iron     = { strike = 4, counter = 4, brace = 4, disarm = 4, dirty = -6, gouge = -4 },
    dark     = { dirty = 6, clinch = 6, headbutt = 4, gouge = 4, taunt = -4, disarm = -4 },
    arcane   = { feint = 6, counter = 6, taunt = 6, disarm = 4, grab = -4, headbutt = -4 },
    gilded   = { feint = 6, counter = 6, disarm = 6, taunt = 4, dirty = -8, gouge = -8, headbutt = -6 },
    twilight = { lunge = 4, gouge = 4, dirty = 4, headbutt = 4, brace = -4 },
}

-- ═══════════════════════════════════════════════════════
-- API
-- ═══════════════════════════════════════════════════════

function Moves.get(id)
    return DEFS[id]
end

function Moves.all_ids()
    local copy = {}
    for i, id in ipairs(ALL_IDS) do copy[i] = id end
    return copy
end

function Moves.check_counter(atk_move_id, def_move_id)
    local atk = DEFS[atk_move_id]
    if not atk then return "neutral" end
    if atk.counters == def_move_id then return "counters" end
    if atk.countered_by == def_move_id then return "countered" end
    return "neutral"
end

--- Select a move for this combatant given context.
---@param combatant table Fighter data
---@param rng function Seeded RNG
---@param round number Current round (1-based)
---@param opponent_last table|nil { move_id, damage } from last exchange
---@param terrain string|nil Terrain type
---@param era string|nil Current era
---@return string move_id
function Moves.select(combatant, rng, round, opponent_last, terrain, era)
    local weights = {}

    for _, id in ipairs(ALL_IDS) do
        local def = DEFS[id]
        local w = 10 -- base weight

        -- Gate checks (hard blocks)
        if def.gate_dirty and not combatant.dirty then
            w = 0
        elseif def.gate_cruel and not combatant.cruel then
            w = 0
        elseif def.gate_aggression and (combatant.aggression or 50) < def.gate_aggression then
            w = 0
        end

        if w > 0 then
            -- Stat affinity: higher stat = more likely to use moves driven by it
            local pstat = combatant[def.power_stat] or 50
            w = w + math.max(0, (pstat - 40) * 0.3)

            -- Aggression bias
            local agg = combatant.aggression or 50
            if agg >= 60 then
                if id == "strike" or id == "lunge" or id == "shove" or id == "headbutt" then
                    w = w + (agg - 50) * 0.2
                end
                if id == "clinch" or id == "dodge" or id == "brace" then
                    w = w - 4
                end
            elseif agg < 40 then
                if id == "brace" or id == "counter" or id == "dodge" then
                    w = w + (50 - agg) * 0.15
                end
            end

            -- Personality bias
            local ptag = combatant.personality_tag
            if ptag == "bold" then
                if id == "lunge" or id == "strike" then w = w + 6 end
                if id == "clinch" or id == "brace" then w = w - 4 end
            elseif ptag == "cruel" then
                if id == "gouge" or id == "dirty" or id == "headbutt" then w = w + 6 end
            elseif ptag == "volatile" then
                -- Volatile fighters are unpredictable — flatten weights
                w = math.max(6, w)
            elseif ptag == "proud" then
                if id == "taunt" or id == "counter" then w = w + 5 end
                if id == "dirty" or id == "clinch" then w = w - 6 end
            elseif ptag == "adaptive" then
                -- Counter-play bonus is doubled for adaptive fighters
                if opponent_last and opponent_last.move_id then
                    local cr = Moves.check_counter(id, opponent_last.move_id)
                    if cr == "counters" then w = w + 10 end
                end
            elseif ptag == "loyal" then
                if id == "brace" or id == "counter" then w = w + 4 end
                if id == "dirty" or id == "gouge" then w = w - 8 end
            end

            -- Fatigue (later rounds favor stalling and desperation)
            if round >= 4 then
                local fatigue_bonus = (round - 3) * 2
                if id == "clinch" then w = w + fatigue_bonus * 2 end
                if id == "dodge" then w = w + fatigue_bonus end
                if id == "headbutt" then w = w + fatigue_bonus end
            end

            -- Low stamina = desperation
            local stam = combatant._effective_stamina or combatant.stamina or 70
            if stam <= 30 then
                if id == "clinch" then w = w + 12 end
                if id == "dirty" and combatant.dirty then w = w + 8 end
                if id == "headbutt" then w = w + 8 end
                if id == "lunge" then w = w + 6 end -- all-in
            end

            -- Counter-play: bonus for countering opponent's last move
            if opponent_last and opponent_last.move_id and ptag ~= "adaptive" then
                local cr = Moves.check_counter(id, opponent_last.move_id)
                if cr == "counters" then w = w + 6 end
            end

            -- Terrain modifiers
            if terrain and TERRAIN_WEIGHTS[terrain] then
                local tw = TERRAIN_WEIGHTS[terrain][id]
                if tw then w = w + tw end
            end

            -- Era modifiers
            if era and ERA_WEIGHTS[era] then
                local ew = ERA_WEIGHTS[era][id]
                if ew then w = w + ew end
            end

            -- Volatility: set a floor so volatile fighters can pick anything
            if (combatant.volatility or 50) >= 60 then
                w = math.max(6, w)
            end
        end

        weights[#weights + 1] = { id = id, w = math.max(0, w) }
    end

    -- Weighted random selection
    local total = 0
    for _, entry in ipairs(weights) do total = total + entry.w end
    if total <= 0 then return "strike" end

    local roll = rng(math.floor(total))
    local sum = 0
    for _, entry in ipairs(weights) do
        sum = sum + entry.w
        if roll <= sum then return entry.id end
    end
    return "strike"
end

--- Calculate damage for a successful hit.
---@param move_id string
---@param attacker table Combatant
---@param defender table Combatant
---@return number damage
function Moves.calc_damage(move_id, attacker, defender)
    local def = DEFS[move_id]
    if not def then return 0 end

    local stat_val = attacker[def.power_stat] or 50
    local damage = def.base_damage + (stat_val - 40) * 0.35

    -- Weapon bonus
    if attacker.weapon and attacker.weapon.damage_bonus then
        damage = damage + attacker.weapon.damage_bonus
    end

    -- Condition multiplier (wounded fighters hit softer)
    damage = damage * (attacker.condition or 1.0)

    -- Relic bonus (named weapons carry weight)
    if attacker.relic and attacker.relic.bonus then
        damage = damage + attacker.relic.bonus
    end

    return math.max(0, damage)
end

--- Get the stamina cost for a move.
---@param move_id string
---@return number
function Moves.stamina_cost(move_id)
    local def = DEFS[move_id]
    return def and def.stamina_cost or 8
end

return Moves
