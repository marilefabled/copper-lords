-- dredwork Dialogue — Logic
-- Personality-driven dialogue: greetings, world commentary, court speech, rival speech.
-- Uses Templates for text pools, selects based on personality axes and world state.

local RNG = require("dredwork_core.rng")
local Templates = require("dredwork_dialogue.templates")

local Logic = {}

--- Determine the dominant personality axis for a speaker.
local function get_dominant(personality)
    if not personality then return "default" end

    local checks = {
        { id = "bold",     axis = "PER_BLD", threshold = 65 },
        { id = "cautious", axis = "PER_BLD", threshold = 35, invert = true },
        { id = "cunning",  axis = "PER_OBS", threshold = 65 },
        { id = "friendly", axis = "PER_LOY", threshold = 65 },
        { id = "loyal",    axis = "PER_LOY", threshold = 70 },
        { id = "volatile", axis = "PER_VOL", threshold = 65 },
        { id = "proud",    axis = "PER_PRI", threshold = 65 },
        { id = "curious",  axis = "PER_CUR", threshold = 65 },
    }

    local best_id = "default"
    local best_dist = 0

    for _, check in ipairs(checks) do
        local val = personality[check.axis] or 50
        local dist
        if check.invert then
            dist = check.threshold - val
        else
            dist = val - check.threshold
        end
        if dist > best_dist then
            best_dist = dist
            best_id = check.id
        end
    end

    return best_id
end

--- Get the current world mood from game_state fields.
local function get_world_mood(gs)
    if gs.politics and gs.politics.unrest and gs.politics.unrest > 60 then return "unrest" end
    if gs.perils and gs.perils.active and #gs.perils.active > 0 then
        for _, p in ipairs(gs.perils.active) do
            if p.category == "disease" then return "plague" end
        end
        return "war" -- use war as generic disaster
    end
    if gs.markets then
        for _, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 15 then return "famine" end
        end
    end
    if gs.underworld and gs.underworld.global_corruption > 50 then return "corruption" end
    if gs.resources and gs.resources.gold > 500 then return "prosperity" end
    return "peace"
end

--- Extract personality from various character formats.
local function extract_personality(speaker)
    if not speaker then return nil end
    -- Direct personality table (rival heirs, court members with traits)
    if speaker.personality then
        if type(speaker.personality) == "table" then return speaker.personality end
    end
    -- Genome traits (heir)
    if speaker.traits then
        local p = {}
        for id, t in pairs(speaker.traits) do
            p[id] = type(t) == "table" and t.value or t
        end
        return p
    end
    return nil
end

--- Generate a reactive greeting.
function Logic.get_greeting(speaker, context)
    local personality = extract_personality(speaker)
    local dominant = get_dominant(personality)

    local pool = Templates.greetings[dominant]
    if not pool then pool = {Templates.greetings.default} end
    if type(pool) == "string" then return pool end

    local line = RNG.pick(pool) or Templates.greetings.default

    if context and context.historical_reference then
        line = line .. " " .. context.historical_reference
    end

    return line
end

--- Generate a contextual comment based on world state.
function Logic.get_contextual_comment(speaker, gs)
    local mood = get_world_mood(gs)
    local pool = Templates.world_state[mood]
    if not pool or #pool == 0 then
        pool = Templates.world_state.peace or {"..."}
    end
    return RNG.pick(pool)
end

--- Generate court member dialogue based on their role.
function Logic.get_court_dialogue(member)
    if not member or not member.role then return nil end
    local pool = Templates.court[member.role]
    if not pool or #pool == 0 then return nil end
    return RNG.pick(pool)
end

--- Generate rival dialogue based on their attitude.
function Logic.get_rival_dialogue(rival_heir)
    if not rival_heir or not rival_heir.attitude then return nil end
    local pool = Templates.rival[rival_heir.attitude]
    if not pool or #pool == 0 then return nil end
    return RNG.pick(pool)
end

--- Comment on a specific subject based on world rumors.
function Logic.get_rumor_comment(subject, reputation)
    local tone = "neutral"
    if reputation then
        if reputation.score then
            if reputation.score > 20 then tone = "praise"
            elseif reputation.score < -20 then tone = "shame"
            end
        end
        if reputation.tags then
            if reputation.tags.scandal then tone = "scandal" end
            if reputation.tags.danger then tone = "danger" end
            if reputation.tags.fear then tone = "fear" end
            if reputation.tags.wealth then tone = "wealth" end
            if reputation.tags.prestige then tone = "prestige" end
            if reputation.tags.migration then tone = "migration" end
        end
    end

    local template = Templates.rumor_reaction[tone] or Templates.rumor_reaction.neutral
    return string.format(template, subject)
end

--- Query a speaker's memory for lines referencing shared history with a focal entity.
---@param speaker table entity with components.memory
---@param focal_id string the player entity id
---@param gs table game_state
---@return string|nil a memory-driven opening line
function Logic.get_memory_line(speaker, focal_id, gs)
    if not speaker or not speaker.components or not speaker.components.memory then return nil end
    local mem = speaker.components.memory

    -- Check grudges
    if mem.grudges then
        for _, g in ipairs(mem.grudges) do
            if g.target_id == focal_id and (g.intensity or 0) > 10 then
                return RNG.pick(Templates.memory_grudge or {})
            end
        end
    end

    -- Check debts
    if mem.debts then
        for _, d in ipairs(mem.debts) do
            if d.target_id == focal_id and (d.amount or 0) > 10 then
                return RNG.pick(Templates.memory_gratitude or {})
            end
        end
    end

    -- Check recent shared events
    if mem.events then
        for i = #mem.events, math.max(1, #mem.events - 5), -1 do
            local e = mem.events[i]
            if e and e.related_entity == focal_id then
                return RNG.pick(Templates.memory_witnessed or {})
            end
        end
    end

    return nil
end

--- Get a context-aware line based on the focal entity's current state.
---@param speaker table entity
---@param focal table focal entity
---@param gs table game_state
---@return string|nil a contextual line
function Logic.get_context_line(speaker, focal, gs)
    if not focal then return nil end

    -- Wealth sympathy
    local pw = focal.components.personal_wealth
    if pw and pw.gold <= 0 then
        return RNG.pick(Templates.context_wealth_sympathy or {})
    end

    -- Claim awareness
    if gs.claim and gs.claim.status ~= "hidden" then
        local known_by = gs.claim.known_by or {}
        for _, kid in ipairs(known_by) do
            if kid == speaker.id then
                return RNG.pick(Templates.context_claim_aware or {})
            end
        end
    end

    -- Reputation reference
    local patterns_data = gs.patterns
    if patterns_data and patterns_data.reputation_label then
        local pool = Templates.context_reputation
        if pool and #pool > 0 then
            return string.format(RNG.pick(pool), patterns_data.reputation_label)
        end
    end

    return nil
end

--- Generate a full dialogue exchange for an NPC.
---@param speaker table character with personality and/or role
---@param gs table game_state
---@param context table|nil { historical_reference, subject, reputation, memory_line, context_line }
---@return table { greeting, comment, mood_line, memory_line, context_line }
function Logic.generate_exchange(speaker, gs, context)
    local result = {
        greeting = Logic.get_greeting(speaker, context),
    }

    -- World state comment
    result.comment = Logic.get_contextual_comment(speaker, gs)

    -- Role-specific line (if court member)
    if speaker.role then
        result.role_line = Logic.get_court_dialogue(speaker)
    end

    -- Attitude-specific line (if rival heir)
    if speaker.attitude then
        result.attitude_line = Logic.get_rival_dialogue(speaker)
    end

    -- Rumor comment (if subject provided)
    if context and context.subject and context.reputation then
        result.rumor_line = Logic.get_rumor_comment(context.subject, context.reputation)
    end

    -- Memory-driven line (pass through if provided, or from context)
    if context and context.memory_line then
        result.memory_line = context.memory_line
    end

    -- Context-aware line
    if context and context.context_line then
        result.context_line = context.context_line
    end

    return result
end

return Logic
