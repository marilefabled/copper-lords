-- dredwork Arcs — Relationship Arc Generation
-- Auto-generated prose summaries from interaction history and memory.
--
-- "You met Sera when she was nobody. You made her somebody.
--  She repaid you with loyalty for three years. Then with a knife."
--
-- Every significant relationship gets a story.
-- Not stats. Not timelines. A NARRATIVE ARC with a shape.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Arcs = {}
Arcs.__index = Arcs

-- Arc shapes: the emotional trajectory of a relationship
local ARC_SHAPES = {
    rising     = { label = "Rising",     pattern = "grew stronger over time" },
    falling    = { label = "Falling",    pattern = "deteriorated over time" },
    betrayal   = { label = "Betrayal",   pattern = "trust shattered by a single act" },
    redemption = { label = "Redemption", pattern = "recovered from a low point" },
    steady     = { label = "Steady",     pattern = "remained constant" },
    volatile   = { label = "Volatile",   pattern = "swung between extremes" },
    tragic     = { label = "Tragic",     pattern = "ended in loss" },
    rivals     = { label = "Rivals",     pattern = "never escaped their opposition" },
}

function Arcs.init(engine)
    local self = setmetatable({}, Arcs)
    self.engine = engine

    engine.game_state.arcs = {
        interaction_log = {},  -- entity_id → [{ day, type, text, sentiment }]
        generated = {},        -- entity_id → { arc_shape, summary, last_updated }
    }

    -- Log every interaction
    engine:on("INTERACTION_PERFORMED", function(ctx)
        if ctx then self:log_interaction(ctx, engine.game_state) end
    end)

    -- Log approach resolutions
    engine:on("APPROACH_RESOLVED", function(ctx)
        if ctx then
            self:log_interaction({
                actor_id = ctx.entity_id,
                target_id = ctx.entity_id,
                interaction = "approach_" .. (ctx.type or "ambient"),
                text = "",
            }, engine.game_state)
        end
    end)

    -- Log echoes that involve specific entities
    engine:on("ECHO_FIRED", function(ctx)
        if ctx and ctx.entity_id then
            self:log_interaction({
                actor_id = ctx.entity_id,
                target_id = ctx.entity_id,
                interaction = "echo_" .. (ctx.echo_type or "unknown"),
                text = ctx.text or "",
            }, engine.game_state)
        end
    end)

    -- Generate arc summaries monthly
    engine:on("NEW_MONTH", function(clock)
        self:update_arcs(engine.game_state, clock)
    end)

    return self
end

--------------------------------------------------------------------------------
-- LOGGING
--------------------------------------------------------------------------------

function Arcs:log_interaction(ctx, gs)
    local focal_mod = self.engine:get_module("entities")
    local focal = focal_mod and focal_mod:get_focus()
    if not focal then return end

    -- Determine which entity this involves (from the focal's perspective)
    local other_id = nil
    if ctx.actor_id == focal.id then
        other_id = ctx.target_id
    elseif ctx.target_id == focal.id then
        other_id = ctx.actor_id
    end
    if not other_id then return end

    local day = gs.clock and gs.clock.total_days or 0

    -- Classify sentiment
    local sentiment = self:_classify_sentiment(ctx.interaction, ctx.tags)

    if not gs.arcs.interaction_log[other_id] then
        gs.arcs.interaction_log[other_id] = {}
    end

    table.insert(gs.arcs.interaction_log[other_id], {
        day = day,
        type = ctx.interaction,
        sentiment = sentiment,
        text = ctx.text or "",
    })

    -- Cap at 30 interactions per entity
    local log = gs.arcs.interaction_log[other_id]
    while #log > 30 do
        table.remove(log, 1)
    end
end

function Arcs:_classify_sentiment(interaction, tags)
    -- Positive
    local positive = {
        gift_item = true, forgive = true, free_person = true,
        confide = true, mentor = true, give_gold = true,
        propose_alliance = true, propose_marriage = true,
        approach_gratitude = true, approach_romantic = true,
        echo_freedom_echo = true, echo_forgiveness_echo = true,
        freedom_echo = true, forgiveness_echo = true,
    }
    -- Negative
    local negative = {
        threaten = true, blackmail = true, betray = true,
        enslave = true, exile = true, intimidate = true,
        approach_confrontation = true,
        echo_betrayal_echo = true, echo_revenge = true,
        betrayal_echo = true, slave_echo = true,
    }

    if positive[interaction] then return 1 end
    if negative[interaction] then return -1 end

    -- Check tags
    if tags then
        for _, tag in ipairs(tags) do
            if tag == "merciful_act" or tag == "kind" or tag == "warm" then return 1 end
            if tag == "cruel_act" or tag == "cold" or tag == "hostile" then return -1 end
        end
    end

    return 0  -- neutral
end

--------------------------------------------------------------------------------
-- ARC DETECTION: What shape is this relationship?
--------------------------------------------------------------------------------

function Arcs:_detect_shape(log)
    if #log < 3 then return "steady" end

    -- Calculate sentiment trajectory
    local first_half_sent = 0
    local second_half_sent = 0
    local mid = math.floor(#log / 2)
    local betrayal_found = false
    local swing_count = 0
    local prev_sent = 0
    local has_death = false

    for i, entry in ipairs(log) do
        if i <= mid then
            first_half_sent = first_half_sent + entry.sentiment
        else
            second_half_sent = second_half_sent + entry.sentiment
        end

        if entry.type and (entry.type:find("betray") or entry.type:find("blackmail")) then
            betrayal_found = true
        end
        if entry.type and entry.type:find("death") then
            has_death = true
        end

        -- Count swings
        if entry.sentiment ~= 0 and entry.sentiment ~= prev_sent and prev_sent ~= 0 then
            swing_count = swing_count + 1
        end
        if entry.sentiment ~= 0 then prev_sent = entry.sentiment end
    end

    -- Detect shape
    if has_death then return "tragic" end
    if betrayal_found and first_half_sent > 0 then return "betrayal" end
    if swing_count > #log * 0.4 then return "volatile" end
    if first_half_sent < -1 and second_half_sent > 1 then return "redemption" end
    if first_half_sent > 1 and second_half_sent < -1 then return "falling" end
    if second_half_sent > first_half_sent and second_half_sent > 0 then return "rising" end
    if second_half_sent < first_half_sent and second_half_sent < 0 then return "falling" end
    if first_half_sent < 0 and second_half_sent < 0 then return "rivals" end

    return "steady"
end

--------------------------------------------------------------------------------
-- ARC GENERATION: Prose from history
--------------------------------------------------------------------------------

function Arcs:update_arcs(gs, clock)
    local day = clock and clock.total_days or 0
    local entities_mod = self.engine:get_module("entities")
    if not entities_mod then return end

    for entity_id, log in pairs(gs.arcs.interaction_log) do
        if #log < 3 then goto skip end

        -- Don't regenerate too often
        local existing = gs.arcs.generated[entity_id]
        if existing and (day - (existing.last_updated or 0)) < 30 then goto skip end

        local entity = entities_mod:get(entity_id)
        local name = entity and entity.name or "someone"

        local shape = self:_detect_shape(log)
        local summary = self:_generate_summary(name, shape, log, entities_mod, gs)

        gs.arcs.generated[entity_id] = {
            arc_shape = shape,
            shape_label = ARC_SHAPES[shape] and ARC_SHAPES[shape].label or "Unknown",
            summary = summary,
            interaction_count = #log,
            last_updated = day,
        }

        ::skip::
    end
end

function Arcs:_generate_summary(name, shape, log, entities_mod, gs)
    local count = #log
    local first = log[1]
    local last = log[count]

    -- Count sentiments
    local pos, neg, neut = 0, 0, 0
    for _, entry in ipairs(log) do
        if entry.sentiment > 0 then pos = pos + 1
        elseif entry.sentiment < 0 then neg = neg + 1
        else neut = neut + 1 end
    end

    local duration = last.day - first.day
    local months = math.max(1, math.floor(duration / 30))

    -- Shape-specific prose
    local templates = {
        rising = {
            "You and " .. name .. " started as strangers. Over " .. months .. " months, something grew — "
                .. "built from " .. pos .. " moments of connection. "
                .. "What you have now was earned. Slowly. Honestly.",
            name .. " was nobody to you once. " .. count .. " interactions later, "
                .. "they're someone you'd miss. That crept up on both of you.",
        },
        falling = {
            "It started well with " .. name .. ". It didn't stay that way. "
                .. "Over " .. months .. " months, " .. neg .. " moments of friction wore the connection thin. "
                .. "What remains is the memory of what it was.",
            "You and " .. name .. " had something once. " .. count .. " interactions later, "
                .. "it's hard to remember what.",
        },
        betrayal = {
            "You trusted " .. name .. ". " .. pos .. " good moments made you believe you could. "
                .. "Then they showed you who they really were. "
                .. "The betrayal didn't erase the history — it reframed it.",
            name .. " built trust with patience. Then spent it all at once. "
                .. "The worst part isn't what they did. It's that you didn't see it coming.",
        },
        redemption = {
            "It was bad with " .. name .. " at first. " .. neg .. " conflicts, "
                .. months .. " months of friction. Then something shifted. "
                .. "Not forgiveness — something harder. Understanding.",
            "You and " .. name .. " clawed back from the edge. "
                .. "What you have now was built on rubble. It's stronger for it.",
        },
        steady = {
            name .. " has been a constant. " .. count .. " interactions over " .. months .. " months. "
                .. "No drama. No betrayal. Just presence. "
                .. "In this world, that's the rarest gift.",
            "Your relationship with " .. name .. " is what it's always been. "
                .. "Unremarkable. Dependable. More valuable than either of you admit.",
        },
        volatile = {
            "You and " .. name .. " — it's never simple. " .. pos .. " good moments, "
                .. neg .. " bad ones, all tangled together over " .. months .. " months. "
                .. "Neither of you can walk away. Neither of you can stay.",
            name .. " makes you better and worse in equal measure. "
                .. count .. " interactions and you still can't predict which it'll be.",
        },
        tragic = {
            "This story doesn't have a happy ending. " .. name .. " is gone. "
                .. count .. " interactions is all you got. "
                .. months .. " months. That's the whole of it.",
            name .. " is a memory now. " .. pos .. " good moments to hold onto. "
                .. neg .. " regrets to carry. The math doesn't balance. It never does.",
        },
        rivals = {
            "You and " .. name .. " never found common ground. " .. neg .. " conflicts over "
                .. months .. " months. Some rivalries define you more than friendships.",
            name .. " was always on the other side. " .. count .. " interactions and "
                .. "not one of them ended with understanding. Some stories are like that.",
        },
    }

    local pool = templates[shape] or templates.steady
    return RNG.pick(pool)
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function Arcs:get_arc(entity_id, gs)
    gs = gs or self.engine.game_state
    return gs.arcs.generated[entity_id]
end

function Arcs:get_all_arcs(gs)
    gs = gs or self.engine.game_state
    local result = {}
    for id, arc in pairs(gs.arcs.generated) do
        table.insert(result, { entity_id = id, arc = arc })
    end
    table.sort(result, function(a, b)
        return (a.arc.interaction_count or 0) > (b.arc.interaction_count or 0)
    end)
    return result
end

function Arcs:get_interaction_count(entity_id, gs)
    gs = gs or self.engine.game_state
    local log = gs.arcs.interaction_log[entity_id]
    return log and #log or 0
end

function Arcs:serialize() return self.engine.game_state.arcs end
function Arcs:deserialize(data) self.engine.game_state.arcs = data end

return Arcs
