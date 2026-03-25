-- dredwork_rumor/rumor.lua
-- Information propagation engine.
-- Rumors start from events, spread through social networks,
-- mutate as they travel, and calcify into reputation or die.

local Rumor = {}

local Math = require("dredwork_core.math")

local function make_id(origin_type, origin_id, generation)
    return tostring(origin_type or "unknown") .. ":" .. tostring(origin_id or "?") .. ":" .. tostring(generation or 0)
end

--[[
    Rumor record:
    {
        id            = unique key
        origin_type   = "combat" | "bond" | "event" | "claim" | "secret" | "player"
        origin_id     = source identifier
        generation    = game generation when created
        subject       = who/what the rumor is about (name string)
        original_text = the truth as it happened
        current_text  = what people are actually saying (mutates)
        truth_score   = 0-100 (100 = perfectly accurate, degrades with spread)
        heat          = 0-100 (how actively spreading, decays each tick)
        reach         = number of unique carriers who've heard it
        carriers      = { [bond_id] = { heard_gen, told_count } }
        mutations     = count of times the content has shifted
        confirmed     = boolean (player confirmed it publicly)
        denied        = boolean (player denied it publicly)
        calcified     = boolean (became permanent reputation)
        dead          = boolean (cooled to nothing)
        tags          = { "violence", "shame", "wealth", ... } for filtering
        severity      = 1-5 (how significant the rumor is)
    }
]]

local MUTATION_TEMPLATES = {
    inflate = {
        "The story grew. What was %s became something worse.",
        "By the time it reached the third mouth, %s had doubled in size.",
        "The version traveling now is louder than the original.",
    },
    deflect = {
        "The blame shifted. %s is no longer the center of the story.",
        "Someone else's name got attached to %s.",
        "The telling changed whose hands were dirty.",
    },
    invert = {
        "The story flipped. What was shameful became daring.",
        "Somewhere between the second and third telling, %s became a boast.",
        "The rumor reversed polarity. Victim became villain.",
    },
    detail_loss = {
        "The specifics faded. Only the feeling remains.",
        "Names dropped out of the story. The shape stayed.",
        "What happened is still known. When and why are not.",
    },
    embellish = {
        "Someone added a detail that wasn't there. It fit too well to correct.",
        "A witness who wasn't present contributed a vivid description.",
        "The story acquired a detail that makes it better and less true.",
    },
}

local MUTATION_TYPES = { "inflate", "deflect", "invert", "detail_loss", "embellish" }

function Rumor.create(spec)
    if not spec or not spec.subject then return nil end
    local text = spec.text or "Something happened."
    return {
        id = spec.id or make_id(spec.origin_type, spec.origin_id, spec.generation),
        origin_type = spec.origin_type or "event",
        origin_id = spec.origin_id or "unknown",
        generation = spec.generation or 1,
        subject = spec.subject,
        original_text = text,
        current_text = text,
        truth_score = Math.clamp(spec.truth_score or 90, 0, 100),
        heat = Math.clamp(spec.heat or 60, 0, 100),
        reach = 0,
        carriers = {},
        mutations = 0,
        confirmed = false,
        denied = false,
        calcified = false,
        dead = false,
        tags = spec.tags or {},
        severity = Math.clamp(spec.severity or 2, 1, 5),
    }
end

return Rumor
