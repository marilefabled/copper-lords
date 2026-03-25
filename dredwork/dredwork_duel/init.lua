-- dredwork Duel — Module Entry
-- Simultaneous 5-step prediction combat. Two combatants plan moves, resolve simultaneously.
-- Connects to genetics (traits → combat traits), biography (wild attributes → bonuses),
-- and emits events that cascade through The Ripple.
-- Ported from "5 Steps Ahead."

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Duel = {}
Duel.__index = Duel

function Duel.init(engine)
    local self = setmetatable({}, Duel)
    self.engine = engine

    self.resolver = require("dredwork_duel.resolver")
    self.intent   = require("dredwork_duel.intent")
    self.moves    = require("dredwork_duel.moves")

    engine.game_state.duels = {
        active = nil,    -- current active duel (or nil)
        history = {},    -- past duel results
    }

    -- Expose duel data
    engine:on("GET_DUEL_DATA", function(req)
        req.active = self.engine.game_state.duels.active
        req.history = self.engine.game_state.duels.history
        req.duel_count = #self.engine.game_state.duels.history
    end)

    -- Listen for duel requests
    engine:on("REQUEST_DUEL", function(ctx)
        if ctx and ctx.combatant_a and ctx.combatant_b then
            self:start_duel(ctx.combatant_a, ctx.combatant_b, ctx.context)
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- Trait Mapping: Genetics → Combat Traits
--------------------------------------------------------------------------------

--- Map a character's genome/personality to duel combat traits.
---@param person table character with .traits and/or .personality
---@return table { traits = {string,...}, stats = {focus, read, discipline}, bias = {...} }
function Duel:map_character(person)
    local combat_traits = {}
    local stats = { focus = 2, read = 2, discipline = 2 }
    local bias = { strike = 0.35, defense = 0.20, evasion = 0.15, movement = 0.15, disruption = 0.15 }

    if not person then return { traits = combat_traits, stats = stats, bias = bias } end

    -- Extract personality values
    local function get_axis(id)
        if person.personality and person.personality[id] then return person.personality[id] end
        if person.traits and person.traits[id] then
            local t = person.traits[id]
            return type(t) == "table" and t.value or t
        end
        return 50
    end

    -- Map personality to combat traits
    local bld = get_axis("PER_BLD")
    local obs = get_axis("PER_OBS")
    local vol = get_axis("PER_VOL")
    local loy = get_axis("PER_LOY")
    local ada = get_axis("PER_ADA")
    local crm = get_axis("PER_CRM")

    -- Bold fighters are aggressive strikers
    if bld > 70 then
        bias.strike = bias.strike + 0.15
        bias.defense = bias.defense - 0.05
        table.insert(combat_traits, "Momentum Fighter")
    elseif bld < 30 then
        bias.defense = bias.defense + 0.10
        bias.evasion = bias.evasion + 0.10
        bias.strike = bias.strike - 0.10
    end

    -- Observant fighters read better
    if obs > 65 then
        stats.read = stats.read + 1
        stats.focus = stats.focus + 1
    end

    -- Volatile fighters are unpredictable
    if vol > 70 then
        table.insert(combat_traits, "Unorthodox")
        bias.disruption = bias.disruption + 0.10
    end

    -- Loyal fighters telegraph (honest body language)
    if loy > 70 then
        table.insert(combat_traits, "Telegraphed")
    end

    -- Adaptive fighters are harder to read
    if ada > 65 then
        table.insert(combat_traits, "Veiled")
        stats.deception = (stats.deception or 0) + 1
    end

    -- Cruel fighters specialize in counters
    if crm > 70 then
        table.insert(combat_traits, "Counter Specialist")
    end

    -- Physical traits affect HP proxy (mapped externally)
    -- Mental traits affect focus/read (already done)

    -- Biography wild attributes add combat bonuses
    local req_bio = { wild_attributes = {} }
    self.engine:emit("GET_BIOGRAPHY_DATA", req_bio)
    for _, wa in ipairs(req_bio.wild_attributes or {}) do
        if wa.category == "physical" then
            stats.discipline = stats.discipline + 1
        elseif wa.category == "mental" then
            stats.focus = stats.focus + 1
        end
    end

    return { traits = combat_traits, stats = stats, bias = bias }
end

--------------------------------------------------------------------------------
-- Duel Lifecycle
--------------------------------------------------------------------------------

--- Start a duel between two characters.
---@param char_a table { name, hp, person } (person = character with traits)
---@param char_b table { name, hp, person, bias_override }
---@param context table|nil { cause, region_id, stakes }
function Duel:start_duel(char_a, char_b, context)
    local gs = self.engine.game_state
    context = context or {}

    -- Map characters to combat profiles
    local profile_a = self:map_character(char_a.person)
    local profile_b = self:map_character(char_b.person)

    -- Override bias if provided (for specific enemy archetypes)
    if char_b.bias_override then profile_b.bias = char_b.bias_override end
    if char_b.traits_override then profile_b.traits = char_b.traits_override end

    local fighter_a = self.resolver.new_fighter(char_a.name or "Combatant A", char_a.hp or 20)
    local fighter_b = self.resolver.new_fighter(char_b.name or "Combatant B", char_b.hp or 18)

    gs.duels.active = {
        fighter_a = fighter_a,
        fighter_b = fighter_b,
        profile_a = profile_a,
        profile_b = profile_b,
        round = 0,
        rounds = {},
        context = context,
        status = "active", -- active, resolved
        winner = nil,
    }

    self.engine:emit("DUEL_STARTED", {
        a_name = fighter_a.name,
        b_name = fighter_b.name,
        cause = context.cause,
        text = string.format("A duel begins between %s and %s!", fighter_a.name, fighter_b.name),
    })
    self.engine:push_ui_event("DUEL_STARTED", {
        text = string.format("A duel begins: %s vs %s!", fighter_a.name, fighter_b.name),
    })

    self.engine.log:info("Duel: %s vs %s", fighter_a.name, fighter_b.name)
end

--- Execute one round of a duel (both sides plan, then resolve).
---@param a_plan table|nil 5 move IDs for side A (if nil, AI generates)
---@return table round events
function Duel:execute_round(a_plan)
    local gs = self.engine.game_state
    local duel = gs.duels.active
    if not duel or duel.status ~= "active" then return nil end

    duel.round = duel.round + 1

    -- Generate plans
    local plan_a = a_plan or self.intent.generate_plan(
        { traits = duel.profile_a.traits, bias = duel.profile_a.bias, stats = duel.profile_a.stats },
        self.moves
    )
    local plan_b = self.intent.generate_plan(
        { traits = duel.profile_b.traits, bias = duel.profile_b.bias, stats = duel.profile_b.stats },
        self.moves
    )

    -- Foresight rewrite (boss mechanic)
    plan_b = self.intent.rewrite_with_foresight(
        { traits = duel.profile_b.traits },
        plan_a, self.moves, plan_b
    )

    -- Resolve
    local events = self.resolver.resolve_round({
        a_plan = plan_a,
        b_plan = plan_b,
        a_unit = duel.fighter_a,
        b_unit = duel.fighter_b,
        moves = self.moves.defs,
        b_traits = duel.profile_b.traits,
    })

    -- Apply final state
    duel.fighter_a = events.final_state.a
    duel.fighter_b = events.final_state.b

    table.insert(duel.rounds, {
        round = duel.round,
        a_plan = plan_a,
        b_plan = plan_b,
        events = events,
    })

    -- Emit round completed
    self.engine:emit("DUEL_ROUND_COMPLETE", {
        round = duel.round,
        a_hp = duel.fighter_a.hp,
        b_hp = duel.fighter_b.hp,
        events = events,
    })

    -- Check for KO
    if duel.fighter_a.hp <= 0 or duel.fighter_b.hp <= 0 then
        self:_resolve_duel(duel)
    end

    return events
end

--- Auto-fight: run rounds until someone drops.
---@param max_rounds number|nil safety cap (default 10)
---@return table duel result
function Duel:auto_fight(max_rounds)
    max_rounds = max_rounds or 10
    local gs = self.engine.game_state
    local duel = gs.duels.active
    if not duel then return nil end

    for _ = 1, max_rounds do
        if duel.status ~= "active" then break end
        self:execute_round()
    end

    -- Force resolve if still going
    if duel.status == "active" then
        self:_resolve_duel(duel)
    end

    return {
        winner = duel.winner,
        rounds = duel.round,
        a_hp = duel.fighter_a.hp,
        b_hp = duel.fighter_b.hp,
    }
end

--- Resolve a completed duel.
function Duel:_resolve_duel(duel)
    duel.status = "resolved"

    if duel.fighter_a.hp <= 0 and duel.fighter_b.hp <= 0 then
        duel.winner = "draw"
    elseif duel.fighter_a.hp <= 0 then
        duel.winner = "b"
    elseif duel.fighter_b.hp <= 0 then
        duel.winner = "a"
    else
        -- Timeout: whoever has more HP wins
        duel.winner = duel.fighter_a.hp >= duel.fighter_b.hp and "a" or "b"
    end

    local winner_name = duel.winner == "a" and duel.fighter_a.name or (duel.winner == "b" and duel.fighter_b.name or "neither")
    local loser_name = duel.winner == "a" and duel.fighter_b.name or (duel.winner == "b" and duel.fighter_a.name or "neither")

    local result = {
        winner = duel.winner,
        winner_name = winner_name,
        loser_name = loser_name,
        rounds = duel.round,
        a_final_hp = duel.fighter_a.hp,
        b_final_hp = duel.fighter_b.hp,
        cause = duel.context and duel.context.cause,
        text = duel.winner == "draw"
            and string.format("The duel between %s and %s ends in a draw.", duel.fighter_a.name, duel.fighter_b.name)
            or string.format("%s defeats %s in %d rounds!", winner_name, loser_name, duel.round),
    }

    -- Archive
    table.insert(self.engine.game_state.duels.history, result)

    -- Emit for The Ripple
    self.engine:emit("DUEL_RESOLVED", result)
    self.engine:push_ui_event("DUEL_RESOLVED", result)

    -- Clear active
    self.engine.game_state.duels.active = nil

    self.engine.log:info("Duel: %s", result.text)
end

--- Get intent visibility for the opponent.
function Duel:get_opponent_intent(reader_stats)
    local duel = self.engine.game_state.duels.active
    if not duel then return nil end

    local plan_b = self.intent.generate_plan(
        { traits = duel.profile_b.traits, bias = duel.profile_b.bias, stats = duel.profile_b.stats },
        self.moves
    )

    return self.intent.reveal_intent(
        reader_stats or duel.profile_a.stats,
        { traits = duel.profile_b.traits, stats = duel.profile_b.stats },
        duel.fighter_b,
        plan_b,
        self.moves
    )
end

function Duel:serialize() return self.engine.game_state.duels end
function Duel:deserialize(data) self.engine.game_state.duels = data end

return Duel
