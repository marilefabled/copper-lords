local Math = require("dredwork_core.math")
-- Bloodweight — Fight Pit (v2)
-- Randomized fighter generation and pit match resolution.
-- Era-influenced names, archetypes, and weapons.
-- Pure Lua, zero Solar2D dependencies.

local Combat = require("dredwork_combat_v2.combat")

local FightPit = {}

-- ═══════════════════════════════════════════════════════
-- NAME POOLS
-- ═══════════════════════════════════════════════════════

local FIRST_NAMES = {
    "Ash", "Horg", "Sev", "Kael", "Ren", "Myr", "Bran", "Vel",
    "Uro", "Gra", "Eld", "Tor", "Nyr", "Cyr", "Quel", "Sal",
    "Orm", "Fen", "Thae", "Rik", "Mar", "Lok", "Ain", "Dav",
    "Jurn", "Weld", "Oss", "Pael", "Cresh", "Tarv",
}

local EPITHETS = {
    "the Scarred", "Half-Tongue", "No-Teeth", "Iron Rib",
    "Three-Scars", "Twice-Dead", "Bonecrusher", "the Lame",
    "Neckbreaker", "the Quiet", "Pale-Eye", "Split-Lip",
    "the Debt", "Last-Standing", "Red-Hands", "the Ledger",
    "Coffin-Filler", "the Receipt", "Surplus", "Write-Off",
}

-- ═══════════════════════════════════════════════════════
-- WEAPON POOL
-- ═══════════════════════════════════════════════════════

local WEAPONS = {
    nil, nil, nil, nil, -- 40% unarmed
    { id = "knife",   label = "a knife",   damage_bonus = 4, speed_penalty = 0 },
    { id = "club",    label = "a club",    damage_bonus = 7, speed_penalty = 3 },
    { id = "chain",   label = "a chain",   damage_bonus = 5, speed_penalty = 1 },
    { id = "staff",   label = "a staff",   damage_bonus = 4, speed_penalty = 1 },
    { id = "bottle",  label = "a bottle",  damage_bonus = 6, speed_penalty = 0 },
    { id = "hammer",  label = "a hammer",  damage_bonus = 8, speed_penalty = 4 },
}

-- ═══════════════════════════════════════════════════════
-- ARCHETYPE STAT BIASES
-- ═══════════════════════════════════════════════════════

local ARCHETYPES = {
    { name = "brawler", power = { base = 62, spread = 18 }, speed = { base = 42, spread = 16 },
      grit = { base = 58, spread = 18 }, cunning = { base = 38, spread = 16 } },
    { name = "quick",   power = { base = 42, spread = 16 }, speed = { base = 64, spread = 18 },
      grit = { base = 44, spread = 16 }, cunning = { base = 56, spread = 18 } },
    { name = "tank",    power = { base = 52, spread = 16 }, speed = { base = 36, spread = 16 },
      grit = { base = 68, spread = 18 }, cunning = { base = 42, spread = 16 } },
    { name = "balanced", power = { base = 50, spread = 20 }, speed = { base = 50, spread = 20 },
      grit = { base = 50, spread = 20 }, cunning = { base = 50, spread = 20 } },
}

local PERSONALITY_TAGS = { "bold", "cruel", "volatile", "proud", "adaptive", "loyal", nil, nil }


local function stat_roll(rng, def)
    return clamp(def.base + rng(def.spread) - math.floor(def.spread / 2), 15, 90)
end

-- ═══════════════════════════════════════════════════════
-- API
-- ═══════════════════════════════════════════════════════

--- Generate a random fighter.
---@param rng function Seeded RNG
---@param era string|nil Current era for flavor
---@return table combatant
function FightPit.roll_fighter(rng, era)
    -- Name
    local first = FIRST_NAMES[rng(#FIRST_NAMES)]
    local name = first
    if rng(3) == 1 then
        name = first .. " " .. EPITHETS[rng(#EPITHETS)]
    end

    -- Archetype
    local arch = ARCHETYPES[rng(#ARCHETYPES)]

    -- Stats
    local power   = stat_roll(rng, arch.power)
    local speed   = stat_roll(rng, arch.speed)
    local grit    = stat_roll(rng, arch.grit)
    local cunning = stat_roll(rng, arch.cunning)
    local aggression = clamp(30 + rng(50), 15, 90)
    local volatility = clamp(25 + rng(50), 15, 90)

    -- Weapon
    local weapon = WEAPONS[rng(#WEAPONS)]

    -- Personality
    local ptag = PERSONALITY_TAGS[rng(#PERSONALITY_TAGS)]

    -- Body traits
    local traits = {}
    if rng(4) == 1 then traits[#traits + 1] = "scarred" end
    if rng(6) == 1 then traits[#traits + 1] = "wounded" end
    if rng(8) == 1 then traits[#traits + 1] = "sick" end

    -- Dirty fighting (30% chance)
    local dirty = rng(10) <= 3

    -- Cruel (20% chance)
    local cruel = rng(5) == 1

    return Combat.build({
        name            = name,
        power           = power,
        speed           = speed,
        grit            = grit,
        cunning         = cunning,
        aggression      = aggression,
        volatility      = volatility,
        stamina         = clamp(60 + rng(30), 40, 95),
        condition       = clamp(0.7 + rng(30) / 100, 0.5, 1.0),
        dirty           = dirty,
        cruel           = cruel,
        personality_tag = ptag,
        traits          = traits,
        weapon          = weapon,
        era             = era,
    })
end

--- Generate a full pit fight between two random fighters.
---@param seed number RNG seed
---@param era string|nil Current era
---@return table { fighter_a, fighter_b, beats, outcome, seed }
function FightPit.generate(seed, era)
    -- Use seed for fighter generation, seed+1000 for combat
    local gen_rng_a = (function()
        local s = math.abs(seed) % 2147483647
        if s == 0 then s = 1 end
        return function(max)
            s = (s * 1103515245 + 12345) % 2147483647
            if max and max > 0 then return (s % max) + 1 end
            return s
        end
    end)()

    local gen_rng_b = (function()
        local s = math.abs(seed + 500) % 2147483647
        if s == 0 then s = 1 end
        return function(max)
            s = (s * 1103515245 + 12345) % 2147483647
            if max and max > 0 then return (s % max) + 1 end
            return s
        end
    end)()

    local a = FightPit.roll_fighter(gen_rng_a, era)
    local b = FightPit.roll_fighter(gen_rng_b, era)

    -- Ensure unique names
    if a.name == b.name then
        b.name = b.name .. " the Second"
    end

    local result = Combat.resolve(a, b, seed + 1000, { type = "casual", terrain = "pit" })

    return {
        fighter_a = a,
        fighter_b = b,
        beats = result.beats,
        outcome = result.outcome,
        seed = seed,
    }
end

--- Format a fighter stat card for display.
---@param fighter table Combatant
---@return string[] lines
function FightPit.fighter_card(fighter)
    local lines = {}
    lines[#lines + 1] = fighter.name .. (fighter.title and (" " .. fighter.title) or "")
    lines[#lines + 1] = string.format("  POW %d  SPD %d  GRT %d  CUN %d",
        fighter.power, fighter.speed, fighter.grit, fighter.cunning)
    lines[#lines + 1] = string.format("  AGG %d  VOL %d  STA %d  CON %.0f%%",
        fighter.aggression, fighter.volatility, fighter.stamina, (fighter.condition or 1) * 100)

    if fighter.weapon then
        lines[#lines + 1] = "  Armed: " .. fighter.weapon.label
    else
        lines[#lines + 1] = "  Unarmed"
    end

    if fighter.personality_tag then
        lines[#lines + 1] = "  Temperament: " .. fighter.personality_tag
    end

    if fighter.dirty then
        lines[#lines + 1] = "  Fights dirty"
    end

    if fighter.traits and #fighter.traits > 0 then
        lines[#lines + 1] = "  Marks: " .. table.concat(fighter.traits, ", ")
    end

    return lines
end

return FightPit
