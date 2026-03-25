local Math = require("dredwork_core.math")
-- Bloodweight — Combat Resolution Engine (v2)
-- Deterministic fight resolution with stakes, terrain, era influence.
-- Produces narrative beats and mechanical outcomes.
-- Pure Lua, zero Solar2D dependencies.

local Moves = require("dredwork_combat_v2.moves")
local Templates = require("dredwork_combat_v2.templates")

local Combat = {}

-- ═══════════════════════════════════════════════════════
-- SEEDABLE RNG (Linear Congruential Generator)
-- ═══════════════════════════════════════════════════════

local function make_rng(seed)
    local state = math.abs(seed or 1) % 2147483647
    if state == 0 then state = 1 end
    return function(max)
        state = (state * 1103515245 + 12345) % 2147483647
        if max and max > 0 then
            return (state % max) + 1
        end
        return state
    end
end


-- ═══════════════════════════════════════════════════════
-- STAKES DEFINITIONS
-- ═══════════════════════════════════════════════════════

local STAKES = {
    casual = { rounds_bonus = -1, injury_mult = 0.3, can_kill = false, ko_threshold = 25 },
    honor  = { rounds_bonus = 0,  injury_mult = 0.7, can_kill = false, ko_threshold = 15 },
    blood  = { rounds_bonus = 2,  injury_mult = 1.5, can_kill = true,  ko_threshold = 0 },
    trial  = { rounds_bonus = 1,  injury_mult = 1.0, can_kill = false, ko_threshold = 10 },
}

-- ═══════════════════════════════════════════════════════
-- INJURY TABLE
-- ═══════════════════════════════════════════════════════

local INJURIES = {
    { id = "bruised",       label = "Bruised",            threshold = 15, severity = 1 },
    { id = "cut",           label = "Cut",                threshold = 20, severity = 1 },
    { id = "sprained",      label = "Sprained",           threshold = 25, severity = 2 },
    { id = "cracked_rib",   label = "Cracked Rib",        threshold = 35, severity = 2 },
    { id = "broken_nose",   label = "Broken Nose",        threshold = 40, severity = 2 },
    { id = "concussion",    label = "Concussion",         threshold = 50, severity = 3 },
    { id = "internal",      label = "Internal Bleeding",  threshold = 65, severity = 3 },
    { id = "maimed",        label = "Maimed",             threshold = 80, severity = 4 },
}

-- ═══════════════════════════════════════════════════════
-- COMBATANT CONSTRUCTORS
-- ═══════════════════════════════════════════════════════

--- Build a combatant from raw stat table.
--- This is the universal constructor — bridge.lua feeds data into this.
---@param spec table Raw combatant data
---@return table combatant
function Combat.build(spec)
    return {
        name            = spec.name or "Unknown",
        power           = clamp(spec.power or 50, 10, 95),
        speed           = clamp(spec.speed or 50, 10, 95),
        grit            = clamp(spec.grit or 50, 10, 95),
        cunning         = clamp(spec.cunning or 50, 10, 95),
        aggression      = clamp(spec.aggression or 50, 10, 95),
        volatility      = clamp(spec.volatility or 50, 10, 95),
        stamina         = clamp(spec.stamina or 70, 20, 100),
        condition       = clamp(spec.condition or 1.0, 0.3, 1.0),
        dirty           = spec.dirty or false,
        cruel           = spec.cruel or false,
        personality_tag = spec.personality_tag,
        traits          = spec.traits or {},
        weapon          = spec.weapon,
        relic           = spec.relic,
        modifiers       = spec.modifiers or {},
        era             = spec.era,
        title           = spec.title,
        is_nemesis      = spec.is_nemesis or false,
    }
end

--- Build a default combatant (baseline for testing).
---@param name string
---@return table combatant
function Combat.build_default(name)
    return Combat.build({ name = name or "Fighter" })
end

-- ═══════════════════════════════════════════════════════
-- INTERNAL: Apply weapon and modifier effects
-- ═══════════════════════════════════════════════════════

local function apply_weapon(c)
    if c.weapon then
        c.power = clamp(c.power + (c.weapon.damage_bonus or 0), 10, 95)
        c.speed = clamp(c.speed - (c.weapon.speed_penalty or 0), 10, 95)
    end
end

local function apply_modifiers(c)
    for _, mod in ipairs(c.modifiers or {}) do
        if mod.stat_deltas then
            for stat, delta in pairs(mod.stat_deltas) do
                if c[stat] then
                    c[stat] = clamp(c[stat] + delta, 10, 95)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- INTERNAL: Single exchange resolution
-- ═══════════════════════════════════════════════════════

local function resolve_exchange(attacker, defender, rng, round, atk_last, def_last, terrain, era)
    -- Move selection
    local atk_move_id = Moves.select(attacker, rng, round, def_last, terrain, era)
    local def_move_id = Moves.select(defender, rng, round, atk_last, terrain, era)

    local atk_move = Moves.get(atk_move_id)
    local def_move = Moves.get(def_move_id)
    if not atk_move then atk_move = Moves.get("strike"); atk_move_id = "strike" end
    if not def_move then def_move = Moves.get("strike"); def_move_id = "strike" end

    local outcome = "hit"
    local damage = Moves.calc_damage(atk_move_id, attacker, defender)
    local special = nil

    -- Counter check
    local counter_result = Moves.check_counter(atk_move_id, def_move_id)
    if counter_result == "counters" then
        -- Attacker's move counters defender's — bonus damage
        damage = damage + 4
        outcome = "hit"
    elseif counter_result == "countered" then
        -- Defender's move counters attacker's — no damage
        damage = 0
        outcome = "countered"
    else
        -- Neutral: speed contest
        local atk_speed = (attacker[atk_move.speed_stat] or 50) + rng(8)
        local def_speed = (defender[def_move.speed_stat] or 50) + rng(8)

        if atk_speed >= def_speed then
            -- Attacker wins speed
            if def_move_id == "dodge" and (defender.speed or 50) >= (attacker.speed or 50) + 8 then
                outcome = "miss"
                damage = 0
            else
                outcome = "hit"
            end
        else
            -- Defender wins speed — partial block
            outcome = "blocked"
            damage = damage * 0.2
        end
    end

    -- Brace damage reduction (defender chose brace)
    if def_move_id == "brace" and damage > 0 then
        damage = damage * (def_move.damage_reduction or 0.5)
        special = "brace_absorb"
    end

    -- Headbutt self-damage
    local self_damage = 0
    if atk_move_id == "headbutt" and outcome == "hit" then
        self_damage = atk_move.self_damage or 3
        special = "headbutt_self"
    end

    -- Taunt debuff (if taunt "hits" via speed, apply debuff to defender)
    if atk_move_id == "taunt" and outcome ~= "countered" then
        if atk_move.debuff then
            defender.aggression = clamp((defender.aggression or 50) + (atk_move.debuff.aggression or 0), 10, 95)
            defender.volatility = clamp((defender.volatility or 50) + (atk_move.debuff.volatility or 0), 10, 95)
        end
        special = "taunt_success"
        damage = 0  -- taunt does psychological damage, not physical
    end

    -- Disarm (strip weapon on successful hit)
    local weapon_stripped = false
    if atk_move_id == "disarm" and outcome == "hit" and defender.weapon then
        weapon_stripped = true
        special = "disarm_success"
    end

    -- Stamina drain (both fighters expend energy)
    local atk_stam_cost = Moves.stamina_cost(atk_move_id)
    attacker._effective_stamina = math.max(0, (attacker._effective_stamina or attacker.stamina) - atk_stam_cost)
    local def_stam_cost = Moves.stamina_cost(def_move_id)
    defender._effective_stamina = math.max(0, (defender._effective_stamina or defender.stamina) - def_stam_cost)

    damage = math.floor(math.max(0, damage))

    return {
        atk_move = atk_move_id,
        def_move = def_move_id,
        outcome = outcome,
        damage = damage,
        self_damage = self_damage,
        special = special,
        weapon_stripped = weapon_stripped,
    }
end

-- ═══════════════════════════════════════════════════════
-- MAIN RESOLUTION
-- ═══════════════════════════════════════════════════════

--- Resolve a full combat encounter.
---@param protagonist table Combatant (player's heir)
---@param opponent table Combatant (rival/enemy)
---@param seed number RNG seed for determinism
---@param stakes table|nil { type = "honor"|"blood"|"casual"|"trial", terrain = string|nil }
---@return table { beats, outcome, injuries }
function Combat.resolve(protagonist, opponent, seed, stakes)
    local rng = make_rng(seed + (stakes and stakes.seed_offset or 0))

    -- Deep copy to avoid mutating originals
    local p = Combat.build(protagonist)
    local o = Combat.build(opponent)

    -- Apply weapons and modifiers
    apply_weapon(p)
    apply_weapon(o)
    apply_modifiers(p)
    apply_modifiers(o)

    -- Initialize effective stamina
    p._effective_stamina = p.stamina
    o._effective_stamina = o.stamina

    local stakes_type = stakes and stakes.type or "honor"
    local stakes_def = STAKES[stakes_type] or STAKES.honor
    local terrain = stakes and stakes.terrain
    local era = p.era or o.era

    -- Calculate max rounds
    local base_rounds = 3 + math.floor(math.min(p.stamina, o.stamina) / 25)
    local max_rounds = clamp(base_rounds + (stakes_def.rounds_bonus or 0), 3, 9)

    local beats = {}
    local p_hp = 100
    local o_hp = 100
    local p_total_damage = 0
    local o_total_damage = 0
    local rounds_fought = 0
    local p_last = nil
    local o_last = nil
    local weapon_lost_by = nil

    -- === PHASE 1: SIZING UP ===

    -- Terrain intro
    if terrain then
        local tb = Templates.terrain_intro(terrain, p, rng)
        if tb then beats[#beats + 1] = tb end
    end

    -- Weapon intros
    local pw = Templates.weapon_intro(p, rng)
    if pw then beats[#beats + 1] = pw end
    local ow = Templates.weapon_intro(o, rng)
    if ow then beats[#beats + 1] = ow end

    -- Sizing up both fighters
    local p_sizing = Templates.sizing_up(p, o, rng, era)
    for _, b in ipairs(p_sizing) do beats[#beats + 1] = b end

    local o_sizing = Templates.sizing_up(o, p, rng, era)
    for _, b in ipairs(o_sizing) do beats[#beats + 1] = b end

    -- === PHASE 2: EXCHANGES ===

    for round = 1, max_rounds do
        rounds_fought = round

        -- Protagonist attacks
        local p_result = resolve_exchange(p, o, rng, round, p_last, o_last, terrain, era)
        o_hp = o_hp - p_result.damage
        p_hp = p_hp - (p_result.self_damage or 0)
        o_total_damage = o_total_damage + p_result.damage
        p_total_damage = p_total_damage + (p_result.self_damage or 0)

        -- Attack beats
        local atk_beats = Templates.attack_beat(p, o, p_result.atk_move, p_result.outcome, p_result.damage, rng, era)
        for _, b in ipairs(atk_beats) do beats[#beats + 1] = b end

        -- Special move beats
        if p_result.special then
            local sb = Templates.special_beat(p_result.atk_move, p, o, rng)
            if sb then beats[#beats + 1] = sb end
        end

        -- Disarm handling
        if p_result.weapon_stripped then
            local wb = Templates.weapon_lost_beat(o.name, o.weapon, rng)
            beats[#beats + 1] = wb
            weapon_lost_by = o.name
            local wpn_bonus = o.weapon and o.weapon.damage_bonus or 0
            o.power = clamp(o.power - wpn_bonus, 10, 95)
            o.weapon = nil
        end

        p_last = { move_id = p_result.atk_move, damage = p_result.damage }

        -- KO check
        if o_hp <= stakes_def.ko_threshold then break end

        -- Opponent attacks
        local o_result = resolve_exchange(o, p, rng, round, o_last, p_last, terrain, era)
        p_hp = p_hp - o_result.damage
        o_hp = o_hp - (o_result.self_damage or 0)
        p_total_damage = p_total_damage + o_result.damage
        o_total_damage = o_total_damage + (o_result.self_damage or 0)

        -- Attack beats
        local def_beats = Templates.attack_beat(o, p, o_result.atk_move, o_result.outcome, o_result.damage, rng, era)
        for _, b in ipairs(def_beats) do beats[#beats + 1] = b end

        -- Special move beats
        if o_result.special then
            local sb = Templates.special_beat(o_result.atk_move, o, p, rng)
            if sb then beats[#beats + 1] = sb end
        end

        -- Disarm handling
        if o_result.weapon_stripped then
            local wb = Templates.weapon_lost_beat(p.name, p.weapon, rng)
            beats[#beats + 1] = wb
            weapon_lost_by = p.name
            local wpn_bonus = p.weapon and p.weapon.damage_bonus or 0
            p.power = clamp(p.power - wpn_bonus, 10, 95)
            p.weapon = nil
        end

        o_last = { move_id = o_result.atk_move, damage = o_result.damage }

        -- KO check
        if p_hp <= stakes_def.ko_threshold then break end

        -- Fatigue beats (after round 3, for fighters below 40% HP)
        if round >= 3 then
            if p_hp <= 40 then
                beats[#beats + 1] = Templates.fatigue_beat(p, rng)
            end
            if o_hp <= 40 then
                beats[#beats + 1] = Templates.fatigue_beat(o, rng)
            end
        end

        -- Round break (if not final)
        if round < max_rounds and p_hp > stakes_def.ko_threshold and o_hp > stakes_def.ko_threshold then
            beats[#beats + 1] = Templates.round_break(round, rng)
        end
    end

    -- === PHASE 3: RESOLUTION ===

    local winner, loser, protag_won, margin, ko
    if p_hp <= stakes_def.ko_threshold and o_hp <= stakes_def.ko_threshold then
        -- Mutual destruction = draw
        winner = nil
        loser = nil
        protag_won = nil
        margin = "draw"
        ko = false
    elseif o_hp <= stakes_def.ko_threshold then
        winner = p
        loser = o
        protag_won = true
        ko = true
        margin = p_hp >= 50 and "dominant" or "narrow"
    elseif p_hp <= stakes_def.ko_threshold then
        winner = o
        loser = p
        protag_won = false
        ko = true
        margin = o_hp >= 50 and "dominant" or "narrow"
    else
        -- No KO — compare damage dealt
        if o_total_damage > p_total_damage + 5 then
            winner = p
            loser = o
            protag_won = true
        elseif p_total_damage > o_total_damage + 5 then
            winner = o
            loser = p
            protag_won = false
        else
            winner = nil
            loser = nil
            protag_won = nil
            margin = "draw"
        end
        if winner then
            margin = (winner == p and p_hp or o_hp) >= 60 and "dominant" or "narrow"
        end
        ko = false
    end

    -- Finish beats
    local finish = Templates.finish_beat(winner, loser, margin or "draw", stakes, rng)
    for _, b in ipairs(finish) do beats[#beats + 1] = b end

    -- === INJURIES ===

    local injuries = {}
    if p_total_damage > 0 then
        local effective_damage = p_total_damage * (stakes_def.injury_mult or 1.0)
        for _, inj in ipairs(INJURIES) do
            if effective_damage >= inj.threshold then
                injuries[#injuries + 1] = {
                    id = inj.id,
                    label = inj.label,
                    severity = inj.severity,
                }
            end
        end
    end

    -- === BUILD RESULT ===

    return {
        beats = beats,
        outcome = {
            winner = winner and winner.name or nil,
            loser = loser and loser.name or nil,
            protag_won = protag_won,
            margin = margin or "draw",
            rounds = rounds_fought,
            ko = ko or false,
            protag_damage = p_total_damage,
            opponent_damage = o_total_damage,
            protag_hp = math.max(0, p_hp),
            opponent_hp = math.max(0, o_hp),
            weapon_lost_by = weapon_lost_by,
        },
        injuries = injuries,
        -- Mechanical feedback for Bloodweight integration
        momentum_shift = protag_won == true and 2 or (protag_won == false and -2 or 0),
        cultural_memory_shift = protag_won == true and { physical = 1 } or {},
    }
end

return Combat
