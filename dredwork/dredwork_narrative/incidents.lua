-- dredwork Narrative — Incident Generator
-- Generates off-field events, scandals, and buzz that feed the rumor and dilemma engines.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Incidents = {}

--- Generate a random incident for a character or group.
---@param engine table The central engine
---@param context table { actors, factions, locations }
function Incidents.generate(engine, context)
    local pool = {
        { id = "media_leak", weight = 30, run = Incidents.media_leak },
        { id = "conflict",   weight = 20, run = Incidents.internal_conflict },
        { id = "buzz",       weight = 25, run = Incidents.rising_buzz },
    }

    local incident_def = RNG.weighted_pick(pool, function(i) return i.weight end)
    return incident_def.run(engine, context)
end

function Incidents.media_leak(engine, context)
    local actor = RNG.pick(context.actors)
    if not actor then return nil end

    local negative = RNG.chance(0.6)
    local subject = actor.name
    
    -- 1. Emit Rumor
    engine:get_module("rumor"):inject(engine.game_state, {
        origin_type = "incident",
        origin_id = "media_leak",
        subject = subject,
        text = negative and (subject .. " was caught in a compromising scandal.") or (subject .. " is becoming a public favorite."),
        heat = 60,
        severity = negative and 4 or 2,
        tags = negative and { "shame", "scandal" } or { "praise", "spotlight" }
    })

    -- 2. Emit Pressure/Dilemma
    engine:get_module("dilemma"):register_source("incident_leak", function(gs)
        return {
            {
                id = "leak_" .. actor.id,
                category = "reputation",
                urgency = negative and 75 or 45,
                label = "Media Cycle: " .. subject,
                summary = "The story is spreading. You can address it now or let it calcify.",
                address = { narrative = "You managed the press cycle." },
                neglect = { narrative = "The story grew teeth." }
            }
        }
    end)
    
    return { id = "media_leak", actor = actor, negative = negative }
end

-- ... (internal_conflict, rising_buzz)

return Incidents
