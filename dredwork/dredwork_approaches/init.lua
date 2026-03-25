-- dredwork Approaches — NPC-Initiated Interactions
-- NPCs don't wait for you. They come to YOU.
-- Based on their memory, grudges, debts, plans, personality, and needs.
--
-- A loyal courtier warns you about a plot. A bitter rival blocks your path.
-- A widow whose husband you killed stares from across the market.
-- They have reasons. You just have to deal with it.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Approaches = {}
Approaches.__index = Approaches

function Approaches.init(engine)
    local self = setmetatable({}, Approaches)
    self.engine = engine

    engine.game_state.approaches = {
        pending = {},    -- approaches queued for delivery
        history = {},    -- past approaches (max 30)
        cooldowns = {},  -- entity_id → day last approached (prevent spam)
    }

    -- Generate approaches each morning
    engine:on("NEW_DAY", function(clock)
        self:generate(engine.game_state, clock)
    end)

    return self
end

--------------------------------------------------------------------------------
-- GENERATION: Who wants to talk to you today?
--------------------------------------------------------------------------------

function Approaches:generate(gs, clock)
    local day = clock and clock.total_days or 0
    local entities_mod = self.engine:get_module("entities")
    if not entities_mod then return end

    local focal = entities_mod:get_focus()
    if not focal then return end

    local focal_loc = focal.components and focal.components.location
    local candidates = {}

    -- Gather all entities who might approach the focal character
    for _, entity in pairs(gs.entities.registry) do
        if entity.id == focal.id then goto next end
        if not entity.components then goto next end

        -- Must be at the same location (or have a compelling reason)
        local same_loc = entity.components.location == focal_loc
        local has_grudge = entity.components.memory and
            self:_has_grudge(entity.components.memory, focal.id)
        local has_debt = entity.components.memory and
            self:_has_debt(entity.components.memory, focal.id)
        local has_plan_involving_focal = entity.components.plan and
            entity.components.plan.status == "active"

        -- Skip if not nearby and no strong reason to seek you out
        if not same_loc and not has_grudge and not has_debt then goto next end

        -- Cooldown: don't let the same NPC bother you every day
        local cd = gs.approaches.cooldowns[entity.id]
        if cd and (day - cd) < 7 then goto next end

        -- Score this entity's desire to approach
        local score = self:_score_approach(entity, focal, gs, day)
        if score > 0 then
            table.insert(candidates, { entity = entity, score = score })
        end

        ::next::
    end

    if #candidates == 0 then return end

    -- Sort by score, pick top candidate (max 1 approach per day)
    table.sort(candidates, function(a, b) return a.score > b.score end)

    -- 40% base chance, higher if top score is strong
    local top = candidates[1]
    local chance = Math.clamp(20 + top.score, 0, 85)
    if RNG.range(1, 100) > chance then return end

    local approach = self:_build_approach(top.entity, focal, gs, day)
    if approach then
        table.insert(gs.approaches.pending, approach)
        gs.approaches.cooldowns[top.entity.id] = day
    end
end

--------------------------------------------------------------------------------
-- SCORING: How badly does this NPC want to find you?
--------------------------------------------------------------------------------

function Approaches:_score_approach(entity, focal, gs, day)
    local score = 0
    local mem = entity.components.memory
    local pers = entity.components.personality or {}
    local needs = entity.components.needs or {}

    -- Grudge: strong motivator
    if mem and mem.grudges then
        for _, g in ipairs(mem.grudges) do
            if g.target_id == focal.id then
                score = score + g.intensity * 0.6
            end
        end
    end

    -- Debt: they owe you / feel grateful
    if mem and mem.debts then
        for _, d in ipairs(mem.debts) do
            if d.target_id == focal.id then
                score = score + d.weight * 0.4
            end
        end
    end

    -- Relationship strength drives social approaches
    local rel = self.engine:get_module("entities")
    if rel then
        local _rels = rel:get_relationships(entity.id)
        local _rel_strength = 0
        local _has_grudge, _has_romance = false, false
        for _, _r in ipairs(_rels) do
            if _r.a == focal.id or _r.b == focal.id then
                _rel_strength = _rel_strength + (_r.strength or 0)
                if _r.type == "grudge" then _has_grudge = true end
                if _r.type == "romance" then _has_romance = true end
            end
        end
        if _rel_strength ~= 0 then
            if _rel_strength > 70 then score = score + 15 end  -- close ally
            if _rel_strength < 20 then score = score + 10 end  -- hostile
            if _has_grudge then score = score + 20 end
            if _has_romance then score = score + 15 end
        end
    end

    -- Unmet needs push NPCs to seek help
    if needs.safety and needs.safety < 25 then score = score + 12 end
    if needs.belonging and needs.belonging < 25 then score = score + 8 end

    -- Personality: bold NPCs approach more
    local bld = pers.PER_BLD or 50
    score = score + (bld - 50) * 0.2

    -- Plans involving the focal character
    if entity.components.plan and entity.components.plan.status == "active" then
        score = score + 10
    end

    -- Witnessed something about focal recently
    if mem and mem.witnessed then
        for _, w in ipairs(mem.witnessed) do
            if w.details and w.details.subject_id == focal.id and
               (day - (w.day or 0)) < 30 then
                score = score + 8
            end
        end
    end

    return score
end

--------------------------------------------------------------------------------
-- BUILD: What does the NPC actually say/do?
--------------------------------------------------------------------------------

function Approaches:_build_approach(entity, focal, gs, day)
    local mem = entity.components.memory
    local pers = entity.components.personality or {}
    local name = entity.name or "A stranger"

    -- Determine approach type by priority
    local approach_type, text, consequences, response_options

    -- 1. Grudge approach (highest priority)
    local grudge = self:_get_grudge(mem, focal.id)
    if grudge and grudge.intensity > 30 then
        approach_type = "confrontation"
        local bld = pers.PER_BLD or 50
        if bld > 60 then
            text = name .. " steps into your path. Their eyes are steady. Practiced. "
                .. "\"We need to talk about what you did. " .. (grudge.reason or "You know what.") .. "\""
        else
            text = name .. " appears at the edge of your vision. Watching. When you meet their eyes, "
                .. "they don't look away. Not anymore. \"" .. (grudge.reason or "You remember.") .. "\""
        end
        consequences = {
            { type = "need", need = "safety", delta = -5 },
        }
        response_options = {
            { id = "face_them", label = "Face them", tags = { "brave" },
              text = "You turn to face " .. name .. " directly.",
              effects = { { type = "need", need = "purpose", delta = 3 } } },
            { id = "deflect", label = "Deflect", tags = { "diplomatic" },
              text = "You meet their gaze but redirect. \"Not here. Not now.\"",
              effects = {} },
            { id = "intimidate", label = "Intimidate", tags = { "cruel_act" },
              text = "You step closer. Close enough that they have to decide if they mean it.",
              effects = { { type = "need", need = "safety", delta = 3 } },
              requires = function(f) return (f.components.personality or {}).PER_BLD and f.components.personality.PER_BLD > 50 end },
            { id = "flee", label = "Walk away", tags = { "cowardly" },
              text = "You turn your back. You feel their eyes on you all the way.",
              effects = { { type = "need", need = "safety", delta = -3 }, { type = "need", need = "status", delta = -2 } } },
        }
        goto done
    end

    -- 2. Debt approach (gratitude)
    do
        local debt = self:_get_debt(mem, focal.id)
        if debt and debt.weight > 20 then
            approach_type = "gratitude"
            text = name .. " finds you. There's something different about them — steadier. "
                .. "\"I came to say what I should have said before. " .. (debt.reason or "Thank you.") .. "\""
            consequences = {
                { type = "need", need = "belonging", delta = 5 },
            }
            response_options = {
                { id = "accept", label = "Accept gracefully", tags = { "kind" },
                  text = "You nod. Sometimes that's enough.",
                  effects = { { type = "need", need = "purpose", delta = 3 } } },
                { id = "call_favor", label = "Call in the favor", tags = { "pragmatic" },
                  text = "\"I'm glad you remember. Because I need something.\"",
                  effects = { { type = "need", need = "status", delta = 2 } } },
                { id = "dismiss", label = "Dismiss them", tags = { "cold" },
                  text = "\"You don't owe me anything.\" The words land harder than you meant.",
                  effects = { { type = "need", need = "belonging", delta = -2 } } },
            }
            goto done
        end
    end

    -- 3. Warning (ally with information)
    do
        local rel_mod = self.engine:get_module("entities")
        local _warn_strength = 0
        if rel_mod then
            local _rels = rel_mod:get_relationships(entity.id)
            for _, _r in ipairs(_rels) do
                if _r.a == focal.id or _r.b == focal.id then _warn_strength = _warn_strength + (_r.strength or 0) end
            end
        end
        if _warn_strength > 60 and mem and mem.witnessed then
            for _, w in ipairs(mem.witnessed) do
                if w.type and (w.type:find("BETRAY") or w.type:find("PLOT") or w.type:find("SCHEME")) then
                    approach_type = "warning"
                    text = name .. " pulls you aside. Urgent. Quiet. "
                        .. "\"I heard something. I don't know if it's true but you need to know.\""
                    consequences = {
                        { type = "need", need = "safety", delta = -3 },
                        { type = "need", need = "belonging", delta = 3 },
                    }
                    response_options = {
                        { id = "investigate", label = "Press for details", tags = { "cautious" },
                          text = "\"Tell me everything. Leave nothing out.\"",
                          effects = { { type = "need", need = "purpose", delta = 3 } } },
                        { id = "thank", label = "Thank them", tags = { "kind" },
                          text = "\"I won't forget this.\"",
                          effects = { { type = "need", need = "belonging", delta = 2 } } },
                        { id = "doubt", label = "Doubt them", tags = { "suspicious" },
                          text = "\"And how do I know this isn't part of it?\"",
                          effects = { { type = "need", need = "safety", delta = -2 } } },
                    }
                    goto done
                end
            end
        end
    end

    -- 4. Request (NPC needs something from you)
    do
        local needs = entity.components.needs or {}
        local worst_need, worst_val = nil, 100
        for k, v in pairs(needs) do
            if type(v) == "number" and v < worst_val then
                worst_need, worst_val = k, v
            end
        end
        if worst_need and worst_val < 30 then
            approach_type = "request"
            local request_texts = {
                safety = name .. " approaches with urgency. Eyes darting. "
                    .. "\"I need protection. I can't—\" they stop. Breathe. \"Please.\"",
                belonging = name .. " lingers nearby. Working up the courage. "
                    .. "\"I don't have anyone else to ask. Would you... just listen?\"",
                purpose = name .. " sits beside you. Heavy. "
                    .. "\"I don't know what I'm doing anymore. Do you ever feel that way?\"",
                comfort = name .. " approaches, pride barely holding. "
                    .. "\"I wouldn't ask if I had another choice. I need help.\"",
                status = name .. " kneels. Not in respect — in desperation. "
                    .. "\"Everyone has forgotten me. But you — you could change that.\"",
            }
            text = request_texts[worst_need] or (name .. " approaches you with a request.")
            consequences = {}
            response_options = {
                { id = "help", label = "Help them", tags = { "merciful_act", "kind" },
                  text = "You give what you can. It costs something. It always does.",
                  effects = { { type = "need", need = "purpose", delta = 5 }, { type = "need", need = "belonging", delta = 3 } } },
                { id = "bargain", label = "Name your price", tags = { "pragmatic" },
                  text = "\"I can help. But nothing is free.\"",
                  effects = { { type = "need", need = "status", delta = 2 } } },
                { id = "refuse", label = "Refuse", tags = { "cold" },
                  text = "You walk past. Their voice follows you, then doesn't.",
                  effects = { { type = "need", need = "belonging", delta = -3 } } },
            }
            goto done
        end
    end

    -- 5. Social (relationship-driven: romance, friendship, rivalry)
    do
        local rel_mod = self.engine:get_module("entities")
        local _has_romance = false
        if rel_mod then
            local _rels = rel_mod:get_relationships(entity.id)
            for _, _r in ipairs(_rels) do
                if (_r.a == focal.id or _r.b == focal.id) and _r.type == "romance" then _has_romance = true; break end
            end
        end
        if _has_romance then
            approach_type = "romantic"
            text = name .. " finds you in a quiet moment. They don't say anything at first. "
                .. "Just stand close enough that you can feel the warmth."
            consequences = {
                { type = "need", need = "belonging", delta = 5 },
                { type = "need", need = "comfort", delta = 3 },
            }
            response_options = {
                { id = "embrace", label = "Draw closer", tags = { "warm" },
                  text = "You close the distance. Words aren't needed.",
                  effects = { { type = "need", need = "belonging", delta = 5 } } },
                { id = "talk", label = "Talk", tags = { "social" },
                  text = "You talk. About nothing. About everything. The words matter less than the sound of them.",
                  effects = { { type = "need", need = "comfort", delta = 3 } } },
                { id = "distance", label = "Keep distance", tags = { "cold" },
                  text = "You don't move closer. They notice. Something shifts between you.",
                  effects = { { type = "need", need = "belonging", delta = -3 } } },
            }
            goto done
        end
    end

    -- 6. Ambient approach (personality-driven small talk / tension)
    do
        approach_type = "ambient"
        local bld = pers.PER_BLD or 50
        local loy = pers.PER_LOY or 50
        if bld > 60 then
            text = name .. " catches you between tasks. Direct. No preamble. "
                .. "\"A word. I've been thinking about this place. About what comes next.\""
        elseif loy > 60 then
            text = name .. " falls into step beside you. Quiet, but present. "
                .. "\"Just wanted you to know — I'm here. Whatever happens.\""
        else
            text = name .. " watches you from across the room. When your eyes meet, "
                .. "they raise a cup. Could mean anything."
        end
        consequences = {}
        response_options = {
            { id = "engage", label = "Engage", tags = { "social" },
              text = "You give them your attention. It's the smallest gift and the most expensive.",
              effects = { { type = "need", need = "belonging", delta = 2 } } },
            { id = "nod", label = "Nod and move on", tags = { "neutral" },
              text = "A nod. Acknowledgment without commitment.",
              effects = {} },
        }
    end

    ::done::

    if not text then return nil end

    return {
        type = approach_type,
        entity_id = entity.id,
        entity_name = name,
        text = text,
        consequences = consequences or {},
        response_options = response_options or {},
        day = day,
    }
end

--------------------------------------------------------------------------------
-- DELIVERY: Pop the next pending approach
--------------------------------------------------------------------------------

function Approaches:pop_pending(gs)
    gs = gs or self.engine.game_state
    if #gs.approaches.pending == 0 then return nil end
    local approach = table.remove(gs.approaches.pending, 1)

    -- Record in history
    table.insert(gs.approaches.history, {
        type = approach.type,
        entity_id = approach.entity_id,
        entity_name = approach.entity_name,
        day = approach.day,
    })
    while #gs.approaches.history > 30 do
        table.remove(gs.approaches.history, 1)
    end

    return approach
end

--- Respond to an approach — apply effects and emit events.
function Approaches:respond(approach, response_id, gs)
    gs = gs or self.engine.game_state
    local entities_mod = self.engine:get_module("entities")
    local focal = entities_mod and entities_mod:get_focus()
    if not focal then return end

    -- Apply base consequences
    if approach.consequences then
        for _, c in ipairs(approach.consequences) do
            if c.type == "need" and focal.components.needs then
                focal.components.needs[c.need] = Math.clamp(
                    (focal.components.needs[c.need] or 50) + (c.delta or 0), 0, 100)
            end
        end
    end

    -- Find and apply response effects
    local response_text = "..."
    if approach.response_options then
        for _, opt in ipairs(approach.response_options) do
            if opt.id == response_id then
                response_text = opt.text or "..."
                if opt.effects then
                    for _, e in ipairs(opt.effects) do
                        if e.type == "need" and focal.components.needs then
                            focal.components.needs[e.need] = Math.clamp(
                                (focal.components.needs[e.need] or 50) + (e.delta or 0), 0, 100)
                        end
                    end
                end
                -- Emit for echoes / memory
                self.engine:emit("INTERACTION_PERFORMED", {
                    actor_id = focal.id,
                    actor_name = focal.name,
                    target_id = approach.entity_id,
                    target_name = approach.entity_name,
                    interaction = "approach_" .. (approach.type or "unknown"),
                    tags = opt.tags or {},
                })
                break
            end
        end
    end

    -- Push narrative beat
    self.engine:push_ui_event("NARRATIVE_BEAT", {
        channel = "whispers",
        text = response_text,
        priority = 60,
        display_hint = "echo",
        tags = { "approach", approach.type },
        timestamp = approach.day,
    })

    self.engine:emit("APPROACH_RESOLVED", {
        type = approach.type,
        entity_id = approach.entity_id,
        response = response_id,
    })
end

function Approaches:has_pending()
    return #self.engine.game_state.approaches.pending > 0
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

function Approaches:_has_grudge(mem, target_id)
    if not mem or not mem.grudges then return false end
    for _, g in ipairs(mem.grudges) do
        if g.target_id == target_id then return true end
    end
    return false
end

function Approaches:_get_grudge(mem, target_id)
    if not mem or not mem.grudges then return nil end
    for _, g in ipairs(mem.grudges) do
        if g.target_id == target_id then return g end
    end
    return nil
end

function Approaches:_has_debt(mem, target_id)
    if not mem or not mem.debts then return false end
    for _, d in ipairs(mem.debts) do
        if d.target_id == target_id then return true end
    end
    return false
end

function Approaches:_get_debt(mem, target_id)
    if not mem or not mem.debts then return nil end
    for _, d in ipairs(mem.debts) do
        if d.target_id == target_id then return d end
    end
    return nil
end

function Approaches:serialize() return self.engine.game_state.approaches end
function Approaches:deserialize(data) self.engine.game_state.approaches = data end

return Approaches
