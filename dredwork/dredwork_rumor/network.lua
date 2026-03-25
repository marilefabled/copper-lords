-- dredwork_rumor/network.lua
-- The propagation engine. Rumors spread through carriers (bonds, factions, locations).
-- Each tick: rumors propagate to adjacent carriers, mutate, cool, or calcify.

local Rumor = require("dredwork_rumor.rumor")
local Math = require("dredwork_core.math")

local Network = {}

--[[
    Network state (stored on game_state.rumor_network):
    {
        rumors = { [id] = rumor_record },
        reputation = { [subject] = { score, tags, sources } },
        generation = current generation,
    }
]]

function Network.ensure_state(game_state)
    if not game_state then return {} end
    game_state.rumor_network = game_state.rumor_network or {}
    local state = game_state.rumor_network
    state.rumors = state.rumors or {}
    state.reputation = state.reputation or {}
    state.generation = state.generation or (game_state.generation or 1)
    return state
end

function Network.inject(game_state, spec)
    if not game_state or not spec then return nil end
    local state = Network.ensure_state(game_state)
    local rumor = Rumor.create(spec)
    if not rumor then return nil end

    -- Deduplicate: if a rumor with same origin exists and is still alive, boost its heat
    local existing = state.rumors[rumor.id]
    if existing and not existing.dead then
        existing.heat = Math.clamp(existing.heat + 15, 0, 100)
        existing.severity = math.max(existing.severity, rumor.severity)
        return existing
    end

    state.rumors[rumor.id] = rumor
    return rumor
end

--[[
    Spread a rumor to a carrier (bond).
    carrier_spec: { id, name, visibility, volatility, temperament }
    Returns: true if the carrier heard it for the first time
]]
function Network.spread_to(game_state, rumor_id, carrier_spec)
    if not game_state or not rumor_id or not carrier_spec then return false end
    local state = Network.ensure_state(game_state)
    local rumor = state.rumors[rumor_id]
    if not rumor or rumor.dead then return false end

    local carrier_id = carrier_spec.id or "unknown"
    if rumor.carriers[carrier_id] then
        -- Already heard it — but they might retell it, boosting heat
        local entry = rumor.carriers[carrier_id]
        entry.told_count = (entry.told_count or 0) + 1
        return false
    end

    -- New carrier hears the rumor
    rumor.carriers[carrier_id] = {
        heard_gen = state.generation,
        told_count = 0,
        carrier_name = carrier_spec.name,
    }
    rumor.reach = rumor.reach + 1

    -- Mutation chance: each new carrier has a chance to distort
    local mutation_chance = 30 + math.floor((carrier_spec.volatility or 30) * 0.3)
        - math.floor((carrier_spec.visibility or 50) * 0.1)
    local roll = math.abs(rumor.reach * 7 + (carrier_spec.volatility or 30) * 3) % 100
    if roll < mutation_chance then
        Network.mutate(rumor)
    end

    return true
end

--[[
    Propagate rumors through available carriers.
    carriers: array of { id, name, visibility, volatility, temperament }
    Returns lines describing what spread this tick.
]]
function Network.propagate(game_state, carriers)
    if not game_state or not carriers then return {} end
    local state = Network.ensure_state(game_state)
    local lines = {}

    for rumor_id, rumor in pairs(state.rumors) do
        if not rumor.dead and not rumor.calcified and rumor.heat >= 15 then
            -- Sort carriers by visibility (loudspeakers first)
            local sorted = {}
            for _, c in ipairs(carriers) do
                if not rumor.carriers[c.id] then
                    sorted[#sorted + 1] = c
                end
            end
            table.sort(sorted, function(a, b)
                return (a.visibility or 0) > (b.visibility or 0)
            end)

            -- Spread to up to 2 new carriers per tick per rumor
            local spread_count = 0
            local max_spread = rumor.heat >= 60 and 3 or 2
            for _, carrier in ipairs(sorted) do
                if spread_count >= max_spread then break end
                -- Visibility gate: low-visibility bonds are harder to reach
                if (carrier.visibility or 0) >= 30 or rumor.heat >= 70 then
                    local heard = Network.spread_to(game_state, rumor_id, carrier)
                    if heard then
                        spread_count = spread_count + 1
                    end
                end
            end

            if spread_count > 0 and rumor.reach >= 3 then
                lines[#lines + 1] = "A story about " .. rumor.subject .. " is traveling."
            end
        end
    end

    return lines
end

--[[
    Mutate a rumor. Called when a new carrier distorts the story.
]]
function Network.mutate(rumor)
    if not rumor then return end
    rumor.mutations = (rumor.mutations or 0) + 1
    rumor.truth_score = Math.clamp((rumor.truth_score or 90) - (8 + rumor.mutations * 3), 0, 100)

    -- Pick a mutation type deterministically from mutation count
    -- Pick mutation type deterministically
    rumor.last_mutation_type = ({"inflate", "deflect", "invert", "detail_loss", "embellish"})[
        ((rumor.mutations * 7 + rumor.reach * 3) % 5) + 1
    ]
end

--[[
    Tick the network: cool rumors, calcify old ones, kill dead ones.
    Called once per year/generation.
]]
function Network.tick(game_state, generation)
    if not game_state then return {} end
    local state = Network.ensure_state(game_state)
    state.generation = generation or (state.generation + 1)
    local lines = {}

    for rumor_id, rumor in pairs(state.rumors) do
        if rumor.dead then
            -- Leave dead rumors for history, but stop processing
        elseif rumor.calcified then
            -- Calcified rumors are permanent reputation — no further changes
        else
            -- Cool heat
            local cool_rate = 8
            if rumor.confirmed then cool_rate = 3 end
            if rumor.denied and rumor.truth_score <= 40 then cool_rate = 14 end
            rumor.heat = Math.clamp(rumor.heat - cool_rate, 0, 100)

            -- Severity decay for low-importance rumors
            if rumor.severity <= 2 then
                rumor.heat = Math.clamp(rumor.heat - 4, 0, 100)
            end

            -- Calcification: high-reach, high-severity rumors become permanent
            if rumor.reach >= 4 and rumor.severity >= 3 and (state.generation - rumor.generation) >= 2 then
                rumor.calcified = true
                Network.apply_reputation(state, rumor)
                lines[#lines + 1] = "The story about " .. rumor.subject .. " has become fact in the mouths of those who matter."
            end

            -- Death: heat exhausted
            if rumor.heat <= 0 then
                rumor.dead = true
            end
        end
    end

    return lines
end

--[[
    Apply a calcified rumor to the reputation ledger.
]]
function Network.apply_reputation(state, rumor)
    if not state or not rumor then return end
    local subject = rumor.subject
    state.reputation[subject] = state.reputation[subject] or { score = 0, tags = {}, sources = {} }
    local rep = state.reputation[subject]

    -- Negative rumors (shame, violence, betrayal) lower score
    -- Positive rumors (generosity, courage) raise it
    local delta = 0
    for _, tag in ipairs(rumor.tags or {}) do
        if tag == "shame" or tag == "betrayal" or tag == "cowardice" or tag == "cruelty" then
            delta = delta - rumor.severity * 3
        elseif tag == "courage" or tag == "generosity" or tag == "honor" or tag == "skill" then
            delta = delta + rumor.severity * 2
        else
            delta = delta - rumor.severity -- ambiguous rumors default slightly negative
        end
        -- Track unique tags
        local found = false
        for _, existing in ipairs(rep.tags) do
            if existing == tag then found = true; break end
        end
        if not found then rep.tags[#rep.tags + 1] = tag end
    end

    rep.score = Math.clamp(rep.score + delta, -100, 100)
    rep.sources[#rep.sources + 1] = {
        rumor_id = rumor.id,
        text = rumor.current_text,
        truth = rumor.truth_score,
        generation = rumor.generation,
    }
    -- Cap sources
    while #rep.sources > 10 do
        table.remove(rep.sources, 1)
    end
end

--[[
    Player actions: confirm, deny, or weaponize a rumor.
]]
function Network.confirm(game_state, rumor_id)
    if not game_state then return nil end
    local state = Network.ensure_state(game_state)
    local rumor = state.rumors[rumor_id]
    if not rumor or rumor.dead then return nil end
    rumor.confirmed = true
    rumor.denied = false
    rumor.heat = Math.clamp(rumor.heat + 20, 0, 100)
    rumor.truth_score = Math.clamp(rumor.truth_score + 15, 0, 100)
    rumor.severity = Math.clamp(rumor.severity + 1, 1, 5)
    return rumor
end

function Network.deny(game_state, rumor_id)
    if not game_state then return nil end
    local state = Network.ensure_state(game_state)
    local rumor = state.rumors[rumor_id]
    if not rumor or rumor.dead then return nil end
    rumor.denied = true
    rumor.confirmed = false
    -- Denying a true rumor is risky: if truth is high, denial backfires
    if rumor.truth_score >= 60 then
        rumor.heat = Math.clamp(rumor.heat + 10, 0, 100)
        rumor.severity = Math.clamp(rumor.severity + 1, 1, 5)
    else
        rumor.heat = Math.clamp(rumor.heat - 15, 0, 100)
    end
    return rumor
end

function Network.weaponize(game_state, rumor_id, target_carrier_spec)
    if not game_state or not rumor_id or not target_carrier_spec then return false end
    local state = Network.ensure_state(game_state)
    local rumor = state.rumors[rumor_id]
    if not rumor or rumor.dead then return false end
    rumor.heat = Math.clamp(rumor.heat + 25, 0, 100)
    return Network.spread_to(game_state, rumor_id, target_carrier_spec)
end

--[[
    Query: get all active rumors about a subject.
]]
function Network.about(game_state, subject)
    if not game_state then return {} end
    local state = Network.ensure_state(game_state)
    local results = {}
    for _, rumor in pairs(state.rumors) do
        if not rumor.dead and rumor.subject == subject then
            results[#results + 1] = rumor
        end
    end
    table.sort(results, function(a, b) return a.heat > b.heat end)
    return results
end

--[[
    Query: get all rumors a specific carrier has heard.
]]
function Network.known_by(game_state, carrier_id)
    if not game_state then return {} end
    local state = Network.ensure_state(game_state)
    local results = {}
    for _, rumor in pairs(state.rumors) do
        if not rumor.dead and rumor.carriers[carrier_id] then
            results[#results + 1] = rumor
        end
    end
    table.sort(results, function(a, b) return a.heat > b.heat end)
    return results
end

--[[
    Query: get reputation for a subject.
]]
function Network.reputation(game_state, subject)
    if not game_state then return { score = 0, tags = {}, sources = {} } end
    local state = Network.ensure_state(game_state)
    return state.reputation[subject] or { score = 0, tags = {}, sources = {} }
end

--[[
    Query: get the hottest rumors currently circulating.
]]
function Network.hottest(game_state, limit)
    if not game_state then return {} end
    local state = Network.ensure_state(game_state)
    limit = limit or 3
    local results = {}
    for _, rumor in pairs(state.rumors) do
        if not rumor.dead and rumor.heat >= 15 then
            results[#results + 1] = rumor
        end
    end
    table.sort(results, function(a, b) return a.heat > b.heat end)
    local out = {}
    for i = 1, math.min(limit, #results) do
        out[#out + 1] = results[i]
    end
    return out
end

--[[
    Chronicle fragments: produce narrative lines for the storyteller.
]]
function Network.chronicle_fragments(game_state, limit)
    if not game_state then return {} end
    local state = Network.ensure_state(game_state)
    limit = limit or 4
    local fragments = {}

    -- Calcified rumors first (they're the permanent record)
    for _, rumor in pairs(state.rumors) do
        if rumor.calcified and #fragments < limit then
            local accuracy = ""
            if rumor.truth_score <= 30 then
                accuracy = " The version that survived bears little resemblance to what happened."
            elseif rumor.truth_score <= 60 then
                accuracy = " The story is close enough to wound, far enough to deny."
            end
            fragments[#fragments + 1] = "It is known that " .. string.lower(rumor.current_text) .. accuracy
        end
    end

    -- Hot rumors
    for _, rumor in pairs(state.rumors) do
        if not rumor.dead and not rumor.calcified and rumor.heat >= 40 and #fragments < limit then
            local spread = ""
            if rumor.reach >= 4 then
                spread = " The story has " .. tostring(rumor.reach) .. " mouths now."
            end
            fragments[#fragments + 1] = "A rumor circulates: " .. string.lower(rumor.current_text) .. spread
        end
    end

    return fragments
end

return Network
