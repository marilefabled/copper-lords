local Math = require("dredwork_core.math")
-- Bloodweight — Combat Bridge (v2)
-- Maps Bloodweight gameState + worldContext into combat-ready data.
-- Handles protagonist construction, rival construction, and aftermath.
-- Pure Lua, zero Solar2D dependencies.

local Combat = require("dredwork_combat_v2.combat")

local Bridge = {}

-- ═══════════════════════════════════════════════════════
-- SAFE ACCESSORS
-- ═══════════════════════════════════════════════════════

local function trait(genome, id)
    if not genome then return 50 end
    if genome.get_value then
        local ok, v = pcall(genome.get_value, genome, id)
        if ok and v then return v end
    end
    -- Fallback: raw trait tables store value in :get_value() or .value
    if genome.traits and genome.traits[id] then
        local t = genome.traits[id]
        if type(t) == "number" then return t end
        if type(t) == "table" and t.get_value then
            local ok2, v2 = pcall(t.get_value, t)
            if ok2 and v2 then return v2 end
        end
        if type(t) == "table" and t.value then return t.value end
    end
    return 50
end

local function axis(personality, id)
    if personality and personality.axes then return personality.axes[id] or 50 end
    return 50
end


local function _contains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════════
-- CONDITION → BODY STATE MAPPING
-- ═══════════════════════════════════════════════════════

local CONDITION_EFFECTS = {
    war     = { stress = 30, wound = 10, traits = { "scarred" } },
    plague  = { illness = 40, stress = 10, traits = { "sick" } },
    famine  = { stress = 20, illness = 10, traits = {} },
    unrest  = { stress = 15, traits = {} },
}

local function compute_body_state(worldContext)
    local wound_load = 0
    local illness_load = 0
    local stress = 0
    local body_traits = {}
    local trait_set = {}

    if not worldContext or not worldContext.world_state then
        return wound_load, illness_load, stress, body_traits
    end

    local conditions = worldContext.world_state.conditions or {}
    for _, cond_id in ipairs(conditions) do
        local effect = CONDITION_EFFECTS[cond_id]
        if effect then
            wound_load = wound_load + (effect.wound or 0)
            illness_load = illness_load + (effect.illness or 0)
            stress = stress + (effect.stress or 0)
            for _, t in ipairs(effect.traits or {}) do
                if not trait_set[t] then
                    body_traits[#body_traits + 1] = t
                    trait_set[t] = true
                end
            end
        end
    end

    return wound_load, illness_load, stress, body_traits
end

-- ═══════════════════════════════════════════════════════
-- RELIC WEAPON DETECTION
-- ═══════════════════════════════════════════════════════

local RELIC_WEAPON_TYPES = {
    weapon = true,  -- reliquary uses "weapon", "tome", "relic", "crown"
}

local function find_relic_weapon(worldContext)
    if not worldContext or not worldContext.reliquary then return nil, nil end

    local ok, relics = pcall(function()
        return worldContext.reliquary:get_all()
    end)
    if not ok or not relics then return nil, nil end

    for _, r in ipairs(relics) do
        local rtype = r.type or r.relic_type or ""
        if RELIC_WEAPON_TYPES[rtype] then
            local weapon = {
                id = r.id,
                label = r.name or r.id,
                damage_bonus = math.min(8, math.floor((r.power or r.influence or 5) / 2)),
                speed_penalty = 1,
            }
            local relic = {
                name = r.name or r.id,
                bonus = math.min(4, math.floor((r.power or r.influence or 3) / 3)),
            }
            return weapon, relic
        end
    end
    return nil, nil
end

-- ═══════════════════════════════════════════════════════
-- PROTAGONIST CONSTRUCTION
-- ═══════════════════════════════════════════════════════

--- Build combat protagonist from Bloodweight gameState + worldContext.
---@param gameState table GeneticsController state
---@param worldContext table WorldController context
---@return table combatant
function Bridge.build_heir(gameState, worldContext)
    local genome = gameState.current_heir
    local pers = gameState.heir_personality

    -- Core stat composition
    local power     = trait(genome, "PHY_STR") * 0.55 + axis(pers, "PER_BLD") * 0.3 + trait(genome, "PHY_BLD") * 0.15
    local speed     = trait(genome, "PHY_VIT") * 0.4 + axis(pers, "PER_ADA") * 0.35 + axis(pers, "PER_VOL") * 0.25
    local grit      = trait(genome, "MEN_WIL") * 0.5 + trait(genome, "PHY_VIT") * 0.3 + trait(genome, "PHY_END") * 0.2
    local cunning   = trait(genome, "MEN_INT") * 0.35 + axis(pers, "PER_ADA") * 0.35 + axis(pers, "PER_CUR") * 0.3
    local aggression = axis(pers, "PER_BLD") * 0.5 + axis(pers, "PER_VOL") * 0.3 + (100 - axis(pers, "PER_CRM")) * 0.2
    local volatility = axis(pers, "PER_VOL") * 0.6 + axis(pers, "PER_BLD") * 0.2

    -- Body state from world conditions
    local wound_load, illness_load, stress, body_traits = compute_body_state(worldContext)

    -- Stamina: base 80, adjusted by vitality and body state
    local stamina = 80 + (trait(genome, "PHY_VIT") - 50) * 0.4
    stamina = stamina - wound_load * 0.3 - illness_load * 0.25
    volatility = volatility + stress * 0.2

    -- Condition multiplier (body integrity)
    local condition = 1.0
    if wound_load >= 30 then condition = condition - 0.15 end
    if illness_load >= 20 then condition = condition - 0.10 end
    if wound_load >= 10 then
        if not _contains(body_traits, "wounded") then
            body_traits[#body_traits + 1] = "wounded"
        end
    end

    -- Cultural memory bonuses
    local cm = gameState.cultural_memory
    if cm then
        local ok_phys, phys_mem = pcall(function() return cm:get("physical") or 0 end)
        local ok_ment, ment_mem = pcall(function() return cm:get("mental") or 0 end)
        if ok_phys and phys_mem then
            power = power + phys_mem * 0.15
            grit = grit + phys_mem * 0.10
        end
        if ok_ment and ment_mem then
            cunning = cunning + ment_mem * 0.15
        end
    end

    -- Momentum bonuses (physical streak)
    local mom = worldContext and worldContext.momentum
    if mom then
        local ok_m, phys_streak = pcall(function()
            return mom.streaks and mom.streaks.physical or 0
        end)
        if ok_m and phys_streak and phys_streak >= 3 then
            power = power + 3
            grit = grit + 2
        end
    end

    -- Personality tag (dominant axis ≥ 65)
    local personality_tag = nil
    local per_bld = axis(pers, "PER_BLD")
    local per_crm = axis(pers, "PER_CRM")
    local per_vol = axis(pers, "PER_VOL")
    local per_pri = axis(pers, "PER_PRI")
    local per_ada = axis(pers, "PER_ADA")
    local per_loy = axis(pers, "PER_LOY")

    local best_axis, best_val = nil, 65
    local axis_map = {
        { val = per_bld, tag = "bold" },
        { val = 100 - per_crm, tag = "cruel" },  -- low mercy = cruel
        { val = per_vol, tag = "volatile" },
        { val = per_pri, tag = "proud" },
        { val = per_ada, tag = "adaptive" },
        { val = per_loy, tag = "loyal" },
    }
    for _, entry in ipairs(axis_map) do
        if entry.val >= best_val then
            best_axis = entry.tag
            best_val = entry.val
        end
    end
    personality_tag = best_axis

    -- Dirty fighting: low mercy (CRM ≤ 35) or high volatility (≥ 70)
    local dirty = per_crm <= 35 or per_vol >= 70

    -- Cruel moves: low mercy (CRM ≤ 40)
    local cruel = per_crm <= 40

    -- Relic weapon
    local weapon, relic = find_relic_weapon(worldContext)

    -- Era
    local era = gameState.era and gameState.era:lower() or nil

    return Combat.build({
        name            = gameState.heir_name or "The Heir",
        power           = power,
        speed           = speed,
        grit            = grit,
        cunning         = cunning,
        aggression      = aggression,
        volatility      = volatility,
        stamina         = stamina,
        condition       = condition,
        dirty           = dirty,
        cruel           = cruel,
        personality_tag = personality_tag,
        traits          = body_traits,
        weapon          = weapon,
        relic           = relic,
        era             = era,
        title           = gameState.lineage_name and ("of House " .. gameState.lineage_name) or nil,
        is_nemesis      = false,
    })
end

-- ═══════════════════════════════════════════════════════
-- OPPONENT CONSTRUCTION
-- ═══════════════════════════════════════════════════════

--- Build combat opponent from a rival heir + faction data.
---@param rival_heir table RivalHeir object (name, personality, etc.)
---@param faction table Faction object
---@param worldContext table|nil WorldController context
---@return table combatant
function Bridge.build_rival(rival_heir, faction, worldContext)
    if not rival_heir and not faction then
        return Combat.build_default("Unknown Rival")
    end

    local rh = rival_heir or {}
    local f = faction or {}
    local p = rh.personality or f.personality or {}

    -- Map rival heir stats from personality axes
    local per_bld = p.PER_BLD or 50
    local per_crm = p.PER_CRM or 50
    local per_vol = p.PER_VOL or 50
    local per_pri = p.PER_PRI or 50
    local per_ada = p.PER_ADA or 50
    local per_loy = p.PER_LOY or 50

    -- Base stats from faction archetype + personality
    local archetype = f.archetype or f.type or "warriors"
    local arch_bonus = {
        warriors  = { power = 12, grit = 8, speed = 0, cunning = -5 },
        scholars  = { power = -5, grit = 0, speed = 0, cunning = 12 },
        diplomats = { power = 0, grit = -5, speed = 5, cunning = 8 },
        artisans  = { power = 5, grit = 5, speed = 5, cunning = 5 },
    }
    local bonus = arch_bonus[archetype] or arch_bonus.warriors

    local power     = 50 + bonus.power + per_bld * 0.2
    local speed     = 50 + bonus.speed + per_ada * 0.2
    local grit      = 50 + bonus.grit + (100 - per_vol) * 0.15
    local cunning   = 50 + bonus.cunning + per_ada * 0.15
    local aggression = per_bld * 0.4 + per_vol * 0.3 + (100 - per_crm) * 0.3
    local volatility = per_vol * 0.5 + per_bld * 0.2

    -- Scale by faction power
    local fpower = f.power or 50
    local power_scale = 0.8 + (fpower / 100) * 0.4  -- 0.8 to 1.2
    power = power * power_scale
    grit = grit * power_scale

    -- Personality tag
    local personality_tag = nil
    if per_bld >= 65 then personality_tag = "bold"
    elseif per_crm <= 35 then personality_tag = "cruel"
    elseif per_vol >= 65 then personality_tag = "volatile"
    elseif per_pri >= 65 then personality_tag = "proud"
    elseif per_ada >= 65 then personality_tag = "adaptive"
    elseif per_loy >= 65 then personality_tag = "loyal"
    end

    local dirty = per_crm <= 35 or per_vol >= 70
    local cruel = per_crm <= 40

    -- Name
    local name = rh.name or f.name or "The Rival"
    local era = worldContext and worldContext.world_state and worldContext.world_state.era
    if era then era = era:lower() end

    return Combat.build({
        name            = name,
        power           = power,
        speed           = speed,
        grit            = grit,
        cunning         = cunning,
        aggression      = aggression,
        volatility      = volatility,
        stamina         = 70 + (fpower - 50) * 0.3,
        condition       = 1.0,
        dirty           = dirty,
        cruel           = cruel,
        personality_tag = personality_tag,
        traits          = {},
        era             = era,
        title           = f.name and ("of " .. f.name) or nil,
        is_nemesis      = true,
    })
end

--- Build combat opponent from a generic event context.
---@param spec table { name, power, speed, grit, cunning, personality_tag, ... }
---@return table combatant
function Bridge.build_from_event(spec)
    return Combat.build(spec)
end

-- ═══════════════════════════════════════════════════════
-- STAKES CONSTRUCTION
-- ═══════════════════════════════════════════════════════

--- Build stakes from event context.
---@param stakes_type string "casual"|"honor"|"blood"|"trial"
---@param terrain string|nil Terrain type
---@param seed_offset number|nil Extra seed variation
---@return table stakes
function Bridge.build_stakes(stakes_type, terrain, seed_offset)
    return {
        type = stakes_type or "honor",
        terrain = terrain,
        seed_offset = seed_offset or 0,
    }
end

-- ═══════════════════════════════════════════════════════
-- AFTERMATH — Feed combat results back into Bloodweight
-- ═══════════════════════════════════════════════════════

--- Process combat results into Bloodweight-compatible consequences.
---@param result table Combat.resolve() output
---@param stakes_type string "casual"|"honor"|"blood"|"trial"
---@return table consequences { injuries, lineage_power_shift, cultural_memory_shift, moral_act, ... }
function Bridge.aftermath(result, stakes_type)
    local consequences = {
        injuries = result.injuries or {},
        lineage_power_shift = 0,
        cultural_memory_shift = {},
        moral_act = nil,
        narration = nil,
    }

    local won = result.outcome.protag_won
    local margin = result.outcome.margin

    -- Lineage power
    if won == true then
        consequences.lineage_power_shift = margin == "dominant" and 5 or 3
    elseif won == false then
        consequences.lineage_power_shift = margin == "dominant" and -5 or -2
    end

    -- Blood stakes: killing an opponent
    if stakes_type == "blood" and won == true and result.outcome.ko then
        consequences.moral_act = {
            act_id = "combat_kill",
            description = "Killed " .. (result.outcome.loser or "an opponent") .. " in blood combat",
        }
        consequences.lineage_power_shift = consequences.lineage_power_shift + 3
    end

    -- Cultural memory (physical category shifts from combat)
    if won == true then
        consequences.cultural_memory_shift = { physical = margin == "dominant" and 2 or 1 }
    elseif won == false and margin == "dominant" then
        consequences.cultural_memory_shift = { physical = -1 }
    end

    -- Trial verdict
    if stakes_type == "trial" then
        if won == true then
            consequences.narration = "The trial by combat was decided. The bloodline was vindicated."
        else
            consequences.narration = "The trial by combat was decided. Against the bloodline."
        end
    end

    return consequences
end

return Bridge
